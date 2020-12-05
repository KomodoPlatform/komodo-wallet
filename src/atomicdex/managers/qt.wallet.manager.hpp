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

#pragma once

//! QT Headers
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVector>

//! Project Headers
#include "atomicdex/config/wallet.cfg.hpp"
#include "atomicdex/data/wallet/qt.addressbook.contact.contents.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/security.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace atomic_dex
{
    class qt_wallet_manager : public ag::ecs::pre_update_system<qt_wallet_manager>
    {
      public:
        qt_wallet_manager(entt::registry& registry);
        QString get_wallet_default_name() const noexcept;
        void    just_set_wallet_name(QString wallet_name);

        void set_wallet_default_name(QString wallet_name) noexcept;

        template <typename Functor>
        bool login(const QString& password, const QString& wallet_name, mm2_service& mm2_system, Functor&& login_if_success_functor);

        bool create(const QString& password, const QString& seed, const QString& wallet_name);

        bool load_wallet_cfg(const std::string& wallet_name);

        static QStringList get_wallets() noexcept;

        static bool is_there_a_default_wallet() noexcept;

        static QString get_default_wallet_name() noexcept;

        static bool delete_wallet(const QString& wallet_name) noexcept;

        static bool confirm_password(const QString& wallet_name, const QString& password);
        void        update() noexcept override;

        bool update_wallet_cfg() noexcept;

        std::string                     retrieve_transactions_notes(const std::string& tx_hash) const;
        void                            update_transactions_notes(const std::string& tx_hash, const std::string& notes);
        void                            update_contact_ticker(const QString& contact_name, const QString& old_ticker, const QString& new_ticker);
        void                            update_contact_address(const QString& contact_name, const QString& ticker, const QString& address);
        void                            update_or_insert_contact_name(const QString& old_contact_name, const QString& contact_name);
        void                            set_emergency_password(const QString& emergency_password);
        void                            remove_address_entry(const QString& contact_name, const QString& ticker);
        void                            delete_contact(const QString& contact_name);
        [[nodiscard]] const wallet_cfg& get_wallet_cfg() const noexcept;
        const wallet_cfg&               get_wallet_cfg() noexcept;

      private:
        wallet_cfg m_wallet_cfg;
        QString    m_current_default_wallet{""};
    };

    template <typename Functor>
    bool
    qt_wallet_manager::login(const QString& password, const QString& wallet_name, mm2_service& mm2_system, Functor&& login_if_success_functor)
    {
        load_wallet_cfg(wallet_name.toStdString());
        std::error_code ec;
        std::string     password_std = password.toStdString();
        bool            with_pin_cfg = false;
        if (password.contains(QString::fromStdString(m_wallet_cfg.protection_pass)))
        {
            password_std = password_std.substr(0, password.size() - m_wallet_cfg.protection_pass.size());

            with_pin_cfg = true;
        }
        auto key = atomic_dex::derive_password(password_std, ec);
        if (ec)
        {
            SPDLOG_WARN("{}", ec.message());
            if (ec == dextop_error::derive_password_failed)
            {
                return false;
            }
        }
        else
        {
            using namespace std::string_literals;

            const std::string wallet_cfg_file = std::string(atomic_dex::get_raw_version()) + "-coins"s + "."s + wallet_name.toStdString() + ".json"s;
            const fs::path    wallet_cfg_path = utils::get_atomic_dex_config_folder() / wallet_cfg_file;


            if (not fs::exists(wallet_cfg_path))
            {
                const auto  cfg_path = ag::core::assets_real_path() / "config";
                std::string filename = std::string(atomic_dex::get_raw_version()) + "-coins.json";
                fs::copy(cfg_path / filename, wallet_cfg_path);
            }

            const fs::path seed_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
            auto           seed      = atomic_dex::decrypt(seed_path, key.data(), ec);
            if (ec == dextop_error::corrupted_file_or_wrong_password)
            {
                SPDLOG_WARN("{}", ec.message());
                return false;
            }

            login_if_success_functor();
            mm2_system.spawn_mm2_instance(get_default_wallet_name().toStdString(), seed, with_pin_cfg);
            return true;
        }
        return false;
    }
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::qt_wallet_manager))
