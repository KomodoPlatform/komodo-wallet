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

#include <vector>

#include "rpc.hpp"
#include "balance_info.hpp"
#include "atomicdex/config/enable.cfg.hpp"
#include "atomicdex/constants/qt.coins.enums.hpp"
#include "atomicdex/constants/erc.constants.hpp"

namespace atomic_dex::mm2
{
    struct enable_eth_with_tokens_rpc
    {
        static constexpr auto endpoint  = "enable_eth_with_tokens";
        static constexpr bool is_v2     = true;

        struct expected_request_type
        {
            struct erc20_token_request_t
            {
                std::string         ticker;
                std::optional<int>  required_confirmations;
            };

            std::string                         ticker;
            CoinType                            coin_type;
            std::optional<std::string>          gas_station_url;
            std::string                         swap_contract_address;
            std::string                         fallback_swap_contract;
            bool                                tx_history{true};
            std::optional<bool>                 is_testnet{false};
            std::optional<size_t>               gas_station_decimals;
            std::optional<int>                  required_confirmations;
            std::optional<bool>                 requires_notarization;
            std::vector<node>                   nodes;
            std::vector<erc20_token_request_t>  erc20_tokens_requests;
        };
        
        struct expected_result_type
        {
            struct derivation_method_t { std::string type; };
            struct eth_address_infos_t
            {
                derivation_method_t derivation_method;
                std::string         pubkey;
                balance_info        balances;
            };
            struct erc20_address_infos_t
            {
                derivation_method_t                             derivation_method;
                std::string                                     pubkey;
                std::unordered_map<std::string, balance_info>   balances;
            };

            std::size_t current_block;
            std::unordered_map<std::string, eth_address_infos_t> eth_addresses_infos;
            std::unordered_map<std::string, erc20_address_infos_t> erc20_addresses_infos;
        };

        using expected_error_type = rpc_basic_error_type;

        expected_request_type                   request;
        std::optional<expected_result_type>     result;
        std::optional<expected_error_type>      error;
    };

    using enable_eth_with_tokens_request_rpc    = enable_eth_with_tokens_rpc::expected_request_type;
    using enable_eth_with_tokens_result_rpc     = enable_eth_with_tokens_rpc::expected_result_type;
    using enable_eth_with_tokens_error_rpc      = enable_eth_with_tokens_rpc::expected_error_type;

    void to_json(nlohmann::json& j, const enable_eth_with_tokens_request_rpc& in);
    void to_json(nlohmann::json& j, const enable_eth_with_tokens_request_rpc::erc20_token_request_t& in);
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc& out);
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::derivation_method_t& out);
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::eth_address_infos_t& out);
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::erc20_address_infos_t& out);
}