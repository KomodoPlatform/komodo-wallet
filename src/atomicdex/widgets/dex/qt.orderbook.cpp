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

//! Project headers
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"
#include "atomicdex/widgets/dex/qt.orderbook.hpp"

namespace atomic_dex
{
    qt_orderbook_wrapper::qt_orderbook_wrapper(ag::ecs::system_manager& system_manager, QObject* parent) :
        QObject(parent), m_system_manager(system_manager), m_asks(new orderbook_model(orderbook_model::kind::asks, this)),
        m_bids(new orderbook_model(orderbook_model::kind::bids, this))
    {
    }

    atomic_dex::orderbook_model*
    atomic_dex::qt_orderbook_wrapper::get_asks() const noexcept
    {
        return m_asks;
    }

    orderbook_model*
    qt_orderbook_wrapper::get_bids() const noexcept
    {
        return m_bids;
    }

    void
    qt_orderbook_wrapper::refresh_orderbook(t_orderbook_answer answer)
    {
        SPDLOG_DEBUG("refresh orderbook");
        this->m_asks->refresh_orderbook(answer);
        this->m_bids->refresh_orderbook(answer);
        this->set_both_taker_vol();
    }

    void
    qt_orderbook_wrapper::reset_orderbook(t_orderbook_answer answer)
    {
        SPDLOG_DEBUG("full reset orderbook");
        this->m_asks->reset_orderbook(answer);
        this->m_bids->reset_orderbook(answer);
        this->set_both_taker_vol();
    }

    void
    qt_orderbook_wrapper::clear_orderbook()
    {
        this->m_asks->clear_orderbook();
        this->m_bids->clear_orderbook();
    }

    QVariant
    qt_orderbook_wrapper::get_base_max_taker_vol() const noexcept
    {
        return m_base_max_taker_vol;
    }

    QVariant
    qt_orderbook_wrapper::get_rel_max_taker_vol() const noexcept
    {
        return m_rel_max_taker_vol;
    }

    void
    atomic_dex::qt_orderbook_wrapper::set_both_taker_vol()
    {
        auto&& [base, rel]         = m_system_manager.get_system<mm2_service>().get_taker_vol();
        this->m_base_max_taker_vol = QJsonObject{
            {"denom", QString::fromStdString(base.denom)}, {"numer", QString::fromStdString(base.numer)}, {"decimal", QString::fromStdString(base.decimal)}};
        emit baseMaxTakerVolChanged();
        this->m_rel_max_taker_vol = QJsonObject{
            {"denom", QString::fromStdString(rel.denom)}, {"numer", QString::fromStdString(rel.numer)}, {"decimal", QString::fromStdString(rel.decimal)}};
        emit relMaxTakerVolChanged();
    }
} // namespace atomic_dex
