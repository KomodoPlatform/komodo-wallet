/******************************************************************************
 * Copyright © 2013-2022 The Komodo Platform Developers.                      *
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

#include "atomicdex/pch.hpp"

#include <QJsonDocument>
#include <QTranslator>

#include <boost/algorithm/string/replace.hpp>
#include <nlohmann/json.hpp>

#include "atomicdex/events/events.hpp"
#include "atomicdex/services/update/update.checker.service.hpp"
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace
{
    constexpr const char* g_komodolive_endpoint = "https://komodo.earth/adexproversion";
    t_http_client_ptr     g_komodolive_client{std::make_unique<t_http_client>(FROM_STD_STR(g_komodolive_endpoint))};

    pplx::task<web::http::http_response> async_check_retrieve() 
    {
        nlohmann::json json_data{{"currentVersion", atomic_dex::get_raw_version()}};
        return g_komodolive_client->request(create_json_post_request(std::move(json_data)));
    }

    nlohmann::json get_update_info_rpc(web::http::http_response resp_http)
    {
        using namespace std::string_literals;
        nlohmann::json resp;
        nlohmann::json result;
        if (resp_http.status_code() != 200)
        {
            result["status"] = (QObject::tr("Cannot reach the endpoint: ") + g_komodolive_endpoint).toStdString();
        }
        else
        {
            resp = nlohmann::json::parse(TO_STD_STR(resp_http.extract_string(true).get()));
        }
        result["rpcCode"]        = resp_http.status_code();
        result["currentVersion"] = atomic_dex::get_raw_version();
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
            result["updateNeeded"] = update_needed;
            result["newVersion"] = resp["new_version"];
            result["downloadUrl"] = resp["download_url"];
            result["changelog"] = resp["changelog"];
            result["status"] = resp["status"];
        }
        return result;
    }
}

namespace atomic_dex
{
    update_checker_service::update_checker_service(entt::registry& registry, QObject* parent) : QObject(parent), system(registry)
    {
        m_update_clock  = std::chrono::high_resolution_clock::now();
        m_update_info = nlohmann::json::object();
        fetch_update_info();
    }

    void update_checker_service::update() 
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 1h)
        {
            fetch_update_info();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    void update_checker_service::fetch_update_info() 
    {
        if (is_fetching)
            return;
        is_fetching = true;
        emit isFetchingChanged();
        async_check_retrieve()
            .then([this](web::http::http_response resp) {
                this->m_update_info = get_update_info_rpc(resp);
                is_fetching = false;
                emit isFetchingChanged();
                emit updateInfoChanged();
            })
            .then(&handle_exception_pplx_task);
    }

    QVariant update_checker_service::get_update_info() const 
    {
        nlohmann::json info = *m_update_info;
        QJsonDocument  doc  = QJsonDocument::fromJson(QString::fromStdString(info.dump()).toUtf8());
        return doc.toVariant();
    }
} // namespace atomic_dex
