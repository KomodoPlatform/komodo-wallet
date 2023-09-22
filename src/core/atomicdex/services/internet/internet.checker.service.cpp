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

//! Deps
#include <nlohmann/json.hpp>

//! Our project
#include "atomicdex/services/internet/internet.checker.service.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

namespace
{
    web::http::client::http_client_config g_cfg{[]() {
        web::http::client::http_client_config cfg;
        cfg.set_validate_certificates(false);
        cfg.set_timeout(std::chrono::seconds(45));
        return cfg;
    }()};

    t_http_client_ptr g_paprika_proxy_http_client{std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://api.coinpaprika.com"), g_cfg)};
    std::atomic_bool  g_mm2_default_coins_ready{false};

    pplx::task<web::http::http_response>
    async_check_retrieve(t_http_client_ptr& client, const std::string& uri)
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        if (not uri.empty())
        {
            req.set_request_uri(FROM_STD_STR(uri));
        }
        return client->request(req);
    }
} // namespace

//! QT Properties
namespace atomic_dex
{
    void
    atomic_dex::internet_service_checker::set_internet_alive(bool internet_status) 
    {
        if (internet_status != is_internet_reacheable)
        {
            is_internet_reacheable = internet_status;
            emit internetStatusChanged();
        }
    }

    bool
    atomic_dex::internet_service_checker::is_internet_alive() const 
    {
        return is_internet_reacheable.load();
    }

    double
    atomic_dex::internet_service_checker::get_seconds_left_to_auto_retry() const 
    {
        return m_timer;
    }

    void
    atomic_dex::internet_service_checker::set_seconds_left_to_auto_retry(double time_left) 
    {
        m_timer = time_left;
        emit secondsLeftToAutoRetryChanged();
    }
} // namespace atomic_dex

namespace atomic_dex
{
    internet_service_checker::internet_service_checker(
        entt::registry& registry, ag::ecs::system_manager& system_manager, entt::dispatcher& dispatcher, QObject* parent) :
        QObject(parent),
        system(registry), m_system_manager(system_manager)
    {
        dispatcher.sink<default_coins_enabled>().connect<&internet_service_checker::on_default_coins_enabled>(*this);
        retry();
    }

    void
    atomic_dex::internet_service_checker::retry() 
    {
        using namespace std::chrono_literals;
        m_update_clock = std::chrono::high_resolution_clock::now();
        set_seconds_left_to_auto_retry(60.0);
        this->fetch_internet_connection();
    }

    void
    internet_service_checker::update() 
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        set_seconds_left_to_auto_retry(60.0 - s.count());
        if (s >= 60s)
        {
            this->fetch_internet_connection();
            m_update_clock = std::chrono::high_resolution_clock::now();
            set_seconds_left_to_auto_retry(60.0);
        }
    }

    void
    internet_service_checker::generic_treat_answer(
        pplx::task<web::http::http_response>& answer, const std::string& base_uri, std::atomic_bool internet_service_checker::*p)
    {
        answer
            .then([this, p, base_uri](web::http::http_response resp) {
                bool res = resp.status_code() == web::http::status_codes::OK;
                this->*p = res;
                if (res)
                {
                    SPDLOG_INFO("Connectivity is true for the endpoint: {}", base_uri);
                    this->set_internet_alive(true);
                }
                else
                {
                    SPDLOG_WARN("Connectivity is false for: {}", base_uri);
                }
            })
            .then([this, base_uri](pplx::task<void> previous_task) {
                try
                {
                    previous_task.wait();
                }
                catch (const std::exception& e)
                {
                    SPDLOG_WARN("pplx task error: {}, setting internet to false\n Connectivity is false for: {}", e.what(), base_uri);
                    this->dispatcher_.trigger<endpoint_nonreacheable>(base_uri);
                    this->set_internet_alive(false);
                }
            });
    }

    void
    internet_service_checker::query_internet(t_http_client_ptr& client, const std::string uri, std::atomic_bool internet_service_checker::*p) 
    {
        if (client != nullptr)
        {
            std::string base_uri     = TO_STD_STR(client->base_uri().to_string());
            auto        async_answer = async_check_retrieve(client, uri);
            generic_treat_answer(async_answer, base_uri, p);
        }
    }


    void
    internet_service_checker::fetch_internet_connection()
    {
        //query_internet(g_paprika_proxy_http_client, "/v1/coins/btc-bitcoin", &internet_service_checker::is_paprika_provider_alive);
        if (this->m_system_manager.has_system<mm2_service>() && g_mm2_default_coins_ready)
        {
            auto& mm2 = this->m_system_manager.get_system<mm2_service>();
            if (mm2.is_mm2_running())
            {
                SPDLOG_INFO("mm2 is alive, checking if we are able to fetch a simple orderbook");
                nlohmann::json      batch           = nlohmann::json::array();
                nlohmann::json      current_request = mm2::template_request("orderbook", true);
                t_orderbook_request req_orderbook{.base = g_primary_dex_coin, .rel = g_second_primary_dex_coin};
                mm2::to_json(current_request, req_orderbook);
                batch.push_back(current_request);
                auto async_answer = mm2.get_mm2_client().async_rpc_batch_standalone(batch);
                generic_treat_answer(async_answer, TO_STD_STR(atomic_dex::g_dex_rpc), &internet_service_checker::is_mm2_endpoint_alive);
            }
            else
            {
                SPDLOG_WARN("mm2 not running skipping internet connectivity with it");
            }
        }
        else
        {
            SPDLOG_WARN("mm2 system not available skipping internet connectivity with it");
        }
    }

    void
    internet_service_checker::on_default_coins_enabled([[maybe_unused]] const default_coins_enabled& evt)
    {
        SPDLOG_INFO("Default coins are enabled, we can now check internet with mm2 too");
        g_mm2_default_coins_ready = true;
    }
} // namespace atomic_dex
