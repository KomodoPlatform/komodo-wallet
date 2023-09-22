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

//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/api/mm2/rpc2.task.enable_z_coin.status.hpp"

//! Implementation 2.0 RPC [enable_z_coin_status]
namespace atomic_dex::mm2
{
    //! Serialization
    void to_json(nlohmann::json& j, const enable_z_coin_status_request& request)
    {
        j["params"]["task_id"] = request.task_id;
        j["params"]["forget_if_finished"] = false;
    }

    //! Deserialization
    void from_json(const nlohmann::json& j, enable_z_coin_status_answer_success& answer)
    {
        j.at("result").at("status").get_to(answer.status);     // [InProgress, Ready]
        j.at("result").at("details").get_to(answer.details);

        if (j.at("result").at("details").contains("UpdatingBlocksCache"))
        {
            answer.current_scanned_block = j.at("result").at("details").at("UpdatingBlocksCache").at("current_scanned_block").get<std::string>();
            answer.latest_block = j.at("result").at("details").at("UpdatingBlocksCache").at("latest_block").get<std::string>();
        }
        else if (j.at("result").at("details").contains("BuildingWalletDb"))
        {
            answer.current_scanned_block = j.at("result").at("details").at("BuildingWalletDb").at("current_scanned_block").get<std::string>();
            answer.latest_block = j.at("result").at("details").at("BuildingWalletDb").at("latest_block").get<std::string>();
        }

        if (j.at("result").at("details").contains("result"))
        {
            answer.coin = j.at("result").at("details").at("ticker").get<std::string>();
            answer.current_block = j.at("result").at("details").at("current_block").get<std::string>();

            if (j.at("result").at("details").contains("wallet_balance"))
            {
                answer.wallet_type = j.at("result").at("details").at("wallet_balance").at("wallet_type").get<std::string>();
                answer.address = j.at("result").at("details").at("wallet_balance").at("address").get<std::string>();
                answer.spendable_balance = j.at("result").at("details").at("wallet_balance").at("balance").at("spendable").get<std::string>();
                answer.unspendable_balance = j.at("result").at("details").at("wallet_balance").at("balance").at("unspendable").get<std::string>();
            }
        }
    }

    void
    from_json(const nlohmann::json& j, enable_z_coin_status_answer& answer)
    {
        if (j.count("error") >= 1)
        {
            answer.error = j;
        }
        else
        {
            if (j.contains("result") && j.contains("mmrpc") && j.at("mmrpc").get<std::string>() == "2.0")
            {
                answer.result = j.at("result").get<enable_z_coin_status_answer_success>();
            }
        }
    }
} // namespace atomic_dex::mm2

