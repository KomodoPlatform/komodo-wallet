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

//! PCH
#include "atomicdex/pch.hpp"

//! Deps
#include <boost/random/random_device.hpp>
#include <wally_bip39.h>

//! QT
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QTimer>

#if defined(_WIN32) || defined(WIN32)
#    ifndef WIN32_LEAN_AND_MEAN
#        define WIN32_LEAN_AND_MEAN
#    endif
#    define NOMINMAX
#    include <windows.h>

#    include <wincrypt.h>
#endif

#ifdef __APPLE__

#    include <QGuiApplication>
#    include <QWindow>
#    include <QWindowList>

#    include "atomicdex/platform/osx/manager.hpp"
#endif

//! Project Headers
#include "atomicdex/app.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/pages/qt.wallet.page.hpp"
#include "atomicdex/services/ip/ip.checker.service.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
//#include "atomicdex/services/ohlc/ohlc.provider.hpp"
#include "atomicdex/services/price/coinpaprika/coinpaprika.provider.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/services/price/oracle/band.provider.hpp"
#include "atomicdex/services/update/update.checker.service.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.bindings.hpp"
#include "atomicdex/utilities/security.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace
{
    constexpr std::size_t g_timeout_q_timer_ms = 16;

#if defined(_WIN32) || defined(WIN32)
    bool
    acquire_context(HCRYPTPROV* ctx)
    {
        if (!CryptAcquireContext(ctx, nullptr, nullptr, PROV_RSA_FULL, 0))
        {
            return CryptAcquireContext(ctx, nullptr, nullptr, PROV_RSA_FULL, CRYPT_NEWKEYSET);
        }
        return true;
    }


    size_t
    sysrandom(void* dst, size_t dstlen)
    {
        HCRYPTPROV ctx;
        if (!acquire_context(&ctx))
        {
            throw std::runtime_error("Unable to initialize Win32 crypt library.");
        }

        BYTE* buffer = reinterpret_cast<BYTE*>(dst);
        if (!CryptGenRandom(ctx, dstlen, buffer))
        {
            throw std::runtime_error("Unable to generate random bytes.");
        }

        if (!CryptReleaseContext(ctx, 0))
        {
            throw std::runtime_error("Unable to release Win32 crypt library.");
        }

        return dstlen;
    }
#endif
} // namespace

namespace atomic_dex
{
    void
    atomic_dex::application::change_state([[maybe_unused]] int visibility)
    {
#ifdef __APPLE__
        //qDebug() << visibility;
        {
            QWindowList windows = QGuiApplication::allWindows();
            QWindow*    win     = windows.first();
            atomic_dex::mac_window_setup(win->winId(), visibility == QWindow::FullScreen);
        }
#endif
    }

    QVariantList
    atomic_dex::application::get_enabled_coins() const noexcept
    {
        return m_enabled_coins;
    }

    QVariantList
    atomic_dex::application::get_enableable_coins() const noexcept
    {
        return m_enableable_coins;
    }

    bool
    atomic_dex::application::enable_coins(const QStringList& coins)
    {
        std::vector<std::string> coins_std;

        coins_std.reserve(coins.size());
        atomic_dex::mm2_service& mm2 = get_mm2();
        for (auto&& coin: coins) { coins_std.push_back(coin.toStdString()); }

        mm2.enable_multiple_coins(coins_std);

        return true;
    }

    bool
    application::disable_coins(const QStringList& coins)
    {
        QStringList coins_copy;
        for (auto&& coin: coins)
        {
            if (not get_orders()->swap_is_in_progress(coin) && coin != "KMD" && coin != "BTC")
            {
                if (coin == "ETH" || coin == "QTUM")
                {
                    coins_copy.push_back(coin);
                }
                else
                {
                    coins_copy.push_front(coin);
                }
            }
        }

        if (not coins_copy.empty())
        {
            std::vector<std::string> coins_std;
            system_manager_.get_system<portfolio_page>().get_portfolio()->disable_coins(coins_copy);
            system_manager_.get_system<trading_page>().disable_coins(coins_copy);
            coins_std.reserve(coins_copy.size());
            for (auto&& coin: coins_copy)
            {
                if (QString::fromStdString(get_mm2().get_current_ticker()) == coin && m_kmd_fully_enabled)
                {
                    system_manager_.get_system<wallet_page>().set_current_ticker("KMD");
                }
                coins_std.push_back(coin.toStdString());
            }
            get_mm2().disable_multiple_coins(coins_std);
            this->dispatcher_.trigger<update_portfolio_values>(false);
        }

        return true;
    }

    bool
    atomic_dex::application::first_run()
    {
        return get_wallets().empty();
    }

    void
    application::launch()
    {
        this->system_manager_.start();
        auto* timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, &application::tick);
        timer->start(g_timeout_q_timer_ms);
    }

    QString
    atomic_dex::application::get_mnemonic()
    {
#if defined(_WIN32) || defined(WIN32)
        std::array<unsigned char, WALLY_SECP_RANDOMIZE_LEN> data;
        sysrandom(data.data(), data.size());
        char*  output;
        words* output_words;
        bip39_get_wordlist(NULL, &output_words);
        bip39_mnemonic_from_bytes(output_words, data.data(), data.size(), &output);
        bip39_mnemonic_validate(output_words, output);
        return output;
#else
        std::array<unsigned char, WALLY_SECP_RANDOMIZE_LEN> data{};
        boost::random_device                                device;
        device.generate(data.begin(), data.end());
        char*  output       = nullptr;
        words* output_words = nullptr;
        bip39_get_wordlist(nullptr, &output_words);
        bip39_mnemonic_from_bytes(output_words, data.data(), data.size(), &output);
        bip39_mnemonic_validate(output_words, output);
        return output;
#endif
    }

    void
    application::tick()
    {
        this->process_one_frame();
        if (m_event_actions[events_action::need_a_full_refresh_of_mm2])
        {
            auto& mm2_s = system_manager_.create_system<mm2_service>(system_manager_);

            system_manager_.create_system<coinpaprika_provider>(mm2_s);
            // system_manager_.create_system<ohlc_provider>(mm2_s);

            connect_signals();
            m_event_actions[events_action::need_a_full_refresh_of_mm2] = false;
        }
        auto& mm2 = get_mm2();
        if (mm2.is_mm2_running())
        {
            std::vector<std::string> to_init;
            while (not m_portfolio_queue.empty())
            {
                const char* ticker_cstr = nullptr;
                m_portfolio_queue.pop(ticker_cstr);
                std::string ticker(ticker_cstr);
                if (ticker == "KMD")
                {
                    this->m_kmd_fully_enabled = true;
                }
                if (ticker == "BTC")
                {
                    this->m_btc_fully_enabled = true;
                }
                to_init.push_back(ticker);
                std::free((void*)ticker_cstr);
            }

            if (not to_init.empty())
            {
                system_manager_.get_system<portfolio_page>().get_portfolio()->initialize_portfolio(to_init);
                if (m_kmd_fully_enabled && m_btc_fully_enabled)
                {
                    if (std::find(to_init.begin(), to_init.end(), "KMD") != to_init.end())
                    {
                        get_wallet_page()->get_transactions_mdl()->reset();
                        this->dispatcher_.trigger<tx_fetch_finished>();
                    }
                    get_wallet_page()->refresh_ticker_infos();
                    this->set_status("complete");
                }
                this->dispatcher_.trigger<update_portfolio_values>();
            }
        }

        system_manager_.get_system<trading_page>().process_action();
        while (not this->m_actions_queue.empty())
        {
            if (m_event_actions[events_action::about_to_exit_app])
                break;
            action last_action;
            this->m_actions_queue.pop(last_action);
            switch (last_action)
            {
            case action::refresh_enabled_coin:
                if (mm2.is_mm2_running())
                {
                    this->process_refresh_enabled_coin_action();
                }
                break;
            case action::post_process_orders_finished:
                if (mm2.is_mm2_running())
                {
                    qobject_cast<orders_model*>(m_manager_models.at("orders"))->refresh_or_insert_orders();
                }
                break;
            case action::post_process_swaps_finished:
                if (mm2.is_mm2_running())
                {
                    qobject_cast<orders_model*>(m_manager_models.at("orders"))->refresh_or_insert_swaps();
                }
                break;
            case action::refresh_update_status:
                const auto&   update_service_sys = this->system_manager_.get_system<update_service_checker>();
                QJsonDocument doc                = QJsonDocument::fromJson(QString::fromStdString(update_service_sys.get_update_status().dump()).toUtf8());
                this->m_update_status            = doc.toVariant();
                emit updateStatusChanged();
                break;
            }
        }
    }

    mm2_service&
    application::get_mm2() noexcept
    {
        return this->system_manager_.get_system<mm2_service>();
    }

    entt::dispatcher&
    application::get_dispatcher() noexcept
    {
        return this->dispatcher_;
    }

    application::application(QObject* pParent) noexcept :
        QObject(pParent),
        m_update_status(QJsonObject{
            {"update_needed", false}, {"changelog", ""}, {"current_version", ""}, {"download_url", ""}, {"new_version", ""}, {"rpc_code", 0}, {"status", ""}}),
        m_manager_models{
            {"addressbook", new addressbook_model(system_manager_.create_system<qt_wallet_manager>(), this)},
            {"orders", new orders_model(this->system_manager_, this->dispatcher_, this)},
            {"internet_service", std::addressof(system_manager_.create_system<internet_service_checker>(this))},
            {"notifications", new notification_manager(this->dispatcher_, this)}}
    {
        get_dispatcher().sink<refresh_update_status>().connect<&application::on_refresh_update_status_event>(*this);
        //! MM2 system need to be created before the GUI and give the instance to the gui
        system_manager_.create_system<ip_service_checker>();
        auto& mm2_system           = system_manager_.create_system<mm2_service>(system_manager_);
        auto& settings_page_system = system_manager_.create_system<settings_page>(system_manager_, m_app, this);
        auto& portfolio_system     = system_manager_.create_system<portfolio_page>(system_manager_, this);
        portfolio_system.get_portfolio()->set_cfg(settings_page_system.get_cfg());

        system_manager_.create_system<wallet_page>(system_manager_, this);
        system_manager_.create_system<global_price_service>(system_manager_, settings_page_system.get_cfg());
        system_manager_.create_system<band_oracle_price_service>();
        system_manager_.create_system<coinpaprika_provider>(mm2_system);
        // system_manager_.create_system<ohlc_provider>(mm2_system);
        system_manager_.create_system<update_service_checker>();
        system_manager_.create_system<trading_page>(
            system_manager_, m_event_actions.at(events_action::about_to_exit_app), portfolio_system.get_portfolio(), this);

        connect_signals();
        if (is_there_a_default_wallet())
        {
            set_wallet_default_name(get_default_wallet_name());
        }
    }

    void
    atomic_dex::application::on_enabled_coins_event([[maybe_unused]] const enabled_coins_event& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::refresh_enabled_coin);
        }
    }

    void
    application::on_enabled_default_coins_event([[maybe_unused]] const enabled_default_coins_event& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::refresh_enabled_coin);
        }
    }

    void
    application::on_coin_fully_initialized_event(const coin_fully_initialized& evt) noexcept
    {
        //! This event is called when a call is enabled and cex provider finished fetch datas
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
            for (auto&& ticker: evt.tickers) { m_portfolio_queue.push(strdup(ticker.c_str())); }
        }
    }

    bool
    application::do_i_have_enough_funds(const QString& ticker, const QString& amount) const
    {
        t_float_50 amount_f(amount.toStdString());
        return get_mm2().do_i_have_enough_funds(ticker.toStdString(), amount_f);
    }

    const mm2_service&
    application::get_mm2() const noexcept
    {
        return this->system_manager_.get_system<mm2_service>();
    }

    void
    application::on_coin_disabled_event([[maybe_unused]] const coin_disabled& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::refresh_enabled_coin);
        }
    }

    QString
    application::get_balance(const QString& coin)
    {
        std::error_code ec;
        auto            res = get_mm2().my_balance(coin.toStdString(), ec);
        return QString::fromStdString(res);
    }

    QString
    application::get_status() const noexcept
    {
        return m_current_status;
    }

    void
    application::set_status(QString status) noexcept
    {
        this->m_current_status = std::move(status);
        emit onStatusChanged();
    }

    void
    application::on_mm2_initialized_event([[maybe_unused]] const mm2_initialized& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        this->set_status("enabling_coins");
    }

    void
    application::on_refresh_update_status_event([[maybe_unused]] const refresh_update_status& evt) noexcept
    {
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::refresh_update_status);
        }
    }

    void
    application::refresh_infos()
    {
        auto& mm2 = get_mm2();
        mm2.fetch_infos_thread();
    }

    void
    application::refresh_orders_and_swaps()
    {
        auto& mm2 = get_mm2();
        if (mm2.is_mm2_running())
        {
            mm2.batch_fetch_orders_and_swap();
        }
    }

    QVariant
    application::get_coin_info(const QString& ticker)
    {
        QVariant       out;
        nlohmann::json j      = to_qt_binding(get_mm2().get_coin_info(ticker.toStdString()));
        QJsonDocument  q_json = QJsonDocument::fromJson(QString::fromStdString(j.dump()).toUtf8());
        out                   = q_json.toVariant();
        return out;
    }

    bool
    application::disconnect()
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);

        //! Clear pending events
        while (not this->m_actions_queue.empty())
        {
            [[maybe_unused]] action act;
            this->m_actions_queue.pop(act);
        }

        while (not this->m_portfolio_queue.empty())
        {
            const char* ticker;
            m_portfolio_queue.pop(ticker);
            free((void*)ticker);
        }

        //! Clear models
        addressbook_model* addressbook = qobject_cast<addressbook_model*>(m_manager_models.at("addressbook"));
        if (auto count = addressbook->rowCount(); count > 0)
        {
            addressbook->removeRows(0, count);
        }

        orders_model* orders = qobject_cast<orders_model*>(m_manager_models.at("orders"));
        if (auto count = orders->rowCount(QModelIndex()); count > 0)
        {
            orders->removeRows(0, count, QModelIndex());
        }
        orders->clear_registry();

        system_manager_.get_system<portfolio_page>().get_portfolio()->reset();
        system_manager_.get_system<trading_page>().clear_models();
        get_wallet_page()->get_transactions_mdl()->reset();

        //! Mark systems
        system_manager_.mark_system<mm2_service>();
        system_manager_.mark_system<coinpaprika_provider>();
        // system_manager_.mark_system<ohlc_provider>();

        //! Disconnect signals
        system_manager_.get_system<trading_page>().disconnect_signals();
        qobject_cast<notification_manager*>(m_manager_models.at("notifications"))->disconnect_signals();
        get_dispatcher().sink<ticker_balance_updated>().disconnect<&application::on_ticker_balance_updated_event>(*this);
        get_dispatcher().sink<fiat_rate_updated>().disconnect<&application::on_fiat_rate_updated>(*this);
        get_dispatcher().sink<enabled_coins_event>().disconnect<&application::on_enabled_coins_event>(*this);
        get_dispatcher().sink<enabled_default_coins_event>().disconnect<&application::on_enabled_default_coins_event>(*this);
        get_dispatcher().sink<coin_fully_initialized>().disconnect<&application::on_coin_fully_initialized_event>(*this);
        get_dispatcher().sink<coin_disabled>().disconnect<&application::on_coin_disabled_event>(*this);
        get_dispatcher().sink<mm2_initialized>().disconnect<&application::on_mm2_initialized_event>(*this);
        get_dispatcher().sink<process_orders_finished>().disconnect<&application::on_process_orders_finished_event>(*this);
        get_dispatcher().sink<process_swaps_finished>().disconnect<&application::on_process_swaps_finished_event>(*this);

        m_event_actions[events_action::need_a_full_refresh_of_mm2] = true;

        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        wallet_manager.just_set_wallet_name("");
        emit onWalletDefaultNameChanged();

        this->m_btc_fully_enabled = false;
        this->m_kmd_fully_enabled = false;
        this->set_status("None");
        return fs::remove(utils::get_atomic_dex_config_folder() / "default.wallet");
    }

    void
    application::connect_signals()
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        qobject_cast<notification_manager*>(m_manager_models.at("notifications"))->connect_signals();
        system_manager_.get_system<trading_page>().connect_signals();
        get_dispatcher().sink<ticker_balance_updated>().connect<&application::on_ticker_balance_updated_event>(*this);
        get_dispatcher().sink<fiat_rate_updated>().connect<&application::on_fiat_rate_updated>(*this);
        get_dispatcher().sink<enabled_coins_event>().connect<&application::on_enabled_coins_event>(*this);
        get_dispatcher().sink<enabled_default_coins_event>().connect<&application::on_enabled_default_coins_event>(*this);
        get_dispatcher().sink<coin_fully_initialized>().connect<&application::on_coin_fully_initialized_event>(*this);
        get_dispatcher().sink<coin_disabled>().connect<&application::on_coin_disabled_event>(*this);
        get_dispatcher().sink<mm2_initialized>().connect<&application::on_mm2_initialized_event>(*this);
        get_dispatcher().sink<process_orders_finished>().connect<&application::on_process_orders_finished_event>(*this);
        get_dispatcher().sink<process_swaps_finished>().connect<&application::on_process_swaps_finished_event>(*this);
    }

    QString
    atomic_dex::application::get_regex_password_policy() noexcept
    {
        return QString(::atomic_dex::get_regex_password_policy());
    }

    /*QVariantMap
    application::get_trade_infos(const QString& ticker, const QString& receive_ticker, const QString& amount)
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        QVariantMap out;

        //! If the initial amount is < minimal trade amount it's not required to continue
        if (t_float_50(amount.toStdString()) < t_float_50("0.00777"))
        {
            out.insert("not_enough_balance_to_pay_the_fees", true);
            out.insert("trade_fee", "0");
            out.insert("input_final_value", "0");
            out.insert("tx_fee", "0");
            return out;
        }

        //! Get the trading fee -> 1 / (777 * amount);
        t_float_50 trade_fee_f = get_mm2().get_trade_fee(ticker.toStdString(), amount.toStdString(), false);

        //! Get the transaction fees (from mm2)
        auto answer = get_mm2().get_transaction_fees(ticker.toStdString());

        //! Is fixed fee are available
        if (!answer.amount.empty())
        {
            //! ERC fees will be use only if rel is an ERC-20 token
            t_float_50 erc_fees = 0;

            // > mm2
            t_float_50 tx_fee_f = t_float_50(answer.amount) * 2;

            //! If receive ticker exist we try to apply erc fees
            if (receive_ticker != "")
            {
                get_mm2().apply_specific_fees(receive_ticker.toStdString(), erc_fees);
            }

            auto tx_fee_value = QString::fromStdString(utils::get_formated_float(tx_fee_f));

            const std::string amount_std =
                t_float_50(amount.toStdString()) < utils::minimal_trade_amount() ? utils::minimal_trade_amount_str() : amount.toStdString();
            t_float_50  final_balance_f = t_float_50(amount_std) - (trade_fee_f + tx_fee_f);
            std::string final_balance   = amount.toStdString();
            // SPDLOG_DEBUG("{} = {} - ({} + {})", final_balance_f.str(8), amount_std, trade_fee_f.str(8), tx_fee_f.str(8));
            if (final_balance_f.convert_to<float>() > 0.0)
            {
                final_balance = utils::get_formated_float(final_balance_f);
                out.insert("not_enough_balance_to_pay_the_fees", false);
            }
            else
            {
                out.insert("not_enough_balance_to_pay_the_fees", true);
                t_float_50 amount_needed = utils::minimal_trade_amount() - final_balance_f;
                out.insert("amount_needed", QString::fromStdString(utils::get_formated_float(amount_needed)));
            }
            auto final_balance_qt = QString::fromStdString(final_balance);

            out.insert("trade_fee", QString::fromStdString(get_mm2().get_trading_fees_str(ticker.toStdString(), amount.toStdString(), false)));
            out.insert("tx_fee", tx_fee_value);
            if (erc_fees > 0)
            {
                auto erc_value = QString::fromStdString(utils::get_formated_float(erc_fees));
                out.insert("erc_fees", erc_value);
            }
            out.insert("is_ticker_of_fees_eth", get_mm2().get_coin_info(ticker.toStdString()).is_erc_20);
            out.insert("input_final_value", final_balance_qt);
        }
        return out;
    }*/

    void
    application::set_qt_app(std::shared_ptr<QApplication> app, QQmlApplicationEngine* engine) noexcept
    {
        this->m_app = app;
        connect(m_app.get(), SIGNAL(aboutToQuit()), this, SLOT(exit_handler()));
        connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, &application::app_state_changed);
        auto& settings_system = system_manager_.get_system<settings_page>();
        settings_system.set_qml_engine(engine);
        settings_system.init_lang();
    }

    QString
    application::retrieve_seed(const QString& wallet_name, const QString& password)
    {
        std::error_code ec;
        auto            key = atomic_dex::derive_password(password.toStdString(), ec);
        if (ec)
        {
            SPDLOG_WARN("{}", ec.message());
            if (ec == dextop_error::derive_password_failed)
            {
                return "wrong password";
            }
        }
        using namespace std::string_literals;
        const fs::path seed_path = utils::get_atomic_dex_config_folder() / (wallet_name.toStdString() + ".seed"s);
        auto           seed      = atomic_dex::decrypt(seed_path, key.data(), ec);
        if (ec == dextop_error::corrupted_file_or_wrong_password)
        {
            SPDLOG_WARN("{}", ec.message());
            return "wrong password";
        }
        return QString::fromStdString(seed);
    }


    bool
    application::mnemonic_validate(const QString& entropy)
    {
        return bip39_mnemonic_validate(nullptr, entropy.toStdString().c_str()) == 0;
    }

    bool
    application::export_swaps_json() noexcept
    {
        auto swaps = get_mm2().get_swaps().raw_result;

        if (not swaps.empty())
        {
            auto export_file_path = utils::get_atomic_dex_current_export_recent_swaps_file();

            std::ofstream ofs(export_file_path.string(), std::ios::out | std::ios::trunc);
            auto          j = nlohmann::json::parse(swaps);
            ofs << std::setw(4) << j;
            ofs.close();
            return true;
        }
        return false;
    }

    bool
    application::export_swaps(const QString& csv_filename) noexcept
    {
        auto           swaps    = get_mm2().get_swaps();
        const fs::path csv_path = utils::get_atomic_dex_export_folder() / (csv_filename.toStdString() + std::string(".csv"));

        std::ofstream ofs(csv_path.string(), std::ios::out | std::ios::trunc);
        ofs << "Maker Coin, Taker Coin, Maker Amount, Taker Amount, Type, Events, My Info, Is Recoverable" << std::endl;
        for (auto&& swap: swaps.swaps)
        {
            ofs << swap.maker_coin << ",";
            ofs << swap.taker_coin << ",";
            ofs << swap.maker_amount << ",";
            ofs << swap.taker_amount << ",";
            ofs << swap.type << ",";
            ofs << "not supported yet,"; //! This contains many events, what do we want to export here?
            ofs << "not supported yet,"; //! This is a big json object, need to choose which information we need to export ?
            ofs << (swap.funds_recoverable ? "True," : "False,");
            ofs << std::endl;
        }
        ofs.close();
        return true;
    }

    QString
    application::recover_fund(const QString& uuid)
    {
        QString result;

        ::mm2::api::recover_funds_of_swap_request request{.swap_uuid = uuid.toStdString()};
        auto                                      res = ::mm2::api::rpc_recover_funds(std::move(request), get_mm2().get_mm2_client());
        result                                        = QString::fromStdString(res.raw_result);

        return result;
    }

    QString
    application::get_price_amount(const QString& base_amount, const QString& rel_amount)
    {
        t_float_50 base_amount_f(base_amount.toStdString());
        t_float_50 rel_amount_f(rel_amount.toStdString());
        auto       final = (rel_amount_f / base_amount_f);

        std::stringstream ss;
        ss << std::fixed << std::setprecision(50) << final;
        SPDLOG_INFO("base_amount = {}, rel_amount = {}, final_amount = {}", base_amount.toStdString(), rel_amount.toStdString(), ss.str());
        return QString::fromStdString(ss.str());
    }
} // namespace atomic_dex

//! Constructor / Destructor
namespace atomic_dex
{
    application::~application() noexcept {}
} // namespace atomic_dex

//! Misc QML Utilities
namespace atomic_dex
{
    QVariant
    application::get_update_status() const noexcept
    {
        return m_update_status;
    }

    QVariantList
    application::get_all_coins() const noexcept
    {
        return to_qt_binding(get_mm2().get_all_coins());
    }

    QString
    application::get_version() noexcept
    {
        return QString::fromStdString(atomic_dex::get_version());
    }

    QString
    application::get_log_folder()
    {
        return QString::fromStdString(utils::get_atomic_dex_logs_folder().string());
    }

    QString
    application::get_mm2_version()
    {
        return QString::fromStdString(::mm2::api::rpc_version());
    }

    QString
    application::get_export_folder()
    {
        return QString::fromStdString(utils::get_atomic_dex_export_folder().string());
    }

    QString
    application::to_eth_checksum_qt(const QString& eth_lowercase_address)
    {
        auto str = eth_lowercase_address.toStdString();
        utils::to_eth_checksum(str);
        return QString::fromStdString(str);
    }
} // namespace atomic_dex

//! Trading functions
namespace atomic_dex
{
    /*QString
    application::get_cex_rates(const QString& base, const QString& rel)
    {
        std::error_code ec;
        const auto&     price_service = system_manager_.get_system<global_price_service>();
        return QString::fromStdString(price_service.get_cex_rates(base.toStdString(), rel.toStdString(), ec));
    }*/

    QString
    application::get_fiat_from_amount(const QString& ticker, const QString& amount)
    {
        std::error_code ec;
        const auto&     config        = system_manager_.get_system<settings_page>().get_cfg();
        const auto&     price_service = system_manager_.get_system<global_price_service>();
        return QString::fromStdString(price_service.get_price_as_currency_from_amount(config.current_fiat, ticker.toStdString(), amount.toStdString(), ec));
    }
} // namespace atomic_dex

//! Ticker balance change
namespace atomic_dex
{
    void
    application::on_fiat_rate_updated(const fiat_rate_updated&) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        this->dispatcher_.trigger<update_portfolio_values>();
    }

    void
    application::on_ticker_balance_updated_event(const ticker_balance_updated& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            if (not evt.tickers.empty())
            {
                get_portfolio_page()->get_portfolio()->update_balance_values(evt.tickers);
                this->dispatcher_.trigger<update_portfolio_values>(false);
            }
        }
    }
} // namespace atomic_dex

//! Addressbook
namespace atomic_dex
{
    addressbook_model*
    application::get_addressbook() const noexcept
    {
        return qobject_cast<addressbook_model*>(m_manager_models.at("addressbook"));
    }
} // namespace atomic_dex

//! Orders
namespace atomic_dex
{
    void
    application::on_process_swaps_finished_event([[maybe_unused]] const process_swaps_finished& evt) noexcept
    {
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::post_process_swaps_finished);
        }
    }

    void
    application::on_process_orders_finished_event([[maybe_unused]] const process_orders_finished& evt) noexcept
    {
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::post_process_orders_finished);
        }
    }

    orders_model*
    application::get_orders() const noexcept
    {
        return qobject_cast<orders_model*>(m_manager_models.at("orders"));
    }
} // namespace atomic_dex

//! Portfolio
namespace atomic_dex
{
    portfolio_page*
    application::get_portfolio_page() const noexcept
    {
        portfolio_page* ptr = const_cast<portfolio_page*>(std::addressof(system_manager_.get_system<portfolio_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Wallet manager QML API
namespace atomic_dex
{
    bool
    application::is_pin_cfg_enabled() const noexcept
    {
        return get_mm2().is_pin_cfg_enabled();
    }

    void
    application::set_emergency_password(const QString& emergency_password)
    {
        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        wallet_manager.set_emergency_password(emergency_password);
    }

    QString
    application::get_wallet_default_name() const noexcept
    {
        const auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        return wallet_manager.get_wallet_default_name();
    }

    void
    application::set_wallet_default_name(QString wallet_name) noexcept
    {
        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        wallet_manager.set_wallet_default_name(std::move(wallet_name));
        emit onWalletDefaultNameChanged();
    }

    bool
    atomic_dex::application::create(const QString& password, const QString& seed, const QString& wallet_name)
    {
        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        return wallet_manager.create(password, seed, wallet_name);
    }

    bool
    application::login(const QString& password, const QString& wallet_name)
    {
        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        bool  res            = wallet_manager.login(password, wallet_name, get_mm2(), [this, &wallet_name]() {
            this->set_wallet_default_name(wallet_name);
            this->set_status("initializing_mm2");
        });
        if (res)
        {
            addressbook_model* addressbook = qobject_cast<addressbook_model*>(m_manager_models.at("addressbook"));
            addressbook->initializeFromCfg();
        }
        return res;
    }

    bool
    application::confirm_password(const QString& wallet_name, const QString& password)
    {
        return atomic_dex::qt_wallet_manager::confirm_password(wallet_name, password);
    }

    bool
    application::delete_wallet(const QString& wallet_name)
    {
        return qt_wallet_manager::delete_wallet(wallet_name);
    }

    QString
    application::get_default_wallet_name()
    {
        return atomic_dex::qt_wallet_manager::get_default_wallet_name();
    }

    QStringList
    application::get_wallets()
    {
        return atomic_dex::qt_wallet_manager::get_wallets();
    }

    bool
    application::is_there_a_default_wallet()
    {
        return atomic_dex::qt_wallet_manager::is_there_a_default_wallet();
    }
} // namespace atomic_dex

//! Actions implementation
namespace atomic_dex
{
    void
    application::process_refresh_enabled_coin_action()
    {
        auto& mm2          = get_mm2();
        auto  refresh_coin = [](t_coins coins_container, auto&& coins_list) {
            coins_list.clear();
            coins_list = to_qt_binding(std::move(coins_container));
        };

        {
            auto coins = mm2.get_enabled_coins();
            refresh_coin(coins, m_enabled_coins);
            emit enabledCoinsChanged();
        }
        {
            auto coins = mm2.get_enableable_coins();
            refresh_coin(coins, m_enableable_coins);
            emit enableableCoinsChanged();
        }
    }

    void
    application::exit_handler()
    {
        SPDLOG_DEBUG("will quit app, prevent all threading event");
        this->system_manager_.mark_system<mm2_service>();
        this->process_one_frame();
        m_event_actions[events_action::about_to_exit_app] = true;
    }

    void
    application::app_state_changed()
    {
        switch (m_app->applicationState())
        {
        case Qt::ApplicationSuspended:
            SPDLOG_INFO("Application suspended");
            break;
        case Qt::ApplicationHidden:
            SPDLOG_INFO("Application hidden");
            break;
        case Qt::ApplicationInactive:
            SPDLOG_INFO("Application inactive");
            break;
        case Qt::ApplicationActive:
            SPDLOG_INFO("Application active");
            break;
        }
    }

} // namespace atomic_dex

//! trading
namespace atomic_dex
{
    trading_page*
    application::get_trading_page() const noexcept
    {
        trading_page* ptr = const_cast<trading_page*>(std::addressof(system_manager_.get_system<trading_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! wallet
namespace atomic_dex
{
    wallet_page*
    application::get_wallet_page() const noexcept
    {
        wallet_page* ptr = const_cast<wallet_page*>(std::addressof(system_manager_.get_system<wallet_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Settings
namespace atomic_dex
{
    settings_page*
    application::get_settings_page() const noexcept
    {
        settings_page* ptr = const_cast<settings_page*>(std::addressof(system_manager_.get_system<settings_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Notification
namespace atomic_dex
{
    notification_manager*
    application::get_notification_manager() const noexcept
    {
        return qobject_cast<notification_manager*>(m_manager_models.at("notifications"));
    }
} // namespace atomic_dex

//! Internet checker
namespace atomic_dex
{
    internet_service_checker*
    application::get_internet_checker() const noexcept
    {
        return qobject_cast<internet_service_checker*>(m_manager_models.at("internet_service"));
    }
} // namespace atomic_dex

//! IP checker
namespace atomic_dex
{
    ip_service_checker*
    application::get_ip_checker() const noexcept
    {
        ip_service_checker* ptr = const_cast<ip_service_checker*>(std::addressof(system_manager_.get_system<ip_service_checker>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! App restart
namespace atomic_dex
{
    void
    application::restart()
    {
        SPDLOG_INFO("restarting the application");
        const char* appimage = nullptr;
        if (appimage = std::getenv("APPIMAGE"); appimage)
        {
            SPDLOG_INFO("APPIMAGE path is {}", appimage);
        }

        qApp->quit();

        if (appimage == nullptr || not QString(appimage).contains("atomicdex-desktop"))
        {
            QProcess::startDetached(qApp->arguments()[0], qApp->arguments(), qApp->applicationDirPath());
        }
        else
        {
            QString path(appimage);
            QProcess::startDetached(path, qApp->arguments());
        }
    }
} // namespace atomic_dex
