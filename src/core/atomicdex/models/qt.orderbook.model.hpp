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

#pragma once

//! QT
#include <QAbstractListModel>
#include <QVariantMap>

//! STD
#include <unordered_set>

//! Deps
#include <antara/gaming/ecs/system.manager.hpp>

//! Project
#include "atomicdex/api/mm2/rpc.orderbook.hpp"
#include "atomicdex/models/qt.orderbook.proxy.model.hpp"

namespace atomic_dex
{
    class trading_page;

    class orderbook_model final : public QAbstractListModel
    {
        Q_OBJECT
        Q_PROPERTY(int length READ get_length NOTIFY lengthChanged)
        Q_PROPERTY(orderbook_proxy_model* proxy_mdl READ get_orderbook_proxy NOTIFY proxyMdlChanged)

      public:
        enum class kind
        {
            asks        = 1,
            bids        = 2,
            best_orders = 3,
        };

        enum OrderbookRoles
        {
            PriceRole = Qt::UserRole + 1, // 257
            CoinRole,
            TotalRole,
            UUIDRole,
            IsMineRole,
            PriceDenomRole,
            PriceNumerRole,
            PercentDepthRole,
            MinVolumeRole,
            EnoughFundsToPayMinVolume,
            CEXRatesRole,
            SendRole,
            PriceFiatRole,
            HaveCEXIDRole,
            BaseMinVolumeRole,
            BaseMinVolumeDenomRole,
            BaseMinVolumeNumerRole,
            BaseMaxVolumeRole,
            BaseMaxVolumeDenomRole,
            BaseMaxVolumeNumerRole,
            RelMinVolumeRole,
            RelMinVolumeDenomRole,
            RelMinVolumeNumerRole,
            RelMaxVolumeRole,
            RelMaxVolumeDenomRole,
            RelMaxVolumeNumerRole,
            NameAndTicker
        };

        orderbook_model(kind orderbook_kind, ag::ecs::system_manager& system_mgr, QObject* parent = nullptr);
        ~orderbook_model() final = default;

        [[nodiscard]] int                    rowCount(const QModelIndex& parent = QModelIndex()) const final;
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role) const final;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const final;
        bool                                 setData(const QModelIndex& index, const QVariant& value, int role) final;
        bool                                 removeRows(int row, int count, const QModelIndex& parent) override;

        void                                 reset_orderbook(const t_orders_contents& orderbook, bool is_bestorders=false);
        void                                 refresh_orderbook(const t_orders_contents& orderbook, bool is_bestorders=false);
        void                                 clear_orderbook();
        [[nodiscard]] int                    get_length() const;
        [[nodiscard]] orderbook_proxy_model* get_orderbook_proxy() const;
        [[nodiscard]] t_order_contents       get_order_content(const QModelIndex& index) const;
        kind                                 get_orderbook_kind() const;

      signals:
        void lengthChanged();
        void proxyMdlChanged();
        void betterOrderDetected(QVariantMap order_object);

      private:
        void        initialize_order(const mm2::order_contents& order);
        void        update_order(const mm2::order_contents& order);
        QVariantMap get_order_from_uuid(QString uuid);
        void        check_for_better_order(trading_page& trading_pg, const QVariantMap& preferred_order, std::string uuid);

      private:
        kind                            m_current_orderbook_kind{kind::asks};
        ag::ecs::system_manager&        m_system_mgr;
        t_orders_contents               m_model_data;
        std::unordered_set<std::string> m_orders_id_registry;
        orderbook_proxy_model*          m_model_proxy;
    };

} // namespace atomic_dex
