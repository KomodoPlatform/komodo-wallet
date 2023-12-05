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

//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/api/mm2/rpc.enable.hpp"

//! Implementation RPC [enable]
namespace atomic_dex::mm2
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const enable_request& cfg)
    {
        j["coin"] = cfg.coin_name;
        switch (cfg.coin_type)
        {
        case CoinType::ERC20:
        {
            if (cfg.gas_station_url.has_value())
            {
                j["gas_station_url"]        = cfg.gas_station_url.value();
            }
        }
        case CoinType::Matic:
        {
            if (cfg.is_testnet)
            {
                if (cfg.testnet_matic_gas_station_url.has_value())
                {
                    j["gas_station_url"]    = cfg.testnet_matic_gas_station_url.value();
                }
            }
            else
            {
                if (cfg.matic_gas_station_url.has_value())
                {
                    j["gas_station_url"]        = cfg.matic_gas_station_url.value();
                }
            }
            if (cfg.matic_gas_station_decimals.has_value())
            {
                j["gas_station_decimals"]   = cfg.matic_gas_station_decimals.value();
            }
        }
        default:
            j["urls"]                   = cfg.urls;
            j["swap_contract_address"]  = cfg.swap_contract_address;
            if (cfg.fallback_swap_contract_address.has_value())
            {
                j["fallback_swap_contract"] = cfg.fallback_swap_contract_address.value();
            }
            break;
        }

        j["tx_history"] = cfg.with_tx_history;
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, enable_answer& cfg)
    {
        j.at("address").get_to(cfg.address);
        j.at("balance").get_to(cfg.balance);
        j.at("result").get_to(cfg.result);
        // SPDLOG_INFO("balance for {} is {}", cfg.address, cfg.balance);
    }
} // namespace atomic_dex::mm2
