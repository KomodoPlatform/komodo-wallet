#pragma once

#include <entt/core/attribute.h>
#include <nlohmann/json.hpp>

#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

namespace atomic_dex::komodo_prices::api
{
    enum class provider : int
    {
        binance,
        coingecko,
        coinpaprika,
        forex,
        unknown
    };

    struct komodo_ticker_infos
    {
        std::string    ticker;
        std::string    last_price{"0.00"};
        std::string    last_updated;
        int64_t        last_updated_timestamp;
        std::string    volume24_h{"0.00"};
        provider       price_provider{provider::unknown};
        provider       volume_provider{provider::unknown};
        std::string    change_24_h{"0.00"};
        provider       change_24_h_provider{provider::unknown};
        nlohmann::json sparkline_7_d;
        provider       sparkline_provider;
    };

    void from_json(const nlohmann::json& j, komodo_ticker_infos& x);
    void from_json(const nlohmann::json& j, provider& x);

    using t_komodo_tickers_price_registry = std::unordered_map<std::string, komodo_ticker_infos>;
} // namespace atomic_dex::komodo_prices::api

namespace atomic_dex::komodo_prices::api
{
    ENTT_API pplx::task<web::http::http_response> async_market_infos(bool fallback = false);
}