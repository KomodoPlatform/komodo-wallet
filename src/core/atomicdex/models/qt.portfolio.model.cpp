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

//! Qt
#include <QJSValue>

//! Deps
#include <taskflow/taskflow.hpp>

//! Project Headers
#include "atomicdex/events/qt.events.hpp"
#include "atomicdex/managers/qt.wallet.manager.hpp"
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/pages/qt.wallet.page.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"
#include "qt.portfolio.model.hpp"

namespace atomic_dex
{
    portfolio_model::portfolio_model(ag::ecs::system_manager& system_manager, entt::dispatcher& dispatcher, QObject* parent) :
        QAbstractListModel(parent), m_system_manager(system_manager), m_dispatcher(dispatcher),
        m_model_proxy(new portfolio_proxy_model(m_system_manager, parent)), m_pie_chart_proxy_model(new portfolio_proxy_model(m_system_manager, parent))
    {
        m_model_proxy->setSourceModel(this);
        m_model_proxy->setDynamicSortFilter(true);
        m_model_proxy->sort_by_currency_balance(false);
        m_model_proxy->setFilterRole(NameAndTicker);
        m_model_proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);

        m_pie_chart_proxy_model->setSourceModel(this);
        m_pie_chart_proxy_model->setDynamicSortFilter(true);
        m_pie_chart_proxy_model->set_with_fiat_balance(true);
        m_pie_chart_proxy_model->sort_by_currency_balance(false);
        m_pie_chart_proxy_model->setFilterRole(NameAndTicker);
        m_pie_chart_proxy_model->setFilterCaseSensitivity(Qt::CaseInsensitive);
    }

    void
    atomic_dex::portfolio_model::initialize_portfolio(const std::vector<std::string>& tickers)
    {
        QVector<portfolio_data> datas;

        for (auto&& ticker: tickers)
        {
            if (m_ticker_registry.find(ticker) != m_ticker_registry.end())
                continue;
            const auto& mm2_system    = this->m_system_manager.get_system<mm2_service>();
            const auto& price_service = this->m_system_manager.get_system<global_price_service>();
            const auto& provider      = this->m_system_manager.get_system<komodo_prices_provider>();
            auto        coin          = mm2_system.get_coin_info(ticker);

            std::error_code ec;
            const QString   change_24h = retrieve_change_24h(provider, coin, *m_config, m_system_manager);
            portfolio_data  data{
                .ticker                           = QString::fromStdString(coin.ticker),
                .gui_ticker                       = QString::fromStdString(coin.gui_ticker),
                .coin_type                        = QString::fromStdString(coin.type),
                .name                             = QString::fromStdString(coin.name),
                .balance                          = QString::fromStdString(mm2_system.my_balance(coin.ticker, ec)),
                .main_currency_balance            = QString::fromStdString(price_service.get_price_in_fiat(m_config->current_currency, coin.ticker, ec)),
                .change_24h                       = change_24h,
                .main_currency_price_for_one_unit = QString::fromStdString(price_service.get_rate_conversion(m_config->current_currency, coin.ticker, true)),
                .main_fiat_price_for_one_unit     = QString::fromStdString(price_service.get_rate_conversion(m_config->current_fiat, coin.ticker)),
                .trend_7d                         = nlohmann_json_array_to_qt_json_array(provider.get_ticker_historical(coin.ticker)),
                .activation_status                = nlohmann_json_object_to_qt_json_object(coin.activation_status),
                .price_provider                   = QString::fromStdString(provider.get_price_provider(coin.ticker)),
                .price_last_timestamp             = static_cast<int>(provider.get_last_price_timestamp(coin.ticker)),
                .is_excluded                      = false,
                .public_address                   = QString::fromStdString(mm2_system.address(coin.ticker, ec))};
            // data.percent_main_currency = percent_functor(data.main_currency_balance);
            data.display         = QString::fromStdString(coin.gui_ticker) + " (" + data.balance + ")";
            data.ticker_and_name = QString::fromStdString(coin.gui_ticker) + data.name;
            datas.push_back(std::move(data));
            m_ticker_registry.emplace(ticker);
        }
        if (not datas.isEmpty())
        {
            beginInsertRows(QModelIndex(), this->m_model_data.count(), this->m_model_data.count() + tickers.size() - 1);
            this->m_model_data.append(datas);
            endInsertRows();
            SPDLOG_INFO("size of the portfolio after batch inserted: {}", this->get_length());
            emit lengthChanged();
        }
    }

    bool
    portfolio_model::update_currency_values()
    {
        const auto&        mm2_system    = this->m_system_manager.get_system<mm2_service>();
        const auto&        price_service = this->m_system_manager.get_system<global_price_service>();
        const auto&        provider      = this->m_system_manager.get_system<komodo_prices_provider>();
        const auto         coins         = this->m_system_manager.get_system<portfolio_page>().get_global_cfg()->get_enabled_coins();
        const std::string& currency      = m_config->current_currency;
        const std::string& fiat          = m_config->current_fiat;

        for (auto&& [_, coin]: coins)
        {
            if (m_ticker_registry.find(coin.ticker) == m_ticker_registry.end())
            {
                SPDLOG_WARN("ticker: {} not inserted yet in the model, skipping", coin.ticker);
                return false;
            }
            const std::string& ticker = coin.ticker;
            if (const auto res = this->match(this->index(0, 0), TickerRole, QString::fromStdString(ticker), 1, Qt::MatchFlag::MatchExactly);
                not res.isEmpty())
            {
                std::error_code    ec;
                const QModelIndex& idx                         = res.at(0);
                const QString      main_currency_balance_value = QString::fromStdString(price_service.get_price_in_fiat(currency, ticker, ec));
                update_value(MainCurrencyBalanceRole, main_currency_balance_value, idx, *this);
                const QString currency_price_for_one_unit = QString::fromStdString(price_service.get_rate_conversion(currency, ticker, true));
                update_value(MainCurrencyPriceForOneUnit, currency_price_for_one_unit, idx, *this);
                const QString currency_fiat_for_one_unit = QString::fromStdString(price_service.get_rate_conversion(fiat, ticker, false));
                update_value(MainFiatPriceForOneUnit, currency_fiat_for_one_unit, idx, *this);
                const QString price_provider = QString::fromStdString(provider.get_price_provider(ticker));
                update_value(PriceProvider, price_provider, idx, *this);
                int last_price_timestamp = static_cast<int>(provider.get_last_price_timestamp(ticker));
                update_value(LastPriceTimestamp, last_price_timestamp, idx, *this);
                QString change24_h = retrieve_change_24h(provider, coin, *m_config, m_system_manager);
                update_value(Change24H, change24_h, idx, *this);
                const QString balance                           = QString::fromStdString(mm2_system.my_balance(coin.ticker, ec));
                auto&& [prev_balance, new_balance, is_change_b] = update_value(BalanceRole, balance, idx, *this);
                const QString display                           = QString::fromStdString(coin.ticker) + " (" + balance + ")";
                update_value(Display, display, idx, *this);
                // Not a good way to trigger notification, use websocket instead in the future. New was of enabling coins is not compatible.
                if (is_change_b)
                {
                    balance_update_handler(prev_balance.toString(), new_balance.toString(), QString::fromStdString(ticker));
                }
                QJsonArray trend = nlohmann_json_array_to_qt_json_array(provider.get_ticker_historical(ticker));
                update_value(Trend7D, trend, idx, *this);
        
                auto        coin_info          = mm2_system.get_coin_info(ticker);
                QJsonObject status = nlohmann_json_object_to_qt_json_object(coin_info.activation_status);
                update_value(ActivationStatus, status, idx, *this);
                // SPDLOG_DEBUG("updated currency values of: {}", ticker);
            }
        }
        return true;
    }

    bool
    portfolio_model::update_balance_values(const std::vector<std::string>& tickers)
    {
        SPDLOG_INFO("update_balance_values");
        for (auto&& ticker: tickers)
        {
            if (ticker.empty())
            {
                return false;
            }
            if (m_ticker_registry.find(ticker) == m_ticker_registry.end())
            {
                SPDLOG_WARN("ticker: {} not inserted yet in the model, skipping", ticker);
                return false;
            }
            // SPDLOG_DEBUG("trying updating balance values of: {}", ticker);
            if (const auto res = this->match(this->index(0, 0), TickerRole, QString::fromStdString(ticker), 1, Qt::MatchFlag::MatchExactly); not res.isEmpty())
            {
                const auto&        mm2_system    = this->m_system_manager.get_system<mm2_service>();
                const auto*        global_cfg    = this->m_system_manager.get_system<portfolio_page>().get_global_cfg();
                const auto         coin          = global_cfg->get_coin_info(ticker);
                const auto&        price_service = this->m_system_manager.get_system<global_price_service>();
                const auto&        provider      = this->m_system_manager.get_system<komodo_prices_provider>();
                std::error_code    ec;
                const std::string& currency                     = m_config->current_currency;
                const std::string& fiat                         = m_config->current_fiat;
                const QModelIndex& idx                          = res.at(0);
                const QString      balance                      = QString::fromStdString(mm2_system.my_balance(ticker, ec));
                auto&& [prev_balance, new_balance, is_change_b] = update_value(BalanceRole, balance, idx, *this);
                const QString main_currency_balance_value       = QString::fromStdString(price_service.get_price_in_fiat(currency, ticker, ec));
                auto&& [_1, _2, is_change_mc]                   = update_value(MainCurrencyBalanceRole, main_currency_balance_value, idx, *this);
                const QString currency_price_for_one_unit       = QString::fromStdString(price_service.get_rate_conversion(currency, ticker, true));
                auto&& [_3, _4, is_change_mcpfo]                = update_value(MainCurrencyPriceForOneUnit, currency_price_for_one_unit, idx, *this);
                const QString currency_fiat_for_one_unit        = QString::fromStdString(price_service.get_rate_conversion(fiat, ticker, false));
                update_value(MainFiatPriceForOneUnit, currency_fiat_for_one_unit, idx, *this);
                const QString price_provider = QString::fromStdString(provider.get_price_provider(ticker));
                update_value(PriceProvider, price_provider, idx, *this);
                int last_price_timestamp = static_cast<int>(provider.get_last_price_timestamp(ticker));
                update_value(LastPriceTimestamp, last_price_timestamp, idx, *this);
                const QString display = QString::fromStdString(ticker) + " (" + balance + ")";
                update_value(Display, display, idx, *this);
                QString change24_h = retrieve_change_24h(provider, coin, *m_config, m_system_manager);
                update_value(Change24H, change24_h, idx, *this);
                if (is_change_b)
                {
                    balance_update_handler(prev_balance.toString(), new_balance.toString(), QString::fromStdString(ticker));
                }
                QJsonArray trend = nlohmann_json_array_to_qt_json_array(provider.get_ticker_historical(ticker));
                update_value(Trend7D, trend, idx, *this);
                auto        coin_info          = mm2_system.get_coin_info(ticker);
                QJsonObject status = nlohmann_json_object_to_qt_json_object(coin_info.activation_status);
                update_value(ActivationStatus, status, idx, *this);
                if (ticker == mm2_system.get_current_ticker() && (is_change_b || is_change_mc || is_change_mcpfo))
                {
                    m_system_manager.get_system<wallet_page>().refresh_ticker_infos();
                }
            }
        }
        return true;
    }

    QVariant
    atomic_dex::portfolio_model::data(const QModelIndex& index, int role) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()))
        {
            return {};
        }

        const portfolio_data& item = m_model_data.at(index.row());
        switch (static_cast<PortfolioRoles>(role))
        {
        case TickerRole:
            return item.ticker;
        case GuiTickerRole:
            return item.gui_ticker;
        case BalanceRole:
            return item.balance;
        case MainCurrencyBalanceRole:
            return item.main_currency_balance;
        case Change24H:
            return item.change_24h;
        case MainCurrencyPriceForOneUnit:
            return item.main_currency_price_for_one_unit;
        case MainFiatPriceForOneUnit:
            return item.main_fiat_price_for_one_unit;
        case NameRole:
            return item.name;
        case ActivationStatus:
            return item.activation_status;
        case Trend7D:
            return item.trend_7d;
        case Excluded:
            return item.is_excluded;
        case Display:
            return item.display;
        case NameAndTicker:
            return item.ticker_and_name;
        case MultiTickerCurrentlyEnabled:
            return item.is_multi_ticker_enabled;
        case MultiTickerData:
            return item.multi_ticker_data.has_value() ? item.multi_ticker_data.value() : QJsonObject{};
        case CoinType:
            return item.coin_type;
        case MultiTickerError:
            return static_cast<qint32>(item.multi_ticker_error.value_or(TradingError::None));
        case MultiTickerPrice:
            return item.multi_ticker_price.value_or("0");
        case MultiTickerReceiveAmount:
            return item.multi_ticker_receive_amount.value_or("0");
        case MultiTickerFeesInfo:
            return item.multi_ticker_fees_info.value_or(QJsonObject());
        case Address:
            return item.public_address;
        case PrivKey:
            return item.priv_key;
        case PercentMainCurrency:
            return item.percent_main_currency;
        case PriceProvider:
            return item.price_provider;
        case LastPriceTimestamp:
            return item.price_last_timestamp;
        }
        return {};
    }

    bool
    atomic_dex::portfolio_model::setData(const QModelIndex& index, const QVariant& value, int role)
    {
        if (!hasIndex(index.row(), index.column(), index.parent()) || !value.isValid())
        {
            return false;
        }

        portfolio_data& item = m_model_data[index.row()];
        switch (static_cast<PortfolioRoles>(role))
        {
        case CoinType:
            item.coin_type = value.toString();
            break;
        case BalanceRole:
            item.balance = value.toString();
            break;
        case MainCurrencyBalanceRole:
        {
            item.main_currency_balance = value.toString();
            break;
        }
        case Change24H:
            item.change_24h = value.toString();
            break;
        case MainCurrencyPriceForOneUnit:
            item.main_currency_price_for_one_unit = value.toString();
            break;
        case MainFiatPriceForOneUnit:
            item.main_fiat_price_for_one_unit = value.toString();
            break;
        case Trend7D:
            item.trend_7d = value.toJsonArray();
            break;
        case ActivationStatus:
            item.activation_status = value.toJsonObject();
            break;
        case Excluded:
            item.is_excluded = value.toBool();
            break;
        case Display:
            item.display = value.toString();
            break;
        case NameAndTicker:
            item.ticker_and_name = value.toString();
            break;
        case MultiTickerCurrentlyEnabled:
            if (item.is_multi_ticker_enabled != value.toBool())
            {
                item.is_multi_ticker_enabled = value.toBool();
                if (item.is_multi_ticker_enabled == true)
                {
                    this->m_dispatcher.trigger<multi_ticker_enabled>(item.ticker);
                }
            }
            break;
        case MultiTickerData:
            item.multi_ticker_data = QJsonObject::fromVariantMap(value.value<QVariantMap>());
            break;
        case MultiTickerError:
            item.multi_ticker_error = static_cast<TradingError>(value.toInt());
            break;
        case MultiTickerPrice:
        {
            item.multi_ticker_price = value.toString();
            // auto& trade_page        = m_system_manager.get_system<trading_page>();
            /*trade_page.get_orders_widget()->determine_multi_ticker_total_amount(
                item.ticker, item.multi_ticker_price.value(), item.is_multi_ticker_enabled, trade_page.get_market_pairs_mdl(), trade_page.get_market_mode(),
                trade_page.get_volume());*/
            break;
        }
        case MultiTickerReceiveAmount:
            item.multi_ticker_receive_amount = value.toString();
            break;
        case MultiTickerFeesInfo:
            item.multi_ticker_fees_info = QJsonObject::fromVariantMap(value.value<QVariantMap>());
            break;
        case Address:
            item.public_address = value.toString();
            break;
        case PrivKey:
            item.priv_key = value.toString();
            // emit dataChanged(index, index, {role});
            break;
        case PercentMainCurrency:
            item.percent_main_currency = value.toString();
            // emit dataChanged(index, index, {role});
            break;
        case PriceProvider:
            item.price_provider = value.toString();
            break;
        case LastPriceTimestamp:
            item.price_last_timestamp = value.toInt();
            break;
        default:
            return false;
        }

        emit dataChanged(index, index, {role});
        return true;
    }

    bool
    portfolio_model::removeRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginRemoveRows(QModelIndex(), position, position + rows - 1);
        for (int row = 0; row < rows; ++row)
        {
            this->m_ticker_registry.erase(this->m_model_data.at(position).ticker.toStdString());
            this->m_model_data.removeAt(position);
            emit lengthChanged();
        }
        endRemoveRows();

        return true;
    }

    QString
    portfolio_model::coin_balance(QString coin)
    {
        auto res = this->match(this->index(0, 0), TickerRole, coin, 1, Qt::MatchFlag::MatchExactly);
        // assert(not res.empty());
        if (not res.empty())
        {
            return QString(this->data(res.at(0), BalanceRole).toString());
        }
    }

    void
    portfolio_model::disable_coins(const QStringList& coins)
    {
        for (auto&& coin: coins)
        {
            auto res = this->match(this->index(0, 0), TickerRole, coin, 1, Qt::MatchFlag::MatchExactly);
            // assert(not res.empty());
            if (not res.empty())
            {
                this->removeRow(res.at(0).row());
            }
        }
    }

    int
    atomic_dex::portfolio_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return this->m_model_data.count();
    }

    QHash<int, QByteArray>
    portfolio_model::roleNames() const
    {
        return {
            {TickerRole, "ticker"},
            {GuiTickerRole, "gui_ticker"},
            {CoinType, "type"},
            {NameRole, "name"},
            {BalanceRole, "balance"},
            {MainCurrencyBalanceRole, "main_currency_balance"},
            {Change24H, "change_24h"},
            {MainCurrencyPriceForOneUnit, "main_currency_price_for_one_unit"},
            {MainFiatPriceForOneUnit, "main_fiat_price_for_one_unit"},
            {Trend7D, "trend_7d"},
            {ActivationStatus, "activation_status"},
            {Excluded, "excluded"},
            {Display, "display"},
            {NameAndTicker, "name_and_ticker"},
            {MultiTickerCurrentlyEnabled, "is_multi_ticker_currently_enabled"},
            {MultiTickerData, "multi_ticker_data"},
            {MultiTickerPrice, "multi_ticker_price"},
            {MultiTickerError, "multi_ticker_error"},
            {MultiTickerReceiveAmount, "multi_ticker_receive_amount"},
            {MultiTickerFeesInfo, "multi_ticker_fees_info"},
            {Address, "public_address"},
            {PrivKey, "priv_key"},
            {PercentMainCurrency, "percent_main_currency"},
            {LastPriceTimestamp, "lastPriceTimestamp"},
            {PriceProvider, "priceProvider"}};
    }

    portfolio_proxy_model*
    atomic_dex::portfolio_model::get_portfolio_proxy_mdl() const
    {
        return m_model_proxy;
    }

    portfolio_proxy_model*
    portfolio_model::get_pie_char_proxy_mdl() const
    {
        return m_pie_chart_proxy_model;
    }

    int
    portfolio_model::get_length() const
    {
        return this->rowCount(QModelIndex());
    }

    void
    portfolio_model::set_cfg(cfg& cfg)
    {
        m_config = &cfg;
    }

    void
    portfolio_model::reset()
    {
        this->m_ticker_registry.clear();
        this->beginResetModel();
        this->m_model_data.clear();
        this->endResetModel();
    }

    portfolio_model::t_portfolio_datas
    portfolio_model::get_underlying_data() const
    {
        return m_model_data;
    }

    void
    portfolio_model::clean_priv_keys()
    {
        const auto coins = this->m_system_manager.get_system<portfolio_page>().get_global_cfg()->get_enabled_coins();
        for (auto&& [coin, cfg]: coins)
        {
            auto res = this->match(this->index(0, 0), TickerRole, QString::fromStdString(coin), 1, Qt::MatchFlag::MatchExactly);
            // assert(not res.empty());
            if (not res.empty())
            {
                update_value(PortfolioRoles::PrivKey, "", res.at(0), *this);
            }
        }
    }
} // namespace atomic_dex

namespace atomic_dex
{
    void
    portfolio_model::balance_update_handler(const QString& prev_balance, const QString& new_balance, const QString& ticker)
    {
        using namespace std::chrono;
        t_float_50 prev_balance_f = safe_float(prev_balance.toStdString());
        t_float_50 new_balance_f  = safe_float(new_balance.toStdString());
        bool       am_i_sender    = false;
        if (prev_balance_f > new_balance_f)
        {
            am_i_sender = true;
        }
        t_float_50 amount_f   = am_i_sender ? prev_balance_f - new_balance_f : new_balance_f - prev_balance_f;
        QString    amount     = QString::fromStdString(amount_f.str(8, std::ios_base::fixed));
        qint64     timestamp  = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        QString    human_date = QString::fromStdString(utils::to_human_date<std::chrono::seconds>(timestamp, "%e %b %Y, %H:%M"));
        // Logs showed `balance update notification: am_i_sender: false amount: 0.00000000 ticker: USDT-SLP` sometimes, just before a crash.
        // This is a temporary fix to see if it prevents the crash.
        if (amount_f > 0.0)
        {
            this->m_dispatcher.trigger<balance_update_notification>(am_i_sender, amount, ticker, human_date, timestamp);
        }
        emit portfolioItemDataChanged();
    }

    void
    portfolio_model::adjust_percent_current_currency(QString balance_all)
    {
        // SPDLOG_INFO("adjust_percent_current_currency");
        const auto coins = this->m_system_manager.get_system<portfolio_page>().get_global_cfg()->get_enabled_coins();
        for (auto&& [coin, cfg]: coins)
        {
            auto res = this->match(this->index(0, 0), TickerRole, QString::fromStdString(coin), 1, Qt::MatchFlag::MatchExactly);
            // assert(not res.empty());
            if (not res.empty())
            {
                t_float_50 balance_all_f         = safe_float(balance_all.toStdString());
                t_float_50 main_currency_balance = safe_float(this->data(res.at(0), MainCurrencyBalanceRole).toString().toStdString());
                if (balance_all_f > 0 && main_currency_balance > 0)
                {
                    t_float_50 res_f   = (100 * main_currency_balance) / balance_all_f;
                    auto       percent = QString::fromStdString(res_f.str(2, std::ios::fixed));
                    update_value(PortfolioRoles::PercentMainCurrency, percent, res.at(0), *this);
                }
                // update_value(PortfolioRoles::PrivKey, "", res.at(0), *this);
            }
        }
    }
} // namespace atomic_dex
