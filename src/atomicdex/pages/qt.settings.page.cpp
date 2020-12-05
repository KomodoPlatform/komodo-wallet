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

//! QT
#include <QDebug>
#include <QLocale>

//! PCH
#include "atomicdex/pch.hpp"

//! Deps
#include <boost/algorithm/string/case_conv.hpp>

//! Project Headers
#include "atomicdex/events/events.hpp"
#include "atomicdex/managers/qt.wallet.manager.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.bindings.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

namespace
{
    void
    copy_icon(const QString icon_filepath, const QString icons_path_directory, const std::string& ticker)
    {
        if (not icon_filepath.isEmpty())
        {
            const fs::path& suffix = fs::path(icon_filepath.toStdString()).extension();
            fs::copy_file(
                icon_filepath.toStdString(), fs::path(icons_path_directory.toStdString()) / (boost::algorithm::to_lower_copy(ticker) + suffix.string()),
                get_override_options());
        }
    }
} // namespace

//! Constructo destructor
namespace atomic_dex
{
    settings_page::settings_page(entt::registry& registry, ag::ecs::system_manager& system_manager, std::shared_ptr<QApplication> app, QObject* parent) noexcept
        :
        QObject(parent),
        system(registry), m_system_manager(system_manager), m_app(app)
    {
    }
} // namespace atomic_dex

//! Override
namespace atomic_dex
{
    void
    settings_page::update() noexcept
    {
    }
} // namespace atomic_dex

//! Properties
namespace atomic_dex
{
    QString
    settings_page::get_empty_string() const noexcept
    {
        return m_empty_string;
    }

    QString
    settings_page::get_current_lang() const noexcept
    {
        return QString::fromStdString(m_config.current_lang);
    }

    void
    atomic_dex::settings_page::set_current_lang(QString new_lang) noexcept
    {
        const std::string new_lang_std = new_lang.toStdString();
        change_lang(m_config, new_lang_std);

        auto get_locale = [](const std::string& current_lang) {
            if (current_lang == "tr")
            {
                return QLocale::Language::Turkish;
            }
            if (current_lang == "en")
            {
                return QLocale::Language::English;
            }
            if (current_lang == "fr")
            {
                return QLocale::Language::French;
            }
            if (current_lang == "ru")
            {
                return QLocale::Language::Russian;
            }
            return QLocale::Language::AnyLanguage;
        };

        SPDLOG_INFO("Locale before parsing AtomicDEX settings: {}", QLocale().name().toStdString());
        QLocale::setDefault(get_locale(m_config.current_lang));
        SPDLOG_INFO("Locale after parsing AtomicDEX settings: {}", QLocale().name().toStdString());
        [[maybe_unused]] auto res = this->m_translator.load("atomic_defi_" + new_lang, QLatin1String(":/atomic_defi_design/assets/languages"));
        assert(res);
        this->m_app->installTranslator(&m_translator);
        this->m_qml_engine->retranslate();
        emit onLangChanged();
        // emit langChanged();
    }

    bool
    atomic_dex::settings_page::is_notification_enabled() const noexcept
    {
        return m_config.notification_enabled;
    }

    void
    settings_page::set_notification_enabled(bool is_enabled) noexcept
    {
        if (m_config.notification_enabled != is_enabled)
        {
            change_notification_status(m_config, is_enabled);
            emit onNotificationEnabledChanged();
        }
    }

    QString
    settings_page::get_current_currency_sign() const noexcept
    {
        return QString::fromStdString(this->m_config.current_currency_sign);
    }

    QString
    settings_page::get_current_fiat_sign() const noexcept
    {
        return QString::fromStdString(this->m_config.current_fiat_sign);
    }

    QString
    settings_page::get_current_currency() const noexcept
    {
        return QString::fromStdString(this->m_config.current_currency);
    }

    void
    settings_page::set_current_currency(const QString& current_currency) noexcept
    {
        if (current_currency.toStdString() != m_config.current_currency)
        {
            SPDLOG_INFO("change currency {} to {}", m_config.current_currency, current_currency.toStdString());
            atomic_dex::change_currency(m_config, current_currency.toStdString());
            this->dispatcher_.trigger<update_portfolio_values>();
            this->dispatcher_.trigger<current_currency_changed>();
            emit onCurrencyChanged();
            emit onCurrencySignChanged();
            emit onFiatSignChanged();
        }
    }

    QString
    settings_page::get_current_fiat() const noexcept
    {
        return QString::fromStdString(this->m_config.current_fiat);
    }

    void
    settings_page::set_current_fiat(const QString& current_fiat) noexcept
    {
        if (current_fiat.toStdString() != m_config.current_fiat)
        {
            SPDLOG_INFO("change fiat {} to {}", m_config.current_fiat, current_fiat.toStdString());
            atomic_dex::change_fiat(m_config, current_fiat.toStdString());
            emit onFiatChanged();
        }
    }
} // namespace atomic_dex

//! Public API
namespace atomic_dex
{
    atomic_dex::cfg&
    settings_page::get_cfg() noexcept
    {
        return m_config;
    }

    const atomic_dex::cfg&
    settings_page::get_cfg() const noexcept
    {
        return m_config;
    }

    void
    settings_page::init_lang() noexcept
    {
        set_current_lang(QString::fromStdString(m_config.current_lang));
    }
} // namespace atomic_dex

//! QML API
namespace atomic_dex
{
    QStringList
    settings_page::get_available_langs() const
    {
        QStringList out;
        out.reserve(m_config.available_lang.size());
        for (auto&& cur_lang: m_config.available_lang) { out.push_back(QString::fromStdString(cur_lang)); }
        return out;
    }

    QStringList
    settings_page::get_available_fiats() const
    {
        QStringList out;
        out.reserve(m_config.available_fiat.size());
        for (auto&& cur_fiat: m_config.available_fiat) { out.push_back(QString::fromStdString(cur_fiat)); }
        return out;
    }

    QStringList
    settings_page::get_available_currencies() const
    {
        QStringList out;
        out.reserve(m_config.possible_currencies.size());
        for (auto&& cur_currency: m_config.possible_currencies) { out.push_back(QString::fromStdString(cur_currency)); }
        return out;
    }

    bool
    settings_page::is_this_ticker_present_in_raw_cfg(const QString& ticker) const noexcept
    {
        return m_system_manager.get_system<mm2_service>().is_this_ticker_present_in_raw_cfg(ticker.toStdString());
    }

    bool
    settings_page::is_this_ticker_present_in_normal_cfg(const QString& ticker) const noexcept
    {
        return m_system_manager.get_system<mm2_service>().is_this_ticker_present_in_normal_cfg(ticker.toStdString());
    }

    QVariantList
    settings_page::get_custom_coins() const noexcept
    {
        auto coins = m_system_manager.get_system<mm2_service>().get_custom_coins();
        return to_qt_binding(std::move(coins));
    }

    QString
    settings_page::get_custom_coins_icons_path() const noexcept
    {
        return QString::fromStdString(utils::get_runtime_coins_path().string());
    }

    void
    settings_page::process_qrc_20_token_add(const QString& contract_address, const QString& coinpaprika_id, const QString& icon_filepath)
    {
        this->set_fetching_custom_token_data_busy(true);
        using namespace std::string_literals;
        std::string url            = "/contract/"s + contract_address.toStdString();
        auto        answer_functor = [this, contract_address, coinpaprika_id, icon_filepath](web::http::http_response resp) {
            std::string    body = TO_STD_STR(resp.extract_string(true).get());
            nlohmann::json out  = nlohmann::json::object();
            out["mm2_cfg"]      = nlohmann::json::object();
            out["adex_cfg"]     = nlohmann::json::object();
            if (resp.status_code() == 200)
            {
                nlohmann::json body_json      = nlohmann::json::parse(body);
                const auto     ticker         = body_json.at("qrc20").at("symbol").get<std::string>();
                const auto     adex_ticker    = ticker + "-QRC";
                const auto     name_lowercase = boost::algorithm::to_lower_copy(body_json.at("qrc20").at("name").get<std::string>());
                out["adex_ticker"]            = adex_ticker;
                out["ticker"]                 = ticker;
                out["name"]                   = name_lowercase;
                copy_icon(icon_filepath, get_custom_coins_icons_path(), adex_ticker);
                const auto&    mm2      = this->m_system_manager.get_system<mm2_service>();
                nlohmann::json qtum_cfg = mm2.get_raw_mm2_ticker_cfg("QTUM");
                if (not is_this_ticker_present_in_raw_cfg(QString::fromStdString(adex_ticker)))
                {
                    out["mm2_cfg"]["protocol"]                                      = nlohmann::json::object();
                    out["mm2_cfg"]["protocol"]["type"]                              = "QRC20";
                    out["mm2_cfg"]["protocol"]["protocol_data"]                     = nlohmann::json::object();
                    out["mm2_cfg"]["protocol"]["protocol_data"]["platform"]         = "QTUM";
                    std::string out_address                                         = "0x" + contract_address.toStdString();
                    out["mm2_cfg"]["protocol"]["protocol_data"]["contract_address"] = out_address;
                    out["mm2_cfg"]["coin"]                                          = adex_ticker;
                    out["mm2_cfg"]["gui_coin"]                                      = ticker;
                    out["mm2_cfg"]["mm2"]                                           = 1;
                    if (body_json.at("qrc20").contains("decimals"))
                    {
                        out["mm2_cfg"]["decimals"] = body_json.at("qrc20").at("decimals").get<int>();
                    }
                    out["mm2_cfg"]["txfee"]                  = qtum_cfg["txfee"];
                    out["mm2_cfg"]["pubtype"]                = qtum_cfg["pubtype"];
                    out["mm2_cfg"]["p2shtype"]               = qtum_cfg["p2shtype"];
                    out["mm2_cfg"]["wiftype"]                = qtum_cfg["wiftype"];
                    out["mm2_cfg"]["name"]                   = qtum_cfg["name"];
                    out["mm2_cfg"]["rpcport"]                = qtum_cfg["rpcport"];
                    out["mm2_cfg"]["segwit"]                 = qtum_cfg["segwit"];
                    out["mm2_cfg"]["required_confirmations"] = 3;
                    out["mm2_cfg"]["fname"]                  = name_lowercase;
                }
                if (not is_this_ticker_present_in_normal_cfg(QString::fromStdString(adex_ticker)))
                {
                    //!
                    out["adex_cfg"][adex_ticker]                      = nlohmann::json::object();
                    out["adex_cfg"][adex_ticker]["coin"]              = adex_ticker;
                    out["adex_cfg"][adex_ticker]["gui_coin"]          = ticker;
                    out["adex_cfg"][adex_ticker]["name"]              = body_json.at("qrc20").at("name").get<std::string>();
                    out["adex_cfg"][adex_ticker]["coinpaprika_id"]    = coinpaprika_id.toStdString();
                    out["adex_cfg"][adex_ticker]["explorer_url"]      = nlohmann::json::array({"https://explorer.qtum.org/"});
                    out["adex_cfg"][adex_ticker]["type"]              = "QRC-20";
                    out["adex_cfg"][adex_ticker]["active"]            = false;
                    out["adex_cfg"][adex_ticker]["currently_enabled"] = false;
                    out["adex_cfg"][adex_ticker]["is_custom_coin"]    = true;
                    if (not out.at("mm2_cfg").empty())
                    {
                        SPDLOG_INFO("mm2_cfg found, backup from new cfg");
                        out["adex_cfg"][adex_ticker]["mm2_backup"] = out["mm2_cfg"];
                    }
                    else
                    {
                        if (mm2.is_this_ticker_present_in_raw_cfg(adex_ticker))
                        {
                            SPDLOG_INFO("mm2_cfg not found backup {} cfg from current cfg", adex_ticker);
                            out["adex_cfg"][adex_ticker]["mm2_backup"] = mm2.get_raw_mm2_ticker_cfg(adex_ticker);
                        }
                    }
                }
            }
            else
            {
                out["error_message"] = body;
                out["error_code"]    = resp.status_code();
            }
            SPDLOG_DEBUG("result json of fetch qrc infos from contract address is: {}", out.dump(4));
            this->set_custom_token_data(nlohmann_json_object_to_qt_json_object(out));
            this->set_fetching_custom_token_data_busy(false);
        };
        ::mm2::api::async_process_rpc_get(::mm2::api::g_qtum_proxy_http_client, "qrc_infos", url).then(answer_functor).then(&handle_exception_pplx_task);
    }

    void
    settings_page::process_erc_20_token_add(const QString& contract_address, const QString& coinpaprika_id, const QString& icon_filepath)
    {
        this->set_fetching_custom_token_data_busy(true);
        using namespace std::string_literals;
        std::string url            = "/api/v1/erc_infos/"s + contract_address.toStdString();
        auto        answer_functor = [this, contract_address, coinpaprika_id, icon_filepath](web::http::http_response resp) {
            //! Extract answer
            std::string    body = TO_STD_STR(resp.extract_string(true).get());
            nlohmann::json out  = nlohmann::json::object();
            out["mm2_cfg"]      = nlohmann::json::object();
            out["adex_cfg"]     = nlohmann::json::object();
            if (resp.status_code() == 200)
            {
                nlohmann::json body_json      = nlohmann::json::parse(body).at("result")[0];
                const auto     ticker         = body_json.at("symbol").get<std::string>();
                const auto     name_lowercase = body_json.at("tokenName").get<std::string>();
                out["ticker"]                 = ticker;
                out["name"]                   = name_lowercase;
                copy_icon(icon_filepath, get_custom_coins_icons_path(), ticker);
                if (not is_this_ticker_present_in_raw_cfg(QString::fromStdString(ticker)))
                {
                    out["mm2_cfg"]["protocol"]                              = nlohmann::json::object();
                    out["mm2_cfg"]["protocol"]["type"]                      = "ERC20";
                    out["mm2_cfg"]["protocol"]["protocol_data"]             = nlohmann::json::object();
                    out["mm2_cfg"]["protocol"]["protocol_data"]["platform"] = "ETH";
                    std::string out_address                                 = contract_address.toStdString();
                    boost::algorithm::to_lower(out_address);
                    utils::to_eth_checksum(out_address);
                    out["mm2_cfg"]["protocol"]["protocol_data"]["contract_address"] = out_address;
                    out["mm2_cfg"]["rpcport"]                                       = 80;
                    out["mm2_cfg"]["coin"]                                          = ticker;
                    out["mm2_cfg"]["mm2"]                                           = 1;
                    out["mm2_cfg"]["decimals"]                                      = std::stoi(body_json.at("divisor").get<std::string>());
                    out["mm2_cfg"]["avg_blocktime"]                                 = 0.25;
                    out["mm2_cfg"]["required_confirmations"]                        = 3;
                    out["mm2_cfg"]["name"]                                          = name_lowercase;
                }
                if (not is_this_ticker_present_in_normal_cfg(QString::fromStdString(ticker)))
                {
                    //!
                    out["adex_cfg"][ticker]                   = nlohmann::json::object();
                    out["adex_cfg"][ticker]["coin"]           = ticker;
                    out["adex_cfg"][ticker]["name"]           = name_lowercase;
                    out["adex_cfg"][ticker]["coinpaprika_id"] = coinpaprika_id.toStdString();
                    out["adex_cfg"][ticker]["eth_nodes"] =
                        nlohmann::json::array({"http://eth1.cipig.net:8555", "http://eth2.cipig.net:8555", "http://eth3.cipig.net:8555"});
                    out["adex_cfg"][ticker]["explorer_url"]      = nlohmann::json::array({"https://etherscan.io/"});
                    out["adex_cfg"][ticker]["type"]              = "ERC-20";
                    out["adex_cfg"][ticker]["active"]            = false;
                    out["adex_cfg"][ticker]["currently_enabled"] = false;
                    out["adex_cfg"][ticker]["is_custom_coin"]    = true;
                    out["adex_cfg"][ticker]["mm2_backup"]        = out["mm2_cfg"];
                }
            }
            else
            {
                out["error_message"] = body;
                out["error_code"]    = resp.status_code();
            }
            SPDLOG_DEBUG("result json of fetch erc infos from contract address is: {}", out.dump(4));
            this->set_custom_token_data(nlohmann_json_object_to_qt_json_object(out));
            this->set_fetching_custom_token_data_busy(false);
        };
        ::mm2::api::async_process_rpc_get(::mm2::api::g_etherscan_proxy_http_client, "erc_infos", url).then(answer_functor).then(&handle_exception_pplx_task);
    }

    bool
    settings_page::is_fetching_custom_token_data_busy() const noexcept
    {
        return m_fetching_erc_data_busy.load();
    }

    void
    settings_page::set_fetching_custom_token_data_busy(bool status) noexcept
    {
        if (m_fetching_erc_data_busy != status)
        {
            m_fetching_erc_data_busy = status;
            emit customTokenDataStatusChanged();
        }
    }

    QVariant
    settings_page::get_custom_token_data() const noexcept
    {
        return nlohmann_json_object_to_qt_json_object(m_custom_token_data.get());
    }

    void
    settings_page::set_custom_token_data(QVariant rpc_data) noexcept
    {
        nlohmann::json out  = nlohmann::json::parse(QString(QJsonDocument(rpc_data.toJsonObject()).toJson()).toStdString());
        m_custom_token_data = out;
        emit customTokenDataChanged();
    }

    void
    settings_page::submit()
    {
        SPDLOG_DEBUG("submit whole cfg");
        nlohmann::json out = m_custom_token_data.get();
        this->m_system_manager.get_system<mm2_service>().add_new_coin(out.at("adex_cfg"), out.at("mm2_cfg"));
        this->set_custom_token_data(QJsonObject{{}});
    }

    void
    settings_page::remove_custom_coin(const QString& ticker) noexcept
    {
        SPDLOG_DEBUG("remove ticker: {}", ticker.toStdString());
        this->m_system_manager.get_system<mm2_service>().remove_custom_coin(ticker.toStdString());
    }

    void
    settings_page::set_qml_engine(QQmlApplicationEngine* engine) noexcept
    {
        m_qml_engine = engine;
    }

    void
    settings_page::reset_coin_cfg()
    {
        using namespace std::string_literals;
        const std::string wallet_name     = qt_wallet_manager::get_default_wallet_name().toStdString();
        const std::string wallet_cfg_file = std::string(atomic_dex::get_raw_version()) + "-coins"s + "."s + wallet_name + ".json"s;
        const fs::path    wallet_cfg_path{utils::get_atomic_dex_config_folder() / wallet_cfg_file};
        const fs::path    mm2_coins_file_path{atomic_dex::utils::get_current_configs_path() / "coins.json"};
        const auto        functor_remove = [](const auto&& path_to_remove) {
            if (fs::exists(path_to_remove))
            {
                fs_error_code ec;
                fs::remove(path_to_remove, ec);
                if (ec)
                {
                    SPDLOG_ERROR("error when removing {}: {}", path_to_remove.string(), ec.message());
                }
                else
                {
                    SPDLOG_INFO("Successfully removed {}", path_to_remove.string());
                }
            }
        };

        functor_remove(std::move(wallet_cfg_path));
        functor_remove(std::move(mm2_coins_file_path));
    }
} // namespace atomic_dex
