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

//! Deps
#include <optional>
#include <nlohmann/json_fwd.hpp>

//! Project Headers
#include "atomicdex/constants/qt.coins.enums.hpp"

namespace atomic_dex::mm2
{
    //! Only for erc 20
    struct enable_request
    {
        std::string                 coin_name;
        std::vector<std::string>    urls;
        CoinType                    coin_type;
        bool                        is_testnet{false};
        const std::string           swap_contract_address;
        std::optional<std::string>  fallback_swap_contract_address{std::nullopt};
        std::optional<std::size_t>  matic_gas_station_decimals{9};
        std::optional<std::string>  gas_station_url{std::nullopt};
        std::optional<std::string>  matic_gas_station_url{std::nullopt};
        std::optional<std::string>  testnet_matic_gas_station_url{std::nullopt};
        std::optional<std::string>  type; ///< QRC-20 ?
        bool                        with_tx_history{true};
    };

    void to_json(nlohmann::json& j, const enable_request& cfg);

    struct enable_answer
    {
        std::string address;
        std::string balance;
        std::string result;
        std::string raw_result;
        int         rpc_result_code;
    };

    void from_json(const nlohmann::json& j, const enable_answer& cfg);
} // namespace atomic_dex::mm2

namespace atomic_dex
{
    using t_enable_request = mm2::enable_request;
    using t_enable_answer  = mm2::enable_answer;
} // namespace atomic_dex
