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

//! Deps
#include <boost/random/random_device.hpp>
#include <wally_bip39.h>

//! QT
#include <QDebug>
#include <QJsonDocument>
#include <QProcess>
#include <QSettings>
#include <QTimer>
#include <QSettings>

#ifdef __APPLE__

#    include <QGuiApplication>
#    include <QWindow>
#    include <QWindowList>

#    include "atomicdex/platform/osx/manager.hpp"
#endif

//! Project Headers
#include "app.hpp"
#include "atomicdex/services/exporter/exporter.service.hpp"
#include "atomicdex/services/mm2/auto.update.maker.order.service.hpp"
//#include "atomicdex/services/price/coingecko/coingecko.provider.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/services/price/coingecko/coingecko.wallet.charts.hpp"
#include "atomicdex/services/price/coinpaprika/coinpaprika.provider.hpp"
#include "atomicdex/services/price/oracle/band.provider.hpp"
#include "atomicdex/services/price/orderbook.scanner.service.hpp"

namespace
{
    constexpr std::size_t g_timeout_q_timer_ms = 16;
}

namespace atomic_dex
{
    void
    atomic_dex::application::change_state([[maybe_unused]] int visibility)
    {
/*#ifdef __APPLE__
        {
            QWindowList windows = QGuiApplication::allWindows();
            auto        win     = windows.first();
            atomic_dex::mac_window_setup(win->winId(), visibility == QWindow::FullScreen);
        }
#endif*/
    }

    bool
    atomic_dex::application::enable_coins(const QStringList& coins)
    {
        auto enableable_coins_count = entity_registry_.template ctx<QSettings>().value("MaximumNbCoinsEnabled").toULongLong();
        if (enableable_coins_count < coins.size() + get_portfolio_page()->get_global_cfg()->get_enabled_coins().size())
        {
            return false;
        }
        
        std::vector<std::string> coins_std{};
        coins_std.reserve(coins.size());
        atomic_dex::mm2_service& mm2 = get_mm2();
        std::unordered_set<std::string> extra_coins;
        for (auto&& coin: coins) {
            auto coin_info = mm2.get_coin_info(coin.toStdString());
            if (coin_info.has_parent_fees_ticker && coin_info.ticker != coin_info.fees_ticker)
            {
                auto coin_parent_info = mm2.get_coin_info(coin_info.fees_ticker);
                if (!coin_parent_info.currently_enabled && !coin_parent_info.active && extra_coins.insert(coin_parent_info.ticker).second)
                {
                    SPDLOG_INFO("Adding extra coin: {} to enable", coin_parent_info.ticker);
                }
            }
            coins_std.push_back(coin.toStdString());
        }

        for (auto&& extra_coin : extra_coins)
        {
            coins_std.push_back(extra_coin);
        }
        mm2.enable_multiple_coins(coins_std);

        return true;
    }

    bool
    atomic_dex::application::enable_coin(const QString& coin)
    {
        return enable_coins(QStringList{coin});
    }

    bool
    application::disable_coins(const QStringList& coins)
    {
        QString     primary_coin   = QString::fromStdString(g_primary_dex_coin);
        QString     secondary_coin = QString::fromStdString(g_second_primary_dex_coin);
        QStringList coins_copy;
        const auto& mm2 = system_manager_.get_system<mm2_service>();
        for (auto&& coin: coins)
        {
            const auto coin_info       = mm2.get_coin_info(coin.toStdString());
            bool       has_parent_fees = coin_info.has_parent_fees_ticker;
            if (not get_orders()->swap_is_in_progress(coin) && coin != primary_coin && coin != secondary_coin)
            {
                if (has_parent_fees)
                {
                    coins_copy.push_front(coin);
                }
                else
                {
                    coins_copy.push_back(coin);
                }
            }
        }

        if (not coins_copy.empty())
        {
            std::vector<std::string> coins_std{};
            system_manager_.get_system<portfolio_page>().disable_coins(coins_copy);
            system_manager_.get_system<trading_page>().disable_coins(coins_copy);
            coins_std.reserve(coins_copy.size());
            for (auto&& coin: coins_copy)
            {
                if (QString::fromStdString(get_mm2().get_current_ticker()) == coin && m_primary_coin_fully_enabled)
                {
                    system_manager_.get_system<wallet_page>().set_current_ticker(primary_coin);
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
        return qt_wallet_manager::get_wallets().empty();
    }

    void
    application::launch()
    {
        SPDLOG_INFO("Launch the application");
        this->system_manager_.start();
        auto* timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, &application::tick);
        timer->start(g_timeout_q_timer_ms);
    }

    QString
    atomic_dex::application::get_mnemonic()
    {
        std::array<unsigned char, WALLY_SECP_RANDOMIZE_LEN> data{};
        boost::random_device                                device;
        device.generate(data.begin(), data.end());
        char*  output       = nullptr;
        words* output_words = nullptr;
        bip39_get_wordlist(nullptr, &output_words);
        bip39_mnemonic_from_bytes(output_words, data.data(), data.size(), &output);
        bip39_mnemonic_validate(output_words, output);
        return output;
    }

    void
    application::tick()
    {
        this->process_one_frame();
        if (m_event_actions[events_action::need_a_full_refresh_of_mm2])
        {
            system_manager_.create_system<mm2_service>(system_manager_);

            // system_manager_.create_system<coinpaprika_provider>(system_manager_);
            // system_manager_.create_system<coingecko_provider>(system_manager_);
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
                if (ticker == g_primary_dex_coin)
                {
                    this->m_primary_coin_fully_enabled = true;
                }
                if (ticker == g_second_primary_dex_coin)
                {
                    this->m_secondary_coin_fully_enabled = true;
                }
                to_init.push_back(ticker);
                std::free((void*)ticker_cstr);
            }

            if (not to_init.empty())
            {
                system_manager_.get_system<portfolio_page>().initialize_portfolio(to_init);
                if (m_primary_coin_fully_enabled && m_secondary_coin_fully_enabled)
                {
                    if (std::find(to_init.begin(), to_init.end(), g_primary_dex_coin) != to_init.end())
                    {
                        get_wallet_page()->get_transactions_mdl()->reset();
                        this->dispatcher_.trigger<tx_fetch_finished>();
                    }
                    get_wallet_page()->refresh_ticker_infos();
                    system_manager_.get_system<qt_wallet_manager>().set_status("complete");
                }
                this->dispatcher_.trigger<update_portfolio_values>();
                if (system_manager_.has_system<coingecko_wallet_charts_service>())
                {
                    system_manager_.get_system<coingecko_wallet_charts_service>().manual_refresh("tick");
                }
            }
        }

        system_manager_.get_system<trading_page>().process_action();
        while (not this->m_actions_queue.empty())
        {
            if (m_event_actions[events_action::about_to_exit_app])
            {
                break;
            }
            action last_action;
            this->m_actions_queue.pop(last_action);
            switch (last_action)
            {
            case action::post_process_orders_and_swaps_finished:
                if (mm2.is_mm2_running())
                {
                    qobject_cast<orders_model*>(m_manager_models.at("orders"))->refresh_or_insert();
                }
                break;
            case action::post_process_orders_and_swaps_finished_reset:
                if (mm2.is_mm2_running())
                {
                    qobject_cast<orders_model*>(m_manager_models.at("orders"))->refresh_or_insert(true);
                }
                break;
            }
        }
    }

    mm2_service&
    application::get_mm2()
    {
        return this->system_manager_.get_system<mm2_service>();
    }

    entt::dispatcher&
    application::get_dispatcher()
    {
        return this->dispatcher_;
    }

    const entt::registry&
    application::get_registry() const
    {
        return this->entity_registry_;
    }

    entt::registry&
    application::get_registry()
    {
        return this->entity_registry_;
    }

    void
    application::post_handle_settings()
    {
        QSettings& settings = get_registry().ctx<QSettings>();
        if (settings.value("AutomaticUpdateOrderBot", false).toBool())
        {
            SPDLOG_INFO("AutomaticUpdateOrderBot is true, activating the service");
            system_manager_.create_system<auto_update_maker_order_service>(system_manager_);
        }
        else
        {
            SPDLOG_WARN("AutomaticUpdateOrderBot is false, ignoring the service");
        }
        auto category_chart = static_cast<WalletChartsCategories>(settings.value("WalletChartsCategory", 2).toInt());
        system_manager_.get_system<portfolio_page>().set_chart_category(category_chart);
    }

    application::application(QObject* pParent) : QObject(pParent)
    {
        fs::path settings_path = (atomic_dex::utils::get_current_configs_path() / "cfg.ini");
        #if defined(_WIN32) || defined(WIN32)
            this->entity_registry_.set<QSettings>(QString::fromStdWString(settings_path.wstring()), QSettings::IniFormat);
        #else
            this->entity_registry_.set<QSettings>(QString::fromStdString(settings_path.string()), QSettings::IniFormat);
        #endif

        //! Creates managers
        {
            system_manager_.create_system<qt_wallet_manager>(system_manager_);
            system_manager_.create_system<addressbook_page>(system_manager_);
        }

        //! Creates models
        {
            // m_manager_models.emplace("addressbook", new addressbook_model(system_manager_, this));
            m_manager_models.emplace("orders", new orders_model(system_manager_, this->dispatcher_, this));
            m_manager_models.emplace(
                "internet_service", std::addressof(system_manager_.create_system<internet_service_checker>(system_manager_, this->dispatcher_, this)));
            m_manager_models.emplace("notifications", new notification_manager(dispatcher_, this));
        }

        // get_dispatcher().sink<refresh_update_status>().connect<&application::on_refresh_update_status_event>(*this);
        //! MM2 system need to be created before the GUI and give the instance to the gui
        system_manager_.create_system<ip_service_checker>();
        system_manager_.create_system<mm2_service>(system_manager_);
        auto& settings_page_system = system_manager_.create_system<settings_page>(system_manager_, m_app, this);
        auto& portfolio_system     = system_manager_.create_system<portfolio_page>(system_manager_, this);
        portfolio_system.get_portfolio()->set_cfg(settings_page_system.get_cfg());

        system_manager_.create_system<wallet_page>(system_manager_, this);
        system_manager_.create_system<global_price_service>(system_manager_, settings_page_system.get_cfg());
        system_manager_.create_system<orderbook_scanner_service>(system_manager_);
        system_manager_.create_system<band_oracle_price_service>();
        // system_manager_.create_system<coinpaprika_provider>(system_manager_);
        //system_manager_.create_system<coingecko_provider>(system_manager_);
        system_manager_.create_system<komodo_prices_provider>();
        auto& self_update_system = system_manager_.create_system<self_update_service>();
#if !defined(Q_OS_WINDOWS)
        self_update_system.disable();
#endif
        system_manager_.create_system<coingecko_wallet_charts_service>(system_manager_);
        system_manager_.create_system<exporter_service>(system_manager_);
        system_manager_.create_system<trading_page>(
            system_manager_, m_event_actions.at(events_action::about_to_exit_app), portfolio_system.get_portfolio(), this);

        connect_signals();
        if (qt_wallet_manager::is_there_a_default_wallet())
        {
            auto* wallet_mgr = get_wallet_mgr();
            wallet_mgr->set_wallet_default_name(wallet_mgr->get_default_wallet_name());
            // set_wallet_default_name(get_default_wallet_name());
        }
        SPDLOG_INFO("application created");
    }

    void
    application::on_coin_fully_initialized_event(const coin_fully_initialized& evt)
    {
        //! This event is called when a call is enabled and cex provider finished fetch data
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            SPDLOG_DEBUG("on_coin_fully_initialized_event");
#if !defined(_WIN32)
            for (auto&& ticker: evt.tickers) { m_portfolio_queue.push(strdup(ticker.c_str())); }
#else
            for (auto&& ticker: evt.tickers) { m_portfolio_queue.push(_strdup(ticker.c_str())); }
#endif
        }
    }

    bool
    application::do_i_have_enough_funds(const QString& ticker, const QString& amount) const
    {
        t_float_50 amount_f = safe_float(amount.toStdString());
        return get_mm2().do_i_have_enough_funds(ticker.toStdString(), amount_f);
    }

    const mm2_service&
    application::get_mm2() const
    {
        return this->system_manager_.get_system<mm2_service>();
    }

    QString
    application::get_balance(const QString& coin)
    {
        std::error_code ec;
        auto            res = get_mm2().my_balance(coin.toStdString(), ec);
        return QString::fromStdString(res);
    }

    void
    application::on_mm2_initialized_event([[maybe_unused]] const mm2_initialized& evt)
    {
        SPDLOG_DEBUG("{} l{}", __FUNCTION__, __LINE__);
        system_manager_.get_system<qt_wallet_manager>().set_status("enabling_coins");
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

    bool
    application::disconnect()
    {
        //! Clears pending events
        while (not this->m_actions_queue.empty())
        {
            [[maybe_unused]] action act;
            this->m_actions_queue.pop(act);
        }

        while (not this->m_portfolio_queue.empty())
        {
            const char* ticker = nullptr;
            m_portfolio_queue.pop(ticker);
            free((void*)ticker);
        }

        auto* addressbook_pg = get_addressbook_page();
        addressbook_pg->clear();

        orders_model* orders = qobject_cast<orders_model*>(m_manager_models.at("orders"));
        if (auto count = orders->rowCount(QModelIndex()); count > 0)
        {
            orders->removeRows(0, count, QModelIndex());
        }
        orders->reset();

        system_manager_.get_system<portfolio_page>().get_portfolio()->reset();
        system_manager_.get_system<portfolio_page>().set_current_balance_fiat_all("0");
        system_manager_.get_system<trading_page>().clear_models();
        get_wallet_page()->get_transactions_mdl()->reset();


        //! Mark systems
        system_manager_.mark_system<mm2_service>();
        //system_manager_.mark_system<coingecko_provider>();

        //! Disconnect signals
        get_trading_page()->disconnect_signals();
        addressbook_pg->disconnect_signals();
        qobject_cast<notification_manager*>(m_manager_models.at("notifications"))->disconnect_signals();
        dispatcher_.sink<ticker_balance_updated>().disconnect<&application::on_ticker_balance_updated_event>(*this);
        dispatcher_.sink<fiat_rate_updated>().disconnect<&application::on_fiat_rate_updated>(*this);
        dispatcher_.sink<coin_fully_initialized>().disconnect<&application::on_coin_fully_initialized_event>(*this);
        dispatcher_.sink<mm2_initialized>().disconnect<&application::on_mm2_initialized_event>(*this);
        dispatcher_.sink<process_swaps_and_orders_finished>().disconnect<&application::on_process_orders_and_swaps_finished_event>(*this);

        m_event_actions[events_action::need_a_full_refresh_of_mm2] = true;

        //! Resets wallet name.
        auto& wallet_manager = this->system_manager_.get_system<qt_wallet_manager>();
        wallet_manager.just_set_wallet_name("");

        this->m_secondary_coin_fully_enabled = false;
        this->m_primary_coin_fully_enabled   = false;
        system_manager_.get_system<qt_wallet_manager>().set_status("None");
        return fs::remove(utils::get_atomic_dex_config_folder() / "default.wallet");
    }

    void
    application::connect_signals()
    {
        SPDLOG_INFO("connecting signals");
        qobject_cast<notification_manager*>(m_manager_models.at("notifications"))->connect_signals();
        system_manager_.get_system<trading_page>().connect_signals();
        system_manager_.get_system<addressbook_page>().connect_signals();
        get_dispatcher().sink<ticker_balance_updated>().connect<&application::on_ticker_balance_updated_event>(*this);
        get_dispatcher().sink<fiat_rate_updated>().connect<&application::on_fiat_rate_updated>(*this);
        get_dispatcher().sink<coin_fully_initialized>().connect<&application::on_coin_fully_initialized_event>(*this);
        get_dispatcher().sink<mm2_initialized>().connect<&application::on_mm2_initialized_event>(*this);
        get_dispatcher().sink<process_swaps_and_orders_finished>().connect<&application::on_process_orders_and_swaps_finished_event>(*this);
        // get_dispatcher().sink<process_swaps_finished>().connect<&application::on_process_swaps_finished_event>(*this);
    }

    void
    application::set_qt_app(std::shared_ptr<QApplication> app, QQmlApplicationEngine* engine)
    {
        this->m_app = app;
        connect(m_app.get(), SIGNAL(aboutToQuit()), this, SLOT(exit_handler()));
        connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, &application::app_state_changed);
        auto& settings_system = system_manager_.get_system<settings_page>();
        settings_system.set_qml_engine(engine);
        settings_system.init_lang();
    }

    QString
    application::recover_fund(const QString& uuid)
    {
        QString result;

        ::mm2::api::recover_funds_of_swap_request request{.swap_uuid = uuid.toStdString()};
        auto                                      res = get_mm2().get_mm2_client().rpc_recover_funds(std::move(request));
        result                                        = QString::fromStdString(res.raw_result);

        return result;
    }
} // namespace atomic_dex

//! Misc QML Utilities
namespace atomic_dex
{
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
    QString
    application::get_fiat_from_amount(const QString& ticker, const QString& amount)
    {
        std::error_code ec;
        const auto&     config        = system_manager_.get_system<settings_page>().get_cfg();
        const auto&     price_service = system_manager_.get_system<global_price_service>();
        return QString::fromStdString(price_service.get_price_as_currency_from_amount(config.current_fiat, ticker.toStdString(), amount.toStdString()));
    }
} // namespace atomic_dex

//! Ticker balance change
namespace atomic_dex
{
    void
    application::on_fiat_rate_updated(const fiat_rate_updated&)
    {
        SPDLOG_DEBUG("on_fiat_rate_updated");
        this->dispatcher_.trigger<update_portfolio_values>();
        // this->dispatcher_.trigger<current_currency_changed>();
    }

    void
    application::on_ticker_balance_updated_event(const ticker_balance_updated& evt)
    {
        SPDLOG_DEBUG("Ticker balance is about to be updated.");
        if (m_event_actions[events_action::about_to_exit_app])
        {
            SPDLOG_DEBUG("Ticker balance not updated because app is exiting.");
        }
        else if (evt.tickers.empty())
        {
            SPDLOG_DEBUG("Ticker balance not updated because there are not tickers to update");
        }
        else if (get_portfolio_page()->get_portfolio()->update_balance_values(evt.tickers))
        {
            this->dispatcher_.trigger<update_portfolio_values>(false);
            SPDLOG_DEBUG("Ticker balance updated.");
        }
        else
        {
            SPDLOG_ERROR("Ticker balance not updated, tickers not found in the registry: {}", fmt::join(evt.tickers, ", "));
        }
    }
} // namespace atomic_dex

//! Orders
namespace atomic_dex
{
    /*void
    application::on_process_swaps_finished_event([[maybe_unused]] const process_swaps_finished& evt)
    {
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(action::post_process_swaps_finished);
        }
    }*/

    void
    application::on_process_orders_and_swaps_finished_event([[maybe_unused]] const process_swaps_and_orders_finished& evt)
    {
        if (not m_event_actions[events_action::about_to_exit_app])
        {
            this->m_actions_queue.push(
                evt.after_manual_reset ? action::post_process_orders_and_swaps_finished_reset : action::post_process_orders_and_swaps_finished);
        }
    }

    orders_model*
    application::get_orders() const
    {
        return qobject_cast<orders_model*>(m_manager_models.at("orders"));
    }
} // namespace atomic_dex

//! Portfolio
namespace atomic_dex
{
    portfolio_page*
    application::get_portfolio_page() const
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
    application::is_pin_cfg_enabled() const
    {
        return get_mm2().is_pin_cfg_enabled();
    }
} // namespace atomic_dex

//! Actions implementation
namespace atomic_dex
{
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
    application::get_trading_page() const
    {
        auto ptr = const_cast<trading_page*>(std::addressof(system_manager_.get_system<trading_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! wallet
namespace atomic_dex
{
    wallet_page*
    application::get_wallet_page() const
    {
        auto ptr = const_cast<wallet_page*>(std::addressof(system_manager_.get_system<wallet_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Settings
namespace atomic_dex
{
    settings_page*
    application::get_settings_page() const
    {
        auto ptr = const_cast<settings_page*>(std::addressof(system_manager_.get_system<settings_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Addressbook
namespace atomic_dex
{
    addressbook_page*
    application::get_addressbook_page() const
    {
        auto ptr = const_cast<addressbook_page*>(std::addressof(system_manager_.get_system<addressbook_page>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Notification
namespace atomic_dex
{
    notification_manager*
    application::get_notification_manager() const
    {
        return qobject_cast<notification_manager*>(m_manager_models.at("notifications"));
    }
} // namespace atomic_dex

//! Internet checker
namespace atomic_dex
{
    internet_service_checker*
    application::get_internet_checker() const
    {
        return qobject_cast<internet_service_checker*>(m_manager_models.at("internet_service"));
    }
} // namespace atomic_dex

//! update checker
namespace atomic_dex
{
    self_update_service*
    application::get_self_update_service() const
    {
        auto ptr = const_cast<self_update_service*>(std::addressof(system_manager_.get_system<self_update_service>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! IP checker
namespace atomic_dex
{
    ip_service_checker*
    application::get_ip_checker() const
    {
        auto ptr = const_cast<ip_service_checker*>(std::addressof(system_manager_.get_system<ip_service_checker>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Exporter service
namespace atomic_dex
{
    exporter_service*
    application::get_exporter_service() const
    {
        auto ptr = const_cast<exporter_service*>(std::addressof(system_manager_.get_system<exporter_service>()));
        assert(ptr != nullptr);
        return ptr;
    }
} // namespace atomic_dex

//! Wallet_mgr
namespace atomic_dex
{
    qt_wallet_manager*
    application::get_wallet_mgr() const
    {
        auto ptr = const_cast<qt_wallet_manager*>(std::addressof(system_manager_.get_system<qt_wallet_manager>()));
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
        const char* appimage{nullptr};
        if (appimage = std::getenv("APPIMAGE"); appimage != nullptr)
        {
            SPDLOG_INFO("APPIMAGE path is {}", appimage);
        }

        qApp->quit();

        if (appimage == nullptr || not QString(appimage).contains(DEX_PROJECT_NAME))
        {
            bool res = QProcess::startDetached(qApp->arguments()[0], qApp->arguments(), qApp->applicationDirPath());
            if (!res)
            {
                SPDLOG_ERROR("Couldn't start a new process");
            }
            else
            {
                SPDLOG_INFO("Successfully restarted the app");
            }
        }
        else
        {
            QString path(appimage);
            QProcess::startDetached(path, qApp->arguments());
        }
    }
} // namespace atomic_dex
