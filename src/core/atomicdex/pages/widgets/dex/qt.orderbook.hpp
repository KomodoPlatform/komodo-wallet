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

#pragma once

//! QT
#include <QJsonObject>
#include <QObject>

//! Deps
#include <antara/gaming/ecs/system.manager.hpp>
#include <boost/thread/synchronized_value.hpp>

//! Project
#include "atomicdex/models/qt.orderbook.model.hpp"

namespace atomic_dex
{
    class qt_orderbook_wrapper final : public QObject
    {
        Q_OBJECT
        Q_PROPERTY(orderbook_model* asks READ get_asks MEMBER m_asks NOTIFY asksChanged)
        Q_PROPERTY(orderbook_model* bids READ get_bids MEMBER m_bids NOTIFY bidsChanged)
        Q_PROPERTY(orderbook_model* best_orders READ get_best_orders MEMBER m_best_orders NOTIFY bestOrdersChanged)
        Q_PROPERTY(bool best_orders_busy READ is_best_orders_busy NOTIFY bestOrdersBusyChanged)
        Q_PROPERTY(QVariant base_max_taker_vol READ get_base_max_taker_vol NOTIFY baseMaxTakerVolChanged)
        Q_PROPERTY(bool orderbook_busy READ is_orderbook_busy NOTIFY orderbookBusyChanged)
        Q_PROPERTY(QVariant rel_max_taker_vol READ get_rel_max_taker_vol NOTIFY relMaxTakerVolChanged)
        Q_PROPERTY(QString base_min_taker_vol READ get_base_min_taker_vol NOTIFY baseMinTakerVolChanged)
        Q_PROPERTY(QString rel_min_taker_vol READ get_rel_min_taker_vol NOTIFY relMinTakerVolChanged)
        Q_PROPERTY(QString current_min_taker_vol READ get_current_min_taker_vol NOTIFY currentMinTakerVolChanged)
      public:
        qt_orderbook_wrapper(ag::ecs::system_manager& system_manager, entt::dispatcher& dispatcher, QObject* parent = nullptr);
        ~qt_orderbook_wrapper() final = default;

      public:
        void                           adjust_min_vol();
        void                           refresh_orderbook(t_orderbook_answer answer);
        void                           reset_orderbook(t_orderbook_answer answer);
        void                           clear_orderbook();
        [[nodiscard]] orderbook_model* get_asks() const;
        [[nodiscard]] orderbook_model* get_bids() const;
        [[nodiscard]] orderbook_model* get_best_orders() const;
        [[nodiscard]] bool             is_best_orders_busy() const;
        [[nodiscard]] bool             is_orderbook_busy() const;
        [[nodiscard]] QVariant         get_base_max_taker_vol() const;
        [[nodiscard]] QVariant         get_rel_max_taker_vol() const;
        [[nodiscard]] QString          get_base_min_taker_vol() const;
        [[nodiscard]] QString          get_rel_min_taker_vol() const;
        [[nodiscard]] QString          get_current_min_taker_vol() const;

        Q_INVOKABLE void refresh_best_orders();
        Q_INVOKABLE void select_best_order(const QString& order_uuid);

      signals:
        void asksChanged();
        void bidsChanged();
        void bestOrdersChanged();
        void bestOrdersBusyChanged();
        void orderbookBusyChanged();
        void baseMaxTakerVolChanged();
        void relMaxTakerVolChanged();
        void baseMinTakerVolChanged();
        void relMinTakerVolChanged();
        void currentMinTakerVolChanged();

      private:
        void                                                  set_both_taker_vol();
        ag::ecs::system_manager&                              m_system_manager;
        entt::dispatcher&                                     m_dispatcher;
        orderbook_model*                                      m_asks;
        orderbook_model*                                      m_bids;
        orderbook_model*                                      m_best_orders;
        QJsonObject                                           m_base_max_taker_vol;
        QJsonObject                                           m_rel_max_taker_vol;
        QString                                               m_base_min_taker_vol;
        QString                                               m_rel_min_taker_vol;
        boost::synchronized_value<std::optional<QVariantMap>> m_selected_best_order{std::nullopt};
    };
} // namespace atomic_dex
