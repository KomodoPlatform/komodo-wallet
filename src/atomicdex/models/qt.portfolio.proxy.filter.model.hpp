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

//! Qt
#include <QSortFilterProxyModel>

namespace atomic_dex
{
    class portfolio_proxy_model final : public QSortFilterProxyModel
    {
        Q_OBJECT
        QString m_excluded_coin{""};
        bool    am_i_a_market_selector{false};

      public:
        //! Constructor
        portfolio_proxy_model(QObject* parent);

        //! Destructor
        ~portfolio_proxy_model() noexcept final = default;

      public:
        //! API
        Q_INVOKABLE void sort_by_name(bool is_ascending);
        Q_INVOKABLE void sort_by_currency_balance(bool is_ascending);
        Q_INVOKABLE void sort_by_change_last24h(bool is_ascending);
        Q_INVOKABLE void sort_by_currency_unit(bool is_ascending);

        void set_excluded_coin(const QString& ticker);
        void is_a_market_selector(bool is_market_selector) noexcept;

        void reset();

      protected:
        //! Override member functions
        [[nodiscard]] bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const final;
        bool               filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    };
} // namespace atomic_dex
