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

//! Deps
#include <antara/app/net/http.code.hpp>
#include <range/v3/algorithm/any_of.hpp>

//! Project
#include "atomicdex/api/mm2/rpc.recover.funds.hpp"
#include "atomicdex/events/qt.events.hpp"
#include "atomicdex/models/qt.orders.model.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

//! Constructor
namespace atomic_dex
{
    orders_model::orders_model(ag::ecs::system_manager& system_manager, entt::dispatcher& dispatcher, QObject* parent) :
        QAbstractListModel(parent), m_system_manager(system_manager), m_dispatcher(dispatcher), m_model_proxy(new orders_proxy_model(this, system_manager))
    {
        this->m_model_proxy->setSourceModel(this);
        this->m_model_proxy->setDynamicSortFilter(true);
        this->m_model_proxy->setSortRole(UnixTimestampRole);
        this->m_model_proxy->setFilterRole(TickerPairRole);
        this->m_model_proxy->sort(0, Qt::DescendingOrder);
        this->m_dispatcher.sink<current_currency_changed>().connect<&orders_model::on_current_currency_changed>(this);
    }
} // namespace atomic_dex

//! Qt model override
namespace atomic_dex
{
    int
    orders_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return static_cast<int>(this->m_model_data.orders_and_swaps.size());
    }

    bool
    orders_model::setData(const QModelIndex& index, const QVariant& value, int role)
    {
        if (!hasIndex(index.row(), index.column(), index.parent()) || !value.isValid())
        {
            return false;
        }

        t_order_swaps_data& item = m_model_data.orders_and_swaps[index.row()];
        switch (static_cast<OrdersRoles>(role))
        {
        case BaseCoinRole:
            item.base_coin = value.toString();
            break;
        case RelCoinRole:
            item.rel_coin = value.toString();
            break;
        case TickerPairRole:
            item.ticker_pair = value.toString();
            break;
        case BaseCoinAmountRole:
            item.base_amount = value.toString();
            break;
        case BaseCoinAmountCurrentCurrencyRole:
            item.base_amount_fiat = value.toString();
            break;
        case RelCoinAmountRole:
            item.rel_amount = value.toString();
            break;
        case RelCoinAmountCurrentCurrencyRole:
            item.rel_amount_fiat = value.toString();
            break;
        case OrderTypeRole:
            item.order_type = value.toString();
            break;
        case HumanDateRole:
            item.human_date = value.toString();
            break;
        case UnixTimestampRole:
            item.unix_timestamp = value.toULongLong();
            break;
        case PaymentLockRole:
            item.paymentLock = value.toULongLong();
            break;
        case OrderIdRole:
            item.order_id = value.toString();
            break;
        case OrderStatusRole:
            item.order_status = value.toString();
            break;
        case MakerPaymentIdRole:
            item.maker_payment_id = value.toString();
            break;
        case TakerPaymentIdRole:
            item.taker_payment_id = value.toString();
            break;
        case CancellableRole:
            item.is_cancellable = value.toBool();
            break;
        case IsMakerRole:
            item.is_maker = value.toBool();
            break;
        case IsSwapRole:
            item.is_swap = value.toBool();
            break;
        case IsRecoverableRole:
            item.is_recoverable = value.toBool();
            break;
        case OrderErrorStateRole:
            item.order_error_state = value.toString();
            break;
        case OrderErrorMessageRole:
            item.order_error_message = value.toString();
            break;
        case EventsRole:
            item.events = value.toJsonArray();
            break;
        case SuccessEventsRole:
            item.success_events = value.toStringList();
            break;
        case ErrorEventsRole:
            item.error_events = value.toStringList();
            break;
        default:
            break;
        }

        emit dataChanged(index, index, {role});
        return true;
    }

    QVariant
    orders_model::data(const QModelIndex& index, int role) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()))
        {
            return {};
        }

        const t_order_swaps_data& item = m_model_data.orders_and_swaps.at(index.row());
        switch (static_cast<OrdersRoles>(role))
        {
        case BaseCoinRole:
            return item.base_coin;
        case RelCoinRole:
            return item.rel_coin;
        case TickerPairRole:
            return item.ticker_pair;
        case BaseCoinAmountRole:
            return item.base_amount;
        case BaseCoinAmountCurrentCurrencyRole:
            return item.base_amount_fiat;
        case RelCoinAmountRole:
            return item.rel_amount;
        case RelCoinAmountCurrentCurrencyRole:
            return item.rel_amount_fiat;
        case OrderTypeRole:
            return item.order_type;
        case HumanDateRole:
            return item.human_date;
        case UnixTimestampRole:
            return item.unix_timestamp;
        case PaymentLockRole:
            return item.paymentLock;
        case OrderIdRole:
            return item.order_id;
        case OrderStatusRole:
            return item.order_status;
        case MakerPaymentIdRole:
            return item.maker_payment_id;
        case TakerPaymentIdRole:
            return item.taker_payment_id;
        case CancellableRole:
            return item.is_cancellable;
        case IsMakerRole:
            return item.is_maker;
        case IsSwapRole:
            return item.is_swap;
        case IsRecoverableRole:
            return item.is_recoverable;
        case OrderErrorStateRole:
            return item.order_error_state;
        case OrderErrorMessageRole:
            return item.order_error_message;
        case EventsRole:
            return item.events;
        case SuccessEventsRole:
            return item.success_events;
        case ErrorEventsRole:
            return item.error_events;
        default:
            break;
        }
        return {};
    }

    bool
    orders_model::removeRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        SPDLOG_DEBUG("(orders_model::removeRows) removing {} elements at position {}", rows, position);

        beginRemoveRows(QModelIndex(), position, position + rows - 1);
        for (int row = 0; row < rows; ++row)
        {
            this->m_model_data.orders_and_swaps.erase(begin(m_model_data.orders_and_swaps) + position);
            emit lengthChanged();
        }
        endRemoveRows();

        return true;
    }

    QHash<int, QByteArray>
    orders_model::roleNames() const
    {
        return {
            {BaseCoinRole, "base_coin"},
            {RelCoinRole, "rel_coin"},
            {TickerPairRole, "ticker_pair"},
            {BaseCoinAmountRole, "base_amount"},
            {BaseCoinAmountCurrentCurrencyRole, "base_amount_current_currency"},
            {RelCoinAmountRole, "rel_amount"},
            {RelCoinAmountCurrentCurrencyRole, "rel_amount_current_currency"},
            {OrderTypeRole, "type"},
            {IsMakerRole, "is_maker"},
            {HumanDateRole, "date"},
            {UnixTimestampRole, "timestamp"},
            {PaymentLockRole, "paymentLock"},
            {OrderIdRole, "order_id"},
            {OrderStatusRole, "order_status"},
            {MakerPaymentIdRole, "maker_payment_id"},
            {TakerPaymentIdRole, "taker_payment_id"},
            {IsSwapRole, "is_swap"},
            {CancellableRole, "cancellable"},
            {IsRecoverableRole, "recoverable"},
            {OrderErrorStateRole, "order_error_state"},
            {OrderErrorMessageRole, "order_error_message"},
            {EventsRole, "events"},
            {SuccessEventsRole, "success_events"},
            {ErrorEventsRole, "error_events"}};
    }
} // namespace atomic_dex

//! Properties
namespace atomic_dex
{
    int
    orders_model::get_length() const
    {
        return this->m_model_proxy->rowCount(QModelIndex());
    }

    orders_proxy_model*
    orders_model::get_orders_proxy_mdl() const
    {
        return m_model_proxy;
    }

    QVariant
    atomic_dex::orders_model::get_average_events_time_registry() const
    {
        return m_json_time_registry;
    }

    void
    atomic_dex::orders_model::set_average_events_time_registry(const QVariant& average_time_registry)
    {
        m_json_time_registry = average_time_registry;
        emit onAverageEventsTimeRegistryChanged();
    }

    int
    orders_model::get_current_page() const
    {
        return static_cast<int>(m_model_data.current_page);
    }

    void
    orders_model::set_current_page(int current_page)
    {
        if (static_cast<std::size_t>(current_page) != m_model_data.current_page)
        {
            SPDLOG_INFO("Current page: {}, new page: {}", m_model_data.current_page, current_page);
            this->set_fetching_busy(true);
            this->reset_backend("set_current_page"); ///< We change page, we need to clear, but do not notify the front-end
            auto& mm2 = this->m_system_manager.get_system<mm2_service>();
            mm2.set_orders_and_swaps_pagination_infos(static_cast<std::size_t>(current_page), m_model_data.limit, m_model_data.filtering_infos);
        }
    }

    int
    orders_model::get_limit_nb_elements() const
    {
        return static_cast<int>(m_model_data.limit);
    }

    void
    orders_model::set_limit_nb_elements(int limit)
    {
        if (static_cast<std::size_t>(limit) != m_model_data.limit)
        {
            this->m_model_data.limit = limit;
            if (m_model_data.current_page == 1)
            {
                this->set_fetching_busy(true);
                this->reset_backend("set_limit_nb_elements"); ///< We change page, we need to clear, but do not notify the front-end
                auto& mm2 = this->m_system_manager.get_system<mm2_service>();
                mm2.set_orders_and_swaps_pagination_infos(m_model_data.current_page, static_cast<std::size_t>(limit), m_model_data.filtering_infos);
            }
            else
            {
                this->set_current_page(1);
            }
        }
    }

    QVariant
    orders_model::get_recover_fund_data() const
    {
        return m_recover_funds_data.get();
    }

    void
    orders_model::set_recover_fund_data(QVariant rpc_data)
    {
        auto json_result     = rpc_data.toJsonObject();
        m_recover_funds_data = json_result;
        emit recoverFundDataChanged();
    }

    bool
    orders_model::is_fetching_busy() const
    {
        return m_fetching_busy.load();
    }

    bool
    orders_model::is_recover_fund_busy() const
    {
        return m_recover_funds_busy.load();
    }

    void
    orders_model::set_fetching_busy(bool fetching_status)
    {
        if (fetching_status != m_fetching_busy)
        {
            m_fetching_busy = fetching_status;
            emit fetchingStatusChanged();
        }
    }

    void
    orders_model::set_recover_fund_busy(bool recover_funds_status)
    {
        if (recover_funds_status != m_recover_funds_busy)
        {
            m_recover_funds_busy = recover_funds_status;
            emit recoverFundBusyChanged();
        }
    }

    int
    orders_model::get_nb_pages() const
    {
        return static_cast<int>(m_model_data.nb_pages);
    }
} // namespace atomic_dex

//! Events
namespace atomic_dex
{
    void
    orders_model::on_current_currency_changed([[maybe_unused]] const current_currency_changed&)
    {
        auto& mm2 = m_system_manager.get_system<mm2_service>();

        mm2.batch_fetch_orders_and_swap();
    }
} // namespace atomic_dex

//! Private API
namespace atomic_dex
{
    void
    orders_model::update_existing_order(const t_order_swaps_data& contents)
    {
        if (const auto res = this->match(index(0, 0), OrderIdRole, contents.order_id); !res.isEmpty())
        {
            const QModelIndex& idx = res.at(0);
            update_value(OrdersRoles::CancellableRole, contents.is_cancellable, idx, *this);
            update_value(OrdersRoles::IsMakerRole, contents.order_type == "maker", idx, *this);
            update_value(OrdersRoles::OrderTypeRole, contents.order_type, idx, *this);
            update_value(OrdersRoles::BaseCoinAmountCurrentCurrencyRole, contents.base_amount_fiat, idx, *this);
            update_value(OrdersRoles::RelCoinAmountCurrentCurrencyRole, contents.rel_amount_fiat, idx, *this);
            if (contents.order_type == "maker")
            {
                update_value(OrdersRoles::BaseCoinAmountRole, contents.base_amount, idx, *this);
                update_value(OrdersRoles::RelCoinAmountRole, contents.rel_amount, idx, *this);
            }
            emit lengthChanged();
        }
    }

    void
    orders_model::update_swap(const t_order_swaps_data& contents)
    {
        if (const auto res = this->match(index(0, 0), OrderIdRole, contents.order_id); !res.isEmpty())
        {
            const QModelIndex& idx = res.at(0);
            update_value(OrdersRoles::IsRecoverableRole, contents.is_recoverable, idx, *this);
            auto&& [prev_value, new_value, is_change] = update_value(OrdersRoles::OrderStatusRole, contents.order_status, idx, *this);

            update_value(OrdersRoles::UnixTimestampRole, contents.unix_timestamp, idx, *this);
            update_value(OrdersRoles::PaymentLockRole, contents.paymentLock, idx, *this);
            auto&& [prev_value_d, new_value_d, _] = update_value(OrdersRoles::HumanDateRole, contents.human_date, idx, *this);
            if (is_change)
            {
                const QString& base_coin = data(idx, OrdersRoles::BaseCoinRole).toString();
                const QString& rel_coin  = data(idx, OrdersRoles::RelCoinRole).toString();
                m_dispatcher.trigger<swap_status_notification>(
                    contents.order_id, prev_value.toString(), new_value.toString(), base_coin, rel_coin, new_value_d.toString());
                auto& mm2 = m_system_manager.get_system<mm2_service>();
                mm2.process_orderbook(true);
            }
            update_value(OrdersRoles::MakerPaymentIdRole, contents.maker_payment_id, idx, *this);
            update_value(OrdersRoles::TakerPaymentIdRole, contents.taker_payment_id, idx, *this);
            update_value(OrdersRoles::OrderErrorStateRole, contents.order_error_state, idx, *this);
            update_value(OrdersRoles::OrderErrorMessageRole, contents.order_error_message, idx, *this);
            update_value(OrdersRoles::EventsRole, contents.events, idx, *this);
            update_value(OrdersRoles::SuccessEventsRole, contents.success_events, idx, *this);
            update_value(OrdersRoles::ErrorEventsRole, contents.error_events, idx, *this);

            //! Updates values in current currency of amounts traded.
            update_value(OrdersRoles::BaseCoinAmountCurrentCurrencyRole, contents.base_amount_fiat, idx, *this);
            update_value(OrdersRoles::RelCoinAmountCurrentCurrencyRole, contents.rel_amount_fiat, idx, *this);

            emit lengthChanged();
        }
    }

    void
    orders_model::init_model(const orders_and_swaps& contents)
    {
        const auto size = contents.orders_and_swaps.size();
        if (size == 0)
            return;
        SPDLOG_INFO("Full initialization, inserting {} elements, nb_elements / page {}", size, contents.limit);
        beginResetModel();
        m_model_data = contents;
        endResetModel();
        m_orders_id_registry = std::move(m_model_data.orders_registry);
        m_swaps_id_registry  = std::move(m_model_data.swaps_registry);
        emit lengthChanged();
        emit currentPageChanged();
        emit limitNbElementsChanged();
        emit nbPageChanged();
        this->set_average_events_time_registry(nlohmann_json_object_to_qt_json_object(m_model_data.average_events_time));
    }

    void
    orders_model::common_insert(const std::vector<t_order_swaps_data>& contents, const std::string& kind)
    {
        SPDLOG_INFO("common_insert, nb elements to insert: {}", contents.size());
        auto& data = m_model_data.orders_and_swaps;
        beginInsertRows(QModelIndex(), rowCount(), rowCount() + static_cast<int>(contents.size()) - 1);
        data.insert(end(data), begin(contents), end(contents));
        if (kind == "orders")
        {
            m_model_data.nb_orders += contents.size();
        }
        endInsertRows();
        emit lengthChanged();
        if (m_system_manager.has_system<mm2_service>())
        {
            SPDLOG_DEBUG("Swaps inserted, refreshing orderbook to get new max taker vol");
            this->m_system_manager.get_system<mm2_service>().process_orderbook(true);
        }
        SPDLOG_DEBUG("{} model size: {}", kind, rowCount());
    }

    void
    orders_model::update_or_insert_swaps(const orders_and_swaps& contents)
    {
        const auto&                     data = contents.orders_and_swaps;
        std::vector<t_order_swaps_data> to_init;
        std::for_each(
            begin(data) + contents.nb_orders, end(data),
            [this, &to_init](const auto& cur)
            {
                if (cur.is_swap)
                {
                    const auto& uuid = cur.order_id.toStdString();
                    if (this->m_swaps_id_registry.contains(uuid))
                    {
                        this->update_swap(cur);
                    }
                    else
                    {
                        to_init.emplace_back(cur);
                        m_swaps_id_registry.emplace(uuid);
                    }
                }
            });
        if (!to_init.empty())
        {
            this->common_insert(to_init, "swaps");
        }
    }

    void
    orders_model::update_or_insert_orders(const orders_and_swaps& contents)
    {
        const auto&                     data = contents.orders_and_swaps;
        std::unordered_set<std::string> are_present;
        if (contents.nb_orders > 0)
        {
            std::vector<t_order_swaps_data> to_init;
            std::for_each(
                begin(data), begin(data) + contents.nb_orders,
                [this, &to_init, &are_present](const auto& cur)
                {
                    if (this->m_orders_id_registry.contains(cur.order_id.toStdString()))
                    {
                        this->update_existing_order(cur);
                    }
                    else
                    {
                        m_orders_id_registry.emplace(to_init.emplace_back(cur).order_id.toStdString());
                    }
                    are_present.emplace(cur.order_id.toStdString());
                });

            if (!to_init.empty())
            {
                this->common_insert(to_init, "orders");
            }
        }

        remove_orders(are_present);
    }

    void
    orders_model::remove_orders(const t_orders_id_registry& are_present)
    {
        std::vector<std::string> to_remove;
        for (auto&& id: this->m_orders_id_registry)
        {
            if (!are_present.contains(id))
            {
                //! If it's the case retrieve the index of the row that match this id
                auto res_list = this->match(index(0, 0), OrderIdRole, QString::fromStdString(id));
                if (!res_list.empty())
                {
                    //! And then delete it
                    this->removeRow(res_list.at(0).row());
                    m_model_data.nb_orders -= 1;
                    to_remove.emplace_back(id);
                }
            }
        }
        for (auto&& cur_to_remove: to_remove) { m_orders_id_registry.erase(cur_to_remove); }
    }

    void
    orders_model::set_common_data(const orders_and_swaps& contents)
    {
        this->set_average_events_time_registry(nlohmann_json_object_to_qt_json_object(contents.average_events_time));
        m_model_data.nb_orders = contents.nb_orders;
        if (m_model_data.nb_pages != contents.nb_pages)
        {
            SPDLOG_INFO("nb page changed");
            m_model_data.nb_pages = contents.nb_pages;
            emit nbPageChanged();
        }

        if (m_model_data.limit != contents.limit)
        {
            SPDLOG_INFO("nb elements / page changed");
            this->set_limit_nb_elements(static_cast<int>(contents.limit));
        }

        if (m_model_data.current_page != contents.current_page)
        {
            SPDLOG_INFO("Page is different from mm2 contents, force change");
            this->set_current_page(static_cast<int>(contents.current_page));
        }
    }
} // namespace atomic_dex

//! Public API
namespace atomic_dex
{
    void
    orders_model::reset()
    {
        SPDLOG_DEBUG("resetting orders, will be emitted");
        this->beginResetModel();
        reset_backend("reset");
        this->endResetModel();
        this->set_fetching_busy(false);
    }

    void
    orders_model::reset_backend(const std::string& from)
    {
        SPDLOG_DEBUG("clearing orders in backend {}", from);
        const auto limit     = this->m_model_data.limit;
        const auto filtering = this->m_model_data.filtering_infos;
        this->m_swaps_id_registry.clear();
        this->m_orders_id_registry.clear();
        this->m_model_data = {.limit = limit, .filtering_infos = filtering};
    }

    bool
    atomic_dex::orders_model::swap_is_in_progress(const QString& coin) const
    {
        auto functor = [coin](const auto& cur_hist_swap)
        {
            return (cur_hist_swap.base_coin == coin || cur_hist_swap.rel_coin == coin) &&
                   (cur_hist_swap.order_status == "matched" || cur_hist_swap.order_status == "ongoing" || cur_hist_swap.order_status == "matching");
        };

        return ranges::any_of(m_model_data.orders_and_swaps, functor);
    }

    void
    orders_model::refresh_or_insert(bool after_manual_reset)
    {
        if (after_manual_reset)
        {
            this->set_fetching_busy(false);
            SPDLOG_INFO("Fetching is not busy anymore");
        }

        if (is_fetching_busy())
        {
            SPDLOG_INFO("Fetching busy skipping");
            return;
        }
        const auto& mm2      = m_system_manager.get_system<mm2_service>();
        const auto  contents = mm2.get_orders_and_swaps();

        //! If model is empty let's init it once
        if (m_model_data.orders_and_swaps.empty())
        {
            init_model(contents);
        }
        else
        {
            this->set_common_data(contents);
            update_or_insert_orders(contents);
            update_or_insert_swaps(contents);
        }
    }

    void
    orders_model::set_filtering_infos(t_filtering_infos infos)
    {
        if (this->is_fetching_busy())
        {
            SPDLOG_WARN("Fetching busy - skipping filtering infos set");
            return;
        }

        m_model_data.filtering_infos = std::move(infos);

        if (m_model_data.current_page == 1 && m_model_proxy->am_i_in_history())
        {
            //! Filtering changed
            this->set_fetching_busy(true);
            this->reset();
            // this->reset_backend("set_filtering_infos"); ///< We change page, we need to clear, but do not notify the front-end
            if (this->m_system_manager.has_system<mm2_service>())
            {
                auto& mm2 = this->m_system_manager.get_system<mm2_service>();
                mm2.set_orders_and_swaps_pagination_infos(m_model_data.current_page, m_model_data.limit, m_model_data.filtering_infos);
            }
            else
            {
                SPDLOG_WARN("MM2 is not available, skipping orders and swaps pagination reset");
            }
        }
        else
        {
            this->set_current_page(1);
        }
    }

    t_filtering_infos
    orders_model::get_filtering_infos() const
    {
        return m_model_data.filtering_infos;
    }

    void
    orders_model::recover_fund(QString uuid)
    {
        this->set_recover_fund_busy(true);
        auto&                                   mm2_system = m_system_manager.get_system<mm2_service>();
        nlohmann::json                          batch      = nlohmann::json::array();
        nlohmann::json                          json_data  = mm2::template_request("recover_funds_of_swap");
        mm2::recover_funds_of_swap_request req{.swap_uuid = uuid.toStdString()};
        mm2::to_json(json_data, req);
        batch.push_back(json_data);

        // json_data["userpass"] = "*****";
        // SPDLOG_DEBUG("recover_funds_of_swap request: {}", json_data.dump(-1));

        auto answer_functor = [this](web::http::http_response resp)
        {
            nlohmann::json j_out = nlohmann::json::object();
            std::string    body  = TO_STD_STR(resp.extract_string(true).get());

            SPDLOG_DEBUG("recover_funds_of_swap answer received: {}", body);

            if (resp.status_code() == web::http::status_codes::OK)
            {
                auto answers        = nlohmann::json::parse(body);
                auto recover_answer = mm2::rpc_process_answer_batch<t_recover_funds_of_swap_answer>(answers[0], "recover_funds_of_swap");
                if (recover_answer.result.has_value())
                {
                    auto answer       = recover_answer.result.value();
                    j_out["is_valid"] = true;
                    j_out["coin"]     = answer.coin;
                    j_out["action"]   = answer.action;
                    j_out["tx_hash"]  = answer.tx_hash;
                    j_out["tx_hex"]   = answer.tx_hex;
                }
                else if (recover_answer.error.has_value())
                {
                    j_out["is_valid"] = false;
                    j_out["error"]    = recover_answer.error.value();
                }
                else
                {
                    j_out["is_valid"] = false;
                    j_out["error"]    = recover_answer.raw_result;
                }
            }
            else if (resp.status_code() == web::http::status_codes::RequestTimeout)
            {
                j_out["is_valid"] = false;
                j_out["error"]    = "Request to mm2 timeout - skipping";
            }
            else
            {
                j_out["is_valid"] = false;
                j_out["error"]    = body;
            }
            this->set_recover_fund_data(nlohmann_json_object_to_qt_json_object(j_out));
            this->set_recover_fund_busy(false);
        };

        auto error_functor = [this](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("pplx task error from orders_model::recover_fund(QString uuid): {}", e.what());
                nlohmann::json j_out = nlohmann::json::object();
                j_out["is_valid"]    = false;
                j_out["error"]       = e.what();
                this->set_recover_fund_data(nlohmann_json_object_to_qt_json_object(j_out));
                this->set_recover_fund_busy(false);
            }
        };

        mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(error_functor);
    }
} // namespace atomic_dex
