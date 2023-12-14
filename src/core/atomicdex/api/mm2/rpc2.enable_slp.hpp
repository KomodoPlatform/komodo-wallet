/******************************************************************************
 * Copyright © 2013-2022 The Komodo Platform Developers.                      *
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

#include <optional>

#include <string>

#include <nlohmann/json_fwd.hpp> //> nlohmann::json

#include "rpc.hpp"
#include "balance_info.hpp"

namespace atomic_dex::mm2
{
    struct enable_slp_rpc
    {
        static constexpr auto endpoint  = "enable_slp";
        static constexpr bool is_v2     = true;
        
        struct expected_request_type
        {
            std::string                                             ticker;
            struct { std::optional<int> required_confirmations; }   activation_params;
        };
        
        struct expected_result_type
        {
            std::string                                     token_id;
            std::string                                     platform_coin;
            int                                             required_confirmations;
            std::unordered_map<std::string, balance_info>   balances;
        };

        using expected_error_type = rpc_basic_error_type;

        expected_request_type                  request;
        std::optional<expected_result_type>    result;
        std::optional<expected_error_type>     error;
    };

    using enable_slp_rpc_request    = enable_slp_rpc::expected_request_type;
    using enable_slp_rpc_result     = enable_slp_rpc::expected_result_type;
    using enable_slp_rpc_error      = enable_slp_rpc::expected_error_type;

    void to_json(nlohmann::json& j, const enable_slp_rpc_request& request);
    void from_json(const nlohmann::json& j, enable_slp_rpc_result& in);
}