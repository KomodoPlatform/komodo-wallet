/******************************************************************************
 * Copyright © 2013-2023 The Komodo Platform Developers.                      *
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

//! Project Headers
#include "atomicdex/services/price/defi.stats.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/api/coinpaprika/coinpaprika.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/services/price/global.provider.hpp"


//! Constructor
namespace atomic_dex
{
    global_defi_stats_service::global_defi_stats_service(entt::registry& registry, ag::ecs::system_manager& system_manager):
        system(registry), m_system_manager(system_manager)
    {
        SPDLOG_INFO("global_defi_stats_service created");
        m_update_clock = std::chrono::high_resolution_clock::now();
        process_update();
    }
} // namespace atomic_dex

namespace
{
    web::http::client::http_client_config g_defi_stats_cfg{
        [](){
            web::http::client::http_client_config cfg;
            cfg.set_validate_certificates(false);
            cfg.set_timeout(std::chrono::seconds(5));
            return cfg;
        }()
    };

    t_http_client_ptr g_defi_stats_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://defi-stats.komodo.earth/"), g_defi_stats_cfg);
    pplx::cancellation_token_source d_token_source;

    pplx::task<web::http::http_response>
    async_fetch_defi_ticker_stats()
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        req.set_request_uri(FROM_STD_STR("api/v3/tickers/summary"));
        SPDLOG_INFO("defi_stats req: {}", TO_STD_STR(req.to_string()));
        return g_defi_stats_client->request(req, d_token_source.get_token());
    }

    nlohmann::json
    process_fetch_defi_ticker_stats_answer(web::http::http_response resp)
    {
        std::string body = TO_STD_STR(resp.extract_string(true).get());
        if (resp.status_code() == 200)
        {
            nlohmann::json    answer = nlohmann::json::parse(body);
            return answer;
        }
        else
        {
            SPDLOG_WARN("Failed to update defi_stats!");
            return nlohmann::json::array();            
        }
        
    }
} // namespace

namespace atomic_dex
{
    void
    global_defi_stats_service::update()
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 5min)
        {
            SPDLOG_INFO("[global_defi_stats_service::update()] - 5min elapsed, updating ticker stats");
            process_update();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

} // namespace atomic_dex


// Events
namespace atomic_dex
{   
    void
    global_defi_stats_service::process_update()
    {
        static std::atomic_size_t nb_try = 0;
        nb_try += 1;
        SPDLOG_INFO("pair volume stats service tick loop");
        auto error_functor = [this](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("pplx task error from async_fetch_ticker_stats: {} - nb_try {}", e.what(), nb_try);
                using namespace std::chrono_literals;
                std::this_thread::sleep_for(1s);
                this->process_update();
            };
        };
        async_fetch_defi_ticker_stats()
            .then(
                [this](web::http::http_response resp)
                {
                    this->m_defi_ticker_stats = process_fetch_defi_ticker_stats_answer(resp);
                    nb_try = 0;
                })
            .then(error_functor);
    }

    std::string
    global_defi_stats_service::get_volume_24h_usd(const std::string& base, const std::string& quote) const
    {
        std::string volume_24h_usd = "0.00";
        auto ticker = base + "_" + quote;
        auto ticker_reversed = quote + "_" + base;
        SPDLOG_INFO("Getting 24hr volume data for {}", ticker);
        if (base == quote)
        {
            SPDLOG_INFO("Base/quote must be different, no volume data for {}", ticker);
            return volume_24h_usd;
        }

        auto defi_ticker_stats = m_defi_ticker_stats.get();
        // SPDLOG_INFO("Volume data: {}", defi_ticker_stats.dump(4));
        
        if (defi_ticker_stats.contains("data"))
        {
            SPDLOG_INFO("Combined volume usd: {}", defi_ticker_stats["combined_volume_usd"]);
            if (defi_ticker_stats.at("data").contains(ticker))
            {
                volume_24h_usd = defi_ticker_stats.at("data").at(ticker).at("volume_usd_24hr").get<std::string>();
                SPDLOG_INFO("{} volume usd: {}", ticker, volume_24h_usd);
            }
            else if (defi_ticker_stats.at("data").contains(ticker_reversed))
            {
                volume_24h_usd = defi_ticker_stats.at("data").at(ticker_reversed).at("volume_usd_24hr").get<std::string>();
                SPDLOG_INFO("{} volume usd: {}", ticker_reversed, volume_24h_usd);
            }
        }
        else
        {
            SPDLOG_WARN("Empty 24hr volume data for {}", defi_ticker_stats.dump(4));
        }
        return volume_24h_usd;
    }
} // namespace atomic_dex
