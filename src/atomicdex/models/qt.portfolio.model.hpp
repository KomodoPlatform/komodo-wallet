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

//! Qt Headers
#include <QAbstractListModel>
#include <QString>
#include <QVector>

//! Deps
#include <entt/core/attribute.h>

//! Project headers
#include "atomicdex/config/app.cfg.hpp"
#include "atomicdex/data/wallet/qt.portfolio.data.hpp"
#include "atomicdex/events/events.hpp"
#include "atomicdex/models/qt.portfolio.proxy.filter.model.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"

namespace atomic_dex
{
    class ENTT_API portfolio_model final : public QAbstractListModel
    {
        Q_OBJECT
        Q_PROPERTY(portfolio_proxy_model* portfolio_proxy_mdl READ get_portfolio_proxy_mdl NOTIFY portfolioProxyChanged);
        Q_PROPERTY(int length READ get_length NOTIFY lengthChanged);

      public:
        enum PortfolioRoles
        {
            TickerRole = Qt::UserRole + 1,
            GuiTickerRole,
            NameRole,
            BalanceRole,
            MainCurrencyBalanceRole,
            Change24H,
            MainCurrencyPriceForOneUnit,
            MainFiatPriceForOneUnit,
            Trend7D,
            Excluded,
            Display,
            NameAndTicker,
            MultiTickerCurrentlyEnabled, ///< If set to true multi ticker is enabled
            MultiTickerData,             ///< Multi ticker data for the confirm model
            MultiTickerError,            ///< In case of error code will be stored
            MultiTickerPrice,            ///< The price field of multi ticker
            MultiTickerReceiveAmount,    ///< The total receive amount (it's readonly from front-end)
            MultiTickerFeesInfo,         ///< the fees json infos (it's readonly from front-end)
            CoinType
        };
        Q_ENUM(PortfolioRoles)

      private:
        //! Typedef
        using t_portfolio_datas = QVector<portfolio_data>;
        using t_ticker_registry = std::unordered_set<std::string>;

      public:
        //! Constructor / Destructor
        explicit portfolio_model(ag::ecs::system_manager& system_manager, entt::dispatcher& dispatcher, QObject* parent = nullptr) noexcept;
        ~portfolio_model() noexcept final = default;

        //! Overrides
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role) const final;
        bool                                 setData(const QModelIndex& index, const QVariant& value, int role) final; //< Will be used internally
        [[nodiscard]] int                    rowCount(const QModelIndex& parent) const final;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const final;
        bool                                 removeRows(int row, int count, const QModelIndex& parent) final;

        //! Public api
        void initialize_portfolio(const std::vector<std::string>& tickers);
        void update_currency_values();
        void update_balance_values(const std::vector<std::string>& tickers) noexcept;
        void disable_coins(const QStringList& coins);
        void set_cfg(atomic_dex::cfg& cfg) noexcept;

        //! Properties
        [[nodiscard]] portfolio_proxy_model* get_portfolio_proxy_mdl() const noexcept;
        [[nodiscard]] int                    get_length() const noexcept;

        void reset();

      signals:
        void portfolioProxyChanged();
        void lengthChanged();
        void portfolioItemDataChanged();

      private:
        //! From project
        ag::ecs::system_manager& m_system_manager;
        entt::dispatcher&        m_dispatcher;
        atomic_dex::cfg*         m_config;

        //! Properties
        portfolio_proxy_model* m_model_proxy;
        //! Data holders
        t_portfolio_datas m_model_data;
        t_ticker_registry m_ticker_registry;
    };

} // namespace atomic_dex

using t_portfolio_roles = atomic_dex::portfolio_model::PortfolioRoles;
