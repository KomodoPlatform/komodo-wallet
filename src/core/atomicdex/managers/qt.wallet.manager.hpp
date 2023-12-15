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

#pragma once

//! QT Headers
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVector>

//! Project Headers
#include "atomicdex/config/wallet.cfg.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/security.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace atomic_dex
{
    class ENTT_API qt_wallet_manager final : public QObject, public ag::ecs::pre_update_system<qt_wallet_manager>
    {
        //! Q_OBJECT Declaration
        Q_OBJECT

        //! Properties
        Q_PROPERTY(QString initial_loading_status READ get_status WRITE set_status NOTIFY onStatusChanged)
        Q_PROPERTY(QString wallet_default_name READ get_wallet_default_name WRITE set_wallet_default_name NOTIFY onWalletDefaultNameChanged)

        //! Private fields
        ag::ecs::system_manager& m_system_manager;
        wallet_cfg               m_wallet_cfg;
        QString                  m_current_default_wallet{""};
        QString                  m_current_status{"None"};
        bool                     m_login_status{false};

        //! Private functions
        bool load_wallet_cfg(const std::string& wallet_name);
        bool update_wallet_cfg() ;

      signals:
        void onStatusChanged();
        void onWalletDefaultNameChanged();

      public:
        //! Constructor
        qt_wallet_manager(entt::registry& registry, ag::ecs::system_manager& system_manager, QObject* parent = nullptr);

        //! Properties
        QString        get_status() const ;
        void           set_status(QString status) ;
        QString        get_wallet_default_name() const ;
        void           set_wallet_default_name(QString wallet_default_name) ;
        static QString get_default_wallet_name() ; ///< Static version

        //! Q_INVOKABLE (QML API)
        Q_INVOKABLE bool               login(const QString& password, const QString& wallet_name, bool use_static_rpcpass = false);
        Q_INVOKABLE bool               create(const QString& password, const QString& seed, const QString& wallet_name);
        Q_INVOKABLE static QStringList get_wallets(const QString& wallet_name = "") ;
        Q_INVOKABLE static bool        delete_wallet(const QString& wallet_name) ;
        Q_INVOKABLE static bool        confirm_password(const QString& wallet_name, const QString& password);
        Q_INVOKABLE void               set_emergency_password(const QString& emergency_password);
        Q_INVOKABLE static bool        mnemonic_validate(const QString& entropy);
        Q_INVOKABLE bool               log_status() const ;
        Q_INVOKABLE void               set_log_status(bool status) ;

        //! API
        static bool is_there_a_default_wallet() ;
        void        just_set_wallet_name(QString wallet_name);
        std::string retrieve_transactions_notes(const std::string& tx_hash) const;
        void        update_transactions_notes(const std::string& tx_hash, const std::string& notes);

        //! Override
        void update()  override;
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::qt_wallet_manager))
