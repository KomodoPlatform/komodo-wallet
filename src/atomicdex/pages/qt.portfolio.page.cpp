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
#include "src/atomicdex/pch.hpp"

//! Project Headers
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/services/price/oracle/band.provider.hpp"
#include "qt.portfolio.page.hpp"
#include "qt.settings.page.hpp"
#include "qt.wallet.page.hpp"

namespace atomic_dex
{
    portfolio_page::portfolio_page(entt::registry& registry, ag::ecs::system_manager& system_manager, QObject* parent) :
        QObject(parent), system(registry), m_system_manager(system_manager), m_portfolio_mdl(new portfolio_model(system_manager, dispatcher_, this))
    {
        emit portfolioChanged();
        this->dispatcher_.sink<update_portfolio_values>().connect<&portfolio_page::on_update_portfolio_values_event>(*this);
        this->dispatcher_.sink<band_oracle_refreshed>().connect<&portfolio_page::on_band_oracle_refreshed>(*this);
    }

    portfolio_model*
    portfolio_page::get_portfolio() const noexcept
    {
        return m_portfolio_mdl;
    }

    void
    portfolio_page::update() noexcept
    {
    }

    portfolio_page::~portfolio_page() noexcept {}

    QStringList
    portfolio_page::get_oracle_price_supported_pairs() const noexcept
    {
        auto        result = m_system_manager.get_system<band_oracle_price_service>().supported_pair();
        QStringList out;
        out.reserve(result.size());
        for (auto&& cur: result) { out.push_back(QString::fromStdString(cur)); }
        return out;
    }

    QString
    portfolio_page::get_oracle_last_price_reference() const noexcept
    {
        return QString::fromStdString(m_system_manager.get_system<band_oracle_price_service>().last_oracle_reference());
    }

    void
    portfolio_page::on_band_oracle_refreshed(const band_oracle_refreshed&)
    {
        emit oraclePriceUpdated();
    }

    void
    portfolio_page::set_current_balance_fiat_all(QString current_fiat_all_balance) noexcept
    {
        if (this->m_current_balance_all != current_fiat_all_balance)
        {
            this->m_current_balance_all = std::move(current_fiat_all_balance);
            emit onFiatBalanceAllChanged();
        }
    }

    QString
    portfolio_page::get_balance_fiat_all() const noexcept
    {
        return m_current_balance_all;
    }

    void
    portfolio_page::on_update_portfolio_values_event(const update_portfolio_values& evt) noexcept
    {
        if (evt.with_update_model)
        {
            m_portfolio_mdl->update_currency_values();
            m_system_manager.get_system<wallet_page>().refresh_ticker_infos();
        }
        std::error_code ec;
        const auto&     config           = m_system_manager.get_system<settings_page>().get_cfg();
        const auto&     price_service    = m_system_manager.get_system<global_price_service>();
        auto            fiat_balance_std = price_service.get_price_in_fiat_all(config.current_currency, ec);
        if (!ec)
        {
            set_current_balance_fiat_all(QString::fromStdString(fiat_balance_std));
        }
    }
} // namespace atomic_dex
