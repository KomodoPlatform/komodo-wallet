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

//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/config/coins.cfg.hpp"

namespace atomic_dex
{
    void
    to_json(nlohmann::json& j, const electrum_server& cfg)
    {
        j["url"] = cfg.url;
        if (cfg.protocol.has_value())
        {
            j["protocol"] = cfg.protocol.value();
        }
        if (cfg.disable_cert_verification.has_value())
        {
            j["disable_cert_verification"] = cfg.disable_cert_verification.value();
        }
    }

    void
    from_json(const nlohmann::json& j, electrum_server& cfg)
    {
        if (j.count("protocol") == 1)
        {
            cfg.protocol = j.at("protocol").get<std::string>();
        }
        if (j.count("disable_cert_verification") == 1)
        {
            cfg.disable_cert_verification = j.at("disable_cert_verification").get<bool>();
        }
        j.at("url").get_to(cfg.url);
    }

    void
    from_json(const nlohmann::json& j, coin_config& cfg)
    {
        j.at("coin").get_to(cfg.ticker);
        cfg.gui_ticker = j.contains("gui_coin") ? j.at("gui_coin").get<std::string>() : cfg.ticker;
        j.at("name").get_to(cfg.name);
        j.at("type").get_to(cfg.type);
        if (j.contains("mm2_backup"))
        {
            cfg.custom_backup = j.at("mm2_backup");
        }
        if (j.contains("electrum"))
        {
            cfg.electrum_urls = j.at("electrum").get<std::vector<electrum_server>>();
        }
        if (j.contains("eth_nodes"))
        {
            cfg.eth_urls = j.at("eth_nodes").get<std::vector<std::string>>();
        }
        cfg.is_claimable         = j.count("is_claimable") > 0;
        cfg.minimal_claim_amount = cfg.is_claimable ? j.at("minimal_claim_amount").get<std::string>() : "0";
        j.at("active").get_to(cfg.active);
        j.at("currently_enabled").get_to(cfg.currently_enabled);
        j.at("coinpaprika_id").get_to(cfg.coinpaprika_id);
        if (j.contains("is_custom_coin"))
        {
            cfg.is_custom_coin = true;
        }
        
        j.at("explorer_url").get_to(cfg.explorer_url);
        if (j.contains("explorer_tx_url"))
        {
            j.at("explorer_tx_url").get_to(cfg.tx_uri);
        }
        if (j.contains("explorer_address_url"))
        {
            j.at("explorer_address_url").get_to(cfg.address_url);
        }
        if (j.contains("need_electrum"))
        {
            cfg.need_electrum = j.at("need_electrum").get<bool>();
        }
        if (j.contains("is_testnet"))
        {
            cfg.is_testnet = j.at("is_testnet").get<bool>();
        }
        if (cfg.type == "QRC-20")
        {
            cfg.coin_type = coin_type::QRC20;
        }
        else if (cfg.type == "ERC-20")
        {
            cfg.coin_type = coin_type::ERC20;
        }
        else if (cfg.type == "UTXO")
        {
            cfg.coin_type = coin_type::UTXO;
        }
        else if (cfg.type == "Smart Chain")
        {
            cfg.coin_type = coin_type::SmartChain;
        }
    }
} // namespace atomic_dex
