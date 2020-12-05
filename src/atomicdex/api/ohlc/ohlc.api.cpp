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
#include "atomicdex/api/ohlc/ohlc.api.hpp"

namespace atomic_dex
{
    inline constexpr const char*                           g_cex_endpoint = "https://komodo.live:3333/";
    inline std::unique_ptr<web::http::client::http_client> g_cex_ohlc_proxy_http_client{
        std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_cex_endpoint))};
} // namespace atomic_dex

//! Json Serialization / Deserialization functions
namespace atomic_dex
{
    void
    from_json(const nlohmann::json& j, ohlc_answer_success& answer)
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        answer.raw_result = j;

        for (const auto& [key, value]: j.items())
        {
            ohlc_answer_success::t_ohlc_contents contents;
            for (const auto& c_value: value.items())
            {
                auto cur_value = c_value.value();

                contents.emplace_back(ohlc_contents{
                    .close_time_timestamp         = cur_value.at("timestamp").get<std::size_t>(),
                    .human_readeable_closing_time = "todo",
                    .open                         = std::to_string(cur_value.at("open").get<float>()),
                    .high                         = std::to_string(cur_value.at("high").get<float>()),
                    .low                          = std::to_string(cur_value.at("low").get<float>()),
                    .close                        = std::to_string(cur_value.at("close").get<float>()),
                    .volume                       = std::to_string(cur_value.at("volume").get<float>()),
                    .quote_volume                 = std::to_string(cur_value.at("quote_volume").get<float>())});
            }
            answer.result.insert({key, contents});
        }
    }

    void
    from_json(const nlohmann::json& j, ohlc_answer& answer)
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());

        if (j.contains("60"))
        {
            answer.result = ohlc_answer_success{};
            from_json(j, answer.result.value());
        }
    }

    ohlc_answer
    ohlc_answer_from_async_resp(web::http::http_response resp)
    {
        using namespace std::string_literals;
        SPDLOG_INFO("{} l{} resp code: {}", __FUNCTION__, __LINE__, resp.status_code());
        ohlc_answer answer;
        if (resp.status_code() != 200)
        {
            answer.error = "error occured, code : "s + std::to_string(resp.status_code());
        }
        else
        {
            try
            {
                const auto json_answer = nlohmann::json::parse(TO_STD_STR(resp.extract_string(true).get()));
                from_json(json_answer, answer);
            }
            catch (const std::exception& error)
            {
                SPDLOG_WARN("{}", error.what());
                answer.error = error.what();
            }
        }
        return answer;
    }

    pplx::task<web::http::http_response>
    async_rpc_ohlc_get_data(ohlc_request&& request)
    {
        using namespace std::string_literals;
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        auto&& [base_id, quote_id] = request;
        const auto url             = g_cex_endpoint + "/api/v1/ohlc/"s + base_id + "-"s + quote_id;
        SPDLOG_INFO("url: {}", url);
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        req.set_request_uri(FROM_STD_STR(url));
        auto resp = g_cex_ohlc_proxy_http_client->request(req);
        return resp;
    }
} // namespace atomic_dex
