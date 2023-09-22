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

#pragma once

//! STD
#include <unordered_set>

//! Deps
#include <antara/gaming/ecs/system.manager.hpp>
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/config/coins.cfg.hpp"
#include "atomicdex/api/mm2/mm2.constants.hpp"
#include "atomicdex/constants/qt.coins.enums.hpp"
#include "atomicdex/data/dex/qt.orders.data.hpp"
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

namespace ag = antara::gaming;

namespace atomic_dex::mm2
{
    inline constexpr const char*                           g_etherscan_proxy_endpoint = "https://komodo.earth:3334";
    inline std::unique_ptr<web::http::client::http_client> g_etherscan_proxy_http_client{
        std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_etherscan_proxy_endpoint))};
    inline std::unique_ptr<web::http::client::http_client> g_qtum_proxy_http_client{
        std::make_unique<web::http::client::http_client>(FROM_STD_STR(::atomic_dex::g_qtum_infos_endpoint))};

    nlohmann::json basic_batch_answer(const web::http::http_response& resp);

    std::string rpc_version();

    struct trade_fee_request
    {
        std::string coin;
    };

    void to_json(nlohmann::json& j, const trade_fee_request& cfg);

    struct trade_fee_answer
    {
        std::string amount;
        std::string coin;
        std::string raw_result;      ///< internal
        int         rpc_result_code; ///< internal
    };

    void from_json(const nlohmann::json& j, trade_fee_answer& cfg);

    struct send_raw_transaction_request
    {
        std::string tx_hex;
        std::string coin;
    };

    void to_json(nlohmann::json& j, const send_raw_transaction_request& cfg);

    struct send_raw_transaction_answer
    {
        std::string tx_hash;
        std::string raw_result;      ///< internal
        int         rpc_result_code; ///< internal
    };

    void from_json(const nlohmann::json& j, send_raw_transaction_answer& answer);

    send_raw_transaction_answer rpc_send_raw_transaction(send_raw_transaction_request&& request, std::shared_ptr<t_http_client> mm2_client);

    struct cancel_order_request
    {
        std::string uuid;
    };

    void to_json(nlohmann::json& j, const cancel_order_request& request);

    struct cancel_order_answer
    {
        std::optional<std::string> result;
        std::optional<std::string> error;
        int                        rpc_result_code;
        std::string                raw_result;
    };

    void from_json(const nlohmann::json& j, cancel_order_answer& answer);

    struct cancel_data
    {
        //! If by == Pair
        std::optional<std::pair<std::string, std::string>> pair;

        //! If by == Coin
        std::optional<std::string> ticker;
    };

    void to_json(nlohmann::json& j, const cancel_data& cfg);

    struct cancel_type
    {
        std::string                type{"All"};
        std::optional<cancel_data> data{std::nullopt};
    };

    void to_json(nlohmann::json& j, const cancel_type& cfg);

    struct cancel_all_orders_request
    {
        cancel_type cancel_by;
    };

    void to_json(nlohmann::json& j, const cancel_all_orders_request& cfg);

    struct cancel_all_orders_answer
    {
        std::vector<std::string> cancelled;
        std::vector<std::string> currently_matching;
        int                      rpc_result_code;
        std::string              raw_result;
    };

    void from_json(const nlohmann::json& j, cancel_all_orders_answer& answer);

    struct my_orders_answer
    {
        std::vector<order_swaps_data>   orders;
        std::unordered_set<std::string> orders_id;
        int                             rpc_result_code;
        std::string                     raw_result;
    };

    void from_json(const nlohmann::json& j, my_orders_answer& answer);

    struct my_recent_swaps_request
    {
        std::size_t                limit{50ull};
        std::optional<std::size_t> page_number{1};
        std::optional<std::string> from_uuid;

        //! Filtering
        std::optional<std::string> my_coin;        ///< base_coin
        std::optional<std::string> other_coin;     ///< rel_coin
        std::optional<std::size_t> from_timestamp; ///< start date
        std::optional<std::size_t> to_timestamp;   ///< end date
    };

    void to_json(nlohmann::json& j, const my_recent_swaps_request& request);

    void from_json(const nlohmann::json& j, order_swaps_data& contents);

    struct my_recent_swaps_answer_success
    {
        std::vector<order_swaps_data>   swaps;
        std::unordered_set<std::string> swaps_id;
        std::size_t                     limit;
        std::size_t                     skipped;
        std::size_t                     total;
        std::size_t                     page_number;
        std::size_t                     total_pages;
        std::string                     raw_result;
        nlohmann::json                  average_events_time;
    };

    void from_json(const nlohmann::json& j, my_recent_swaps_answer_success& results);

    struct my_recent_swaps_answer
    {
        std::optional<my_recent_swaps_answer_success> result;
        std::optional<std::string>                    error;
        int                                           rpc_result_code;
        std::string                                   raw_result;
    };

    void from_json(const nlohmann::json& j, my_recent_swaps_answer& answer);

    struct active_swaps_request
    {
        std::optional<bool> statuses;
    };

    void to_json(nlohmann::json& j, const active_swaps_request& request);

    struct active_swaps_answer
    {
        std::unordered_set<std::string> uuids;
        std::vector<order_swaps_data>   swaps;
        int                             rpc_result_code;
        std::string                     raw_result;
    };

    void from_json(const nlohmann::json& j, active_swaps_answer& answer);

    struct show_priv_key_request
    {
        std::string coin;
    };

    void to_json(nlohmann::json& j, const show_priv_key_request& request);

    struct show_priv_key_answer
    {
        std::string coin;
        std::string priv_key;
        std::string raw_result;
        int         rpc_result_code;
    };

    void from_json(const nlohmann::json& j, show_priv_key_answer& answer);

    struct kmd_rewards_info_answer
    {
        nlohmann::json result;
        int            rpc_result_code;
    };

    // kmd_rewards_info_answer rpc_kmd_rewards_info(std::shared_ptr<t_http_client> mm2_client);
    kmd_rewards_info_answer process_kmd_rewards_answer(nlohmann::json result);

    template <typename RpcReturnType>
    RpcReturnType rpc_process_answer_batch(nlohmann::json& json_answer, const std::string& rpc_command) ;

    pplx::task<web::http::http_response> async_process_rpc_get(t_http_client_ptr& client, const std::string rpc_command, const std::string& url);

    nlohmann::json template_request(std::string method_name, bool is_protocol_v2 = false);

    void               set_rpc_password(std::string rpc_password) ;
    const std::string& get_rpc_password() ;
    void               set_system_manager(ag::ecs::system_manager& system_manager);
} // namespace atomic_dex::mm2

namespace atomic_dex
{
    using t_my_orders_answer        = mm2::my_orders_answer;
    using t_broadcast_request       = mm2::send_raw_transaction_request;
    using t_my_recent_swaps_answer  = mm2::my_recent_swaps_answer;
    using t_my_recent_swaps_request = mm2::my_recent_swaps_request;
    using t_active_swaps_request    = mm2::active_swaps_request;
    using t_active_swaps_answer     = mm2::active_swaps_answer;
    using t_get_trade_fee_request   = mm2::trade_fee_request;
    using t_get_trade_fee_answer    = mm2::trade_fee_answer;
} // namespace atomic_dex
