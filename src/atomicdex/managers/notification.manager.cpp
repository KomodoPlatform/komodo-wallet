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

//! Project Headers
#include "atomicdex/managers/notification.manager.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace atomic_dex
{
    notification_manager::notification_manager(entt::dispatcher& dispatcher, QObject* parent) noexcept : QObject(parent), m_dispatcher(dispatcher)
    {
    }

    void
    notification_manager::on_swap_status_notification(const atomic_dex::swap_status_notification& evt)
    {
        using namespace std::chrono;
        qint64  timestamp  = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        QString human_date = QString::fromStdString(utils::to_human_date<std::chrono::seconds>(timestamp, "%e %b %Y, %H:%M"));
        emit    updateSwapStatus(evt.prev_status, evt.new_status, evt.uuid, evt.base, evt.rel, human_date);
    }

    void
    notification_manager::connect_signals() noexcept
    {
        m_dispatcher.sink<swap_status_notification>().connect<&notification_manager::on_swap_status_notification>(*this);
        m_dispatcher.sink<balance_update_notification>().connect<&notification_manager::on_balance_update_notification>(*this);
        m_dispatcher.sink<enabling_coin_failed>().connect<&notification_manager::on_enabling_coin_failed>(*this);
        m_dispatcher.sink<endpoint_nonreacheable>().connect<&notification_manager::on_endpoint_nonreacheable>(*this);
        m_dispatcher.sink<mismatch_configuration_custom_coin>().connect<&notification_manager::on_mismatch_custom_coins_configuration>(*this);
    }

    void
    notification_manager::disconnect_signals() noexcept
    {
        m_dispatcher.sink<swap_status_notification>().disconnect<&notification_manager::on_swap_status_notification>(*this);
        m_dispatcher.sink<balance_update_notification>().disconnect<&notification_manager::on_balance_update_notification>(*this);
        m_dispatcher.sink<enabling_coin_failed>().disconnect<&notification_manager::on_enabling_coin_failed>(*this);
        m_dispatcher.sink<endpoint_nonreacheable>().disconnect<&notification_manager::on_endpoint_nonreacheable>(*this);
        m_dispatcher.sink<mismatch_configuration_custom_coin>().disconnect<&notification_manager::on_mismatch_custom_coins_configuration>(*this);
    }

    void
    notification_manager::on_balance_update_notification(const balance_update_notification& evt)
    {
        emit balanceUpdateStatus(evt.am_i_sender, evt.amount, evt.ticker, evt.human_date, evt.timestamp);
    }

    void
    notification_manager::on_enabling_coin_failed(const enabling_coin_failed& evt)
    {
        using namespace std::chrono;
        qint64  timestamp  = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        QString human_date = QString::fromStdString(utils::to_human_date<std::chrono::seconds>(timestamp, "%e %b %Y, %H:%M"));
        emit    enablingCoinFailedStatus(QString::fromStdString(evt.coin), QString::fromStdString(evt.reason), human_date, timestamp);
    }

    void
    notification_manager::on_endpoint_nonreacheable(const endpoint_nonreacheable& evt)
    {
        using namespace std::chrono;
        qint64  timestamp  = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        QString human_date = QString::fromStdString(utils::to_human_date<std::chrono::seconds>(timestamp, "%e %b %Y, %H:%M"));
        emit    endpointNonReacheableStatus(QString::fromStdString(evt.base_uri), human_date, timestamp);
    }
    void
    notification_manager::on_mismatch_custom_coins_configuration(const mismatch_configuration_custom_coin& evt)
    {
        using namespace std::chrono;
        qint64  timestamp  = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        QString human_date = QString::fromStdString(utils::to_human_date<std::chrono::seconds>(timestamp, "%e %b %Y, %H:%M"));
        emit    mismatchCustomCoinConfiguration(QString::fromStdString(evt.coin), human_date, timestamp);
    }
} // namespace atomic_dex
