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

//! Qt
#include <QSettings>

//! Project Headers
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/pages/qt.wallet.page.hpp"
#include "atomicdex/services/price/coingecko/coingecko.wallet.charts.hpp"
#include "atomicdex/services/price/global.provider.hpp"

namespace atomic_dex
{
    portfolio_page::portfolio_page(entt::registry& registry, ag::ecs::system_manager& system_manager, QObject* parent) :
        QObject(parent), system(registry), m_system_manager(system_manager), m_portfolio_mdl(new portfolio_model(system_manager, dispatcher_, this)),
        m_global_cfg_mdl(new global_coins_cfg_model(entity_registry_, this))
    {
        emit portfolioChanged();
        this->dispatcher_.sink<update_portfolio_values>().connect<&portfolio_page::on_update_portfolio_values_event>(*this);
        this->dispatcher_.sink<coin_cfg_parsed>().connect<&portfolio_page::on_coin_cfg_parsed>(*this);
        SPDLOG_INFO("portfolio_page created");
    }

    portfolio_model*
    portfolio_page::get_portfolio() const
    {
        return m_portfolio_mdl;
    }

    void
    portfolio_page::update()
    {
    }

    portfolio_page::~portfolio_page() {}

    void
    portfolio_page::set_current_balance_fiat_all(QString current_fiat_all_balance)
    {
        if (this->m_current_balance_all != current_fiat_all_balance)
        {
            // SPDLOG_INFO("current_balance_all changed previous: {}, new: {}", m_current_balance_all.toStdString(), current_fiat_all_balance.toStdString());
            this->m_current_balance_all = std::move(current_fiat_all_balance);
            emit       onFiatBalanceAllChanged();
            const auto currency = m_system_manager.get_system<settings_page>().get_current_currency().toStdString();
            if (currency != g_primary_dex_coin && currency != g_second_primary_dex_coin && currency != "BTC")
            {
                m_main_current_balance_all = m_current_balance_all;
                emit onMainFiatBalanceAllChanged();
                m_system_manager.get_system<coingecko_wallet_charts_service>().manual_refresh("set_current_balance_fiat_all");
            }
        }
    }

    QString
    portfolio_page::get_balance_fiat_all() const
    {
        return m_current_balance_all;
    }

    void
    portfolio_page::on_update_portfolio_values_event(const update_portfolio_values& evt)
    {
        SPDLOG_INFO("Updating portfolio values with model: {}", evt.with_update_model);

        bool res = true;
        if (evt.with_update_model)
        {
            res = m_portfolio_mdl->update_currency_values();
            m_system_manager.get_system<wallet_page>().refresh_ticker_infos();
        }

        std::error_code ec;
        const auto&     config           = m_system_manager.get_system<settings_page>().get_cfg();
        const auto&     price_service    = m_system_manager.get_system<global_price_service>();
        auto            fiat_balance_std = price_service.get_price_in_fiat_all(config.current_currency, ec);
        if (!ec && res)
        {
            set_current_balance_fiat_all(QString::fromStdString(fiat_balance_std));
            m_portfolio_mdl->adjust_percent_current_currency(QString::fromStdString(fiat_balance_std));
        }
    }

    QStringList
    atomic_dex::portfolio_page::get_all_enabled_coins() const
    {
        return get_all_coins_by_type("All");
    }

    QStringList
    atomic_dex::portfolio_page::get_all_coins_by_type(const QString& coin_type) const
    {
        QStringList enabled_coins;
        const auto& portfolio_list = this->get_portfolio()->get_underlying_data();
        enabled_coins.reserve(portfolio_list.count());
        for (auto&& cur_coin: portfolio_list)
        {
            if (coin_type == "All")
            {
                enabled_coins.push_back(cur_coin.ticker);
            }
            else if (cur_coin.coin_type == coin_type)
            {
                enabled_coins.push_back(cur_coin.ticker);
            }
        }
        return enabled_coins;
    }

    bool
    atomic_dex::portfolio_page::is_coin_enabled(const QString& coin_name) const
    {
        return get_all_enabled_coins().contains(coin_name);
    }

    global_coins_cfg_model*
    portfolio_page::get_global_cfg() const
    {
        return m_global_cfg_mdl;
    }

    void
    portfolio_page::on_coin_cfg_parsed(const coin_cfg_parsed& evt)
    {
        this->m_global_cfg_mdl->initialize_model(evt.cfg);
    }

    void
    portfolio_page::initialize_portfolio(const std::vector<std::string>& tickers)
    {
        SPDLOG_INFO("initialize_portfolio with tickers: {}", fmt::join(tickers, ", "));
        m_portfolio_mdl->initialize_portfolio(tickers);
        m_global_cfg_mdl->update_status(tickers, true);
    }

    void
    portfolio_page::disable_coins(const QStringList& coins)
    {
        m_portfolio_mdl->disable_coins(coins);
        m_global_cfg_mdl->update_status(coins, false);
    }

    WalletChartsCategories
    portfolio_page::get_chart_category() const
    {
        return m_current_chart_category;
    }
    void
    portfolio_page::set_chart_category(WalletChartsCategories category)
    {
        SPDLOG_INFO("new chart category: {}", QMetaEnum::fromType<WalletChartsCategories>().valueToKey(category));
        if (m_current_chart_category != category)
        {
            m_current_chart_category = category;
            QSettings& settings      = entity_registry_.ctx<QSettings>();
            settings.setValue("WalletChartsCategory", qint32(m_current_chart_category));
            if (m_system_manager.get_system<mm2_service>().is_mm2_running() && m_system_manager.has_system<coingecko_wallet_charts_service>())
            {
                m_system_manager.get_system<coingecko_wallet_charts_service>().manual_refresh("set_chart_category");
            }
            emit chartCategoryChanged();
        }
    }

    bool
    portfolio_page::is_chart_busy() const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().is_busy();
    }

    QVariant
    portfolio_page::get_charts() const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().get_charts();
    }

    QString
    portfolio_page::get_min_total_chart() const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().get_min_total();
    }

    QString
    portfolio_page::get_max_total_chart() const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().get_max_total();
    }

    QVariant
    portfolio_page::get_wallet_stats() const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().get_wallet_stats();
    }

    QString
    portfolio_page::get_main_balance_fiat_all() const
    {
        return m_main_current_balance_all;
    }

    int
    portfolio_page::get_neareast_point(int timestamp) const
    {
        return m_system_manager.get_system<coingecko_wallet_charts_service>().get_neareast_point(timestamp);
    }
} // namespace atomic_dex
