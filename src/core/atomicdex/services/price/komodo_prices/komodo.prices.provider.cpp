//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/events/events.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

//! Constructor
namespace atomic_dex
{
    komodo_prices_provider::komodo_prices_provider(entt::registry& registry) : system(registry)
    {
        SPDLOG_INFO("komodo_prices_provider created");
        m_clock = std::chrono::high_resolution_clock::now();
        process_update();
    }
} // namespace atomic_dex

//! Private functions
namespace atomic_dex
{
    komodo_prices::api::komodo_ticker_infos
    komodo_prices_provider::get_info_answer(const std::string& ticker) const
    {
        std::shared_lock lock(m_market_mutex);
        // SPDLOG_INFO("Looking for ticker: {}", ticker);
        const auto it = m_market_registry.find(ticker);
        return it != m_market_registry.cend() ? it->second : komodo_prices::api::komodo_ticker_infos{.ticker = ticker};
    }

    void
    komodo_prices_provider::process_update(bool fallback)
    {
        SPDLOG_INFO("komodo price service tick loop");

        auto answer_functor = [this, fallback](web::http::http_response resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                nlohmann::json    j = nlohmann::json::parse(body);
                t_market_registry answer;
                answer = j.get<t_market_registry>();
                {
                    std::unique_lock lock(m_market_mutex);
                    m_market_registry = std::move(answer);
                    SPDLOG_INFO("komodo price registry size: {}", m_market_registry.size());
                }
            }
            else
            {
                SPDLOG_ERROR("Error during the rpc call to komodo price provider: {}", body);
                if (!fallback)
                {
                    process_update(true);
                }
            }
            dispatcher_.trigger<fiat_rate_updated>("");
        };

        auto error_functor = [this, fallback](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                dispatcher_.trigger<fiat_rate_updated>("");
                SPDLOG_ERROR("error occured when fetching price: {}", e.what());
                if (!fallback)
                {
                    process_update(true);
                }
            };
        };

        atomic_dex::komodo_prices::api::async_market_infos(fallback).then(answer_functor).then(error_functor);
    }
} // namespace atomic_dex

//! Public Functions
namespace atomic_dex
{
    void
    komodo_prices_provider::update()
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_clock);

        if (s >= 30s)
        {
            process_update();
            m_clock = std::chrono::high_resolution_clock::now();
        }
    }

    std::string
    komodo_prices_provider::get_total_volume(const std::string& ticker) const
    {
        return get_info_answer(ticker).volume24_h;
    }

    nlohmann::json
    komodo_prices_provider::get_ticker_historical(const std::string& ticker) const
    {
        nlohmann::json j = get_info_answer(ticker).sparkline_7_d;
        if (j.is_null())
        {
            j = nlohmann::json::array();
        }
        return j;
    }

    std::string
    komodo_prices_provider::get_change_24h(const std::string& ticker) const
    {
        return get_info_answer(ticker).change_24_h;
    }

    std::string
    komodo_prices_provider::get_rate_conversion(const std::string& ticker) const
    {
        return get_info_answer(ticker).last_price;
    }

    std::string
    komodo_prices_provider::get_price_provider(const std::string& ticker) const
    {
        auto provider = get_info_answer(utils::retrieve_main_ticker(ticker)).price_provider;
        switch (provider)
        {
        case komodo_prices::api::provider::binance:
            return "binance";
        case komodo_prices::api::provider::coingecko:
            return "coingecko";
        case komodo_prices::api::provider::coinpaprika:
            return "coinpaprika";
        case komodo_prices::api::provider::forex:
            return "forex";
        default:
            return "unknown";
        }
    }

    int64_t
    komodo_prices_provider::get_last_price_timestamp(const std::string& ticker) const
    {
        return get_info_answer(ticker).last_updated_timestamp;
    }
} // namespace atomic_dex
