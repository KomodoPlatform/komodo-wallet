#pragma once

//! Qt
#include <QObject>
#include <QVariant>

//! 3rdParty
#include <boost/thread/synchronized_value.hpp>
#include <antara/gaming/ecs/system.hpp>

//! Project
#include "atomicdex/api/github/github.api.hpp"
#include "atomicdex/utilities/qt.download.manager.hpp"
#include "atomicdex/events/events.hpp"

namespace atomic_dex
{
    class self_update_service : public QObject, public ag::ecs::pre_update_system<self_update_service>
    {
        Q_OBJECT

        Q_PROPERTY(QString last_release_tag_name    READ get_last_release_tag_name    NOTIFY last_release_tag_nameChanged)
        Q_PROPERTY(bool    update_needed            READ is_update_needed             NOTIFY update_neededChanged)
        Q_PROPERTY(bool    update_downloading       READ is_update_downloading        NOTIFY updateDownloadingChanged)
        Q_PROPERTY(float   update_download_progress READ get_update_download_progress NOTIFY updateDownloadProgressChanged)
        Q_PROPERTY(bool    update_ready             READ is_update_ready              NOTIFY update_readyChanged)
        Q_PROPERTY(bool    invalid_update_files     READ are_update_files_invalid     NOTIFY invalidUpdateFilesChanged)
        
        boost::synchronized_value<github_api::repository_release> m_last_release_info;
        bool                                                      m_update_downloading{false};
        float                                                     m_update_download_progress{0.0F};
        boost::synchronized_value<bool>                           m_update_ready{false};
        bool                                                      m_update_files_invalid{false};
        
        // Clock used to time the `update()` loop of this ecs system.
        std::chrono::high_resolution_clock::time_point            m_update_clock;
        
        // Download manager used to download latest release.
        qt_download_manager                                       m_download_mgr;

      public:
        explicit self_update_service(entt::registry& entity_registry);
        
        // ecs::pre_update_system::update implementation
        // Basically it calls `fetch_last_release_info()` every hour.
        void update();
        
        // Fetches last release info and notifies the frontend if a new release is available.
        // Notification happens by modifying Q_PROPERTY `update_info`.
        Q_INVOKABLE void fetch_last_release_info();
        
        // Downloads last release.
        Q_INVOKABLE void download_update();
        
        // Updates the program to the latest release (downloaded by self_update_service::download_update()).
        // Updating might fail if `check_update_files_integrity()` sets `m_update_files_invalid` to true
        Q_INVOKABLE void perform_update();
    
        // Returns the fetched release tag name.
        [[nodiscard]] QString get_last_release_tag_name() const noexcept;
    
        // Compares fetched last release version to this build version then tells if an update can be downloaded or not.
        [[nodiscard]] bool is_update_needed() const noexcept;
        
        // Tells if an update is downloading.
        [[nodiscard]] bool is_update_downloading() const noexcept;
        
        // Returns the current progress of the update downloading.
        [[nodiscard]] float get_update_download_progress() const noexcept;
        
        [[nodiscard]] bool is_update_ready() const noexcept;
        
        [[nodiscard]] bool are_update_files_invalid() const noexcept;
        
        // Removes files used for recent update.
        void remove_update_files() const noexcept;

        //! Events
        void on_download_release_progressed(qt_download_progressed download_progressed);
        void on_download_release_finished([[maybe_unused]] const download_release_finished& evt);
        
      signals:
        void last_release_tag_nameChanged();
        void update_neededChanged();
        void updateDownloadingChanged();
        void updateDownloadProgressChanged();
        void update_readyChanged();
        void invalidUpdateFilesChanged();
    };
}

REFL_AUTO(type(atomic_dex::self_update_service));