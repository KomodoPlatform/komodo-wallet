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
#include <spdlog/spdlog.h>

//! Project Headers
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

t_http_request
create_json_post_request(nlohmann::json&& json_data)
{
    t_http_request req;
    req.set_method(web::http::methods::POST);
    req.headers().set_content_type(FROM_STD_STR("application/json"));
    req.set_body(json_data.dump());
    return req;
}

void
handle_exception_pplx_task(pplx::task<void> previous_task)
{
    try
    {
        previous_task.wait();
    }
    catch (const std::exception& e)
    {
        SPDLOG_ERROR("pplx task error: {}", e.what());
    }
}
