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

#pragma once

//! Deps
#include <antara/gaming/ecs/system.hpp>
#include <antara/gaming/ecs/system.manager.hpp>
#include <boost/thread/synchronized_value.hpp>
#include <reproc++/reproc.hpp>

//! Project Headers
#include "atomicdex/api/mm2/mm2.hpp"
#include "atomicdex/config/coins.cfg.hpp"
#include "atomicdex/config/raw.mm2.coins.cfg.hpp"
#include "atomicdex/constants/mm2.constants.hpp"
#include "atomicdex/constants/mm2.error.code.hpp"
#include "atomicdex/events/events.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace atomic_dex
{
    namespace bm = boost::multiprecision;
    namespace ag = antara::gaming;

    struct tx_infos
    {
        bool                     am_i_sender;
        std::size_t              confirmations;
        std::vector<std::string> from;
        std::vector<std::string> to;
        std::string              date;
        std::size_t              timestamp;
        std::string              tx_hash;
        std::string              fees;
        std::string              my_balance_change;
        std::string              total_amount;
        std::size_t              block_height;
        t_mm2_ec                 ec{dextop_error::success};
        bool                     unconfirmed{false};
        std::string              transaction_note{""};
    };

    struct tx_state
    {
        std::string state;
        std::size_t current_block;
        std::size_t blocks_left;
        std::size_t transactions_left;
    };

    using t_ticker              = std::string;
    using t_tx_state            = tx_state;
    using t_coins_registry      = t_concurrent_reg<t_ticker, coin_config>;
    using t_wallet_cfg_registry = t_concurrent_reg<std::string, t_coins_registry>;
    using t_transactions        = std::vector<tx_infos>;
    using t_coins               = std::vector<coin_config>;

    //! Constants
    inline constexpr const std::size_t g_tx_max_limit{50_sz};

    class mm2_service final : public ag::ecs::pre_update_system<mm2_service>
    {
      public:
        using t_pair_max_vol = std::pair<::mm2::api::max_taker_vol_answer_success, ::mm2::api::max_taker_vol_answer_success>;

      private:
        //! Private typedefs
        using t_mm2_time_point             = std::chrono::high_resolution_clock::time_point;
        using t_balance_registry           = t_concurrent_reg<t_ticker, t_balance_answer>;
        using t_my_orders                  = t_concurrent_reg<t_ticker, t_my_orders_answer>;
        using t_tx_history_registry        = t_concurrent_reg<t_ticker, t_transactions>;
        using t_tx_state_registry          = t_concurrent_reg<t_ticker, t_tx_state>;
        using t_orderbook_registry         = t_concurrent_reg<t_ticker, t_orderbook_answer>;
        using t_swaps_registry             = t_concurrent_reg<t_ticker, t_my_recent_swaps_answer>;
        using t_fees_registry              = t_concurrent_reg<t_ticker, t_get_trade_fee_answer>;
        using t_synchronized_ticker_pair   = boost::synchronized_value<std::pair<std::string, std::string>>;
        using t_synchronized_max_taker_vol = boost::synchronized_value<t_pair_max_vol>;
        using t_synchronized_ticker        = boost::synchronized_value<std::string>;

        ag::ecs::system_manager& m_system_manager;
        //! Client
        std::shared_ptr<t_http_client>  m_mm2_client{nullptr};
        pplx::cancellation_token_source m_token_source;
        //! Process
        reproc::process m_mm2_instance;

        //! Current ticker
        t_synchronized_ticker m_current_ticker{"KMD"};

        //! Current orderbook
        t_synchronized_ticker_pair   m_synchronized_ticker_pair{std::make_pair("KMD", "BTC")};
        t_synchronized_max_taker_vol m_synchronized_max_taker_vol;

        //! Timers
        t_mm2_time_point m_orderbook_clock;
        t_mm2_time_point m_info_clock;

        //! Atomicity / Threads
        std::atomic_bool m_mm2_running{false};
        std::atomic_bool m_orderbook_thread_active{false};
        std::thread      m_mm2_init_thread;

        //! Current wallet name
        std::string m_current_wallet_name;

        //! Concurrent Registry.
        t_coins_registry&        m_coins_informations{entity_registry_.set<t_coins_registry>()};
        t_balance_registry&      m_balance_informations{entity_registry_.set<t_balance_registry>()};
        t_tx_history_registry    m_tx_informations;
        t_tx_state_registry      m_tx_state;
        t_my_orders              m_orders_registry;
        t_fees_registry          m_trade_fees_registry;
        t_orderbook_registry     m_current_orderbook;
        t_swaps_registry         m_swaps_registry;
        t_mm2_raw_coins_registry m_mm2_raw_coins_cfg{parse_raw_mm2_coins_file()};

        //! Balance factor
        double m_balance_factor{1.0};

        //! Refresh the orderbook registry (internal)
        nlohmann::json prepare_batch_orderbook();

        //! Batch process fees and fetch current_orderbook thread
        void           batch_process_fees_and_fetch_current_orderbook_thread(bool is_a_reset);
        nlohmann::json prepare_process_fees_and_current_orderbook();

        //! Batch balance / tx
        std::tuple<nlohmann::json, std::vector<std::string>, std::vector<std::string>> prepare_batch_balance_and_tx(bool only_tx = false) const;
        auto batch_balance_and_tx(bool is_a_reset, std::vector<std::string> tickers = {}, bool is_during_enabling = false, bool only_tx = false);
        void process_balance_answer(const nlohmann::json& answer);
        void process_tx_answer(const nlohmann::json& answer_json);
        void process_tx_etherscan(const std::string& ticker, bool is_a_refresh);

        //!
        std::pair<bool, std::string> process_batch_enable_answer(const nlohmann::json& answer);
        std::vector<electrum_server> get_electrum_server_from_token(const std::string& ticker);

      public:
        //! Constructor
        explicit mm2_service(entt::registry& registry, ag::ecs::system_manager& system_manager);

        //! Delete useless operator
        mm2_service(const mm2_service& other)  = delete;
        mm2_service(const mm2_service&& other) = delete;
        mm2_service& operator=(const mm2_service& other) = delete;
        mm2_service& operator=(const mm2_service&& other) = delete;

        //! Destructor
        ~mm2_service() noexcept final;

        //! Events
        void on_refresh_orderbook(const orderbook_refresh& evt);

        void on_gui_enter_trading(const gui_enter_trading& evt) noexcept;

        void on_gui_leave_trading(const gui_leave_trading& evt) noexcept;

        //! Spawn mm2 instance with given seed
        void spawn_mm2_instance(std::string wallet_name, std::string passphrase, bool with_pin_cfg = false);

        //! Refresh the current info (internally call process_balance and process_tx)
        void fetch_infos_thread(bool is_a_fresh = true, bool only_tx = false);

        //! Enable coins
        bool enable_default_coins() noexcept;

        //! Batch Enable coins
        void batch_enable_coins(const std::vector<std::string>& tickers, bool first_time = false) noexcept;

        //! Enable multiple coins
        void enable_multiple_coins(const std::vector<std::string>& tickers) noexcept;

        //! Add a new coin in the coin_info cfg add_new_coin(normal_cfg, mm2_cfg)
        void                  add_new_coin(const nlohmann::json& coin_cfg_json, const nlohmann::json& raw_coin_cfg_json) noexcept;
        void                  remove_custom_coin(const std::string& ticker) noexcept;
        [[nodiscard]] bool    is_this_ticker_present_in_raw_cfg(const std::string& ticker) const noexcept;
        [[nodiscard]] bool    is_this_ticker_present_in_normal_cfg(const std::string& ticker) const noexcept;
        [[nodiscard]] t_coins get_custom_coins() const noexcept;

        //! Disable a single coin
        bool disable_coin(const std::string& ticker, std::error_code& ec) noexcept;

        //! Disable multiple coins, prefer this function if you want persistent disabling
        void disable_multiple_coins(const std::vector<std::string>& tickers) noexcept;

        //! Called every ticks, and execute tasks if the timer expire.
        void update() noexcept final;

        //! Retrieve public address of the given ticker
        std::string address(const std::string& ticker, t_mm2_ec& ec) const noexcept;

        //! Is MM2 Process correctly running ?
        [[nodiscard]] const std::atomic_bool& is_mm2_running() const noexcept;

        //! Retrieve my balance for a given ticker as a string.
        [[nodiscard]] std::string my_balance(const std::string& ticker, t_mm2_ec& ec) const;

        //! Retrieve my balance with locked funds for a given ticker as a string.
        [[nodiscard]] std::string my_balance_with_locked_funds(const std::string& ticker, t_mm2_ec& ec) const;

        //! Refresh the current orderbook (internally call process_orderbook)
        void fetch_current_orderbook_thread(bool is_a_reset = false);

        void process_orderbook(bool is_a_reset = false);

        //! Last 50 transactions maximum
        [[nodiscard]] t_transactions get_tx_history(t_mm2_ec& ec) const;

        //! Last 50 transactions maximum
        [[nodiscard]] t_tx_state get_tx_state(t_mm2_ec& ec) const;

        //! Get coins that are currently enabled
        [[nodiscard]] t_coins get_enabled_coins() const noexcept;

        //! Get coins that are active, but may be not enabled
        [[nodiscard]] t_coins get_active_coins() const noexcept;

        //! Get coins that can be activated
        [[nodiscard]] t_coins get_enableable_coins() const noexcept;

        //! Get all coins
        [[nodiscard]] t_coins get_all_coins() const noexcept;

        //! Get Specific info about one coin
        [[nodiscard]] coin_config get_coin_info(const std::string& ticker) const;

        [[nodiscard]] t_float_50 get_trading_fees(const std::string& ticker, const std::string& sell_amount, bool is_max) const;

        [[nodiscard]] t_get_trade_fee_answer get_transaction_fees(const std::string& ticker) const;

        std::string apply_specific_fees(const std::string& ticker, t_float_50& value) const;

        //! Get Current orderbook
        [[nodiscard]] t_orderbook_answer get_orderbook(t_mm2_ec& ec) const noexcept;

        //! Get orders
        [[nodiscard]] ::mm2::api::my_orders_answer              get_orders(const std::string& ticker, t_mm2_ec& ec) const noexcept;
        [[nodiscard]] ::mm2::api::my_orders_answer              get_raw_orders(t_mm2_ec& ec) const noexcept;
        [[nodiscard]] std::vector<::mm2::api::my_orders_answer> get_orders(t_mm2_ec& ec) const noexcept;

        //! Get Swaps
        [[nodiscard]] t_my_recent_swaps_answer get_swaps() const noexcept;
        t_my_recent_swaps_answer               get_swaps() noexcept;

        //! Get balance with locked funds for a given ticker as a boost::multiprecision::cpp_dec_float_50.
        [[nodiscard]] t_float_50 get_balance(const std::string& ticker) const;

        //! Return true if we the balance of the `ticker` > amount, false otherwise.
        [[nodiscard]] bool do_i_have_enough_funds(const std::string& ticker, const t_float_50& amount) const;

        [[nodiscard]] bool is_orderbook_thread_active() const noexcept;

        [[nodiscard]] nlohmann::json get_raw_mm2_ticker_cfg(const std::string& ticker) const noexcept;

        [[nodiscard]] t_pair_max_vol get_taker_vol() const noexcept;

        //! Pin cfg api
        [[nodiscard]] bool is_pin_cfg_enabled() const noexcept;
        void               reset_fake_balance_to_zero(const std::string& ticker) noexcept;
        void               decrease_fake_balance(const std::string& ticker, const std::string& amount) noexcept;
        void               batch_fetch_orders_and_swap();
        void               add_orders_answer(t_my_orders_answer answer);

        //! Async API
        std::shared_ptr<t_http_client>         get_mm2_client() noexcept;
        [[nodiscard]] pplx::cancellation_token get_cancellation_token() const noexcept;

        //! Wallet api
        [[nodiscard]] std::string get_current_ticker() const noexcept;
        bool                      set_current_ticker(const std::string& ticker) noexcept;

        //! Multi ticker
        void add_get_trade_fee_answer(const std::string& ticker, t_get_trade_fee_answer answer) noexcept;
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::mm2_service))
