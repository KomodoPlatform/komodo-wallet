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
#include "atomicdex/api/mm2/rpc2.task.enable_z_coin.cancel.hpp"

//! Implementation 2.0 RPC [enable_z_coin_cancel]
namespace atomic_dex::mm2
{
    //! Serialization
    void to_json(nlohmann::json& j, const enable_z_coin_cancel_request& request)
    {
        j["params"]["task_id"] = request.task_id;
    }

    //! Deserialization
    void from_json(const nlohmann::json& j, enable_z_coin_cancel_answer_success& answer)
    {
        answer.result = j.at("result").get<std::string>();
    }

    void
    from_json(const nlohmann::json& j, enable_z_coin_cancel_answer& answer)
    {
        if (j.count("error") >= 1)
        {
            answer.error = j;
        }
        else
        {
            if (j.contains("result") && j.contains("mmrpc") && j.at("mmrpc").get<std::string>() == "2.0")
            {
                answer.result = j.get<enable_z_coin_cancel_answer_success>();
            }
        }
    }
} // namespace atomic_dex::mm2
