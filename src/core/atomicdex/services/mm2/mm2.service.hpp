/******************************************************************************
* Copyright © 2013-2023 The Komodo Platform Developers.                      *
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

#include <shared_mutex>
#include <thread>
#include <unordered_set>
#include <unordered_map>

#include <QNetworkAccessManager>
#include <antara/gaming/ecs/system.hpp>
#include <antara/gaming/ecs/system.manager.hpp>
#include <boost/thread/shared_mutex.hpp>
#include <boost/thread/synchronized_value.hpp>

#include "atomicdex/api/mm2/mm2.client.hpp"
#include "atomicdex/api/mm2/mm2.constants.hpp"
#include "atomicdex/api/mm2/mm2.error.code.hpp"
#include "atomicdex/api/mm2/mm2.hpp"
#include "atomicdex/api/mm2/rpc.balance.hpp"
#include "atomicdex/api/mm2/rpc.max.taker.vol.hpp"
#include "atomicdex/api/mm2/rpc.min.volume.hpp"
#include "atomicdex/api/mm2/rpc.orderbook.hpp"
#include "atomicdex/api/mm2/enable_bch_with_tokens_rpc.hpp"
#include "atomicdex/api/mm2/enable_slp_rpc.hpp"
#include "atomicdex/api/mm2/rpc2.enable_tendermint_with_assets.hpp"
#include "atomicdex/api/mm2/rpc2.enable_tendermint_token.hpp"
#include "atomicdex/config/raw.mm2.coins.cfg.hpp"
#include "atomicdex/constants/dex.constants.hpp"
#include "atomicdex/data/dex/orders.and.swaps.data.hpp"
#include "atomicdex/data/wallet/tx.data.hpp"
#include "atomicdex/events/events.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace atomic_dex
{
   namespace bm = boost::multiprecision;
   namespace ag = antara::gaming;

   template <typename T>
   using t_shared_synchronized_value = boost::synchronized_value<T, std::shared_mutex>;

   using t_ticker         = std::string;
   using t_coins_registry = std::unordered_map<t_ticker, coin_config>;
   using t_coins          = std::vector<coin_config>;

   class ENTT_API mm2_service final : public ag::ecs::pre_update_system<mm2_service>
   {
     public:
       using t_pair_max_vol = std::pair<t_max_taker_vol_answer_success, t_max_taker_vol_answer_success>;
       using t_pair_min_vol = std::pair<t_min_volume_answer_success, t_min_volume_answer_success>;

     private:
       using t_mm2_time_point             = std::chrono::high_resolution_clock::time_point;
       using t_balance_registry           = std::unordered_map<t_ticker, t_balance_answer>;
       using t_tx_registry                = t_shared_synchronized_value<std::unordered_map<t_ticker, std::pair<t_transactions, t_tx_state>>>;
       using t_orderbook                  = boost::synchronized_value<t_orderbook_answer>;
       using t_orders_and_swaps           = boost::synchronized_value<orders_and_swaps>;
       using t_synchronized_ticker_pair   = boost::synchronized_value<std::pair<std::string, std::string>>;
       using t_synchronized_max_taker_vol = boost::synchronized_value<t_pair_max_vol>;
       using t_synchronized_min_taker_vol = boost::synchronized_value<t_pair_min_vol>;
       using t_synchronized_ticker        = boost::synchronized_value<std::string>;

       ag::ecs::system_manager& m_system_manager;

       mm2::mm2_client m_mm2_client;

       //! Current ticker
       t_synchronized_ticker m_current_ticker{g_primary_dex_coin};

       //! Current orderbook
       t_synchronized_ticker_pair   m_synchronized_ticker_pair{std::make_pair(g_primary_dex_coin, g_second_primary_dex_coin)};
       t_synchronized_max_taker_vol m_synchronized_max_taker_vol;
       t_synchronized_min_taker_vol m_synchronized_min_taker_vol;

       //! Timers
       t_mm2_time_point m_orderbook_clock;
       t_mm2_time_point m_info_clock;

       //! Atomicity / Threads
       std::atomic_bool m_mm2_running{false};
       std::atomic_bool m_orderbook_thread_active{false};
       std::atomic_size_t m_nb_update_required{0};
       std::thread      m_mm2_init_thread;

       //! Current wallet name
       std::string m_current_wallet_name;

       //! Mutex
       mutable std::shared_mutex m_balance_mutex;
       mutable std::shared_mutex m_coin_cfg_mutex;
       mutable std::shared_mutex m_raw_coin_cfg_mutex;

       //! Concurrent Registry.
       t_coins_registry&        m_coins_informations{entity_registry_.set<t_coins_registry>()};
       t_balance_registry       m_balance_informations;
       t_tx_registry            m_tx_informations;
       t_orderbook              m_orderbook{t_orderbook_answer{}};
       t_orders_and_swaps       m_orders_and_swaps{orders_and_swaps{}};
       t_mm2_raw_coins_registry m_mm2_raw_coins_cfg{parse_raw_mm2_coins_file()};

       //! Balance factor
       double m_balance_factor{1.0};

       //! Refresh the orderbook registry (internal)
       nlohmann::json prepare_batch_orderbook(bool is_a_reset);

       //! Batch balance / tx
       std::tuple<nlohmann::json, std::vector<std::string>, std::vector<std::string>> prepare_batch_balance_and_tx(bool only_tx = false) const;
       auto batch_balance_and_tx(bool is_a_reset, std::vector<std::string> tickers = {}, bool is_during_enabling = false, bool only_tx = false);
       void process_balance_answer(const nlohmann::json& answer);
       void process_tx_answer(const nlohmann::json& answer_json, std::string ticker);
       void process_tx_tokenscan(const std::string& ticker, bool is_a_refresh);
       void fetch_single_balance(const coin_config& cfg_infos);

       //!
       std::pair<bool, std::string>                        process_batch_enable_answer(const nlohmann::json& answer);
       [[nodiscard]] std::pair<t_transactions, t_tx_state> get_tx(t_mm2_ec& ec) const;
       std::vector<electrum_server>                        get_electrum_server_from_token(const std::string& ticker);
       std::vector<atomic_dex::coin_config>                retrieve_coins_informations();

       void handle_exception_pplx_task(pplx::task<void> previous_task, const std::string& from, nlohmann::json batch);

     public:
       //! Constructor
       explicit mm2_service(entt::registry& registry, ag::ecs::system_manager& system_manager);

       //! Delete useless operator
       mm2_service(const mm2_service& other)  = delete;
       mm2_service(const mm2_service&& other) = delete;
       mm2_service& operator=(const mm2_service& other) = delete;
       mm2_service& operator=(const mm2_service&& other) = delete;

       //! Destructor
       ~mm2_service() final;

       //! Events
       void on_refresh_orderbook(const orderbook_refresh& evt);

       void on_gui_enter_trading(const gui_enter_trading& evt);

       void on_gui_leave_trading(const gui_leave_trading& evt);

       //! Spawn mm2 instance with given seed
       void spawn_mm2_instance(std::string wallet_name, std::string passphrase, bool with_pin_cfg = false);

       //! Refresh the current info (internally call process_balance and process_tx)
       void fetch_infos_thread(bool is_a_fresh = true, bool only_tx = false);

       // Coins enabling functions
       bool enable_default_coins(); // Enables required coins + coins enabled in the config
       void enable_coins(const std::vector<std::string>& tickers);
       void enable_coins(const t_coins& coins);
       void enable_coin(const std::string& ticker);
       void enable_coin(const coin_config& coin_config);
     private:
       void update_coin_active(const std::vector<std::string>& tickers, bool status);
       void enable_erc_family_coin(const coin_config& coin_config);
       void enable_erc_family_coins(const t_coins& coins);
       void enable_utxo_qrc20_coin(coin_config coin_config);
       void enable_utxo_qrc20_coins(const t_coins& coins);
       void enable_slp_coin(coin_config coin_config);
       void enable_slp_coins(const t_coins& coins);
       void enable_slp_testnet_coin(coin_config coin_config);
       void enable_slp_testnet_coins(const t_coins& coins);
       void enable_tendermint_coin(coin_config coin_config, std::string parent_ticker);
       void enable_tendermint_coins(const t_coins& coins, const std::string parent_ticker);
       void enable_zhtlc(const t_coins& coins);

       // Balances processing functions
       void process_balance_answer(const mm2::enable_bch_with_tokens_rpc& rpc);    // Called after enabling SLP coins along tBCH/BCH.
       void process_balance_answer(const mm2::enable_slp_rpc& rpc);                // Called after enabling an SLP coin.
       void process_balance_answer(const mm2::enable_tendermint_with_assets_rpc& rpc);
       void process_balance_answer(const mm2::enable_tendermint_token_rpc& rpc);

     public:
       //! Add a new coin in the coin_info cfg add_new_coin(normal_cfg, mm2_cfg)
       void                         add_new_coin(const nlohmann::json& coin_cfg_json, const nlohmann::json& raw_coin_cfg_json);
       void                         remove_custom_coin(const std::string& ticker);
       [[nodiscard]] bool           is_this_ticker_present_in_raw_cfg(const std::string& ticker) const;
       [[nodiscard]] bool           is_this_ticker_present_in_normal_cfg(const std::string& ticker) const;
       [[nodiscard]] bool           is_zhtlc_coin_ready(const std::string coin) const;
       [[nodiscard]] nlohmann::json get_zhtlc_status(const std::string coin) const;


       //! Cancel zhtlc activation
       void enable_z_coin_cancel(const std::int8_t task_id);

       //! Disable a single coin
       bool disable_coin(const std::string& ticker, std::error_code& ec);

       //! Disable multiple coins, prefer this function if you want persistent disabling
       void disable_multiple_coins(const std::vector<std::string>& tickers);

       //! Called every ticks, and execute tasks if the timer expire.
       void update() final;

       //! Retrieve public address of the given ticker
       std::string address(const std::string& ticker, t_mm2_ec& ec) const;

       //! Is MM2 Process correctly running ?
       [[nodiscard]] const std::atomic_bool& is_mm2_running() const;

       //! Retrieve my balance for a given ticker as a string.
       [[nodiscard]] std::string my_balance(const std::string& ticker, t_mm2_ec& ec) const;

       //! Refresh the current orderbook (internally call process_orderbook)
       void fetch_current_orderbook_thread(bool is_a_reset = false);

       void process_orderbook(bool is_a_reset = false);

       //! Last 50 transactions maximum
       [[nodiscard]] t_transactions get_tx_history(t_mm2_ec& ec) const;

       //! Last 50 transactions maximum
       [[nodiscard]] t_tx_state get_tx_state(t_mm2_ec& ec) const;

       //! Get coins that are currently enabled
       [[nodiscard]] t_coins get_enabled_coins() const;

       //! Get coins that are active, but may be not enabled
       [[nodiscard]] t_coins get_active_coins() const;

       //! Get Specific info about one coin
       [[nodiscard]] coin_config get_coin_info(const std::string& ticker) const;
       
       // Tells if the given coin is enabled.
       [[nodiscard]] bool is_coin_enabled(const std::string& ticker) const;
       
       // Tells if the given is coin is present inside the config.
       [[nodiscard]] bool has_coin(const std::string& ticker) const;

       //! Get Current orderbook
       [[nodiscard]] t_orderbook_answer get_orderbook(t_mm2_ec& ec) const;

       //! Get Swaps
       [[nodiscard]] orders_and_swaps get_orders_and_swaps() const;

       //! Get balance with locked funds for a given ticker as a boost::multiprecision::cpp_dec_float_50.
       [[nodiscard]] t_float_50 get_balance(const std::string& ticker) const;

       //! Return true if we the balance of the `ticker` > amount, false otherwise.
       [[nodiscard]] bool do_i_have_enough_funds(const std::string& ticker, const t_float_50& amount) const;

       [[nodiscard]] bool is_orderbook_thread_active() const;

       [[nodiscard]] nlohmann::json get_raw_mm2_ticker_cfg(const std::string& ticker) const;

       [[nodiscard]] t_pair_max_vol get_taker_vol() const;
       [[nodiscard]] t_pair_min_vol get_min_vol() const;

       //! Pin cfg api
       [[nodiscard]] bool is_pin_cfg_enabled() const;
       void               reset_fake_balance_to_zero(const std::string& ticker);
       void               decrease_fake_balance(const std::string& ticker, const std::string& amount);
       void               batch_fetch_orders_and_swap(bool after_manual_reset = false);

       //! Async API
       mm2::mm2_client& get_mm2_client();

       //! Wallet api
       [[nodiscard]] std::string get_current_ticker() const;
       bool                      set_current_ticker(const std::string& ticker);

       //! Pagination
       void set_orders_and_swaps_pagination_infos(std::size_t current_page = 1, std::size_t limit = 50, t_filtering_infos infos = {});

   };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::mm2_service))
