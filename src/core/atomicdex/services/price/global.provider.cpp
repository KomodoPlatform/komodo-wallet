/******************************************************************************
 * Copyright © 2013-2021 The Komodo Platform Developers.                      *
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
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/api/coinpaprika/coinpaprika.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/services/price/oracle/band.provider.hpp"

namespace
{
    web::http::client::http_client_config g_openrates_cfg{[]()
                                                          {
                                                              web::http::client::http_client_config cfg;
                                                              cfg.set_validate_certificates(false);
                                                              cfg.set_timeout(std::chrono::seconds(5));
                                                              return cfg;
                                                          }()};
    t_http_client_ptr g_openrates_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://rates.komodo.live"), g_openrates_cfg);
    pplx::cancellation_token_source g_token_source;

    pplx::task<web::http::http_response>
    async_fetch_fiat_rates()
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        req.set_request_uri(FROM_STD_STR("api/v1/usd_rates"));
        //SPDLOG_INFO("req: {}", TO_STD_STR(req.to_string()));
        return g_openrates_client->request(req, g_token_source.get_token());
    }

    nlohmann::json
    process_fetch_fiat_answer(web::http::http_response resp)
    {
        nlohmann::json answer;
        if (resp.status_code() == 200)
        {
            answer = nlohmann::json::parse(TO_STD_STR(resp.extract_string(true).get()));
            return answer;
        }

        SPDLOG_WARN("unable to fetch last open rates");
        return answer;
    }
} // namespace

namespace
{
    std::string
    compute_result(const std::string& amount, const std::string& price, const std::string& currency, atomic_dex::cfg& cfg)
    {
        const t_float_50 amount_f(amount);
        const t_float_50 current_price_f(price);
        const t_float_50 final_price       = amount_f * current_price_f;
        std::size_t      default_precision = atomic_dex::is_this_currency_a_fiat(cfg, currency) ? 2 : 8;
        std::string      result;

        if (auto final_price_str = final_price.str(default_precision, std::ios_base::fixed); final_price_str == "0.00" && final_price > 0.00000000)
        {
            const auto retry = [&result, &final_price, &default_precision]() { result = final_price.str(default_precision, std::ios_base::fixed); };

            result = final_price.str(default_precision);
            if (result.find("e") != std::string::npos)
            {
                //! We have scientific notations lets get ride of that
                do {
                    default_precision += 1;
                    retry();
                } while (t_float_50(result) <= 0);
            }
        }
        else
        {
            result = final_price.str(default_precision, std::ios_base::fixed);
        }

        boost::trim_right_if(result, boost::is_any_of("0"));
        boost::trim_right_if(result, boost::is_any_of("."));
        return result;
    }
} // namespace


namespace atomic_dex
{
    void
    global_price_service::refresh_other_coins_rates(
        const std::string& quote_id, const std::string& ticker, bool with_update_providers, std::atomic_uint16_t nb_try)
    {
        nb_try += 1;
        SPDLOG_INFO("refresh_other_coins_rates - try {}", nb_try.load());
        if (nb_try == 10)
        {
            SPDLOG_WARN("refresh other coins rates max try reached, skipping");
            return;
        }
        using namespace std::chrono_literals;
        coinpaprika::api::price_converter_request request{.base_currency_id = "usd-us-dollars", .quote_currency_id = quote_id};
        auto error_functor = [this, quote_id, ticker, with_update_providers, nb_try_load = nb_try.load()](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("pplx task error from refresh_other_coins_rates: {} - nb_try {}", e.what(), nb_try_load);
                using namespace std::chrono_literals;
                std::this_thread::sleep_for(1s);
                this->refresh_other_coins_rates(quote_id, ticker, with_update_providers, nb_try_load);
            };
        };
        coinpaprika::api::async_price_converter(request)
            .then(
                [this, quote_id, ticker, with_update_providers, nb_try_cap = nb_try.load()](web::http::http_response resp)
                {
                    auto answer = coinpaprika::api::process_generic_resp<t_price_converter_answer>(resp);
                    if (answer.rpc_result_code == static_cast<web::http::status_code>(antara::app::http_code::too_many_requests))
                    {
                        std::this_thread::sleep_for(1s);
                        SPDLOG_WARN("too many request - retrying");
                        this->refresh_other_coins_rates(quote_id, ticker, with_update_providers, nb_try_cap);
                    }
                    else
                    {
                        SPDLOG_INFO("Successfully get the coinpaprika::api::async_price_converter answer after {} try", nb_try_cap);
                        if (answer.raw_result.find("error") == std::string::npos)
                        {
                            if (not answer.price.empty())
                            {
                                std::unique_lock lock(m_coin_rate_mutex);
                                this->m_coin_rate_providers[ticker] = answer.price;
                            }
                        }
                        else
                        {
                            std::unique_lock lock(m_coin_rate_mutex);
                            this->m_coin_rate_providers[ticker] = "0.00";
                        }
                    }
                    if (with_update_providers)
                    {
                        //this->m_system_manager.get_system<komodo_prices_provider>().update_ticker_and_provider();
                    }
                })
            .then(error_functor);
    }

    global_price_service::global_price_service(entt::registry& registry, ag::ecs::system_manager& system_manager, atomic_dex::cfg& cfg) :
        system(registry), m_system_manager(system_manager), m_cfg(cfg)
    {
        m_update_clock = std::chrono::high_resolution_clock::now();
        this->dispatcher_.sink<force_update_providers>().connect<&global_price_service::on_force_update_providers>(*this);
    }
} // namespace atomic_dex

namespace atomic_dex
{
    void
    global_price_service::update()
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 2min)
        {
            SPDLOG_INFO("2min spend - refreshing provider");
            this->on_force_update_providers({});
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    std::string
    global_price_service::get_rate_conversion(const std::string& fiat, const std::string& ticker_in, bool adjusted) const
    {
        if (fiat == utils::retrieve_main_ticker(ticker_in))
        {
            return "1";
        }
        std::string ticker = ticker_in;
        try
        {
            //! FIXME: fix zatJum crash report, frontend QML try to retrieve price before program is even launched
            if (ticker.empty())
                return "0";
            auto&       provider       = m_system_manager.get_system<komodo_prices_provider>();
            auto&       band_service    = m_system_manager.get_system<band_oracle_price_service>();
            std::string current_price   = band_service.retrieve_if_this_ticker_supported(ticker);
            const bool  is_oracle_ready = band_service.is_oracle_ready();

            if (current_price.empty())
            {
                current_price = provider.get_rate_conversion(ticker);
                if (!is_this_currency_a_fiat(m_cfg, fiat))
                {
                    t_float_50 rate(1);
                    {
                        std::shared_lock lock(m_coin_rate_mutex);
                        rate = t_float_50(m_coin_rate_providers.at(fiat)); ///< Retrieve BTC or KMD rate let's say for USD
                    }
                    t_float_50 tmp_current_price = t_float_50(current_price) * rate;
                    current_price                = tmp_current_price.str();
                }
                else if (fiat != "USD")
                {
                    t_float_50 tmp_current_price = t_float_50(current_price) * m_other_fiats_rates->at("rates").at(fiat).get<double>();
                    current_price                = tmp_current_price.str();
                }
            }
            else
            {
                //! We use oracle
                if (is_this_currency_a_fiat(m_cfg, fiat) && fiat != "USD")
                {
                    t_float_50 tmp_current_price = t_float_50(current_price) * m_other_fiats_rates->at("rates").at(fiat).get<double>();
                    current_price                = tmp_current_price.str();
                }

                else if (!is_this_currency_a_fiat(m_cfg, fiat) && is_oracle_ready)
                {
                    t_float_50 tmp_current_price = (t_float_50(current_price)) * band_service.retrieve_rates(fiat);
                    current_price                = tmp_current_price.str();
                }
            }

            if (adjusted)
            {
                std::size_t default_precision = is_this_currency_a_fiat(m_cfg, fiat) ? 2 : 8;

                t_float_50 current_price_f(current_price);
                if (is_this_currency_a_fiat(m_cfg, fiat))
                {
                    if (current_price_f < 1.0)
                    {
                        default_precision = 5;
                    }
                }
                //! Trick: If there conversion in a fixed representation is 0.00 then use a default precision to 2 without fixed ios flags
                if (auto fixed_str = current_price_f.str(default_precision, std::ios_base::fixed); fixed_str == "0.00" && current_price_f > 0.00000000)
                {
                    return current_price_f.str(default_precision);
                }
                return current_price_f.str(default_precision, std::ios::fixed);
            }
            return current_price;
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Exception caught in get_rate_conversion: {} - fiat: {} - ticker: {}", error.what(), fiat, ticker);
            return "0.00";
        }
    }

    std::string
    global_price_service::get_price_as_currency_from_tx(const std::string& currency, const std::string& ticker, const tx_infos& tx) const
    {
        const auto amount        = tx.am_i_sender ? tx.my_balance_change.substr(1) : tx.my_balance_change;
        const auto current_price = get_rate_conversion(currency, ticker);
        if (current_price == "0.00")
        {
            return current_price;
        }
        return compute_result(amount, current_price, currency, this->m_cfg);
    }

    std::string
    global_price_service::get_price_in_fiat_all(const std::string& fiat, std::error_code& ec) const
    {
        auto&   mm2_instance = m_system_manager.get_system<mm2_service>();
        t_coins coins        = mm2_instance.get_enabled_coins();
        try
        {
            t_float_50        final_price_f = 0;
            std::string       current_price = "0.00";
            std::stringstream ss;

            for (auto&& current_coin: coins)
            {
                current_price = get_price_in_fiat(fiat, current_coin.ticker, ec, true);

                if (ec)
                {
                    // SPDLOG_WARN("error when converting {} to {}, err: {}", current_coin.ticker, fiat, ec.message());
                    ec.clear(); //! Reset
                    continue;
                }

                if (not current_price.empty())
                {
                    const auto current_price_f = t_float_50(current_price);
                    final_price_f += current_price_f;
                }
            }

            std::size_t default_precision = is_this_currency_a_fiat(m_cfg, fiat) ? 2 : 8;
            ss.precision(default_precision);
            ss << std::fixed << final_price_f;
            std::string result = ss.str();
            boost::trim_right_if(result, boost::is_any_of("0"));
            boost::trim_right_if(result, boost::is_any_of("."));
            return result;
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Exception caught: {}", error.what());
            return "0.00";
        }
    }

    std::string
    global_price_service::get_price_as_currency_from_amount(const std::string& currency, const std::string& ticker, const std::string& amount) const
    {
        try
        {
            auto& mm2_instance = m_system_manager.get_system<mm2_service>();

            const auto ticker_infos = mm2_instance.get_coin_info(ticker);
            const auto current_price = get_rate_conversion(currency, ticker);

            if (current_price == "0.00")
            {
                return "0.00";
            }

            return compute_result(amount, current_price, currency, this->m_cfg);
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Exception caught: {}, ticker: {}, currency: {}, amount: {}", error.what(), ticker, currency, amount);
            return "0.00";
        }
    }

    std::string
    global_price_service::get_price_in_fiat(const std::string& fiat, const std::string& ticker, std::error_code& ec, bool skip_precision) const
    {
        try
        {
            auto& mm2_instance = m_system_manager.get_system<mm2_service>();

            if (m_supported_fiat_registry.count(fiat) == 0u)
            {
                ec = dextop_error::invalid_fiat_for_rate_conversion;
                return "0.00";
            }

            const auto price = get_rate_conversion(fiat, ticker);

            if (price == "0.00")
            {
                return "0.00";
            }

            std::error_code t_ec;
            const auto      amount = mm2_instance.my_balance(ticker, t_ec);

            if (t_ec)
            {
                ec = t_ec;
                //SPDLOG_ERROR("my_balance error: {} {}", t_ec.message(), ticker);
                return "0.00";
            }

            if (not skip_precision)
            {
                return compute_result(amount, price, fiat, this->m_cfg);
            }

            const t_float_50  price_f(price);
            const t_float_50  amount_f(amount);
            const t_float_50  final_price = price_f * amount_f;
            std::stringstream ss;

            ss << std::fixed << final_price;

            return ss.str() == "0" ? "0.00" : ss.str();
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Exception caught: {}, ticker: {}, fiat: {}", error.what(), ticker, fiat);
            return "0.00";
        }
    }

    std::string
    global_price_service::get_cex_rates(const std::string& base, const std::string& rel) const
    {
        try
        {
            const std::string base_rate_str = get_rate_conversion("USD", base, false);
            const std::string rel_rate_str  = get_rate_conversion("USD", rel, false);

            if (safe_float(rel_rate_str) <= 0 || safe_float(base_rate_str) <= 0)
            {
                return "0.00";
            }

            t_float_50  base_rate_f(base_rate_str);
            t_float_50  rel_rate_f(rel_rate_str);
            t_float_50  result     = base_rate_f / rel_rate_f;
            std::string result_str = result.str(8, std::ios_base::fixed);
            boost::trim_right_if(result_str, boost::is_any_of("0"));
            boost::trim_right_if(result_str, boost::is_any_of("."));
            return result_str;
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Exception caught: {}, base: {}, rel: {}", error.what(), base, rel);
            return "0.00";
        }
    }

    void
    global_price_service::on_force_update_providers([[maybe_unused]] const force_update_providers& evt)
    {
        static std::atomic_size_t nb_try = 0;
        nb_try += 1;
        SPDLOG_INFO("Forcing update providers");
        auto error_functor = [this, evt](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("pplx task error from async_fetch_fiat_rates: {} - nb_try {}", e.what(), nb_try);
                using namespace std::chrono_literals;
                std::this_thread::sleep_for(1s);
                this->on_force_update_providers(evt);
            };
        };
        async_fetch_fiat_rates()
            .then(
                [this](web::http::http_response resp)
                {
                    this->m_other_fiats_rates = process_fetch_fiat_answer(resp);
                    const auto& mm2           = this->m_system_manager.get_system<mm2_service>();
                    const bool  with_update   = mm2.is_mm2_running();
                    bool        already_send  = false;
                    const auto  first_id      = mm2.get_coin_info(g_primary_dex_coin).coinpaprika_id;
                    const auto  second_id     = mm2.get_coin_info(g_second_primary_dex_coin).coinpaprika_id;
                    if (!first_id.empty())
                    {
                        refresh_other_coins_rates(first_id, g_primary_dex_coin, false, 0);
                    }
                    if (!second_id.empty())
                    {
                        refresh_other_coins_rates(second_id, g_second_primary_dex_coin, with_update, 0);
                        already_send = true;
                    }
                    if (g_primary_dex_coin != "BTC" && g_second_primary_dex_coin != "BTC")
                    {
                        const auto third_id = mm2.get_coin_info("BTC").coinpaprika_id;
                        refresh_other_coins_rates(third_id, "BTC", !already_send, 0);
                    }
                    SPDLOG_INFO("Successfully retrieving rate after {} try", nb_try);
                    nb_try = 0;
                })
            .then(error_functor);
    }

    std::string
    global_price_service::get_fiat_rates(const std::string& fiat) const
    {
        if (fiat == "USD")
        {
            return "1";
        }
        return std::to_string(m_other_fiats_rates->at("rates").at(fiat).get<double>());
    }

    bool
    global_price_service::is_fiat_available(const std::string& fiat) const
    {
        if (fiat == "USD")
            return true;
        auto rates = m_other_fiats_rates.get();
        // SPDLOG_INFO("rates: {}", rates.dump(4));
        return !rates.empty() && rates.contains("rates") && rates.at("rates").contains(fiat);
    }

    bool
    global_price_service::is_currency_available(const std::string& currency) const
    {
        bool available = true;
        // SPDLOG_INFO("coin_rate_providers size: {}", m_coin_rate_providers.size());
        available = m_coin_rate_providers.find(currency) != m_coin_rate_providers.end();
        return available;
    }
} // namespace atomic_dex
