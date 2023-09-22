//
// Created by Sztergbaum Roman on 09/09/2021.
//

//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/api/komodo_prices/komodo.prices.hpp"

namespace
{
    constexpr const char*                 g_komodo_prices_endpoint = "https://prices.komodo.earth";
    constexpr const char*                 g_komodo_prices_endpoint_fallback = "https://prices.cipig.net:1717";

    web::http::client::http_client_config g_komodo_prices_cfg{[]()
                                                              {
                                                                  web::http::client::http_client_config cfg;
                                                                  cfg.set_validate_certificates(false);
                                                                  cfg.set_timeout(std::chrono::seconds(30));
                                                                  return cfg;
                                                              }()};
    t_http_client_ptr g_komodo_prices_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_komodo_prices_endpoint), g_komodo_prices_cfg);
    t_http_client_ptr g_komodo_prices_client_fallback = std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_komodo_prices_endpoint_fallback), g_komodo_prices_cfg);
} // namespace

namespace atomic_dex::komodo_prices::api
{
    void
    from_json(const nlohmann::json& j, komodo_ticker_infos& x)
    {
        x.ticker                 = j.at("ticker").get<std::string>();
        x.last_price             = j.at("last_price").get<std::string>();
        x.last_updated           = j.at("last_updated").get<std::string>();
        x.last_updated_timestamp = j.at("last_updated_timestamp").get<int64_t>();
        x.volume24_h             = j.at("volume24h").get<std::string>();
        x.price_provider         = j.at("price_provider").get<provider>();
        x.volume_provider        = j.at("volume_provider").get<provider>();
        x.sparkline_7_d          = j.at("sparkline_7d");
        x.sparkline_provider     = j.at("sparkline_provider").get<provider>();
        x.change_24_h            = j.at("change_24h").get<std::string>();
        x.change_24_h_provider   = j.at("change_24h_provider").get<provider>();
    }

    void
    from_json(const nlohmann::json& j, provider& x)
    {
        if (j == "binance")
        {
            x = provider::binance;
        }
        else if (j == "coingecko")
        {
            x = provider::coingecko;
        }
        else if (j == "coinpaprika")
        {
            x = provider::coinpaprika;
        }
        else if (j == "forex")
        {
            x = provider::forex;
        }
        else
        {
            x = provider::unknown;
        }
    }
} // namespace atomic_dex::komodo_prices::api

namespace atomic_dex::komodo_prices::api
{
    pplx::task<web::http::http_response>
    async_market_infos(bool fallback)
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        SPDLOG_INFO("url: {}", TO_STD_STR(g_komodo_prices_client->base_uri().to_string()) + "api/v2/tickers?expire_at=21600");
        req.set_request_uri(FROM_STD_STR("/api/v2/tickers?expire_at=21600"));
        return fallback ? g_komodo_prices_client_fallback->request(req) : g_komodo_prices_client->request(req);
    }
} // namespace atomic_dex::komodo_prices::api
