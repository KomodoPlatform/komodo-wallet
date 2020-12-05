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

//! Deps
#include <boost/lockfree/queue.hpp>

//! QT
#include <QObject>

//! Project Headers
#include "atomicdex/constants/qt.actions.hpp"
#include "atomicdex/constants/qt.trading.enums.hpp"
#include "atomicdex/events/events.hpp"
#include "atomicdex/events/qt.events.hpp"
#include "atomicdex/models/qt.candlestick.charts.model.hpp"
#include "atomicdex/models/qt.portfolio.model.hpp"
#include "atomicdex/widgets/dex/qt.market.pairs.hpp"
#include "atomicdex/widgets/dex/qt.orderbook.hpp"

namespace atomic_dex
{
    class trading_page final : public QObject, public ag::ecs::pre_update_system<trading_page>
    {
      private:
        //! Q_Object definition
        Q_OBJECT

        //! Q Properties definitions
        Q_PROPERTY(qt_orderbook_wrapper* orderbook READ get_orderbook_wrapper NOTIFY orderbookChanged)
        Q_PROPERTY(market_pairs* market_pairs_mdl READ get_market_pairs_mdl NOTIFY marketPairsChanged)
        Q_PROPERTY(QVariant buy_sell_last_rpc_data READ get_buy_sell_last_rpc_data WRITE set_buy_sell_last_rpc_data NOTIFY buySellLastRpcDataChanged)
        Q_PROPERTY(bool buy_sell_rpc_busy READ is_buy_sell_rpc_busy WRITE set_buy_sell_rpc_busy NOTIFY buySellRpcStatusChanged)
        Q_PROPERTY(bool fetching_multi_ticker_fees_busy READ is_fetching_multi_ticker_fees_busy WRITE set_fetching_multi_ticker_fees_busy NOTIFY
                       multiTickerFeesStatusChanged)

        //! Trading logic
        Q_PROPERTY(MarketMode market_mode READ get_market_mode WRITE set_market_mode NOTIFY marketModeChanged)
        Q_PROPERTY(TradingError last_trading_error READ get_trading_error WRITE set_trading_error NOTIFY tradingErrorChanged)
        Q_PROPERTY(QString price READ get_price WRITE set_price NOTIFY priceChanged)
        Q_PROPERTY(QString volume READ get_volume WRITE set_volume NOTIFY volumeChanged)
        Q_PROPERTY(QString max_volume READ get_max_volume WRITE set_max_volume NOTIFY maxVolumeChanged)
        Q_PROPERTY(QString total_amount READ get_total_amount WRITE set_total_amount NOTIFY totalAmountChanged)
        Q_PROPERTY(QString base_amount READ get_base_amount NOTIFY baseAmountChanged)
        Q_PROPERTY(QString rel_amount READ get_rel_amount NOTIFY relAmountChanged)
        Q_PROPERTY(QVariantMap fees READ get_fees WRITE set_fees NOTIFY feesChanged)
        Q_PROPERTY(QVariantMap preffered_order READ get_preffered_order WRITE set_preffered_order NOTIFY prefferedOrderChanged)
        Q_PROPERTY(QString price_reversed READ get_price_reversed NOTIFY priceReversedChanged)
        Q_PROPERTY(QString cex_price READ get_cex_price NOTIFY cexPriceChanged)
        Q_PROPERTY(QString cex_price_reversed READ get_cex_price_reversed NOTIFY cexPriceReversedChanged)
        Q_PROPERTY(QString cex_price_diff READ get_cex_price_diff NOTIFY cexPriceDiffChanged)
        Q_PROPERTY(bool invalid_cex_price READ get_invalid_cex_price NOTIFY invalidCexPriceChanged)
        Q_PROPERTY(bool multi_order_enabled READ get_multi_order_enabled WRITE set_multi_order_enabled NOTIFY multiOrderEnabledChanged)


        //! Private enum
        enum models
        {
            orderbook       = 0,
            market_selector = 1,
            models_size     = 2
        };

        enum models_actions
        {
            orderbook_need_a_reset = 0,
            models_actions_size    = 1
        };

        enum class trading_actions
        {
            post_process_orderbook_finished = 0,
        };

        //! Private typedefs
        using t_models               = std::array<QObject*, models_size>;
        using t_models_actions       = std::array<std::atomic_bool, models_actions_size>;
        using t_actions_queue        = boost::lockfree::queue<trading_actions>;
        using t_qt_synchronized_json = boost::synchronized_value<QJsonObject>;

        //! Private members fields
        ag::ecs::system_manager& m_system_manager;
        std::atomic_bool&        m_about_to_exit_the_app;
        t_models                 m_models;
        t_models_actions         m_models_actions;
        t_actions_queue          m_actions_queue{g_max_actions_size};
        std::atomic_bool         m_rpc_buy_sell_busy{false};
        std::atomic_bool         m_fetching_multi_ticker_fees_busy{false};
        t_qt_synchronized_json   m_rpc_buy_sell_result;

        //! Trading Logic
        MarketMode                    m_market_mode{MarketModeGadget::Sell};
        TradingError                  m_last_trading_error{TradingErrorGadget::None};
        QString                       m_price{""};
        QString                       m_volume{""};
        QString                       m_max_volume{"0"};
        QString                       m_total_amount{"0"};
        QString                       m_cex_price{"0"};
        std::optional<nlohmann::json> m_preffered_order;
        QVariantMap                   m_fees;
        bool                          m_multi_order_enabled{false};

        //! Private function
        void                       common_cancel_all_orders(bool by_coin = false, const QString& ticker = "");
        void                       clear_forms() noexcept;
        void                       determine_max_volume() noexcept;
        void                       determine_fees() noexcept;
        void                       determine_total_amount() noexcept;
        void                       determine_error_cases() noexcept;
        void                       determine_cex_rates() noexcept;
        void                       cap_volume() noexcept;
        [[nodiscard]] t_float_50   get_max_balance_without_dust(std::optional<QString> trade_with = std::nullopt) const noexcept;
        [[nodiscard]] TradingError generate_fees_error(QVariantMap fees, t_float_50 max_balance_without_dust) const noexcept;

      public:
        //! Constructor
        explicit trading_page(
            entt::registry& registry, ag::ecs::system_manager& system_manager, std::atomic_bool& exit_status, portfolio_model* portfolio,
            QObject* parent = nullptr);
        ~trading_page() noexcept final = default;

        //! Public override
        void update() noexcept final;

        //! Public API
        void process_action();
        void connect_signals();
        void disconnect_signals();
        void clear_models();
        void disable_coins(const QStringList& coins) noexcept;

        //! Public QML API
        Q_INVOKABLE void on_gui_enter_dex();
        Q_INVOKABLE void on_gui_leave_dex();
        Q_INVOKABLE void cancel_order(const QStringList& orders_id);
        Q_INVOKABLE void cancel_all_orders();
        Q_INVOKABLE void cancel_all_orders_by_ticker(const QString& ticker);


        Q_INVOKABLE QVariant get_raw_mm2_coin_cfg(const QString& ticker) const noexcept;

        //! Trading business
        Q_INVOKABLE void swap_market_pair(); ///< market_selector (button to switch market selector and orderbook)
        Q_INVOKABLE bool set_pair(bool is_left_side, QString changed_ticker) noexcept;
        Q_INVOKABLE void set_current_orderbook(const QString& base, const QString& rel); ///< market_selector (called and selecting another coin)

        Q_INVOKABLE void place_buy_order(const QString& base_nota = "", const QString& base_confs = "");
        Q_INVOKABLE void place_sell_order(const QString& rel_nota = "", const QString& rel_confs = "");

        Q_INVOKABLE void fetch_additional_fees(const QString& ticker) noexcept; ///< multi ticker (when enabling a coin of the list)
        Q_INVOKABLE void place_multiple_sell_order() noexcept;                  ///< multi ticker (when confirming a multi order)

        //! Properties
        [[nodiscard]] qt_orderbook_wrapper* get_orderbook_wrapper() const noexcept;
        [[nodiscard]] market_pairs*         get_market_pairs_mdl() const noexcept;
        [[nodiscard]] bool                  is_buy_sell_rpc_busy() const noexcept;
        void                                set_buy_sell_rpc_busy(bool status) noexcept;

        //! Trading Logic
        [[nodiscard]] MarketMode   get_market_mode() const noexcept;
        void                       set_market_mode(MarketMode market_mode) noexcept;
        [[nodiscard]] TradingError get_trading_error() const noexcept;
        void                       set_trading_error(TradingError trading_error) noexcept;
        [[nodiscard]] QString      get_price_reversed() const noexcept;
        [[nodiscard]] QString      get_price() const noexcept;
        void                       set_price(QString price) noexcept;
        [[nodiscard]] QString      get_volume() const noexcept;
        void                       set_volume(QString volume) noexcept;
        [[nodiscard]] QString      get_max_volume() const noexcept;
        void                       set_max_volume(QString max_volume) noexcept;
        [[nodiscard]] QString      get_total_amount() const noexcept;
        void                       set_total_amount(QString total_amount) noexcept;
        [[nodiscard]] QString      get_base_amount() const noexcept;
        [[nodiscard]] QString      get_rel_amount() const noexcept;
        [[nodiscard]] QString      get_cex_price() const noexcept;
        [[nodiscard]] QString      get_cex_price_reversed() const noexcept;
        [[nodiscard]] QString      get_cex_price_diff() const noexcept;
        [[nodiscard]] bool         get_invalid_cex_price() const noexcept;
        [[nodiscard]] QVariantMap  get_preffered_order() noexcept;
        void                       set_preffered_order(QVariantMap price_object) noexcept;
        [[nodiscard]] QVariantMap  get_fees() const noexcept;
        void                       set_fees(QVariantMap fees) noexcept;
        [[nodiscard]] bool         get_multi_order_enabled() const noexcept;
        void                       set_multi_order_enabled(bool multi_order_enabled) noexcept;

        //! For multi ticker part
        [[nodiscard]] bool is_fetching_multi_ticker_fees_busy() const noexcept;
        void               set_fetching_multi_ticker_fees_busy(bool status) noexcept;
        void               determine_multi_ticker_fees(const QString& ticker);
        void               determine_multi_ticker_total_amount(const QString& ticker, const QString& input_price, bool is_enabled);
        void               determine_multi_ticker_error_cases(const QString& ticker, QVariantMap fees);
        void               determine_all_multi_ticker_forms() noexcept;

        [[nodiscard]] QVariant get_buy_sell_last_rpc_data() const noexcept;
        void                   set_buy_sell_last_rpc_data(QVariant rpc_data) noexcept;

        //! Events Callbacks
        void on_process_orderbook_finished_event(const process_orderbook_finished& evt) noexcept;
        void on_multi_ticker_enabled(const multi_ticker_enabled& evt) noexcept;

      signals:
        void orderbookChanged();
        void candlestickChartsChanged();
        void marketPairsChanged();
        void buySellLastRpcDataChanged();
        void buySellRpcStatusChanged();
        void multiTickerFeesStatusChanged();

        //! Trading logic
        void priceChanged();
        void volumeChanged();
        void marketModeChanged();
        void maxVolumeChanged();
        void tradingErrorChanged();
        void prefferedOrderChanged();
        void totalAmountChanged();
        void baseAmountChanged();
        void relAmountChanged();
        void feesChanged();
        void cexPriceChanged();
        void cexPriceReversedChanged();
        void cexPriceDiffChanged();
        void invalidCexPriceChanged();
        void priceReversedChanged();
        void multiOrderEnabledChanged();
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::trading_page))
