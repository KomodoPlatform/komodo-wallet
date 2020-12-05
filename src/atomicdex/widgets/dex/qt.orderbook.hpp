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

//! QT
#include <QJsonObject>
#include <QObject>

//! Deps
#include <antara/gaming/ecs/system.manager.hpp>

//! Project
#include "atomicdex/models/qt.orderbook.model.hpp"

namespace atomic_dex
{
    class qt_orderbook_wrapper final : public QObject
    {
        Q_OBJECT
        Q_PROPERTY(orderbook_model* asks READ get_asks MEMBER m_asks NOTIFY asksChanged)
        Q_PROPERTY(orderbook_model* bids READ get_bids MEMBER m_bids NOTIFY bidsChanged)
        Q_PROPERTY(QVariant base_max_taker_vol READ get_base_max_taker_vol NOTIFY baseMaxTakerVolChanged)
        Q_PROPERTY(QVariant rel_max_taker_vol READ get_rel_max_taker_vol NOTIFY relMaxTakerVolChanged)
      public:
        qt_orderbook_wrapper(ag::ecs::system_manager& system_manager, QObject* parent = nullptr);
        ~qt_orderbook_wrapper() noexcept final = default;

      public:
        void                           refresh_orderbook(t_orderbook_answer answer);
        void                           reset_orderbook(t_orderbook_answer answer);
        void                           clear_orderbook();
        [[nodiscard]] orderbook_model* get_asks() const noexcept;
        [[nodiscard]] orderbook_model* get_bids() const noexcept;
        [[nodiscard]] QVariant         get_base_max_taker_vol() const noexcept;
        [[nodiscard]] QVariant         get_rel_max_taker_vol() const noexcept;


      signals:
        void asksChanged();
        void bidsChanged();
        void baseMaxTakerVolChanged();
        void relMaxTakerVolChanged();

      private:
        void                     set_both_taker_vol();
        ag::ecs::system_manager& m_system_manager;
        orderbook_model*         m_asks;
        orderbook_model*         m_bids;
        QJsonObject              m_base_max_taker_vol;
        QJsonObject              m_rel_max_taker_vol;
    };
} // namespace atomic_dex
