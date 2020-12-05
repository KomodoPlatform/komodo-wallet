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
#include <QDate>
#include <QSortFilterProxyModel>

namespace atomic_dex
{
    class orders_proxy_model final : public QSortFilterProxyModel
    {
        Q_OBJECT
        Q_PROPERTY(bool is_history READ am_i_in_history WRITE set_is_history NOTIFY isHistoryChanged);
        Q_PROPERTY(QDate filter_minimum_date READ filter_minimum_date WRITE set_filter_minimum_date NOTIFY filterMinimumDateChanged);
        Q_PROPERTY(QDate filter_maximum_date READ filter_maximum_date WRITE set_filter_maximum_date NOTIFY filterMaximumDateChanged);

      public:
        //! Constructor
        orders_proxy_model(QObject* parent);

        //! Destructor
        ~orders_proxy_model() noexcept final = default;

        [[nodiscard]] bool am_i_in_history() const noexcept;

        void set_is_history(bool is_history) noexcept;

        [[nodiscard]] QDate filter_minimum_date() const;
        void                set_filter_minimum_date(QDate date);

        [[nodiscard]] QDate filter_maximum_date() const;
        void                set_filter_maximum_date(QDate date);

        Q_INVOKABLE QStringList get_filtered_ids() const noexcept;
        Q_INVOKABLE void        set_coin_filter(const QString& to_filter);
        Q_INVOKABLE void        export_csv_visible_history(const QString& path);


      signals:
        void isHistoryChanged();
        void filterMinimumDateChanged();
        void filterMaximumDateChanged();

      protected:
        //! Override member functions
        [[nodiscard]] bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const final;
        [[nodiscard]] bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;

      private:
        [[nodiscard]] bool date_in_range(QDate date) const;

        bool m_is_history{false};

        QDate m_min_date;
        QDate m_max_date;
    };
} // namespace atomic_dex
