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

//! Qt
#include <QDebug>

//! Deps
#include <sodium/utils.h>

//! Project Headers
#include "atomicdex/managers/qt.wallet.manager.hpp"

namespace atomic_dex
{
    QString
    qt_wallet_manager::get_wallet_default_name() const noexcept
    {
        return m_current_default_wallet;
    }

    void
    qt_wallet_manager::set_wallet_default_name(QString wallet_name) noexcept
    {
        using namespace std::string_literals;
        if (wallet_name == "")
        {
            fs::remove(utils::get_atomic_dex_config_folder() / "default.wallet");
            return;
        }
        if (not fs::exists(utils::get_atomic_dex_config_folder() / "default.wallet"s))
        {
            std::ofstream ofs((utils::get_atomic_dex_config_folder() / "default.wallet"s).string());
            ofs << wallet_name.toStdString();
        }
        else
        {
            std::ofstream ofs((utils::get_atomic_dex_config_folder() / "default.wallet"s).string(), std::ios_base::out | std::ios_base::trunc);
            ofs << wallet_name.toStdString();
        }

        this->m_current_default_wallet = std::move(wallet_name);
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
            const fs::path    seed_path          = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
            const fs::path    wallet_object_path = utils::get_atomic_dex_export_folder() / (wallet_name.toStdString() + ".wallet.json"s);
            const std::string wallet_cfg_file    = std::string(atomic_dex::get_raw_version()) + "-coins"s + "."s + wallet_name.toStdString() + ".json"s;
            const fs::path    wallet_cfg_path    = utils::get_atomic_dex_config_folder() / wallet_cfg_file;


            if (not fs::exists(wallet_cfg_path))
            {
                const auto  cfg_path = ag::core::assets_real_path() / "config";
                std::string filename = std::string(atomic_dex::get_raw_version()) + "-coins.json";
                fs::copy(cfg_path / filename, wallet_cfg_path);
            }

            // Encrypt seed
            atomic_dex::encrypt(seed_path, seed.toStdString().data(), key.data());
            // sodium_memzero(&seed, seed.size());
            sodium_memzero(key.data(), key.size());

            std::ofstream  wallet_object(wallet_object_path.string());
            nlohmann::json wallet_object_json;

            wallet_object_json["name"] = wallet_name.toStdString();
            wallet_object << wallet_object_json.dump(4);
            wallet_object.close();

            return true;
        }
        return false;
    }

    QStringList
    qt_wallet_manager::get_wallets() noexcept
    {
        QStringList out;

        for (auto&& p: fs::directory_iterator((utils::get_atomic_dex_config_folder())))
        {
            if (p.path().extension().string() == ".seed")
            {
                out.push_back(QString::fromStdString(p.path().stem().string()));
            }
        }

        return out;
    }

    bool
    qt_wallet_manager::is_there_a_default_wallet() noexcept
    {
        return fs::exists(utils::get_atomic_dex_config_folder() / "default.wallet");
    }

    QString
    qt_wallet_manager::get_default_wallet_name() noexcept
    {
        if (is_there_a_default_wallet())
        {
            std::ifstream ifs((utils::get_atomic_dex_config_folder() / "default.wallet").c_str());
            assert(ifs);
            std::string str((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
            return QString::fromStdString(str);
        }
        return "nonexistent";
    }

    bool
    qt_wallet_manager::delete_wallet(const QString& wallet_name) noexcept
    {
        using namespace std::string_literals;
        return fs::remove(utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s));
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
        const fs::path seed_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
        auto           seed      = atomic_dex::decrypt(seed_path, key.data(), ec);
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
        using namespace std::string_literals;
        const fs::path wallet_object_path = utils::get_atomic_dex_export_folder() / (wallet_name + ".wallet.json"s);
        std::ifstream  ifs(wallet_object_path.string());

        if (not ifs.is_open())
        {
            return false;
        }
        nlohmann::json j;
        ifs >> j;
        m_wallet_cfg = j;
        return true;
    }

    void
    qt_wallet_manager::update_transactions_notes(const std::string& tx_hash, const std::string& notes)
    {
        m_wallet_cfg.transactions_details->operator[](tx_hash).note = notes;
    }

    bool
    qt_wallet_manager::update_wallet_cfg() noexcept
    {
        using namespace std::string_literals;
        const fs::path wallet_object_path = utils::get_atomic_dex_export_folder() / (m_wallet_cfg.name + ".wallet.json"s);
        std::ofstream  ofs(wallet_object_path.string(), std::ios::trunc);
        if (not ofs.is_open())
        {
            return false;
        }

        nlohmann::json j;
        atomic_dex::to_json(j, m_wallet_cfg);
        ofs << j.dump(4);
        return true;
    }

    void
    qt_wallet_manager::update_or_insert_contact_name(const QString& old_contact_name, const QString& contact_name)
    {
        std::string old_contact_name_str = old_contact_name.toStdString();
        std::string contact_name_str     = contact_name.toStdString();

        if (old_contact_name_str.empty() && !contact_name_str.empty())
        {
            auto it = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
                return cur_contact.name == contact_name_str;
            });
            if (it != m_wallet_cfg.address_book.end())
            {
                //! Find this contact already exist do nothing
                SPDLOG_DEBUG("contact {} already exist, skipping", contact_name_str);
                return;
            }
            m_wallet_cfg.address_book.push_back(contact{.name = std::move(contact_name_str)});
        }
        else if (not old_contact_name_str.empty() && not contact_name_str.empty())
        {
            auto it = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [old_contact_name_str](auto&& cur_contact) {
                return cur_contact.name == old_contact_name_str;
            });
            if (it != m_wallet_cfg.address_book.end())
            {
                SPDLOG_DEBUG("old contact {} found, changing the contact name to: {}", old_contact_name_str, contact_name_str);
                it->name = contact_name_str;
            }
        }
    }

    void
    qt_wallet_manager::delete_contact(const QString& contact)
    {
        std::string contact_name_str = contact.toStdString();
        this->m_wallet_cfg.address_book.erase(
            std::remove_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
                return contact_name_str == cur_contact.name;
            }));
    }

    void
    qt_wallet_manager::update_contact_ticker(const QString& contact_name, const QString& old_ticker, const QString& new_ticker)
    {
        std::string contact_name_str = contact_name.toStdString();
        if (old_ticker.isEmpty() && not new_ticker.isEmpty())
        {
            //! Add new ticker entry
            auto it = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
                return cur_contact.name == contact_name_str;
            });

            if (it != m_wallet_cfg.address_book.end())
            {
                SPDLOG_DEBUG("add for contact {}, ticker {} entry", contact_name_str, new_ticker.toStdString());
                it->contents.emplace_back(contact_contents{.type = new_ticker.toStdString()});
            }
        }
        else
        {
            //! Update ticker entry
            auto it = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
                return cur_contact.name == contact_name_str;
            });

            auto contents_it = std::find_if(begin(it->contents), end(it->contents), [&old_ticker](auto&& cur_contact_contents) {
                return cur_contact_contents.type == old_ticker.toStdString();
            });

            if (contents_it != it->contents.end())
            {
                contents_it->type = new_ticker.toStdString();
            }
        }
    }

    void
    qt_wallet_manager::update_contact_address(const QString& contact_name, const QString& ticker, const QString& address)
    {
        SPDLOG_DEBUG("update contact {} with ticker {} with the new address {}", contact_name.toStdString(), ticker.toStdString(), address.toStdString());
        std::string contact_name_str = contact_name.toStdString();
        auto        it               = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
            return cur_contact.name == contact_name_str;
        });
        auto        contents_it      = std::find_if(
            begin(it->contents), end(it->contents), [&ticker](auto&& cur_contact_contents) { return cur_contact_contents.type == ticker.toStdString(); });
        if (contents_it != it->contents.end())
        {
            contents_it->address = address.toStdString();
        }
    }

    void
    qt_wallet_manager::remove_address_entry(const QString& contact_name, const QString& ticker)
    {
        std::string contact_name_str = contact_name.toStdString();
        auto        it               = std::find_if(begin(m_wallet_cfg.address_book), end(m_wallet_cfg.address_book), [contact_name_str](auto&& cur_contact) {
            return cur_contact.name == contact_name_str;
        });
        it->contents.erase(std::remove_if(
            begin(it->contents), end(it->contents), [&ticker](auto&& cur_contact_contents) { return cur_contact_contents.type == ticker.toStdString(); }));
    }

    const wallet_cfg&
    qt_wallet_manager::get_wallet_cfg() const noexcept
    {
        return m_wallet_cfg;
    }

    const wallet_cfg&
    qt_wallet_manager::get_wallet_cfg() noexcept
    {
        return m_wallet_cfg;
    }

    void
    qt_wallet_manager::just_set_wallet_name(QString wallet_name)
    {
        this->m_current_default_wallet = wallet_name;
    }

    void
    qt_wallet_manager::set_emergency_password(const QString& emergency_password)
    {
        this->m_wallet_cfg.protection_pass = emergency_password.toStdString();
        update_wallet_cfg();
    }

    void
    qt_wallet_manager::update() noexcept
    {
    }

    qt_wallet_manager::qt_wallet_manager(entt::registry& registry) : system(registry) {}

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
} // namespace atomic_dex
