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
#include "atomicdex/models/qt.portfolio.proxy.filter.model.hpp"
#include "atomicdex/models/qt.portfolio.model.hpp"

namespace atomic_dex
{
    //! Constructor
    portfolio_proxy_model::portfolio_proxy_model(QObject* parent) : QSortFilterProxyModel(parent)
    {
    }

    //! Public API
    void
    portfolio_proxy_model::sort_by_name(bool is_ascending)
    {
        this->setSortRole(atomic_dex::portfolio_model::NameRole);
        this->sort(0, is_ascending ? Qt::AscendingOrder : Qt::DescendingOrder);
    }

    void
    portfolio_proxy_model::sort_by_currency_balance(bool is_ascending)
    {
        this->setSortRole(atomic_dex::portfolio_model::MainCurrencyBalanceRole);
        this->sort(0, is_ascending ? Qt::AscendingOrder : Qt::DescendingOrder);
    }

    void
    portfolio_proxy_model::sort_by_change_last24h(bool is_ascending)
    {
        this->setSortRole(atomic_dex::portfolio_model::Change24H);
        this->sort(0, is_ascending ? Qt::AscendingOrder : Qt::DescendingOrder);
    }

    void
    portfolio_proxy_model::sort_by_currency_unit(bool is_ascending)
    {
        this->setSortRole(atomic_dex::portfolio_model::MainCurrencyPriceForOneUnit);
        this->sort(0, is_ascending ? Qt::AscendingOrder : Qt::DescendingOrder);
    }

    //! Override member functions
    bool
    portfolio_proxy_model::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
    {
        int      role       = this->sortRole();
        QVariant left_data  = sourceModel()->data(source_left, role);
        QVariant right_data = sourceModel()->data(source_right, role);
        switch (static_cast<atomic_dex::portfolio_model::PortfolioRoles>(role))
        {
        case atomic_dex::portfolio_model::TickerRole:
            return left_data.toString() > right_data.toString();
        case atomic_dex::portfolio_model::GuiTickerRole:
            return left_data.toString() > right_data.toString();
        case atomic_dex::portfolio_model::NameRole:
            return left_data.toString().toLower() < right_data.toString().toLower();
        case atomic_dex::portfolio_model::BalanceRole:
            return t_float_50(left_data.toString().toStdString()) < t_float_50(right_data.toString().toStdString());
        case atomic_dex::portfolio_model::MainCurrencyBalanceRole:
            if (left_data.toFloat() == right_data.toFloat())
            {
                left_data  = sourceModel()->data(source_left, atomic_dex::portfolio_model::BalanceRole);
                right_data = sourceModel()->data(source_right, atomic_dex::portfolio_model::BalanceRole);
            }
            return left_data.toFloat() < right_data.toFloat();
        case atomic_dex::portfolio_model::Change24H:
            return left_data.toFloat() < right_data.toFloat();
        case atomic_dex::portfolio_model::MainCurrencyPriceForOneUnit:
            return t_float_50(left_data.toString().toStdString()) < t_float_50(right_data.toString().toStdString());
        case portfolio_model::MainFiatPriceForOneUnit:
        case portfolio_model::Trend7D:
        case portfolio_model::Excluded:
        case portfolio_model::Display:
        case portfolio_model::NameAndTicker:
        case portfolio_model::MultiTickerCurrentlyEnabled:
        case portfolio_model::MultiTickerData:
        case portfolio_model::MultiTickerError:
        case portfolio_model::MultiTickerPrice:
        case portfolio_model::MultiTickerReceiveAmount:
        case portfolio_model::MultiTickerFeesInfo:
        case portfolio_model::CoinType:
            return false;
        }
    }

    bool
    portfolio_proxy_model::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
    {
        QModelIndex idx = this->sourceModel()->index(source_row, 0, source_parent);
        assert(this->sourceModel()->hasIndex(idx.row(), 0));
        QString ticker = this->sourceModel()->data(idx, atomic_dex::portfolio_model::TickerRole).toString();
        QString type   = this->sourceModel()->data(idx, atomic_dex::portfolio_model::CoinType).toString();

        if (this->filterRole() == atomic_dex::portfolio_model::MultiTickerCurrentlyEnabled)
        {
            bool is_enabled = this->sourceModel()->data(idx, atomic_dex::portfolio_model::MultiTickerCurrentlyEnabled).toBool();
            if (not is_enabled)
            {
                return false;
            }
        }

        if (m_excluded_coin == ticker)
        {
            return false;
        }
        return QSortFilterProxyModel::filterAcceptsRow(source_row, source_parent);
    }

    void
    portfolio_proxy_model::reset()
    {
        this->beginResetModel();
        this->endResetModel();
    }

    void
    portfolio_proxy_model::set_excluded_coin(const QString& ticker)
    {
        m_excluded_coin = ticker;
        this->invalidateFilter();
    }

    void
    portfolio_proxy_model::is_a_market_selector(bool is_market_selector) noexcept
    {
        this->am_i_a_market_selector = is_market_selector;
    }
} // namespace atomic_dex
