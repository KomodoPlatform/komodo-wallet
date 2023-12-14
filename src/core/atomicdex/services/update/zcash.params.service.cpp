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


#include <QJsonObject>
#include <QJsonDocument>

#include <antara/gaming/ecs/system.manager.hpp>
#include <entt/signal/dispatcher.hpp>
#include <nlohmann/json.hpp>

#include "atomicdex/pch.hpp"
#include "atomicdex/services/update/zcash.params.service.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.download.manager.hpp"

namespace atomic_dex
{
    zcash_params_service::zcash_params_service(
        entt::registry& registry, ag::ecs::system_manager& system_manager,
        entt::dispatcher& dispatcher, QObject* parent) :
        QObject(parent), system(registry),
        m_system_manager(system_manager), m_dispatcher(dispatcher)
    {
        m_update_clock  = std::chrono::high_resolution_clock::now();
        m_update_info = nlohmann::json::object();
    }

    void zcash_params_service::update() 
    {
        using namespace std::chrono_literals;
        // const auto now = std::chrono::high_resolution_clock::now();
        // const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        // if (s >= 15s)
        // {
        //    TODO: We could use this for an ETA
        //    m_update_clock = now;
        // }
        return;
    }

    std::filesystem::path zcash_params_service::get_zcash_params_folder()
    {
        std::filesystem::path zcash_params_path;
#if defined(_WIN32) || defined(WIN32)
        std::wstring out = _wgetenv(L"APPDATA");
        zcash_params_path = std::filesystem::path(out) / "ZcashParams";
#elif defined(__APPLE__)
        zcash_params_path = std::filesystem::path(std::getenv("HOME")) / "Library" / "Application Support" / "ZcashParams";
#else
        zcash_params_path = std::filesystem::path(std::getenv("HOME")) / (std::string(".zcash-params"));
#endif
        return zcash_params_path;
    }

    void zcash_params_service::download_zcash_params() 
    {
        m_is_downloading = true;
        using namespace std::chrono_literals;
        const std::filesystem::path folder = this->get_zcash_params_folder();

        if (not std::filesystem::exists(folder))
        {
            std::filesystem::create_directories(folder);
        }

        std::string zcash_params[2] = {
            "https://z.cash/downloads/sapling-spend.params",
            "https://z.cash/downloads/sapling-output.params"
        };

        for(const std::string &url: zcash_params)
        {
            std::string filename = atomic_dex::utils::u8string(std::filesystem::path(url).filename());
            if (filename.find("deprecated-sworn-elves") > -1)
            {
                filename = "sprout-proving.key";
            }
            SPDLOG_INFO("Downloading {}...", filename);
            qt_downloader* downloader = new qt_downloader(m_dispatcher);
            downloader->do_download(QUrl(QString::fromStdString(url)), filename, folder);
            connect(downloader, &qt_downloader::downloadStatusChanged, this, &zcash_params_service::set_combined_download_status);
        }
    }

    bool
    zcash_params_service::is_downloading()
    {
        return m_is_downloading;
    }

    void
    zcash_params_service::enable_after_download(const QString& coin)
    {
        m_enable_after_download.append(coin);
    }

    void
    zcash_params_service::clear_enable_after_download()
    {
        m_enable_after_download.clear();
    }

    QStringList
    zcash_params_service::get_enable_after_download()
    {
        return m_enable_after_download;
    }

    QString
    zcash_params_service::get_combined_download_progress()
    {
        foreach(const QString& key, m_combined_download_status.keys()) {
            double val = m_combined_download_status.value(key).toDouble();
            if (val < 1)
            {
                break;
            }
            m_is_downloading = false;
        }
        return QString(QJsonDocument(m_combined_download_status).toJson());
    }

    QJsonObject
    zcash_params_service::get_combined_download_status() const
    {
        return m_combined_download_status;
    }

    void
    zcash_params_service::set_combined_download_status(QJsonObject& status)
    {
        QString filename  = status.value("filename").toString();
        m_combined_download_status.insert(filename, status.value("progress"));
        // SPDLOG_INFO("Filename: {} {}%", filename.toUtf8().constData(), std::to_string(status.value("progress").toDouble()));
        emit combinedDownloadStatusChanged();
    }

} // namespace atomic_dex
