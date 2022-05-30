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

//! PCH
#include "atomicdex/pch.hpp"

//! Qt
#include <QJsonDocument>

//! Deps
#include <boost/algorithm/string/replace.hpp>
#include <nlohmann/json.hpp>

//! Project headers
#include "atomicdex/events/events.hpp"
#include "atomicdex/services/update/update.checker.service.hpp"
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace
{
    constexpr const char* g_komodolive_endpoint = "https://komodo.live/adexproversion";
    t_http_client_ptr     g_komodolive_client{std::make_unique<t_http_client>(FROM_STD_STR(g_komodolive_endpoint))};

    pplx::task<web::http::http_response>
    async_check_retrieve() 
    {
        nlohmann::json json_data{{"currentVersion", atomic_dex::get_raw_version()}};
        return g_komodolive_client->request(create_json_post_request(std::move(json_data)));
    }

    nlohmann::json
    get_update_status_rpc(web::http::http_response resp_http)
    {
        using namespace std::string_literals;
        nlohmann::json resp;
        if (resp_http.status_code() != 200)
        {
            resp["status"] = "cannot reach the endpoint: "s + g_komodolive_endpoint;
        }
        else
        {
            resp = nlohmann::json::parse(TO_STD_STR(resp_http.extract_string(true).get()));
        }
        resp["rpc_code"]        = resp_http.status_code();
        resp["current_version"] = atomic_dex::get_raw_version();
        if (resp_http.status_code() == 200)
        {
            bool        update_needed       = false;
            std::string current_version_str = atomic_dex::get_raw_version();
            std::string endpoint_version    = resp.at("new_version").get<std::string>();
            boost::algorithm::replace_all(current_version_str, ".", "");
            boost::algorithm::replace_all(endpoint_version, ".", "");
            boost::algorithm::trim_left_if(current_version_str, boost::is_any_of("0"));
            boost::algorithm::trim_left_if(endpoint_version, boost::is_any_of("0"));
            update_needed         = std::stoi(current_version_str) < std::stoi(endpoint_version);
            resp["update_needed"] = update_needed;
        }
        return resp;
    }
} // namespace
namespace atomic_dex
{
    //! Constructor
    update_service_checker::update_service_checker(entt::registry& registry, QObject* parent) : QObject(parent), system(registry)
    {
        m_update_clock  = std::chrono::high_resolution_clock::now();
        m_update_status = nlohmann::json::object();
        fetch_update_status();
    }

    //! Public override
    void
    update_service_checker::update() 
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 1h)
        {
            fetch_update_status();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    //! Private api
    void
    update_service_checker::fetch_update_status() 
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        SPDLOG_INFO("fetching update status");
        async_check_retrieve()
            .then([this](web::http::http_response resp) {
                this->m_update_status = get_update_status_rpc(resp);
                emit updateStatusChanged();
            })
            .then(&handle_exception_pplx_task);
    }

    QVariant
    update_service_checker::get_update_status() const 
    {
        nlohmann::json status = *m_update_status;
        QJsonDocument  doc    = QJsonDocument::fromJson(QString::fromStdString(status.dump()).toUtf8());
        return doc.toVariant();
    }
} // namespace atomic_dex
