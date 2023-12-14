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

#include <nlohmann/json.hpp>

#include "rpc2.get_public_key.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const get_public_key_rpc_request& request)
    {
    }
    
    void from_json(const nlohmann::json& json, get_public_key_rpc_result& in)
    {
        json.at("public_key").get_to(in.public_key);
    }
}