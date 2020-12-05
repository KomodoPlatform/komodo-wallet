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

//! QT Headers
#include <QObject>

//! Portfolio
#include "atomicdex/models/qt.portfolio.model.hpp"
#include "atomicdex/models/qt.portfolio.proxy.filter.model.hpp"

namespace atomic_dex
{
    class market_pairs final : public QObject
    {
        //! Q_OBJECT Definition
        Q_OBJECT

        //! QT Properties
        Q_PROPERTY(QString left_selected_coin READ get_left_selected_coin WRITE set_left_selected_coin NOTIFY leftSelectedCoinChanged)
        Q_PROPERTY(QString right_selected_coin READ get_right_selected_coin WRITE set_right_selected_coin NOTIFY rightSelectedCoinChanged)
        Q_PROPERTY(QString base_selected_coin READ get_base_selected_coin WRITE set_base_selected_coin NOTIFY baseSelectedCoinChanged)
        Q_PROPERTY(QString rel_selected_coin READ get_rel_selected_coin WRITE set_rel_selected_coin NOTIFY relSelectedCoinChanged)
        Q_PROPERTY(portfolio_proxy_model* left_selection_box READ get_left_selection_box NOTIFY leftSelectionBoxChanged)             ///< Left Selector
        Q_PROPERTY(portfolio_proxy_model* right_selection_box READ get_right_selection_box NOTIFY rightSelectionBoxChanged)          ///! Right selector
        Q_PROPERTY(portfolio_proxy_model* multiple_selection_box READ get_multiple_selection_box NOTIFY multipleSelectionBoxChanged) ///< List on dex page
        Q_PROPERTY(portfolio_proxy_model* multi_order_coins READ get_multiple_order_coins NOTIFY multipleOrderCoinsChanged)          ///< Confirmation modal

        QString                m_left_selected_coin;
        QString                m_right_selected_coin;
        QString                m_base_selected_coin;
        QString                m_rel_selected_coin;
        portfolio_proxy_model* m_left_selection_box;
        portfolio_proxy_model* m_right_selection_box;
        portfolio_proxy_model* m_multiple_selection_box;
        portfolio_proxy_model* m_multi_order_coins;


      public:
        //! Constructor / Destructor
        market_pairs(portfolio_model* portfolio_mdl, QObject* parent = nullptr);
        ~market_pairs() noexcept final;

        //! Properties Getter/Setter
        [[nodiscard]] QString                get_left_selected_coin() const noexcept;
        [[nodiscard]] QString                get_right_selected_coin() const noexcept;
        [[nodiscard]] QString                get_base_selected_coin() const noexcept;
        [[nodiscard]] QString                get_rel_selected_coin() const noexcept;
        [[nodiscard]] portfolio_proxy_model* get_left_selection_box() const noexcept;
        [[nodiscard]] portfolio_proxy_model* get_right_selection_box() const noexcept;
        [[nodiscard]] portfolio_proxy_model* get_multiple_selection_box() const noexcept;
        [[nodiscard]] portfolio_proxy_model* get_multiple_order_coins() const noexcept;
        void                                 set_left_selected_coin(QString left_coin) noexcept;
        void                                 set_right_selected_coin(QString right_coin) noexcept;
        void                                 set_base_selected_coin(QString base_coin) noexcept;
        void                                 set_rel_selected_coin(QString rel_coin) noexcept;
        void                                 reset();

      signals:
        void leftSelectedCoinChanged();
        void rightSelectedCoinChanged();
        void baseSelectedCoinChanged();
        void relSelectedCoinChanged();
        void leftSelectionBoxChanged();
        void rightSelectionBoxChanged();
        void multipleSelectionBoxChanged();
        void multipleOrderCoinsChanged();
    };
} // namespace atomic_dex
