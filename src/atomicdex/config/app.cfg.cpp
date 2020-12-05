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

//! STD
#include <fstream>

//! Deps
#include <antara/gaming/core/real.path.hpp>
#include <nlohmann/json.hpp>
#include <range/v3/algorithm/any_of.hpp>

//! Project Header
#include "atomicdex/config/app.cfg.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace
{
    void
    upgrade_cfg(atomic_dex::cfg& config)
    {
        fs::path       cfg_path = atomic_dex::utils::get_current_configs_path() / "cfg.json";
        std::ifstream  ifs(cfg_path.string());
        nlohmann::json config_json_data;

        assert(ifs.is_open());
        ifs >> config_json_data;
        config_json_data["lang"]                  = config.current_lang;
        config_json_data["current_currency"]      = config.current_currency;
        config_json_data["current_fiat"]          = config.current_fiat;
        config_json_data["possible_currencies"]   = config.possible_currencies;
        config_json_data["current_currency_sign"] = config.current_currency_sign;
        config_json_data["current_fiat_sign"]     = config.current_fiat_sign;
        config_json_data["available_signs"]       = config.available_currency_signs;
        config_json_data["notification_enabled"]  = config.notification_enabled;

        ifs.close();

        //! Write contents
        std::ofstream ofs(cfg_path.string(), std::ios::trunc);
        assert(ofs.is_open());
        ofs << config_json_data;
    }
} // namespace

namespace atomic_dex
{
    void
    from_json(const nlohmann::json& j, atomic_dex::cfg& config)
    {
        j.at("lang").get_to(config.current_lang);
        j.at("available_lang").get_to(config.available_lang);
        j.at("current_currency").get_to(config.current_currency);
        j.at("current_fiat").get_to(config.current_fiat);
        j.at("available_fiat").get_to(config.available_fiat);
        j.at("possible_currencies").get_to(config.possible_currencies);
        j.at("current_currency_sign").get_to(config.current_currency_sign);
        j.at("available_signs").get_to(config.available_currency_signs);
        j.at("current_fiat_sign").get_to(config.current_fiat_sign);
        j.at("notification_enabled").get_to(config.notification_enabled);
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
    change_lang(cfg& config, const std::string& new_lang)
    {
        if (config.current_lang != new_lang)
        {
            config.current_lang = new_lang;
            upgrade_cfg(config);
        }
    }

    cfg
    load_cfg()
    {
        cfg      out;
        fs::path cfg_path = utils::get_current_configs_path() / "cfg.json";
        if (not fs::exists(cfg_path))
        {
            fs::path original_cfg_path{ag::core::assets_real_path() / "config" / "cfg.json"};
            //! Copy our json to current version
            SPDLOG_INFO("Copying app cfg: {} to {}", original_cfg_path.string(), cfg_path.string());

            fs::copy_file(original_cfg_path, cfg_path, get_override_options());
        }
        std::ifstream  ifs(cfg_path.string());
        nlohmann::json config_json_data;

        assert(ifs.is_open());
        ifs >> config_json_data;

        from_json(config_json_data, out);
        return out;
    }

    bool
    is_this_currency_a_fiat(cfg& config, const std::string& currency) noexcept
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
            config.current_fiat           = new_currency;
            config.current_fiat_sign      = config.current_currency_sign;
            config.possible_currencies[0] = new_currency;
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
    retrieve_sign_from_ticker(const cfg& config, const std::string& currency) noexcept
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
