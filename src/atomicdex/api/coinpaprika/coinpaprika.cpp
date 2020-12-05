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
#include <range/v3/view.hpp>

//! Project Headers
#include "atomicdex/api/coinpaprika/coinpaprika.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace
{
    //! Constants
    constexpr const char* g_coinpaprika_endpoint = "https://api.coinpaprika.com/v1/";
    t_http_client_ptr     g_coinpaprika_client   = std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_coinpaprika_endpoint));
} // namespace

namespace atomic_dex
{
    namespace coinpaprika::api
    {
        void
        to_json(nlohmann::json& j, const price_converter_request& evt)
        {
            j["base_currency_id"]  = evt.base_currency_id;
            j["quote_currency_id"] = evt.quote_currency_id;
            j["amount"]            = 1;
        }

        void
        from_json(const nlohmann::json& j, price_converter_answer& evt)
        {
            utils::my_json_sax sx;
            nlohmann::json::sax_parse(j.dump(), &sx);

            evt.base_currency_id         = j.at("base_currency_id").get<std::string>();
            evt.base_currency_name       = j.at("base_currency_name").get<std::string>();
            evt.base_price_last_updated  = j.at("base_price_last_updated").get<std::string>();
            evt.quote_currency_id        = j.at("quote_currency_id").get<std::string>();
            evt.quote_currency_name      = j.at("quote_currency_name").get<std::string>();
            evt.quote_price_last_updated = j.at("quote_price_last_updated").get<std::string>();
            evt.amount                   = j.at("amount").get<int64_t>();
            evt.price                    = sx.float_as_string;

            std::replace(evt.price.begin(), evt.price.end(), ',', '.');
        }

        void
        from_json(const nlohmann::json& j, ticker_info_answer& evt)
        {
            evt.answer = j.at("quotes");
        }

        void
        from_json(const nlohmann::json& j, ticker_historical_answer& evt)
        {
            evt.answer = j;
        }

        pplx::task<web::http::http_response>
        async_price_converter(const price_converter_request& request)
        {
            using namespace std::string_literals;
            web::http::http_request req;
            req.set_method(web::http::methods::GET);
            auto&& [base_id, quote_id] = request;
            const auto url             = "/price-converter?base_currency_id="s + base_id + "&quote_currency_id="s + quote_id + "&amount=1"s;
            req.set_request_uri(FROM_STD_STR(url));
            return g_coinpaprika_client->request(req);
        }

        pplx::task<web::http::http_response>
        async_ticker_info(const ticker_infos_request& request)
        {
            using ranges::views::ints;
            using ranges::views::zip;
            using namespace std::string_literals;
            web::http::http_request req;
            req.set_method(web::http::methods::GET);
            auto&& [ticker_id, quotes] = request;
            auto url                   = "/tickers/"s + ticker_id + "?quotes="s;
            for (auto&& [cur_quote, idx]: zip(quotes, ints(0u, ranges::unreachable)))
            {
                url.append(cur_quote);

                //! Append only if not last element, idx start at 0, if idx + 1 == quotes.size(), we are on the last elemnt, we don't append.
                if (idx < quotes.size() - 1)
                {
                    url.append(",");
                }
            }
            SPDLOG_INFO("url: {}", url);
            req.set_request_uri(FROM_STD_STR(url));
            return g_coinpaprika_client->request(req);
        }

        pplx::task<web::http::http_response>
        async_ticker_historical(const ticker_historical_request& request)
        {
            using namespace std::string_literals;
            web::http::http_request req;
            req.set_method(web::http::methods::GET);
            auto&& [ticker_id, timestamp, interval] = request;
            const auto url                          = "/tickers/"s + ticker_id + "/historical?start="s + std::to_string(timestamp) + "&interval="s + interval;
            SPDLOG_INFO("url: {}", url);
            req.set_request_uri(FROM_STD_STR(url));
            return g_coinpaprika_client->request(req);
        }
    } // namespace coinpaprika::api
} // namespace atomic_dex
