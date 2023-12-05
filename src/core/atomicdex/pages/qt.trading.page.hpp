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

#pragma once

#include <string>
#include <boost/lockfree/queue.hpp>

#include <QObject>

#include "atomicdex/constants/qt.actions.hpp"
#include "atomicdex/constants/qt.trading.enums.hpp"
#include "atomicdex/events/events.hpp"
#include "atomicdex/events/qt.events.hpp"
#include "atomicdex/models/qt.portfolio.model.hpp"
#include "widgets/dex/qt.market.pairs.hpp"
#include "widgets/dex/qt.orderbook.hpp"
#include "widgets/dex/qt.orders.widget.hpp"

namespace atomic_dex
{
    class trading_page final : public QObject, public ag::ecs::pre_update_system<trading_page>
    {
        Q_OBJECT

        // Q Properties definitions
        Q_PROPERTY(qt_orderbook_wrapper* orderbook READ get_orderbook_wrapper NOTIFY orderbookChanged)
        Q_PROPERTY(market_pairs* market_pairs_mdl READ get_market_pairs_mdl NOTIFY marketPairsChanged)
        Q_PROPERTY(qt_orders_widget* orders READ get_orders_widget NOTIFY ordersWidgetChanged)
        Q_PROPERTY(QVariant buy_sell_last_rpc_data READ get_buy_sell_last_rpc_data WRITE set_buy_sell_last_rpc_data NOTIFY buySellLastRpcDataChanged)
        Q_PROPERTY(bool buy_sell_rpc_busy READ is_buy_sell_rpc_busy WRITE set_buy_sell_rpc_busy NOTIFY buySellRpcStatusChanged)
        Q_PROPERTY(bool preimage_rpc_busy READ is_preimage_busy WRITE set_preimage_busy NOTIFY preImageRpcStatusChanged)

        // Trading logic Q properties
        Q_PROPERTY(MarketMode market_mode READ get_market_mode WRITE set_market_mode NOTIFY marketModeChanged)
        Q_PROPERTY(TradingError last_trading_error READ get_trading_error WRITE set_trading_error NOTIFY tradingErrorChanged)
        Q_PROPERTY(TradingMode current_trading_mode READ get_current_trading_mode WRITE set_current_trading_mode NOTIFY tradingModeChanged)
        Q_PROPERTY(QString price READ get_price WRITE set_price NOTIFY priceChanged)
        Q_PROPERTY(QString volume READ get_volume WRITE set_volume NOTIFY volumeChanged)
        Q_PROPERTY(QString max_volume READ get_max_volume WRITE set_max_volume NOTIFY maxVolumeChanged)
        Q_PROPERTY(QString total_amount READ get_total_amount WRITE set_total_amount NOTIFY totalAmountChanged)
        Q_PROPERTY(QString base_amount READ get_base_amount NOTIFY baseAmountChanged)
        Q_PROPERTY(QString rel_amount READ get_rel_amount NOTIFY relAmountChanged)
        Q_PROPERTY(QVariantMap fees READ get_fees WRITE set_fees NOTIFY feesChanged)
        Q_PROPERTY(QVariantMap preffered_order READ get_preferred_order WRITE set_preferred_order NOTIFY prefferedOrderChanged)
        Q_PROPERTY(SelectedOrderStatus selected_order_status READ get_selected_order_status WRITE set_selected_order_status NOTIFY selectedOrderStatusChanged)
        Q_PROPERTY(QString price_reversed READ get_price_reversed NOTIFY priceReversedChanged)
        Q_PROPERTY(QString pair_volume_24hr READ get_pair_volume_24hr NOTIFY pairVolume24hrChanged)
        Q_PROPERTY(QString cex_price READ get_cex_price NOTIFY cexPriceChanged)
        Q_PROPERTY(QString cex_price_reversed READ get_cex_price_reversed NOTIFY cexPriceReversedChanged)
        Q_PROPERTY(QString cex_price_diff READ get_cex_price_diff NOTIFY cexPriceDiffChanged)
        Q_PROPERTY(QString min_trade_vol READ get_min_trade_vol WRITE set_min_trade_vol NOTIFY minTradeVolChanged)
        Q_PROPERTY(bool invalid_cex_price READ get_invalid_cex_price NOTIFY invalidCexPriceChanged)
        Q_PROPERTY(bool skip_taker READ get_skip_taker WRITE set_skip_taker NOTIFY skipTakerChanged)


        //! Private enum
        enum models
        {
            orderbook       = 0,
            market_selector = 1,
            orders          = 2,
            models_size     = 3
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
        t_models_actions         m_models_actions{};
        t_actions_queue          m_actions_queue{g_max_actions_size};
        std::atomic_bool         m_rpc_buy_sell_busy{false};
        std::atomic_bool         m_rpc_preimage_busy{false};
        std::atomic_bool         m_post_clear_forms{false};
        t_qt_synchronized_json   m_rpc_buy_sell_result;

        //! Trading Logic
        MarketMode                             m_market_mode{MarketModeGadget::Sell};
        TradingError                           m_last_trading_error{TradingErrorGadget::None};
        TradingMode                            m_current_trading_mode{TradingModeGadget::Pro};
        SelectedOrderStatus                    m_selected_order_status{SelectedOrderGadget::None};
        QString                                m_price{"0"};
        QString                                m_volume{"0"};
        QString                                m_max_volume{"0"};
        QString                                m_total_amount{"0.00777"};
        QString                                m_cex_price{"0"};
        QString                                m_pair_volume_24hr{"0"};
        QString                                m_minimal_trading_amount{"0.0001"};
        std::optional<nlohmann::json>          m_preferred_order;
        boost::synchronized_value<QVariantMap> m_fees;
        bool                                   m_skip_taker{false};

        //! Private function
        void                       determine_max_volume();
        void                       determine_total_amount();
        void                       determine_cex_rates();
        void                       determine_pair_volume_24hr();
        void                       cap_volume();
        [[nodiscard]] t_float_50   get_max_balance_without_dust(const std::optional<QString>& trade_with = std::nullopt) const;
        [[nodiscard]] TradingError generate_fees_error(QVariantMap fees) const;
        void                       set_preferred_settings();
        static QString             calculate_total_amount(QString price, QString volume) ;

      public:
        //! Constructor
        explicit trading_page(
            entt::registry& registry, ag::ecs::system_manager& system_manager, std::atomic_bool& exit_status, portfolio_model* portfolio,
            QObject* parent = nullptr);
        ~trading_page() final = default;

        //! Public override
        void update() final;

        //! Public API
        void process_action();
        void connect_signals();
        void disconnect_signals();
        void clear_models() const;
        void disable_coins(const QStringList& coins);

        //! Public QML API
        Q_INVOKABLE void     on_gui_enter_dex();
        Q_INVOKABLE void     on_gui_leave_dex();
        Q_INVOKABLE QVariant get_raw_mm2_coin_cfg(const QString& ticker) const;
        Q_INVOKABLE void     clear_forms(QString from);

        //! Trading business
        Q_INVOKABLE void swap_market_pair(); ///< market_selector (button to switch market selector and orderbook)
        Q_INVOKABLE bool set_pair(bool is_left_side, const QString& changed_ticker);
        Q_INVOKABLE void set_current_orderbook(const QString& base, const QString& rel); ///< market_selector (called and selecting another coin)

        Q_INVOKABLE void place_buy_order(const QString& base_nota = "", const QString& base_confs = "");
        Q_INVOKABLE void place_sell_order(const QString& rel_nota = "", const QString& rel_confs = "");

        Q_INVOKABLE void reset_order();

        Q_INVOKABLE void determine_fees();
        Q_INVOKABLE void determine_error_cases();
        Q_INVOKABLE void reset_fees();

        //! Properties
        [[nodiscard]] qt_orderbook_wrapper* get_orderbook_wrapper() const;
        [[nodiscard]] qt_orders_widget*     get_orders_widget() const;
        [[nodiscard]] market_pairs*         get_market_pairs_mdl() const;
        [[nodiscard]] bool                  is_buy_sell_rpc_busy() const;
        void                                set_buy_sell_rpc_busy(bool status);

        //! Trading Logic
        [[nodiscard]] MarketMode          get_market_mode() const;
        void                              set_market_mode(MarketMode market_mode);
        [[nodiscard]] TradingError        get_trading_error() const;
        void                              set_trading_error(TradingError trading_error);
        [[nodiscard]] TradingMode         get_current_trading_mode() const;
        void                              set_current_trading_mode(TradingMode trading_mode);
        [[nodiscard]] SelectedOrderStatus get_selected_order_status() const;
        void                              set_selected_order_status(SelectedOrderStatus order_status);
        [[nodiscard]] QString             get_price_reversed() const;
        [[nodiscard]] QString             get_price() const;
        void                              set_price(QString price);
        [[nodiscard]] QString         get_min_trade_vol() const;
        void                          set_min_trade_vol(QString min_trade_vol);
        [[nodiscard]] QString         get_volume() const;
        void                          set_volume(QString volume);
        [[nodiscard]] QString         get_max_volume() const;
        void                          set_max_volume(QString max_volume);
        [[nodiscard]] QString         get_total_amount() const;
        void                          set_total_amount(QString total_amount);
        [[nodiscard]] QString         get_base_amount() const;
        [[nodiscard]] QString         get_rel_amount() const;
        [[nodiscard]] QString         get_pair_volume_24hr() const;
        [[nodiscard]] QString         get_cex_price() const;
        [[nodiscard]] QString         get_cex_price_reversed() const;
        [[nodiscard]] QString         get_cex_price_diff() const;
        [[nodiscard]] bool            get_invalid_cex_price() const;
        [[nodiscard]] QVariantMap     get_preferred_order() const;
        void                          set_preferred_order(const QVariantMap& price_object);
        std::optional<nlohmann::json> get_raw_preferred_order() const;
        [[nodiscard]] QVariantMap     get_fees() const;
        void                          set_fees(const QVariantMap& fees);
        [[nodiscard]] bool            get_skip_taker() const;
        void                          set_skip_taker(bool skip_taker);
        [[nodiscard]] bool            is_preimage_busy() const;
        void                          set_preimage_busy(bool status);
        [[nodiscard]] QVariant        get_buy_sell_last_rpc_data() const;
        void                          set_buy_sell_last_rpc_data(const QVariant& rpc_data);

        //! Events Callbacks
        void on_process_orderbook_finished_event(const process_orderbook_finished& evt);

      signals:
        void orderbookChanged();
        void ordersWidgetChanged();
        void candlestickChartsChanged();
        void marketPairsChanged();
        void buySellLastRpcDataChanged();
        void buySellRpcStatusChanged();
        void preImageRpcStatusChanged();

        //! Trading logic
        void priceChanged();
        void volumeChanged();
        void marketModeChanged();
        void maxVolumeChanged();
        void tradingErrorChanged();
        void tradingModeChanged();
        void prefferedOrderChanged();
        void totalAmountChanged();
        void baseAmountChanged();
        void relAmountChanged();
        void feesChanged();
        void pairVolume24hrChanged();
        void cexPriceChanged();
        void cexPriceReversedChanged();
        void cexPriceDiffChanged();
        void invalidCexPriceChanged();
        void priceReversedChanged();
        void skipTakerChanged();
        void mm2MinTradeVolChanged();
        void minTradeVolChanged();
        void selectedOrderStatusChanged();
        void preferredOrderChangeFinished();
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::trading_page))
