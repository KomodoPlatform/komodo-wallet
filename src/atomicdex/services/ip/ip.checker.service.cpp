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

//! PCH
#include "atomicdex/pch.hpp"

//! Deps
#include <nlohmann/json.hpp>

//! Project headers
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"
#include "ip.checker.service.hpp"

namespace
{
    web::http::client::http_client_config g_ip_cfg{[]() {
        web::http::client::http_client_config cfg;
        cfg.set_timeout(std::chrono::seconds(5));
        return cfg;
    }()};

    t_http_client_ptr g_ip_proxy_client{std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://komodo.live:3335"), g_ip_cfg)};
    t_http_client_ptr g_ipify_client{std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://api.ipify.org"), g_ip_cfg)};

    pplx::task<web::http::http_response>
    async_check_retrieve_ip(t_http_client_ptr& client, const std::string& uri)
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

//! Constructor
namespace atomic_dex
{
    ip_service_checker::ip_service_checker(entt::registry& registry, QObject* parent) : QObject(parent), system(registry)
    {
        using namespace std::chrono_literals;
        m_update_clock = std::chrono::high_resolution_clock::now();
#if !defined(DISABLE_GEOBLOCKING)
        auto ip_validator_functor = [this](std::string ip) {
            async_check_retrieve_ip(g_ip_proxy_client, "/api/v1/ip_infos/" + ip)
                .then([this, ip](web::http::http_response resp) {
                    if (resp.status_code() == 200)
                    {
                        SPDLOG_INFO("Successfully retrieve ip informations of {}", ip);
                        std::string body   = TO_STD_STR(resp.extract_string(true).get());
                        auto        answer = nlohmann::json::parse(body);
                        this->m_country    = answer.at("country").get<std::string>();
                        if (this->m_non_authorized_countries.count(answer.at("country").get<std::string>()) == 1)
                        {
                            this->m_external_ip_authorized = false;
                            emit this->ipCountryChanged();
                            emit this->ipAuthorizedStatusChanged();
                            SPDLOG_ERROR("ip {} is not authorized in your country: {}", ip, m_country.get());
                        }
                        else
                        {
                            SPDLOG_INFO("ip {} is authorized in your country -> {}", ip, m_country.get());
                        }
                    }
                })
                .then(&handle_exception_pplx_task);
        };
        async_check_retrieve_ip(g_ipify_client, "")
            .then([this, ip_validator_functor](web::http::http_response resp) {
                if (resp.status_code() == 200)
                {
                    std::string ip      = TO_STD_STR(resp.extract_string(true).get());
                    this->m_external_ip = ip;
                    SPDLOG_INFO("my ip address is: [{}]", ip);
                    ip_validator_functor(ip);
                }
            })
            .then(&handle_exception_pplx_task);
#endif
    }
} // namespace atomic_dex

//! Override
namespace atomic_dex
{
    void
    ip_service_checker::update() noexcept
    {
    }

    bool
    ip_service_checker::is_my_ip_authorized() const noexcept
    {
        return m_external_ip_authorized.load();
    }

    QString
    atomic_dex::ip_service_checker::my_country_ip() const noexcept
    {
        return QString::fromStdString(m_country.get());
    }
} // namespace atomic_dex
