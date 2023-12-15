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

//! Qt
#include <QSettings>
#include <QDebug>
#include <QFile>

//! Deps
#include <sodium/utils.h>
#include <wally_bip39.h>

//! Project Headers
#include "atomicdex/managers/qt.wallet.manager.hpp"

namespace atomic_dex
{
    QString
    qt_wallet_manager::get_wallet_default_name() const
    {
        return m_current_default_wallet;
    }

    void
    qt_wallet_manager::set_wallet_default_name(QString wallet_name)
    {
        using namespace std::string_literals;
        if (wallet_name == "")
        {
            std::filesystem::remove(utils::get_atomic_dex_config_folder() / "default.wallet");
            return;
        }

        std::filesystem::path path = (utils::get_atomic_dex_config_folder() / "default.wallet"s);
        QFile out;
        out.setFileName(std_path_to_qstring(path));
        out.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate);
        out.write(wallet_name.toUtf8());
        out.close();
        this->m_current_default_wallet = std::move(wallet_name);
        SPDLOG_INFO("new wallet name: {}", wallet_name.toStdString());
        emit onWalletDefaultNameChanged();
    }

    bool
    qt_wallet_manager::create(const QString& password, const QString& seed, const QString& wallet_name)
    {
        std::error_code ec;
        auto            key = atomic_dex::derive_password(password.toStdString(), ec);
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
            const std::filesystem::path    seed_path          = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
            const std::filesystem::path    rpcpass_path       = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".rpcpass"s);
            const std::filesystem::path    wallet_object_path = utils::get_atomic_dex_export_folder() / (wallet_name.toStdString() + ".wallet.json"s);
            const std::string wallet_cfg_file    = std::string(atomic_dex::get_raw_version()) + "-coins"s + "."s + wallet_name.toStdString() + ".json"s;
            const std::filesystem::path    wallet_cfg_path    = utils::get_atomic_dex_config_folder() / wallet_cfg_file;


            if (not std::filesystem::exists(wallet_cfg_path))
            {
                const auto  cfg_path = ag::core::assets_real_path() / "config";
                std::string filename = std::string(atomic_dex::get_raw_version()) + "-coins.json";
                std::filesystem::copy(cfg_path / filename, wallet_cfg_path);
            }

            // Encrypt seed
            atomic_dex::encrypt(seed_path, seed.toStdString().data(), key.data());
            // Encrypt rpcpass
            std::string rpcpass = atomic_dex::gen_random_password();
            atomic_dex::encrypt(rpcpass_path, rpcpass.data(), key.data());
            // sodium_memzero(&seed, seed.size());
            sodium_memzero(key.data(), key.size());

            QFile wallet_object;
            wallet_object.setFileName(std_path_to_qstring(wallet_object_path));
            wallet_object.open(QIODevice::Text | QIODevice::WriteOnly | QIODevice::Truncate);

            nlohmann::json wallet_object_json;

            wallet_object_json["name"] = wallet_name.toStdString();
            wallet_object.write(QString::fromStdString(wallet_object_json.dump(4)).toUtf8());
            wallet_object.close();
            LOG_PATH("Successfully write file: {}", wallet_object_path);
            SPDLOG_INFO("Successfully write the data: {}", wallet_object_json.dump());

            return true;
        }
        return false;
    }

    QStringList
    qt_wallet_manager::get_wallets(const QString& wallet_name)
    {
        QStringList out;

        for (auto&& p: std::filesystem::directory_iterator((utils::get_atomic_dex_config_folder())))
        {
            if (p.path().extension().string() == ".seed")
            {
                if (wallet_name == "" || QString::fromStdString(p.path().stem().string()).contains(wallet_name, Qt::CaseInsensitive))
                {
                    out.push_back(QString::fromStdString(p.path().stem().string()));
                }
            }
        }

        out.sort();
        return out;
    }

    bool
    qt_wallet_manager::is_there_a_default_wallet()
    {
        return std::filesystem::exists(utils::get_atomic_dex_config_folder() / "default.wallet");
    }

    QString
    qt_wallet_manager::get_default_wallet_name()
    {
        if (is_there_a_default_wallet())
        {
            QFile ifs;
            std::filesystem::path path = (utils::get_atomic_dex_config_folder() / "default.wallet");
            ifs.setFileName(std_path_to_qstring(path));
            ifs.open(QIODevice::ReadOnly | QIODevice::Text);
            QString out = ifs.readAll();
            ifs.close();
            SPDLOG_INFO("Retrieve wallet name: {}", out.toStdString());
            return out;
        }
        return "nonexistent";
    }

    bool
    qt_wallet_manager::delete_wallet(const QString& wallet_name)
    {
        using namespace std::string_literals;
        return std::filesystem::remove(utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s));
        return std::filesystem::remove(utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".rpcpass"s));
    }

    bool
    qt_wallet_manager::confirm_password(const QString& wallet_name, const QString& password)
    {
        std::error_code ec;
        auto            key = atomic_dex::derive_password(password.toStdString(), ec);
        if (ec)
        {
            SPDLOG_DEBUG("{}", ec.message());
            if (ec == dextop_error::derive_password_failed)
            {
                return false;
            }
        }
        using namespace std::string_literals;
        const std::filesystem::path seed_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
        auto           seed      = atomic_dex::decrypt(seed_path, key.data(), ec);
        const std::filesystem::path rpcpass_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".rpcpass"s);
        auto           rpcpass   = atomic_dex::decrypt(rpcpass_path, key.data(), ec);
        if (ec == dextop_error::corrupted_file_or_wrong_password)
        {
            SPDLOG_WARN("{}", ec.message());
            return false;
        }
        return true;
    }

    bool
    qt_wallet_manager::load_wallet_cfg(const std::string& wallet_name)
    {
        SPDLOG_INFO("Loading wallet configuration: {}", wallet_name);
        using namespace std::string_literals;
        const std::filesystem::path wallet_object_path = utils::get_atomic_dex_export_folder() / (wallet_name + ".wallet.json"s);
        QFile          ifs;
        ifs.setFileName(std_path_to_qstring(wallet_object_path));
        ifs.open(QIODevice::ReadOnly | QIODevice::Text);

        if (not ifs.isOpen())
        {
            LOG_PATH("Cannot open: {}", wallet_object_path);
            return false;
        }
        nlohmann::json j = nlohmann::json::parse(QString(ifs.readAll()).toStdString());
        m_wallet_cfg = j;
        //SPDLOG_INFO("wallet_cfg: {}", j.dump(4));
        return true;
    }

    void
    qt_wallet_manager::update_transactions_notes(const std::string& tx_hash, const std::string& notes)
    {
        m_wallet_cfg.transactions_details->operator[](tx_hash).note = notes;
        this->update_wallet_cfg();
    }

    bool
    qt_wallet_manager::update_wallet_cfg()
    {
        SPDLOG_INFO("update_wallet_cfg");
        using namespace std::string_literals;
        const std::filesystem::path wallet_object_path = utils::get_atomic_dex_export_folder() / (m_wallet_cfg.name + ".wallet.json"s);
        QFile ofs;
        ofs.setFileName(std_path_to_qstring(wallet_object_path));
        ofs.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);

        if (not ofs.isOpen())
        {
            return false;
        }

        nlohmann::json j;
        atomic_dex::to_json(j, m_wallet_cfg);
        ofs.write(QString::fromStdString(j.dump(4)).toUtf8());
        ofs.close();
        return true;
    }

    void
    qt_wallet_manager::just_set_wallet_name(QString wallet_name)
    {
        this->m_current_default_wallet = wallet_name;
        emit onWalletDefaultNameChanged();
    }

    void
    qt_wallet_manager::set_emergency_password(const QString& emergency_password)
    {
        this->m_wallet_cfg.protection_pass = emergency_password.toStdString();
        update_wallet_cfg();
    }

    void
    qt_wallet_manager::update()
    {
        //! Disabled system
    }

    qt_wallet_manager::qt_wallet_manager(entt::registry& registry, ag::ecs::system_manager& system_manager, QObject* parent) :
        QObject(parent), system(registry), m_system_manager(system_manager)
    {
        this->disable();
    }

    std::string
    qt_wallet_manager::retrieve_transactions_notes(const std::string& tx_hash) const
    {
        std::string note     = "";
        auto        registry = m_wallet_cfg.transactions_details.get();
        if (registry.find(tx_hash) != registry.end())
        {
            note = registry.at(tx_hash).note;
        }
        return note;
    }

    bool
    qt_wallet_manager::login(const QString& password, const QString& wallet_name, bool use_static_rpcpass)
    {
        SPDLOG_INFO("qt_wallet_manager::login");
        if (not load_wallet_cfg(wallet_name.toStdString()))
        {
            return false;
        }
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
            const std::filesystem::path    wallet_cfg_path = utils::get_atomic_dex_config_folder() / wallet_cfg_file;
            bool  valid_json = false;

            if (std::filesystem::exists(wallet_cfg_path))
            {
                QFile          ifs;
                ifs.setFileName(std_path_to_qstring(wallet_cfg_path));
                ifs.open(QIODevice::ReadOnly | QIODevice::Text);
                std::string json_data = QString(ifs.readAll()).toUtf8().constData();
                valid_json = nlohmann::json::accept(json_data);
                ifs.close();
            }

            if (!valid_json)
            {
                const auto  cfg_path = ag::core::assets_real_path() / "config";
                std::string filename = std::string(atomic_dex::get_raw_version()) + "-coins.json";
                std::filesystem::copy(cfg_path / filename, wallet_cfg_path, std::filesystem::copy_options::overwrite_existing);
            }

            const std::filesystem::path seed_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
            auto           seed      = atomic_dex::decrypt(seed_path, key.data(), ec);

            const std::filesystem::path rpcpass_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".rpcpass"s);
            //! We need to create a new rpcpass if it doesn't exist for existing logins
            std::string rpcpass = atomic_dex::gen_random_password();
            if (not std::filesystem::exists(rpcpass_path) || not use_static_rpcpass)
            {
                atomic_dex::encrypt(rpcpass_path, rpcpass.data(), key.data());
                // sodium_memzero(&seed, seed.size());
                sodium_memzero(key.data(), key.size());
            }
            else
            {
                rpcpass = atomic_dex::decrypt(rpcpass_path, key.data(), ec);
            }
            
            if (ec == dextop_error::corrupted_file_or_wrong_password)
            {
                SPDLOG_WARN("{}", ec.message());
                set_log_status(false);
                return false;
            }

            this->set_wallet_default_name(wallet_name);
            this->set_status("initializing_mm2");
            auto& mm2_system = m_system_manager.get_system<mm2_service>();
            mm2_system.spawn_mm2_instance(get_default_wallet_name().toStdString(), seed, with_pin_cfg, rpcpass);
            this->dispatcher_.trigger<post_login>();
            set_log_status(true);

            return true;
        }
        return false;
    }

    QString
    qt_wallet_manager::get_status() const
    {
        return m_current_status;
    }

    void
    qt_wallet_manager::set_status(QString status)
    {
        this->m_current_status = std::move(status);
        emit onStatusChanged();
        SPDLOG_INFO("Set status: {}", m_current_status.toStdString());
    }

    bool
    qt_wallet_manager::mnemonic_validate(const QString& entropy)
    {
        return bip39_mnemonic_validate(nullptr, entropy.toStdString().c_str()) == 0;
    }

    bool
    qt_wallet_manager::log_status() const
    {
        return m_login_status;
    }

    void
    qt_wallet_manager::set_log_status(bool status)
    {
        m_login_status = status;
    }
} // namespace atomic_dex
