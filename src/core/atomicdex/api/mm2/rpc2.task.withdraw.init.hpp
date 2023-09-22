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

//! Deps
#include <nlohmann/json_fwd.hpp>

namespace atomic_dex::mm2
{
    struct withdraw_init_fees
    {
        std::string                type;      ///< UtxoFixed, UtxoPerKbyte, EthGas, Qrc20Gas
        std::optional<std::string> amount;    ///< Utxo only
    };

    struct withdraw_init_request
    {
        std::string                               coin;
        std::string                               to;
        std::string                               amount;
        std::optional<withdraw_init_fees>         fees{std::nullopt}; ///< ignored if std::nullopt
        std::optional<std::string>                memo;               ///< memo for zhtlc
        bool                                      max{false};
    };

    struct withdraw_init_answer
    {
        int         task_id;
    };

    void to_json(nlohmann::json& j, const withdraw_init_request& request);
    void from_json(const nlohmann::json& j, withdraw_init_answer& answer);
}

namespace atomic_dex
{
    using t_withdraw_init_request = mm2::withdraw_init_request;
    using t_withdraw_init_fees    = mm2::withdraw_init_fees;
    using t_withdraw_init_answer  = mm2::withdraw_init_answer;
} // namespace atomic_dex
