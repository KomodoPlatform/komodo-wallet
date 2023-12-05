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
#include <nlohmann/json_fwd.hpp>

namespace atomic_dex
{
    struct cfg
    {
        std::string                                  current_currency;
        std::string                                  current_fiat;
        std::string                                  current_currency_sign;
        std::string                                  current_fiat_sign;
        std::unordered_map<std::string, std::string> available_currency_signs;
        std::vector<std::string>                     available_fiat;
        std::vector<std::string>                     recommended_fiat;
        std::vector<std::string>                     possible_currencies;
        bool                                         notification_enabled;
        bool                                         spamfilter_enabled{false};
    };

    void               from_json(const nlohmann::json& j, cfg& config);
    void               change_currency(cfg& config, const std::string& new_currency);
    void               change_fiat(cfg& config, const std::string& new_fiat);
    void               change_notification_status(cfg& config, bool is_enabled);
    void               change_spamfilter_status(cfg& config, bool is_enabled);
    [[nodiscard]] bool is_this_currency_a_fiat(const cfg& config, const std::string& currency);
    cfg                load_cfg();
    std::string        retrieve_sign_from_ticker(const cfg& config, const std::string& currency);
} // namespace atomic_dex
