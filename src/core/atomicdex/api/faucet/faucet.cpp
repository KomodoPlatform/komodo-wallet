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

// Deps Headers
#include <nlohmann/json.hpp>
#include <antara/app/net/http.code.hpp>

// Project Headers
#include "atomicdex/api/faucet/faucet.hpp"

namespace
{
    constexpr const char* g_faucet_api_endpoint = "https://faucet.komodo.earth/faucet/";
    const auto            g_faucet_api_client   = std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_faucet_api_endpoint));
} // namespace

namespace atomic_dex::faucet::api
{
    pplx::task<web::http::http_response>
    claim(const claim_request& claim_req)
    {
        web::http::http_request http_request;
        web::uri_builder        uri_builder;

        uri_builder.append_path(FROM_STD_STR(claim_req.coin_name));
        uri_builder.append_path(FROM_STD_STR(claim_req.wallet_address));
        http_request.set_request_uri(uri_builder.to_uri());
        http_request.set_method(web::http::methods::GET);
        return g_faucet_api_client->request(http_request);
    }

    claim_result
    get_claim_result(const web::http::http_response& claim_response)
    {
        const std::string resp_body = TO_STD_STR(claim_response.extract_string(true).get());

        //! request success.
        if (claim_response.status_code() == static_cast<web::http::status_code>(antara::app::http_code::ok))
        {
            auto resp_body_json = nlohmann::json::parse(resp_body);

            return faucet::api::claim_result{
                .message = resp_body_json.at("Result")["Message"].get<std::string>(), .status = resp_body_json.at("Status").get<std::string>()};
        }
        //! request error.
        return faucet::api::claim_result{.message = resp_body, .status = "Request Error"};
    }
} // namespace atomic_dex::faucet::api