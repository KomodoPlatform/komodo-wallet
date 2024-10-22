/******************************************************************************
 * Copyright © 2013-2024 The Komodo Platform Developers.                      *
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

//! Project Deps
#include "atomicdex/api/kdf/rpc_v1/rpc.electrum.hpp"

//! Implementation RPC [electrum]
namespace atomic_dex::kdf
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const electrum_request& cfg)
    {
        j["coin"]       = cfg.coin_name;
        j["tx_history"] = cfg.with_tx_history;
        j["min_connected"] = 1;
        j["max_connected"] = 3;

        if (!cfg.servers.empty())
        {
            j["servers"] = cfg.servers;
        }

        if (cfg.coin_type == CoinType::QRC20)
        {
            if (cfg.swap_contract_address.has_value())
            {
                j["swap_contract_address"] = cfg.swap_contract_address.value();
            }
            if (cfg.fallback_swap_contract.has_value())
            {
                j["fallback_swap_contract"] = cfg.fallback_swap_contract.value();
            }
        }

        if (cfg.bchd_urls.has_value()) {
            j["bchd_urls"] = cfg.bchd_urls.value();
            j["allow_slp_unsafe_conf"] = cfg.allow_slp_unsafe_conf.value_or(false);
        }

        if (cfg.address_format.has_value())
        {
            j["address_format"] = cfg.address_format.value();
        }
        if (cfg.merge_params.has_value())
        {
            j["utxo_merge_params"] = cfg.merge_params.value();
        }
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, electrum_answer& cfg)
    {
        j.at("address").get_to(cfg.address);
        j.at("balance").get_to(cfg.balance);
        j.at("result").get_to(cfg.result);
    }
} // namespace atomic_dex::kdf
