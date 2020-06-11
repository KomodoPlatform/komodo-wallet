/******************************************************************************
 * Copyright © 2013-2019 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

//! Project Headers
#include "atomic.dex.mm2.hpp"
#include "atomic.dex.kill.hpp"
#include "atomic.dex.mm2.config.hpp"
#include "atomic.threadpool.hpp"

//! Anonymous functions
namespace
{
    namespace ag = antara::gaming;

    void
    update_coin_status(const std::vector<std::string> tickers, bool status = true)
    {
        fs::path       cfg_path = ag::core::assets_real_path() / "config";
        std::ifstream  ifs((cfg_path / "coins.json").c_str());
        nlohmann::json config_json_data;

        assert(ifs.is_open());
        ifs >> config_json_data;

        for (auto&& ticker: tickers) { config_json_data.at(ticker)["active"] = status; }

        ifs.close();

        //! Write contents
        std::ofstream ofs((cfg_path / "coins.json").c_str(), std::ios::trunc);
        assert(ofs.is_open());
        ofs << config_json_data;
    }

    bool
    retrieve_coins_information(atomic_dex::t_coins_registry& coins_registry)
    {
        const auto cfg_path = ag::core::assets_real_path() / "config";
        if (exists(cfg_path / "coins.json"))
        {
            std::ifstream ifs((cfg_path / "coins.json").c_str());
            assert(ifs.is_open());
            nlohmann::json config_json_data;
            ifs >> config_json_data;
            auto res = config_json_data.get<std::unordered_map<std::string, atomic_dex::coin_config>>();
            for (auto&& [key, value]: res) { coins_registry.insert_or_assign(key, value); }
            return true;
        }
        return false;
    }
} // namespace

namespace atomic_dex
{
    mm2::mm2(entt::registry& registry) : system(registry)
    {
        m_orderbook_clock = std::chrono::high_resolution_clock::now();
        m_info_clock      = std::chrono::high_resolution_clock::now();

        dispatcher_.sink<gui_enter_trading>().connect<&mm2::on_gui_enter_trading>(*this);
        dispatcher_.sink<gui_leave_trading>().connect<&mm2::on_gui_leave_trading>(*this);
        dispatcher_.sink<orderbook_refresh>().connect<&mm2::on_refresh_orderbook>(*this);

        m_swaps_registry.insert("result", t_my_recent_swaps_answer{.total = 0});
        retrieve_coins_information(m_coins_informations);
    }

    void
    mm2::update() noexcept
    {
        using namespace std::chrono_literals;

        if (not m_mm2_running)
        {
            return;
        }

        const auto now    = std::chrono::high_resolution_clock::now();
        const auto s      = std::chrono::duration_cast<std::chrono::seconds>(now - m_orderbook_clock);
        const auto s_info = std::chrono::duration_cast<std::chrono::seconds>(now - m_info_clock);

        if (s >= 5s)
        {
            spawn([this]() { fetch_current_orderbook_thread(); });
            m_orderbook_clock = std::chrono::high_resolution_clock::now();
        }

        if (s_info >= 30s)
        {
            spawn([this]() { fetch_infos_thread(); });
            m_info_clock = std::chrono::high_resolution_clock::now();
        }
    }

    mm2::~mm2() noexcept
    {
        m_mm2_running = false;

#if defined(_WIN32) || defined(WIN32)
        atomic_dex::kill_executable("mm2");
#else
        const reproc::stop_actions stop_actions = {
            {reproc::stop::terminate, reproc::milliseconds(2000)},
            {reproc::stop::kill, reproc::milliseconds(5000)},
            {reproc::stop::wait, reproc::milliseconds(2000)}};

        const auto ec = m_mm2_instance.stop(stop_actions).second;

        if (ec)
        {
            spdlog::error("error: {}", ec.message());
        }
#endif

        if (m_mm2_init_thread.joinable())
        {
            m_mm2_init_thread.join();
        }

        dispatcher_.sink<gui_enter_trading>().disconnect<&mm2::on_gui_enter_trading>(*this);
        dispatcher_.sink<gui_leave_trading>().disconnect<&mm2::on_gui_leave_trading>(*this);
        dispatcher_.sink<orderbook_refresh>().disconnect<&mm2::on_refresh_orderbook>(*this);
    }

    const std::atomic_bool&
    mm2::is_mm2_running() const noexcept
    {
        return m_mm2_running;
    }

    t_coins
    mm2::get_enabled_coins() const noexcept
    {
        t_coins destination;

        for (auto&& [key, value]: m_coins_informations)
        {
            if (value.currently_enabled)
            {
                destination.push_back(value);
            }
        }

        std::sort(begin(destination), end(destination), [](auto&& lhs, auto&& rhs) { return lhs.ticker < rhs.ticker; });

        return destination;
    }

    t_coins
    mm2::get_enableable_coins() const noexcept
    {
        t_coins destination;

        for (auto&& [key, value]: m_coins_informations)
        {
            if (not value.currently_enabled)
            {
                destination.emplace_back(value);
            }
        }

        return destination;
    }

    t_coins
    mm2::get_active_coins() const noexcept
    {
        t_coins destination;

        for (auto&& [key, value]: m_coins_informations)
        {
            if (value.active)
            {
                destination.emplace_back(value);
            }
        }

        return destination;
    }

    bool
    mm2::disable_coin(const std::string& ticker, std::error_code& ec) noexcept
    {
        coin_config coin_info = m_coins_informations.at(ticker);
        if (not coin_info.currently_enabled)
        {
            return true;
        }

        t_disable_coin_request request{.coin = ticker};
        auto                   answer = rpc_disable_coin(std::move(request));

        if (answer.error.has_value())
        {
            std::string error = answer.error.value();
            if (error.find("such coin") != std::string::npos)
            {
                ec = dextop_error::disable_unknown_coin;
                return false;
            }
            else if (error.find("active swaps") != std::string::npos)
            {
                ec = dextop_error::active_swap_is_using_the_coin;
                return false;
            }
            else if (error.find("matching orders") != std::string::npos)
            {
                ec = dextop_error::order_is_matched_at_the_moment;
                return false;
            }
        }

        coin_info.currently_enabled = false;
        m_coins_informations.assign(coin_info.ticker, coin_info);

        dispatcher_.trigger<coin_disabled>(ticker);
        return true;
    }

    bool
    mm2::enable_coin(const std::string& ticker, bool emit_event)
    {
        coin_config coin_info = m_coins_informations.at(ticker);

        if (coin_info.currently_enabled)
        {
            return true;
        }

        if (not coin_info.is_erc_20)
        {
            t_electrum_request request{.coin_name = coin_info.ticker, .servers = coin_info.electrum_urls.value(), .with_tx_history = true};
            auto               answer = rpc_electrum(std::move(request));
            if (answer.result not_eq "success")
            {
                return false;
            }
        }
        else
        {
            t_enable_request request{.coin_name = coin_info.ticker, .urls = coin_info.eth_urls.value()};
            auto             answer = rpc_enable(std::move(request));
            if (answer.result not_eq "success")
            {
                return false;
            }
        }


        coin_info.currently_enabled = true;
        m_coins_informations.assign(coin_info.ticker, coin_info);

        spawn([this, copy_ticker = ticker]() {
            // loguru::set_thread_name("balance thread");
            process_balance(copy_ticker);
        });

        spawn([this, copy_ticker = ticker]() {
            // loguru::set_thread_name("tx thread");
            process_tx(copy_ticker);
        });

        dispatcher_.trigger<coin_enabled>(ticker);
        if (emit_event)
        {
            this->dispatcher_.trigger<enabled_coins_event>();
        }
        return true;
    }

    bool
    mm2::enable_default_coins() noexcept
    {
        using t_futures = std::vector<std::future<void>>;

        t_futures                futures;
        std::atomic<std::size_t> result{1};
        auto                     coins = get_active_coins();

        futures.reserve(1);

        std::vector<std::string> tickers;
        tickers.reserve(coins.size());
        for (auto&& current_coin: coins) { tickers.push_back(current_coin.ticker); }

        futures.emplace_back(spawn([this, tickers]() {
            // loguru::set_thread_name("enable thread");
            batch_enable_coins(tickers);
        }));

        for (auto&& fut: futures) { fut.get(); }

        this->dispatcher_.trigger<enabled_coins_event>();

        spawn([this]() {
            // loguru::set_thread_name("swaps thread");
            process_swaps();
        });

        spawn([this]() {
            // loguru::set_thread_name("orders thread");
            process_orders();
        });

        // spawn([this]() { process_fees(); });

        return result.load() == 1;
    }

    void
    mm2::disable_multiple_coins(const std::vector<std::string>& tickers) noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        for (const auto& ticker: tickers)
        {
            spawn([this, ticker]() {
                // loguru::set_thread_name("disable multiple coins");
                std::error_code ec;
                disable_coin(ticker, ec);
                if (ec)
                {
                    spdlog::warn("{}", ec.message());
                }
            });
        }

        update_coin_status(tickers, false);
    }

    void
    mm2::batch_enable_coins(const std::vector<std::string>& tickers, bool emit_event) noexcept
    {
        std::vector<t_electrum_request> requests;
        std::vector<t_enable_request>   requests_erc;

        for (const auto& ticker: tickers)
        {
            coin_config coin_info = m_coins_informations.at(ticker);

            if (coin_info.currently_enabled)
            {
                continue;
            }

            if (not coin_info.is_erc_20)
            {
                t_electrum_request request{.coin_name = coin_info.ticker, .servers = coin_info.electrum_urls.value(), .with_tx_history = true};
                requests.emplace_back(request);
            }
            else
            {
                t_enable_request request{.coin_name = coin_info.ticker, .urls = coin_info.eth_urls.value(), .with_tx_history = true};
                requests_erc.emplace_back(request);
            }
        }

        auto functor_process_answer = [this, &emit_event](const nlohmann::json& answer) {
            if (answer.count("coin") == 1)
            {
                auto        ticker          = answer.at("coin").get<std::string>();
                coin_config coin_info       = m_coins_informations.at(ticker);
                coin_info.currently_enabled = true;
                m_coins_informations.assign(coin_info.ticker, coin_info);

                spawn([this, copy_ticker = ticker]() {
                    // loguru::set_thread_name("balance thread");
                    process_balance(copy_ticker);
                });

                spawn([this, copy_ticker = ticker]() {
                    // loguru::set_thread_name("tx thread");
                    process_tx(copy_ticker);
                });

                dispatcher_.trigger<coin_enabled>(ticker);
                if (emit_event)
                {
                    this->dispatcher_.trigger<enabled_coins_event>();
                }
            }
        };

        if (not requests.empty())
        {
            auto answers = rpc_batch_electrum(requests);
            if (answers.count("error") == 0)
            {
                for (auto&& answer: answers) { functor_process_answer(answer); }
            }
        }

        if (not requests_erc.empty())
        {
            auto answers_erc = rpc_batch_enable(requests_erc);
            if (answers_erc.count("error") == 0)
            {
                for (auto&& answer_erc: answers_erc) { functor_process_answer(answer_erc); }
            }
        }
    }

    void
    mm2::enable_multiple_coins(const std::vector<std::string>& tickers) noexcept
    {
        spawn([this, tickers]() {
            // loguru::set_thread_name("enable multiple coins");
            batch_enable_coins(tickers, true);
        });
        /*for (const auto& ticker: tickers)
        {
            spawn([this, ticker]() {
                //loguru::set_thread_name("enable multiple coins");
                enable_coin(ticker, true);
            });
        }*/

        update_coin_status(tickers, true);
    }

    coin_config
    mm2::get_coin_info(const std::string& ticker) const
    {
        if (m_coins_informations.find(ticker) == m_coins_informations.cend())
        {
            return {};
        }
        return m_coins_informations.at(ticker);
    }

    std::vector<t_orderbook_answer>
    mm2::get_orderbook(const std::string& ticker, t_mm2_ec& ec) const noexcept
    {
        if (m_current_orderbook.empty())
        {
            ec = dextop_error::orderbook_empty;
            return {};
        }
        if (m_current_orderbook.find(ticker) == m_current_orderbook.cend())
        {
            ec = dextop_error::orderbook_ticker_not_found;
            return {};
        }
        return m_current_orderbook.at(ticker);
    }

    void
    mm2::process_orderbook(std::string base)
    {
        auto&&                          coins = get_enabled_coins();
        std::vector<t_orderbook_answer> out;
        out.reserve(coins.size() - 1);

        for (auto&& current_coin: coins)
        {
            if (current_coin.ticker != base)
            {
                t_orderbook_request request{.base = base, .rel = current_coin.ticker};
                auto                answer = rpc_orderbook(std::move(request));
                if (answer.rpc_result_code not_eq -1)
                {
                    out.emplace_back(answer);
                }
            }
        }
        m_current_orderbook.insert_or_assign(base, out);
    }

    void
    mm2::fetch_current_orderbook_thread()
    {
        ////loguru::set_thread_name("orderbook thread");
        spdlog::info("Fetch current orderbook");

        //! If thread is not active ex: we are not on the trading page anymore, we continue sleeping.
        if (not m_orderbook_thread_active)
        {
            spdlog::warn("Nothing todo, sleeping");
            return;
        }

        // std::string current = (*m_current_orderbook.begin()).first;

        this->m_orderbook_mutex.try_lock();
        std::string copy = m_current_orderbook_ticker_base;
        this->m_orderbook_mutex.unlock();
        process_orderbook(m_current_orderbook_ticker_base);
    }

    void
    mm2::fetch_infos_thread()
    {
        // loguru::set_thread_name("info thread");
        spdlog::info("{}: Fetching Infos l{}", __FUNCTION__, __LINE__);

        t_coins                        coins = get_enabled_coins();
        std::vector<std::future<void>> futures;

        futures.reserve(coins.size() * 2 + 2);

        futures.emplace_back(spawn([this]() {
            // loguru::set_thread_name("swaps thread");
            process_swaps();
        }));

        futures.emplace_back(spawn([this]() {
            // loguru::set_thread_name("orders thread");
            process_orders();
        }));

        for (auto&& current_coin: coins)
        {
            futures.emplace_back(spawn([this, ticker = current_coin.ticker]() {
                // loguru::set_thread_name("balance thread");
                process_balance(ticker);
            }));
            futures.emplace_back(spawn([this, ticker = current_coin.ticker]() {
                // loguru::set_thread_name("tx thread");
                process_tx(ticker);
            }));
        }

        for (auto&& fut: futures) { fut.get(); }
    }

    void
    mm2::spawn_mm2_instance(std::string passphrase)
    {
        mm2_config cfg{.passphrase = std::move(passphrase)};
        json       json_cfg;
        const auto tools_path = ag::core::assets_real_path() / "tools/mm2/";

        nlohmann::to_json(json_cfg, cfg);

        const std::array<std::string, 2> args = {(tools_path / "mm2").string(), json_cfg.dump()};
        reproc::options                  options;
        options.redirect.parent   = true;
        options.working_directory = strdup(tools_path.string().c_str());

        const auto ec = m_mm2_instance.start(args, options);

        if (ec)
        {
            spdlog::error("{}", ec.message());
        }

        m_mm2_init_thread = std::thread([this]() {
            using namespace std::chrono_literals;
            // loguru::set_thread_name("mm2 init thread");

            const auto wait_ec = m_mm2_instance.wait(2s).second;

            if (wait_ec.value() == static_cast<int>(std::errc::timed_out) || wait_ec.value() == 258)
            {
                spdlog::info("mm2 is initialized");
                dispatcher_.trigger<mm2_initialized>();
                enable_default_coins();
                m_mm2_running = true;
                dispatcher_.trigger<mm2_started>();
            }
            else
            {
                spdlog::error("{}", wait_ec.message());
            }
        });
    }

    std::string
    mm2::my_balance_with_locked_funds(const std::string& ticker, t_mm2_ec& ec) const
    {
        if (m_balance_informations.find(ticker) == m_balance_informations.cend())
        {
            ec = dextop_error::balance_of_a_non_enabled_coin;
            return "0";
        }

        t_float_50 final_balance = get_balance_with_locked_funds(ticker);

        return final_balance.convert_to<std::string>();
    }

    t_float_50
    mm2::get_balance_with_locked_funds(const std::string& ticker) const
    {
        if (m_balance_informations.find(ticker) == m_balance_informations.end())
        {
            return 0;
        }
        const auto       answer = m_balance_informations.at(ticker);
        const t_float_50 balance(answer.balance);
        const t_float_50 locked_funds(answer.locked_by_swaps);
        auto             final_balance = balance - locked_funds;

        return final_balance;
    }

    t_transactions
    mm2::get_tx_history(const std::string& ticker, t_mm2_ec& ec) const
    {
        if (m_tx_informations.find(ticker) == m_tx_informations.cend())
        {
            ec = dextop_error::tx_history_of_a_non_enabled_coin;
            return {};
        }

        return m_tx_informations.at(ticker);
    }

    std::string
    mm2::my_balance(const std::string& ticker, t_mm2_ec& ec) const
    {
        if (m_balance_informations.find(ticker) == m_balance_informations.cend())
        {
            ec = dextop_error::balance_of_a_non_enabled_coin;
            return "0";
        }

        return m_balance_informations.at(ticker).balance;
    }

    t_withdraw_answer
    mm2::withdraw(t_withdraw_request&& request, t_mm2_ec& ec) noexcept
    {
        auto result = rpc_withdraw(std::move(request));
        if (result.error.has_value())
        {
            ec = dextop_error::rpc_withdraw_error;
        }
        if (result.raw_result.find("Not sufficient balance. Couldn't collect enough value from utxos") != std::string::npos)
        {
            result.error = "Not enough funds to cover txfee, please reduce amount.";
        }
        return result;
    }

    t_broadcast_answer
    mm2::broadcast(t_broadcast_request&& request, t_mm2_ec& ec) noexcept
    {
        auto result = rpc_send_raw_transaction(std::move(request));
        if (result.rpc_result_code == -1)
        {
            ec = dextop_error::rpc_send_raw_transaction_error;
        }
        return result;
    }

    void
    mm2::process_balance(const std::string& ticker) const
    {
        t_balance_request balance_request{.coin = ticker};
        auto              answer = rpc_balance(std::move(balance_request));
        if (answer.raw_result.find("error") == std::string::npos)
        {
            m_balance_informations.insert_or_assign(ticker, answer);
        }
    }

    void
    mm2::process_swaps()
    {
        t_my_recent_swaps_request request{.limit = 50};
        auto                      answer = rpc_my_recent_swaps(std::move(request));
        if (answer.result.has_value())
        {
            m_swaps_registry.insert_or_assign("result", answer.result.value());
        }

        /*if (not m_swaps_registry.empty())
        {
            auto swaps = get_swaps();

            for (auto &&swap : swaps.swaps) {
                for (auto&& event : swap.events) {
                    std::cout << event << std::endl;
                }
            }
        }*/
    }

    void
    mm2::process_orders()
    {
        m_orders_registry.insert_or_assign("result", ::mm2::api::rpc_my_orders());
    }

    void
    mm2::process_fees()
    {
        // loguru::set_thread_name("fees thread");
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        t_coins                        coins = get_enabled_coins();
        std::vector<std::future<void>> futures;

        if (not m_current_orderbook_ticker_rel.empty())
        {
            futures.reserve(2);
        }
        else
        {
            futures.reserve(1);
        }

        auto rpc_fees = [this]() {
            t_get_trade_fee_request req{.coin = this->m_current_orderbook_ticker_base};
            auto                    answer = ::mm2::api::rpc_get_trade_fee(std::move(req));
            this->m_trade_fees_registry.insert_or_assign(this->m_current_orderbook_ticker_base, answer);

            if (not m_current_orderbook_ticker_rel.empty())
            {
                t_get_trade_fee_request req_rel{.coin = this->m_current_orderbook_ticker_rel};
                auto                    answer_rel = ::mm2::api::rpc_get_trade_fee(std::move(req_rel));
                this->m_trade_fees_registry.insert_or_assign(this->m_current_orderbook_ticker_rel, answer_rel);
            }
        };

        futures.emplace_back(spawn(rpc_fees));

        for (auto&& fut: futures) { fut.get(); }
    }

    void
    mm2::process_tx(const std::string& ticker)
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        t_tx_history_request tx_request{.coin = ticker, .limit = g_tx_max_limit};
        auto                 answer = rpc_my_tx_history(std::move(tx_request));

        if (answer.error.has_value())
        {
            spdlog::error("{}", answer.error.value());
        }
        else if (answer.rpc_result_code not_eq -1 and answer.result.has_value())
        {
            t_tx_state state{
                .state             = answer.result.value().sync_status.state,
                .current_block     = answer.result.value().current_block,
                .transactions_left = 0,
                .blocks_left       = 0};

            if (answer.result.value().sync_status.additional_info.has_value())
            {
                if (answer.result.value().sync_status.additional_info.value().erc_infos.has_value())
                {
                    state.blocks_left = answer.result.value().sync_status.additional_info.value().erc_infos.value().blocks_left;
                }
                if (answer.result.value().sync_status.additional_info.value().regular_infos.has_value())
                {
                    state.transactions_left = answer.result.value().sync_status.additional_info.value().regular_infos.value().transactions_left;
                }
            }

            t_transactions out;
            out.reserve(answer.result.value().transactions.size());

            for (auto&& current: answer.result.value().transactions)
            {
                tx_infos current_info{

                    .am_i_sender   = current.my_balance_change[0] == '-',
                    .confirmations = current.confirmations.has_value() ? current.confirmations.value() : 0,
                    .from          = current.from,
                    .to            = current.to,
                    .date          = current.timestamp_as_date,
                    .timestamp     = current.timestamp,
                    .tx_hash       = current.tx_hash,
                    .fees          = current.fee_details.normal_fees.has_value() ? current.fee_details.normal_fees.value().amount
                                                                        : current.fee_details.erc_fees.value().total_fee,
                    .my_balance_change = current.my_balance_change,
                    .total_amount      = current.total_amount,
                    .block_height      = current.block_height,
                    .ec                = dextop_error::success,
                };
                if (get_coin_info(ticker).is_erc_20)
                {
                    current_info.tx_hash = "0x" + current_info.tx_hash;
                }
                out.push_back(std::move(current_info));
            }

            std::sort(begin(out), end(out), [](auto&& a, auto&& b) { return a.timestamp > b.timestamp; });

            m_tx_informations.insert_or_assign(ticker, std::move(out));
            m_tx_state.insert_or_assign(ticker, std::move(state));
            this->dispatcher_.trigger<tx_fetch_finished>();
        }
    }

    void
    mm2::on_refresh_orderbook(const orderbook_refresh& evt)
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        spdlog::info("refreshing orderbook pair: [{} / {}]", evt.base, evt.rel);
        const auto key = evt.base;

        {
            std::scoped_lock lock(m_orderbook_mutex);
            this->m_current_orderbook_ticker_base = evt.base;
            if (not evt.rel.empty())
            {
                this->m_current_orderbook_ticker_rel = evt.rel;
            }
        }

        spawn([this]() {
            // loguru::set_thread_name("r_book thread");
            process_fees();
            fetch_current_orderbook_thread();
        });
    }

    void
    mm2::on_gui_enter_trading([[maybe_unused]] const gui_enter_trading& evt) noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        m_orderbook_thread_active = true;
    }

    void
    mm2::on_gui_leave_trading([[maybe_unused]] const gui_leave_trading& evt) noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        m_orderbook_thread_active = false;
    }

    t_buy_answer
    mm2::place_buy_order(t_buy_request&& request, const t_float_50& total, t_mm2_ec& ec) const
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        t_mm2_ec balance_ec;

        if (not do_i_have_enough_funds(request.rel, total))
        {
            ec = dextop_error::balance_not_enough_found;
            return {};
        }

        auto answer = ::mm2::api::rpc_buy(std::move(request));

        if (answer.error.has_value())
        {
            ec = dextop_error::rpc_buy_error;
            return {};
        }

        return answer;
    }

    bool
    mm2::do_i_have_enough_funds(const std::string& ticker, const t_float_50& amount) const
    {
        auto funds = get_balance_with_locked_funds(ticker);
        return funds > amount;
    }

    std::string
    mm2::address(const std::string& ticker, t_mm2_ec& ec) const noexcept
    {
        if (m_balance_informations.find(ticker) == m_balance_informations.cend())
        {
            ec = dextop_error::unknown_ticker;
            return "Invalid";
        }

        return m_balance_informations.at(ticker).address;
    }

    ::mm2::api::my_orders_answer
    mm2::get_orders(const std::string& ticker, t_mm2_ec& ec) const noexcept
    {
        if (m_orders_registry.find("result") == m_orders_registry.cend())
        {
            ec = dextop_error::order_not_available_yet;
            return {};
        }
        auto  result                = m_orders_registry.at("result");
        auto& taker                 = result.taker_orders;
        auto& maker                 = result.maker_orders;
        auto  is_ticker_not_present = [&ticker](const std::pair<std::size_t, t_my_order_contents>& contents) {
            return contents.second.base != ticker && contents.second.rel != ticker;
        };

        erase_if(taker, is_ticker_not_present);
        erase_if(maker, is_ticker_not_present);

        return result;
    }

    std::vector<::mm2::api::my_orders_answer>
    mm2::get_orders(t_mm2_ec& ec) const noexcept
    {
        auto                                      coins = get_enabled_coins();
        std::vector<::mm2::api::my_orders_answer> out;
        out.reserve(coins.size());
        for (auto&& coin: coins) { out.emplace_back(get_orders(coin.ticker, ec)); }
        return out;
    }

    t_my_recent_swaps_answer
    mm2::get_swaps() const noexcept
    {
        return m_swaps_registry.at("result");
    }

    t_my_recent_swaps_answer
    mm2::get_swaps() noexcept
    {
        return m_swaps_registry.at("result");
    }

    t_sell_answer
    mm2::place_sell_order(t_sell_request&& request, const t_float_50& total, t_mm2_ec& ec) const
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        t_mm2_ec balance_ec;

        if (not do_i_have_enough_funds(request.base, total))
        {
            ec = dextop_error::balance_not_enough_found;
            return {.error = ec.message()};
        }

        auto answer = ::mm2::api::rpc_sell(std::move(request));

        if (answer.error.has_value())
        {
            ec = dextop_error::rpc_sell_error;
            return {};
        }

        return answer;
    }

    t_tx_state
    mm2::get_tx_state(const std::string& ticker, t_mm2_ec& ec) const
    {
        if (m_tx_state.find(ticker) == m_tx_state.cend())
        {
            ec = dextop_error::tx_history_of_a_non_enabled_coin;
            return {};
        }

        return m_tx_state.at(ticker);
    }

    bool
    mm2::is_claiming_ready(const std::string& ticker) const noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        using namespace std::chrono_literals;
        auto lock_claim_file_path = fs::temp_directory_path() / (ticker + ".claim.lock");

        spdlog::info("Checking if {} exist", lock_claim_file_path.string());
        if (not fs::exists(lock_claim_file_path))
        {
            return true;
        }

        std::time_t t = fs::last_write_time(lock_claim_file_path);
        if (std::chrono::system_clock::now() - std::chrono::system_clock::from_time_t(t) > 1h)
        {
            spdlog::info("1 hour expire, removing {}", lock_claim_file_path.string());
            fs::remove(lock_claim_file_path);
            return true;
        }
        return false;
    }

    t_withdraw_answer
    mm2::claim_rewards(const std::string& ticker, t_mm2_ec& ec) noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        const auto& info = get_coin_info(ticker);
        if (not info.is_claimable || not do_i_have_enough_funds(ticker, t_float_50(info.minimal_claim_amount)))
        {
            ec = not info.is_claimable ? dextop_error::ticker_is_not_claimable : dextop_error::claim_not_enough_funds;
            return {};
        }
        t_withdraw_request req{.max = true, .coin = ticker, .amount = "0", .to = m_balance_informations.at(ticker).address};
        auto               answer = ::mm2::api::rpc_withdraw(std::move(req));
        return answer;
    }

    t_broadcast_answer
    mm2::send_rewards(t_broadcast_request&& req, t_mm2_ec& ec) noexcept
    {
        spdlog::debug("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        auto ticker   = req.coin;
        auto b_answer = mm2::broadcast(std::move(req), ec);
        if (!ec)
        {
            auto          lock_claim_file_path = fs::temp_directory_path() / (ticker + ".claim.lock");
            std::ofstream ofs(lock_claim_file_path.string());
            assert(ofs);
            spdlog::info("created file {}", lock_claim_file_path.string());
        }
        return b_answer;
    }

    t_float_50
    mm2::get_trade_fee(const std::string& ticker, const std::string& amount, bool is_max) const
    {
        t_float_50 sell_amount_f(amount);
        if (is_max)
        {
            std::error_code ec;
            sell_amount_f = t_float_50(my_balance(ticker, ec));
        }

        return t_float_50(1) / t_float_50(777) * sell_amount_f;
    }

    std::string
    mm2::get_trade_fee_str(const std::string& ticker, const std::string& sell_amount, bool is_max) const
    {
        std::stringstream ss;
        ss.precision(8);
        ss << std::fixed << get_trade_fee(ticker, sell_amount, is_max);
        return ss.str();
    }

    void
    mm2::apply_erc_fees(const std::string& ticker, t_float_50& value)
    {
        if (get_coin_info(ticker).is_erc_20)
        {
            spdlog::info("Calculating erc fees of rel ticker: {}", ticker);
            t_get_trade_fee_request rec_req{.coin = ticker};
            auto                    amount = get_trade_fixed_fee(ticker).amount;
            if (!amount.empty())
            {
                t_float_50 rec_amount = t_float_50(amount);
                value += rec_amount;
            }
        }
    }

    t_get_trade_fee_answer
    mm2::get_trade_fixed_fee(const std::string& ticker) const
    {
        return m_trade_fees_registry.find(ticker) != m_trade_fees_registry.cend() ? m_trade_fees_registry.at(ticker) : t_get_trade_fee_answer{};
    }

} // namespace atomic_dex
