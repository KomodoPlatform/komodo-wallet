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
#include "atomicdex/models/qt.wallet.transactions.proxy.filter.model.hpp"
#include "atomicdex/models/qt.wallet.transactions.model.hpp"

namespace atomic_dex
{
    transactions_proxy_model::transactions_proxy_model(QObject* parent) : QSortFilterProxyModel(parent)
    {
    }

    bool
    transactions_proxy_model::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
    {
        int      role       = this->sortRole();
        QVariant left_data  = sourceModel()->data(source_left, role);
        QVariant right_data = sourceModel()->data(source_right, role);
        switch (static_cast<atomic_dex::transactions_model::TransactionsRoles>(role))
        {
        case transactions_model::AmountRole:
            break;
        case transactions_model::AmISenderRole:
            break;
        case transactions_model::DateRole:
            break;
        case transactions_model::TimestampRole:
            return left_data.toUInt() > right_data.toUInt();
        case transactions_model::AmountFiatRole:
            break;
        case transactions_model::TxHashRole:
            break;
        case transactions_model::FeesRole:
            break;
        case transactions_model::FromRole:
            break;
        case transactions_model::ToRole:
            break;
        case transactions_model::BlockheightRole:
            break;
        case transactions_model::ConfirmationsRole:
            break;
        case transactions_model::UnconfirmedRole:
            break;
        case transactions_model::TransactionNoteRole:
            break;
        }
        return true;
    }
} // namespace atomic_dex
