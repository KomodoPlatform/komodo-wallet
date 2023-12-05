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

//! Project
#include "atomicdex/models/qt.orderbook.model.hpp"
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace
{
    /*template <typename TValue, typename TModel>
    void
    update_value(int role, const TValue& value, const QModelIndex& idx, TModel& model)
    {
        if (value != model.data(idx, role))
        {
            model.setData(idx, value, role);
        }
    }*/
} // namespace

namespace atomic_dex
{
    orderbook_model::orderbook_model(kind orderbook_kind, ag::ecs::system_manager& system_mgr, QObject* parent) :
        QAbstractListModel(parent), m_current_orderbook_kind(orderbook_kind), m_system_mgr(system_mgr),
        m_model_proxy(new orderbook_proxy_model(system_mgr, this))
    {
        this->m_model_proxy->setSourceModel(this);
        this->m_model_proxy->setDynamicSortFilter(true);
        this->m_model_proxy->setSortRole(PriceRole);

        switch (m_current_orderbook_kind)
        {
        case kind::asks:
            this->m_model_proxy->sort(0, Qt::DescendingOrder);
            break;
        case kind::bids:
            this->m_model_proxy->sort(0, Qt::DescendingOrder);
            break;
        case kind::best_orders:
            this->m_model_proxy->setSortRole(CEXRatesRole);
            this->m_model_proxy->setFilterRole(NameAndTicker);
            this->m_model_proxy->sort(0, Qt::DescendingOrder);
            this->m_model_proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
            break;
        }
    }

    int
    orderbook_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return m_model_data.size();
    }

    QVariant
    orderbook_model::data(const QModelIndex& index, int role) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()) || this->rowCount() == 0)
        {
            return {};
        }

        switch (static_cast<OrderbookRoles>(role))
        {
        case PriceRole:
            return QString::fromStdString(m_model_data.at(index.row()).price);
        case CoinRole:
        {
            if (m_current_orderbook_kind == kind::best_orders)
            {
                const auto coin = m_model_data.at(index.row()).rel_coin.value();
                return QString::fromStdString(coin);
            }
            return QString::fromStdString(m_model_data.at(index.row()).coin);
        }
        case NameAndTicker:
        {
            if (m_current_orderbook_kind == kind::best_orders)
            {
                const auto  coin         = m_model_data.at(index.row()).rel_coin.value();
                const auto& portfolio_pg = m_system_mgr.get_system<portfolio_page>();
                const auto  cfg          = portfolio_pg.get_global_cfg()->get_coin_info(coin);
                return QString::fromStdString(coin + cfg.name);
            }
            return QString::fromStdString(m_model_data.at(index.row()).coin);
        }
        case PriceDenomRole:
            return QString::fromStdString(m_model_data.at(index.row()).price_fraction_denom);
        case PriceNumerRole:
            return QString::fromStdString(m_model_data.at(index.row()).price_fraction_numer);
        case TotalRole:
            return QString::fromStdString(m_model_data.at(index.row()).total);
        case UUIDRole:
            return QString::fromStdString(m_model_data.at(index.row()).uuid);
        case IsMineRole:
            return m_model_data.at(index.row()).is_mine;
        case PercentDepthRole:
            return QString::fromStdString(m_model_data.at(index.row()).depth_percent);
        case BaseMinVolumeRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_min_volume);
        case BaseMinVolumeDenomRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_min_volume_denom);
        case BaseMinVolumeNumerRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_min_volume_numer);
        case BaseMaxVolumeRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_max_volume);
        case BaseMaxVolumeDenomRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_max_volume_denom);
        case BaseMaxVolumeNumerRole:
            return QString::fromStdString(m_model_data.at(index.row()).base_max_volume_numer);
        case RelMinVolumeRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_min_volume);
        case RelMinVolumeDenomRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_min_volume_denom);
        case RelMinVolumeNumerRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_min_volume_numer);
        case RelMaxVolumeRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_max_volume);
        case RelMaxVolumeDenomRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_max_volume_denom);
        case RelMaxVolumeNumerRole:
            return QString::fromStdString(m_model_data.at(index.row()).rel_max_volume_numer);
        case MinVolumeRole:
        {
            const bool is_asks = m_current_orderbook_kind == kind::asks;
            return QString::fromStdString(is_asks ? m_model_data.at(index.row()).rel_min_volume : m_model_data.at(index.row()).base_min_volume);
        }
        case EnoughFundsToPayMinVolume:
        {
            bool        i_have_enough_funds = true;
            const auto& order_model_data    = m_model_data.at(index.row());
            const auto& trading_pg          = m_system_mgr.get_system<trading_page>();
            const bool  is_asks             = m_current_orderbook_kind == kind::asks;
            const auto  min_volume_f        = safe_float(is_asks ? order_model_data.rel_min_volume : order_model_data.base_min_volume);
            auto        taker_vol_std =
                ((is_asks) ? trading_pg.get_orderbook_wrapper()->get_rel_max_taker_vol() : trading_pg.get_orderbook_wrapper()->get_base_max_taker_vol())
                    .toJsonObject()["decimal"]
                    .toString()
                    .toStdString();
            if (taker_vol_std.empty())
            {
                taker_vol_std = "0";
            }
            t_float_50 taker_vol = safe_float(taker_vol_std);
            i_have_enough_funds  = min_volume_f > 0 && taker_vol > min_volume_f;
            return i_have_enough_funds;
        }
        case CEXRatesRole:
        {
            const auto& price_service   = m_system_mgr.get_system<global_price_service>();
            const auto& trading_pg      = m_system_mgr.get_system<trading_page>();
            const auto* market_selector = trading_pg.get_market_pairs_mdl();
            const auto& base            = market_selector->get_left_selected_coin().toStdString();
            const auto& rel             = data(index, CoinRole).toString().toStdString();
            const auto& price           = m_model_data.at(index.row()).price;
            if (base == rel)
            {
                return "0";
            }
            const bool is_buy = trading_pg.get_market_mode() == MarketMode::Buy;
            // SPDLOG_INFO("cex rates: {}/{} is_buy: {} price: {}", base, rel, is_buy, price);
            t_float_50 price_diff(0);
            t_float_50 cex_price = safe_float(price_service.get_cex_rates(base, rel));
            if (cex_price > 0)
            {
                price_diff = t_float_50(100) * (t_float_50(1) - safe_float(price) / cex_price) * (!is_buy ? t_float_50(1) : t_float_50(-1));
                // SPDLOG_INFO("{}/{} price_diff({}%) = 100 * (1 - price[{}] / cex_price[{}])) * ({})", base, rel, utils::format_float(price_diff),
                // utils::adjust_precision(price), utils::format_float(cex_price), !is_buy ? 1 : -1);
                return QString::fromStdString(utils::format_float(price_diff));
            }
            return "0";
        }
        case SendRole:
        {
            if (m_current_orderbook_kind == kind::best_orders)
            {
                const auto& data         = m_model_data.at(index.row());
                const auto& trading_pg   = m_system_mgr.get_system<trading_page>();
                t_float_50  volume_f     = safe_float(trading_pg.get_volume().toStdString());
                const bool  is_buy       = trading_pg.get_market_mode() == MarketMode::Buy;
                const auto  trading_mode = trading_pg.get_current_trading_mode();
                if (!is_buy && trading_mode == TradingMode::Simple)
                {
                    volume_f = safe_float(data.base_max_volume);
                }
                t_float_50 total_amount_f = volume_f * safe_float(data.price);
                const auto total_amount   = atomic_dex::utils::format_float(total_amount_f);
                return QString::fromStdString(total_amount);
            }
            else
            {
                return "0";
            }
        }
        case PriceFiatRole:
        {
            if (m_current_orderbook_kind == kind::best_orders)
            {
                const auto& price_service = m_system_mgr.get_system<global_price_service>();
                const auto& fiat          = m_system_mgr.get_system<settings_page>().get_cfg().current_fiat;
                const auto  total_amount  = this->data(index, SendRole).toString().toStdString();
                const auto  coin          = data(index, CoinRole).toString().toStdString();
                const auto  result        = price_service.get_price_as_currency_from_amount(fiat, coin, total_amount);
                auto        final_result  = result;
                // SPDLOG_INFO("Result is: [{}] for coin: {} role: {} total amount: {}", result, coin, PriceFiatRole, total_amount);
                // qDebug() << "final_result[" << final_result << "]";
                if (safe_float(result) <= 0)
                {
                    return "0.00";
                }
                return QString::fromStdString(final_result);
            }
            else
            {
                return "0.00";
            }
        }
        case HaveCEXIDRole:
        {
            const auto* global_cfg = m_system_mgr.get_system<portfolio_page>().get_global_cfg();
            auto        infos      = global_cfg->get_coin_info(data(index, CoinRole).toString().toStdString());
            return infos.coingecko_id != "test-coin" || infos.coinpaprika_id != "test-coin";
        }
        }
    }

    bool
    orderbook_model::setData(const QModelIndex& index, const QVariant& value, int role)
    {
        if (!hasIndex(index.row(), index.column(), index.parent()) || !value.isValid())
        {
            return false;
        }
        mm2::order_contents& order = m_model_data.at(index.row());
        switch (static_cast<OrderbookRoles>(role))
        {
        case PriceRole:
            order.price = value.toString().toStdString();
            break;
        case PriceDenomRole:
            order.price_fraction_denom = value.toString().toStdString();
            break;
        case PriceNumerRole:
            order.price_fraction_denom = value.toString().toStdString();
            break;
        case IsMineRole:
            order.is_mine = value.toBool();
            break;
        case TotalRole:
            order.total = value.toString().toStdString();
            break;
        case UUIDRole:
            order.uuid = value.toString().toStdString();
            break;
        case PercentDepthRole:
            order.depth_percent = value.toString().toStdString();
            break;
        case CoinRole:
            order.coin = value.toString().toStdString();
            break;
        case MinVolumeRole:
            order.min_volume = value.toString().toStdString();
            break;
        case NameAndTicker:
            break;
        case EnoughFundsToPayMinVolume:
            break;
        case CEXRatesRole:
            break;
        case SendRole:
            break;
        case PriceFiatRole:
            break;
        case HaveCEXIDRole:
            break;
        case BaseMinVolumeRole:
            order.base_min_volume = value.toString().toStdString();
            break;
        case BaseMinVolumeDenomRole:
            order.base_min_volume_denom = value.toString().toStdString();
            break;
        case BaseMinVolumeNumerRole:
            order.base_min_volume_numer = value.toString().toStdString();
            break;
        case BaseMaxVolumeRole:
            order.base_max_volume = value.toString().toStdString();
            break;
        case BaseMaxVolumeDenomRole:
            order.base_max_volume_denom = value.toString().toStdString();
            break;
        case BaseMaxVolumeNumerRole:
            order.base_max_volume_numer = value.toString().toStdString();
            break;
        case RelMinVolumeRole:
            order.rel_min_volume = value.toString().toStdString();
            break;
        case RelMinVolumeDenomRole:
            order.rel_min_volume_denom = value.toString().toStdString();
            break;
        case RelMinVolumeNumerRole:
            order.rel_min_volume_numer = value.toString().toStdString();
            break;
        case RelMaxVolumeRole:
            order.rel_max_volume = value.toString().toStdString();
            break;
        case RelMaxVolumeDenomRole:
            order.rel_max_volume_denom = value.toString().toStdString();
            break;
        case RelMaxVolumeNumerRole:
            order.rel_max_volume_numer = value.toString().toStdString();
            break;
        }
        // emit dataChanged(index, index, {role});
        return true;
    }

    QHash<int, QByteArray>
    orderbook_model::roleNames() const
    {
        return {
            {PriceRole, "price"},
            {CoinRole, "coin"},
            {TotalRole, "total"},
            {UUIDRole, "uuid"},
            {IsMineRole, "is_mine"},
            {PriceDenomRole, "price_denom"},
            {PriceNumerRole, "price_numer"},
            {PercentDepthRole, "depth"},
            {MinVolumeRole, "min_volume"},
            {EnoughFundsToPayMinVolume, "enough_funds_to_pay_min_volume"},
            {CEXRatesRole, "cex_rates"},
            {SendRole, "send"},
            {PriceFiatRole, "price_fiat"},
            {BaseMinVolumeRole, "base_min_volume"},
            {BaseMinVolumeDenomRole, "base_min_volume_denom"},
            {BaseMinVolumeNumerRole, "base_min_volume_numer"},
            {BaseMaxVolumeRole, "base_max_volume"},
            {BaseMaxVolumeDenomRole, "base_max_volume_denom"},
            {BaseMaxVolumeNumerRole, "base_max_volume_numer"},
            {RelMinVolumeRole, "rel_min_volume"},
            {RelMinVolumeDenomRole, "rel_min_volume_denom"},
            {RelMinVolumeNumerRole, "rel_min_volume_numer"},
            {RelMaxVolumeRole, "rel_max_volume"},
            {RelMaxVolumeDenomRole, "rel_max_volume_denom"},
            {RelMaxVolumeNumerRole, "rel_max_volume_numer"}};
    }

    void
    orderbook_model::reset_orderbook(const t_orders_contents& orderbook, bool is_bestorders)
    {
        SPDLOG_DEBUG("[orderbook_model::reset_orderbook]");
        if (!orderbook.empty())
        {
            SPDLOG_INFO(
                "full orderbook initialization initial size: {} target size: {}, orderbook_kind: {}", rowCount(), orderbook.size(), m_current_orderbook_kind);
        }
        this->beginResetModel();
        m_model_data = orderbook;
        m_orders_id_registry.clear();
        for (auto&& order: m_model_data)
        {
            if (this->m_orders_id_registry.find(order.uuid) == m_orders_id_registry.end())
            {
                this->m_orders_id_registry.emplace(order.uuid);
            }
        }
        this->endResetModel();
        emit lengthChanged();
        // This assert was causing a crash due to duplicated UUIDs being filtered out for orders that exist for both segwit and non-segwit of a coin,
        // because bestorders response will add duplicate entries (one for each address format) to the response.
        assert(m_model_data.size() == m_orders_id_registry.size());
    }

    int
    orderbook_model::get_length() const
    {
        return rowCount();
    }


    void
    orderbook_model::initialize_order(const mm2::order_contents& order)
    {
        if (m_orders_id_registry.contains(order.uuid))
        {
            SPDLOG_WARN("Order with uuid: {} already present...skipping.", order.uuid);
            return;
        }
        assert(m_model_data.size() == m_orders_id_registry.size());
        beginInsertRows(QModelIndex(), m_model_data.size(), m_model_data.size());
        m_model_data.push_back(order);
        this->m_orders_id_registry.emplace(order.uuid);
        endInsertRows();
        emit lengthChanged();
        assert(m_model_data.size() == m_orders_id_registry.size());
        if (m_system_mgr.has_system<trading_page>() && m_current_orderbook_kind == kind::bids)
        {
            auto& trading_pg = m_system_mgr.get_system<trading_page>();
            if (trading_pg.get_market_mode() == MarketMode::Sell)
            {
                const auto preferred_order = trading_pg.get_preferred_order();
                if (!preferred_order.empty())
                {
                    const t_float_50 price_std       = safe_float(order.price);
                    t_float_50       preferred_price = safe_float(preferred_order.value("price", "0").toString().toStdString());
                    if (price_std > preferred_price)
                    {
                        SPDLOG_INFO(
                            "An order with a better price is inserted, uuid: {}, new_price: {}, current_price: {}", order.uuid, utils::format_float(price_std),
                            utils::format_float(preferred_price));
                        trading_pg.set_selected_order_status(SelectedOrderStatus::BetterPriceAvailable);
                        emit betterOrderDetected(get_order_from_uuid(QString::fromStdString(order.uuid)));
                    }
                }
            }
        }
    }

    void
    orderbook_model::update_order(const mm2::order_contents& order)
    {
        if (const auto res = this->match(index(0, 0), UUIDRole, QString::fromStdString(order.uuid)); not res.isEmpty())
        {
            //! ID Found, update !
            const QModelIndex& idx                  = res.at(0);
            auto&& [_, new_price, is_price_changed] = update_value(OrderbookRoles::PriceRole, QString::fromStdString(order.price), idx, *this);
            update_value(OrderbookRoles::PriceNumerRole, QString::fromStdString(order.price_fraction_numer), idx, *this);
            update_value(OrderbookRoles::PriceDenomRole, QString::fromStdString(order.price_fraction_denom), idx, *this);
            update_value(OrderbookRoles::IsMineRole, order.is_mine, idx, *this);
            update_value(OrderbookRoles::TotalRole, QString::fromStdString(order.total), idx, *this);
            update_value(OrderbookRoles::PercentDepthRole, QString::fromStdString(order.depth_percent), idx, *this);
            update_value(OrderbookRoles::BaseMinVolumeRole, QString::fromStdString(order.base_min_volume), idx, *this);
            update_value(OrderbookRoles::BaseMinVolumeDenomRole, QString::fromStdString(order.base_min_volume_denom), idx, *this);
            update_value(OrderbookRoles::BaseMinVolumeNumerRole, QString::fromStdString(order.base_min_volume_numer), idx, *this);
            update_value(OrderbookRoles::BaseMaxVolumeRole, QString::fromStdString(order.base_max_volume), idx, *this);
            update_value(OrderbookRoles::BaseMaxVolumeDenomRole, QString::fromStdString(order.base_max_volume_denom), idx, *this);
            update_value(OrderbookRoles::BaseMaxVolumeNumerRole, QString::fromStdString(order.base_max_volume_numer), idx, *this);
            update_value(OrderbookRoles::RelMinVolumeRole, QString::fromStdString(order.rel_min_volume), idx, *this);
            update_value(OrderbookRoles::RelMinVolumeDenomRole, QString::fromStdString(order.rel_min_volume_denom), idx, *this);
            update_value(OrderbookRoles::RelMinVolumeNumerRole, QString::fromStdString(order.rel_min_volume_numer), idx, *this);
            update_value(OrderbookRoles::RelMaxVolumeRole, QString::fromStdString(order.rel_max_volume), idx, *this);
            update_value(OrderbookRoles::RelMaxVolumeDenomRole, QString::fromStdString(order.rel_max_volume_denom), idx, *this);
            update_value(OrderbookRoles::RelMaxVolumeNumerRole, QString::fromStdString(order.rel_max_volume_numer), idx, *this);
            update_value(OrderbookRoles::MinVolumeRole, QString::fromStdString(order.min_volume), idx, *this);
            update_value(OrderbookRoles::EnoughFundsToPayMinVolume, true, idx, *this);
            update_value(OrderbookRoles::CEXRatesRole, "0.00", idx, *this);
            update_value(OrderbookRoles::SendRole, "0.00", idx, *this);
            update_value(OrderbookRoles::PriceFiatRole, "0.00", idx, *this);
            emit dataChanged(
                idx, idx,
                {OrderbookRoles::UUIDRole,
                 OrderbookRoles::PriceRole,
                 OrderbookRoles::PriceNumerRole,
                 OrderbookRoles::PriceDenomRole,
                 OrderbookRoles::IsMineRole,
                 OrderbookRoles::TotalRole,
                 OrderbookRoles::PercentDepthRole,
                 OrderbookRoles::BaseMinVolumeRole,
                 OrderbookRoles::BaseMinVolumeDenomRole,
                 OrderbookRoles::BaseMinVolumeNumerRole,
                 OrderbookRoles::BaseMaxVolumeRole,
                 OrderbookRoles::BaseMaxVolumeDenomRole,
                 OrderbookRoles::BaseMaxVolumeNumerRole,
                 OrderbookRoles::RelMinVolumeRole,
                 OrderbookRoles::RelMinVolumeDenomRole,
                 OrderbookRoles::RelMinVolumeNumerRole,
                 OrderbookRoles::RelMaxVolumeRole,
                 OrderbookRoles::RelMaxVolumeDenomRole,
                 OrderbookRoles::RelMaxVolumeNumerRole,
                 OrderbookRoles::MinVolumeRole,
                 OrderbookRoles::EnoughFundsToPayMinVolume,
                 OrderbookRoles::CEXRatesRole,
                 OrderbookRoles::SendRole,
                 OrderbookRoles::PriceFiatRole});

            if (m_system_mgr.has_system<trading_page>() && m_current_orderbook_kind == kind::bids && is_price_changed)
            {
                auto& trading_pg = m_system_mgr.get_system<trading_page>();
                if (trading_pg.get_market_mode() == MarketMode::Sell)
                {
                    const auto preferred_order = trading_pg.get_preferred_order();
                    if (!preferred_order.empty())
                    {
                        const t_float_50 price_std       = safe_float(new_price.toString().toStdString());
                        t_float_50       preferred_price = safe_float(preferred_order.value("price", "0").toString().toStdString());
                        if (price_std > preferred_price)
                        {
                            SPDLOG_INFO(
                                "An order with a better price is available, uuid: {}, new_price: {}, current_price: {}", order.uuid,
                                utils::format_float(price_std), utils::format_float(preferred_price));
                            trading_pg.set_selected_order_status(SelectedOrderStatus::BetterPriceAvailable);
                            emit betterOrderDetected(get_order_from_uuid(QString::fromStdString(order.uuid)));
                        }
                        else if (auto selected_uuid = preferred_order.value("uuid", "").toString().toStdString(); selected_uuid == order.uuid)
                        {
                            SPDLOG_INFO("The price went down with the selected order: {}", order.uuid);
                            check_for_better_order(trading_pg, preferred_order, selected_uuid);
                        }
                    }
                }
            }
        }
    }

    void
    orderbook_model::refresh_orderbook(const t_orders_contents& orderbook, bool is_bestorders)
    {
        auto refresh_functor = [this](const std::vector<mm2::order_contents>& contents)
        {
            for (auto&& order: contents)
            {
                if (this->m_orders_id_registry.find(order.uuid) != this->m_orders_id_registry.end())
                {
                    this->update_order(order);
                }
                else
                {
                    this->initialize_order(order);
                }
            }

            // Deletion
            std::unordered_set<std::string> to_remove;
            for (auto&& id: this->m_orders_id_registry)
            {
                bool res = std::none_of(begin(contents), end(contents), [id](auto&& contents) { return contents.uuid == id; });
                // Need to remove the row
                // segwits are deleted here when they shouldnt be
                if (res)
                {
                    auto res_list = this->match(index(0, 0), UUIDRole, QString::fromStdString(id));
                    if (not res_list.empty())
                    {
                        this->removeRow(res_list.at(0).row());
                        to_remove.emplace(id);
                    }
                }
            }
            for (auto&& cur_to_remove: to_remove) { m_orders_id_registry.erase(cur_to_remove); }
        };

        refresh_functor(orderbook);
    }

    t_order_contents
    orderbook_model::get_order_content(const QModelIndex& index) const
    {
        return m_model_data.at(index.row());
    }

    bool
    orderbook_model::removeRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginRemoveRows(QModelIndex(), position, position + rows - 1);
        for (int row = 0; row < rows; ++row)
        {
            auto       it                 = m_model_data.begin() + position;
            const auto uuid_to_be_removed = it->uuid;
            if (m_system_mgr.has_system<trading_page>() && m_current_orderbook_kind == kind::bids)
            {
                auto&      trading_pg      = m_system_mgr.get_system<trading_page>();
                const auto preffered_order = trading_pg.get_preferred_order();
                if (!preffered_order.empty())
                {
                    const auto selected_order_uuid = preffered_order.value("uuid", "").toString().toStdString();
                    if (selected_order_uuid == uuid_to_be_removed)
                    {
                        SPDLOG_WARN(
                            "The selected order uuid: {} is removed from the orderbook model, checking if a better order is available", uuid_to_be_removed);
                        check_for_better_order(trading_pg, preffered_order, selected_order_uuid);
                    }
                }
            }

            // functor(it);
            m_model_data.erase(it);
            emit lengthChanged();
        }
        endRemoveRows();

        return true;
    }

    void
    orderbook_model::clear_orderbook()
    {
        // SPDLOG_INFO("clear orderbook");
        this->beginResetModel();
        m_model_data = t_orders_contents{};
        m_orders_id_registry.clear();
        this->endResetModel();
        emit lengthChanged();
    }

    orderbook_proxy_model*
    orderbook_model::get_orderbook_proxy() const
    {
        return m_model_proxy;
    }
    orderbook_model::kind
    orderbook_model::get_orderbook_kind() const
    {
        return m_current_orderbook_kind;
    }

    // This is used when betterOrderDetected
    QVariantMap
    orderbook_model::get_order_from_uuid([[maybe_unused]] QString uuid)
    {
        QVariantMap out;

        if (const auto res = this->match(index(0, 0), UUIDRole, uuid); not res.isEmpty())
        {
            const QModelIndex& idx        = res.at(0);
            const auto&        order      = m_model_data.at(idx.row());
            auto&              trading_pg = m_system_mgr.get_system<trading_page>();
            const bool         is_buy     = trading_pg.get_market_mode() == MarketMode::Buy;
            out["coin"]                   = QString::fromStdString(is_buy ? order.rel_coin.value() : order.coin);
            out["price"]                  = QString::fromStdString(order.price);
            out["price_denom"]            = QString::fromStdString(order.price_fraction_denom);
            out["price_numer"]            = QString::fromStdString(order.price_fraction_numer);
            out["min_volume"]             = QString::fromStdString(order.min_volume);
            out["base_min_volume"]        = QString::fromStdString(order.base_min_volume);
            out["base_max_volume"]        = QString::fromStdString(order.base_max_volume);
            out["base_max_volume_denom"]  = QString::fromStdString(order.base_max_volume_denom);
            out["base_max_volume_numer"]  = QString::fromStdString(order.base_max_volume_numer);
            out["rel_min_volume"]         = QString::fromStdString(order.rel_min_volume);
            out["rel_max_volume"]         = QString::fromStdString(order.rel_max_volume);
            out["uuid"]                   = QString::fromStdString(order.uuid);
            if (trading_pg.get_current_trading_mode() == TradingModeGadget::Simple)
            {
                out["initial_input_volume"] = trading_pg.get_volume();
            }
        }

        return out;
    }

    void
    orderbook_model::check_for_better_order(trading_page& trading_pg, const QVariantMap& preferred_order, std::string uuid)
    {
        if (trading_pg.get_market_mode() == MarketMode::Sell)
        {
            t_float_50 preferred_price = safe_float(preferred_order.value("price", "0").toString().toStdString());
            bool       hit             = false;
            for (auto&& order: m_model_data)
            {
                const t_float_50 price_std = safe_float(order.price);

                if (price_std > preferred_price)
                {
                    SPDLOG_INFO(
                        "An order with a better price is available, uuid: {}, new_price: {}, current_price: {}", order.uuid, utils::format_float(price_std),
                        utils::format_float(preferred_price));
                    trading_pg.set_selected_order_status(SelectedOrderStatus::BetterPriceAvailable);
                    emit betterOrderDetected(get_order_from_uuid(QString::fromStdString(order.uuid)));
                    hit = true;
                    break;
                }
            }
            if (!hit)
            {
                SPDLOG_INFO("Order with uuid: {} has been cancelled and no new order with better price is available", uuid);
                trading_pg.set_selected_order_status(SelectedOrderStatus::OrderNotExistingAnymore);
            }
        }
    }
} // namespace atomic_dex
