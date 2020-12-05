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
#include <QAbstractListModel>
#include <QApplication>
#include <QImage>
#include <QObject>
#include <QQmlApplicationEngine>
#include <QSize>
#include <QStringList>
#include <QTranslator>
#include <QVariantMap>

//! Deps
#include <entt/core/attribute.h>
#include <antara/gaming/world/world.app.hpp>

//! Project Headers
#include "atomicdex/config/app.cfg.hpp"
#include "atomicdex/constants/qt.actions.hpp"
#include "atomicdex/managers/notification.manager.hpp"
#include "atomicdex/managers/qt.wallet.manager.hpp"
#include "atomicdex/models/qt.addressbook.model.hpp"
#include "atomicdex/models/qt.candlestick.charts.model.hpp"
#include "atomicdex/models/qt.orders.model.hpp"
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/pages/qt.wallet.page.hpp"
#include "atomicdex/services/internet/internet.checker.service.hpp"
#include "atomicdex/services/ip/ip.checker.service.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/utilities/qt.bindings.hpp"
#include "atomicdex/widgets/dex/qt.orderbook.hpp"

namespace ag = antara::gaming;

using portfolio_page_ptr = atomic_dex::portfolio_page*;
Q_DECLARE_METATYPE(portfolio_page_ptr)

namespace atomic_dex
{
    struct ENTT_API application : public QObject, public ag::world::app
    {
        Q_OBJECT

        //! Properties
        Q_PROPERTY(QList<QVariant> enabled_coins READ get_enabled_coins NOTIFY enabledCoinsChanged)
        Q_PROPERTY(QList<QVariant> enableable_coins READ get_enableable_coins NOTIFY enableableCoinsChanged)
        Q_PROPERTY(addressbook_model* addressbook_mdl READ get_addressbook NOTIFY addressbookChanged)
        Q_PROPERTY(orders_model* orders_mdl READ get_orders NOTIFY ordersChanged)
        Q_PROPERTY(QVariant update_status READ get_update_status NOTIFY updateStatusChanged)
        Q_PROPERTY(portfolio_page_ptr portfolio_pg READ get_portfolio_page NOTIFY portfolioPageChanged)
        Q_PROPERTY(notification_manager* notification_mgr READ get_notification_manager)
        Q_PROPERTY(internet_service_checker* internet_checker READ get_internet_checker NOTIFY internetCheckerChanged)
        Q_PROPERTY(ip_service_checker* ip_checker READ get_ip_checker NOTIFY ipCheckerChanged)
        Q_PROPERTY(trading_page* trading_pg READ get_trading_page NOTIFY tradingPageChanged)
        Q_PROPERTY(wallet_page* wallet_pg READ get_wallet_page NOTIFY walletPageChanged)
        Q_PROPERTY(settings_page* settings_pg READ get_settings_page NOTIFY settingsPageChanged)
        Q_PROPERTY(QString wallet_default_name READ get_wallet_default_name WRITE set_wallet_default_name NOTIFY onWalletDefaultNameChanged)
        Q_PROPERTY(QString initial_loading_status READ get_status WRITE set_status NOTIFY onStatusChanged)

        //! Private function
        void connect_signals();
        void tick();
        void process_refresh_enabled_coin_action();

        enum events_action
        {
            need_a_full_refresh_of_mm2 = 0,
            candlestick_need_a_reset   = 1,
            orderbook_need_a_reset     = 2,
            about_to_exit_app          = 3,
            size                       = 4
        };

        //! Private typedefs
        using t_actions_queue                       = boost::lockfree::queue<action>;
        using t_portfolio_coins_to_initialize_queue = boost::lockfree::queue<const char*>;
        using t_manager_model_registry              = std::unordered_map<std::string, QObject*>;
        using t_events_actions                      = std::array<std::atomic_bool, events_action::size>;

        //! Private members fields
        std::shared_ptr<QApplication>         m_app;
        t_actions_queue                       m_actions_queue{g_max_actions_size};
        t_portfolio_coins_to_initialize_queue m_portfolio_queue{g_max_actions_size};
        QVariantList                          m_enabled_coins;
        QVariantList                          m_enableable_coins;
        QVariant                              m_update_status;
        QString                               m_current_status{"None"};
        t_manager_model_registry              m_manager_models;
        t_events_actions                      m_event_actions{{false}};
        std::atomic_bool                      m_btc_fully_enabled{false};
        std::atomic_bool                      m_kmd_fully_enabled{false};

      public:
        //! Constructor
        explicit application(QObject* pParent = nullptr) noexcept;
        ~application() noexcept;

        //! entt::dispatcher events
        void on_ticker_balance_updated_event(const ticker_balance_updated&) noexcept;
        void on_fiat_rate_updated(const fiat_rate_updated&) noexcept;
        void on_enabled_coins_event(const enabled_coins_event&) noexcept;
        void on_enabled_default_coins_event(const enabled_default_coins_event&) noexcept;
        void on_coin_fully_initialized_event(const coin_fully_initialized&) noexcept;
        void on_coin_disabled_event(const coin_disabled&) noexcept;
        void on_mm2_initialized_event(const mm2_initialized&) noexcept;
        void on_refresh_update_status_event(const refresh_update_status&) noexcept;
        void on_process_orders_finished_event(const process_orders_finished&) noexcept;
        void on_process_swaps_finished_event(const process_swaps_finished&) noexcept;

        //! Properties Getter
        mm2_service&               get_mm2() noexcept;
        const mm2_service&         get_mm2() const noexcept;
        entt::dispatcher&          get_dispatcher() noexcept;
        addressbook_model*         get_addressbook() const noexcept;
        portfolio_page*            get_portfolio_page() const noexcept;
        wallet_page*               get_wallet_page() const noexcept;
        orders_model*              get_orders() const noexcept;
        notification_manager*      get_notification_manager() const noexcept;
        trading_page*              get_trading_page() const noexcept;
        settings_page*             get_settings_page() const noexcept;
        internet_service_checker*  get_internet_checker() const noexcept;
        ip_service_checker*        get_ip_checker() const noexcept;
        QVariantList               get_enabled_coins() const noexcept;
        QVariantList               get_enableable_coins() const noexcept;
        QString                    get_wallet_default_name() const noexcept;
        QString                    get_status() const noexcept;
        QVariant                   get_update_status() const noexcept;
        Q_INVOKABLE static QString get_version() noexcept;

        //! Properties Setter
        void set_wallet_default_name(QString wallet_default_name) noexcept;
        void set_status(QString status) noexcept;
        void set_qt_app(std::shared_ptr<QApplication> app, QQmlApplicationEngine* qml_engine) noexcept;

        //! Launch the internal loop for the SDK.
        void launch();

        //! Bind to the QML Worlds
        Q_INVOKABLE void restart();

        //! Wallet Manager QML API Bindings, this internally call the `atomic_dex::qt_wallet_manager`
        Q_INVOKABLE bool               login(const QString& password, const QString& wallet_name);
        Q_INVOKABLE bool               create(const QString& password, const QString& seed, const QString& wallet_name);
        Q_INVOKABLE static QStringList get_wallets();
        Q_INVOKABLE static bool        is_there_a_default_wallet();
        Q_INVOKABLE static QString     get_default_wallet_name();
        Q_INVOKABLE static bool        delete_wallet(const QString& wallet_name);
        Q_INVOKABLE static bool        confirm_password(const QString& wallet_name, const QString& password);
        Q_INVOKABLE void               set_emergency_password(const QString& emergency_password);
        Q_INVOKABLE bool               is_pin_cfg_enabled() const noexcept;

        //! Miscs
        // Q_INVOKABLE QString        get_paprika_id_from_ticker(const QString& ticker) const;
        Q_INVOKABLE static QString to_eth_checksum_qt(const QString& eth_lowercase_address);
        Q_INVOKABLE static QString get_mm2_version();
        Q_INVOKABLE static QString get_log_folder();
        Q_INVOKABLE static QString get_export_folder();
        Q_INVOKABLE static void    change_state(int visibility);

        //! Portfolio QML API Bindings
        Q_INVOKABLE QString recover_fund(const QString& uuid);

        //! Others
        Q_INVOKABLE static bool    mnemonic_validate(const QString& entropy);
        Q_INVOKABLE static QString retrieve_seed(const QString& wallet_name, const QString& password);
        Q_INVOKABLE void           refresh_infos();
        Q_INVOKABLE void           refresh_orders_and_swaps();
        Q_INVOKABLE static QString get_mnemonic();
        Q_INVOKABLE static bool    first_run();
        Q_INVOKABLE bool           disconnect();
        Q_INVOKABLE bool           enable_coins(const QStringList& coins);
        Q_INVOKABLE QString        get_balance(const QString& coin);
        Q_INVOKABLE static QString get_price_amount(const QString& base_amount, const QString& rel_amount);
        Q_INVOKABLE bool           do_i_have_enough_funds(const QString& ticker, const QString& amount) const;
        Q_INVOKABLE bool           disable_coins(const QStringList& coins);

        //Q_INVOKABLE QString        get_cex_rates(const QString& base, const QString& rel);
        Q_INVOKABLE QString        get_fiat_from_amount(const QString& ticker, const QString& amount);
        Q_INVOKABLE QVariant       get_coin_info(const QString& ticker);
        Q_INVOKABLE bool           export_swaps(const QString& csv_filename) noexcept;
        Q_INVOKABLE bool           export_swaps_json() noexcept;
        Q_INVOKABLE static QString get_regex_password_policy() noexcept;
        //Q_INVOKABLE QVariantMap    get_trade_infos(const QString& ticker, const QString& receive_ticker, const QString& amount);
        Q_INVOKABLE QVariantList   get_all_coins() const noexcept;

      signals:
        //! Signals to the QML Worlds
        void enabledCoinsChanged();
        void enableableCoinsChanged();
        void coinInfoChanged();
        void onStatusChanged();
        void onWalletDefaultNameChanged();
        void myOrdersUpdated();
        void addressbookChanged();
        void portfolioPageChanged();
        void walletPageChanged();
        void updateStatusChanged();
        void ordersChanged();
        void tradingPageChanged();
        void settingsPageChanged();
        void internetCheckerChanged();
        void ipCheckerChanged();
      public slots:
        void exit_handler();
        void app_state_changed();
    };
} // namespace atomic_dex
