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

//! Project
#include "atomicdex/models/qt.orderbook.proxy.model.hpp"
#include "atomicdex/models/qt.orderbook.model.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace atomic_dex
{
    orderbook_proxy_model::orderbook_proxy_model(QObject* parent) : QSortFilterProxyModel(parent)
    {
    }

    bool
    orderbook_proxy_model::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
    {
        int      role       = this->sortRole();
        QVariant left_data  = sourceModel()->data(source_left, role);
        QVariant right_data = sourceModel()->data(source_right, role);
        switch (static_cast<atomic_dex::orderbook_model::OrderbookRoles>(role))
        {
        case orderbook_model::PriceRole:
            return t_float_50(left_data.toString().toStdString()) < t_float_50(right_data.toString().toStdString());
        case orderbook_model::QuantityRole:
            break;
        case orderbook_model::TotalRole:
            break;
        case orderbook_model::UUIDRole:
            break;
        case orderbook_model::IsMineRole:
            break;
        case orderbook_model::PriceDenomRole:
            break;
        case orderbook_model::PriceNumerRole:
            break;
        case orderbook_model::PercentDepthRole:
            break;
        case orderbook_model::QuantityDenomRole:
            break;
        case orderbook_model::QuantityNumerRole:
            break;
        case orderbook_model::CoinRole:
            break;
        }
        return true;
    }
} // namespace atomic_dex
