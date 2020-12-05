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

//! QT Include
#include <QObject>

//! Deps
#include <entt/signal/dispatcher.hpp>

//! Project Headers
#include "atomicdex/events/events.hpp"
#include "atomicdex/events/qt.events.hpp"

namespace atomic_dex
{
    class notification_manager final : public QObject
    {
        Q_OBJECT
      public:
        notification_manager(entt::dispatcher& dispatcher, QObject* parent = nullptr) noexcept;
        ~notification_manager() noexcept final = default;

        //! Public API
        void connect_signals() noexcept;
        void disconnect_signals() noexcept;

        //! Callbacks
        void on_swap_status_notification(const swap_status_notification& evt);
        void on_enabling_coin_failed(const enabling_coin_failed& evt);
        void on_balance_update_notification(const balance_update_notification& evt);
        void on_endpoint_nonreacheable(const endpoint_nonreacheable& evt);
        void on_mismatch_custom_coins_configuration(const mismatch_configuration_custom_coin& evt);

      signals:
        void updateSwapStatus(QString old_swap_status, QString new_swap_status, QString swap_uuid, QString base_coin, QString rel_coin, QString human_date);
        void balanceUpdateStatus(bool am_i_sender, QString amount, QString ticker, QString human_date, qint64 timestamp);
        void enablingCoinFailedStatus(QString coin, QString error, QString human_date, qint64 timestamp);
        void endpointNonReacheableStatus(QString base_uri, QString human_date, qint64 timestamp);
        void mismatchCustomCoinConfiguration(QString asset, QString human_date, qint64 timestamp);

      private:
        entt::dispatcher& m_dispatcher;
    };
} // namespace atomic_dex
