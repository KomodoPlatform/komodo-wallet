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
#include "atomicdex/api/mm2/rpc2.task.withdraw.status.hpp"

//! Implementation 2.0 RPC [withdraw_status]
namespace atomic_dex::mm2
{
    //! Serialization
    void to_json(nlohmann::json& j, const withdraw_status_request& request)
    {
        j["params"]["task_id"] = request.task_id;
        j["params"]["forget_if_finished"] = false;
    }

    //! Deserialization
    void from_json(const nlohmann::json& j, withdraw_status_answer& answer)
    {
        if (j.count("error") >= 1)
        {
            answer.error = j;
        }
        else
        {
            answer.result = j.at("result").at("details").get<transaction_data>();
        }
    }
} // namespace atomic_dex::mm2
