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

//! Qt
#include <QFile>
#include <QJsonDocument>

//! Deps
#include <antara/gaming/core/real.path.hpp>
#include <nlohmann/json.hpp>
#include <range/v3/algorithm/any_of.hpp>

//! Project Header
#include "atomicdex/config/app.cfg.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

namespace
{
    void
    upgrade_cfg(atomic_dex::cfg& config)
    {
        std::filesystem::path cfg_path = atomic_dex::utils::get_current_configs_path() / "cfg.json";
        QFile    file;
        file.setFileName(atomic_dex::std_path_to_qstring(cfg_path));
        file.open(QIODevice::ReadOnly | QIODevice::Text);
        nlohmann::json config_json_data;

        QString val                                 = file.readAll();
        config_json_data                            = nlohmann::json::parse(val.toStdString());
        config_json_data["current_currency"]        = config.current_currency;
        config_json_data["current_fiat"]            = config.current_fiat;
        config_json_data["recommended_fiat"]        = config.recommended_fiat;
        config_json_data["possible_currencies"]     = config.possible_currencies;
        config_json_data["current_currency_sign"]   = config.current_currency_sign;
        config_json_data["current_fiat_sign"]       = config.current_fiat_sign;
        config_json_data["available_signs"]         = config.available_currency_signs;
        config_json_data["notification_enabled"]    = config.notification_enabled;
        config_json_data["spamfilter_enabled"]      = config.spamfilter_enabled;

        file.close();

        //! Write contents
        file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate);
        file.write(QString::fromStdString(config_json_data.dump()).toUtf8());
        file.close();
    }
} // namespace

namespace atomic_dex
{
    void
    from_json(const nlohmann::json& j, atomic_dex::cfg& config)
    {
        j.at("current_currency").get_to(config.current_currency);
        j.at("current_fiat").get_to(config.current_fiat);
        j.at("available_fiat").get_to(config.available_fiat);
        j.at("recommended_fiat").get_to(config.recommended_fiat);
        j.at("possible_currencies").get_to(config.possible_currencies);
        j.at("current_currency_sign").get_to(config.current_currency_sign);
        j.at("available_signs").get_to(config.available_currency_signs);
        j.at("current_fiat_sign").get_to(config.current_fiat_sign);
        j.at("notification_enabled").get_to(config.notification_enabled);

        if (j.contains("spamfilter_enabled"))
        {
            j.at("spamfilter_enabled").get_to(config.spamfilter_enabled);
        }
        else
        {
            config.spamfilter_enabled = true;
        }
    }

    void
    change_notification_status(cfg& config, bool is_enabled)
    {
        if (config.notification_enabled != is_enabled)
        {
            config.notification_enabled = is_enabled;
            upgrade_cfg(config);
        }
    }

    void
    change_spamfilter_status(cfg& config, bool is_enabled)
    {
        if (config.spamfilter_enabled != is_enabled)
        {
            config.spamfilter_enabled = is_enabled;
            upgrade_cfg(config);
        }
    }

    cfg
    load_cfg()
    {
        cfg      out;
        std::filesystem::path cfg_path = utils::get_current_configs_path() / "cfg.json";
        if (not std::filesystem::exists(cfg_path))
        {
            std::filesystem::path original_cfg_path{ag::core::assets_real_path() / "config" / "cfg.json"};
            //! Copy our json to current version
            LOG_PATH_CMP("Copying app cfg: {} to {}", original_cfg_path, cfg_path);
            std::filesystem::copy_file(original_cfg_path, cfg_path, std::filesystem::copy_options::overwrite_existing);
        }

        QFile file;
        file.setFileName(std_path_to_qstring(cfg_path));
        file.open(QIODevice::ReadOnly | QIODevice::Text);
        QString val = file.readAll();
        file.close();

        nlohmann::json config_json_data = nlohmann::json::parse(val.toStdString());

        from_json(config_json_data, out);
        return out;
    }

    bool
    is_this_currency_a_fiat(const cfg& config, const std::string& currency)
    {
        return ranges::any_of(config.available_fiat, [currency](const std::string& current_fiat) { return current_fiat == currency; });
    }

    void
    change_currency(cfg& config, const std::string& new_currency)
    {
        config.current_currency      = new_currency;
        config.current_currency_sign = retrieve_sign_from_ticker(config, new_currency);

        //! If it's fiat, i set the first element of the possible currencies to the new currency (the new fiat here) and i also set the current fiat
        if (is_this_currency_a_fiat(config, new_currency))
        {
            SPDLOG_INFO("{} is fiat, setting it as current fiat and possible currencies", new_currency);
            config.current_fiat              = new_currency;
            config.current_fiat_sign         = config.current_currency_sign;
            config.possible_currencies[0]    = new_currency;
            bool update_recommended_fiat{true};

            if (std::count(config.recommended_fiat.begin(), config.recommended_fiat.end(), new_currency))
            {
                SPDLOG_INFO("{} is already in recommended fiats", new_currency);
                update_recommended_fiat = false;
            }
            if (update_recommended_fiat) {
                SPDLOG_INFO("Adding {} to recommended fiats", new_currency);
                config.recommended_fiat.pop_back();
                config.recommended_fiat.insert(config.recommended_fiat.begin(), new_currency);
            }
        }
        upgrade_cfg(config);
    }

    void
    change_fiat(cfg& config, const std::string& new_fiat)
    {
        config.current_fiat           = new_fiat;
        config.possible_currencies[0] = new_fiat;
        upgrade_cfg(config);
    }

    std::string
    retrieve_sign_from_ticker(const cfg& config, const std::string& currency)
    {
#if defined(__linux__)
        if (currency == "BTC")
        {
            return config.available_currency_signs.at("BTC_ALT");
        }
#endif
        return config.available_currency_signs.at(currency);
    }
} // namespace atomic_dex
