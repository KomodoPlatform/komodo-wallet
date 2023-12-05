/******************************************************************************
 * Copyright © 2013-2022 The Komodo Platform Developers.                      *
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

//! Qt Headers
#include <QJsonArray>
#include <QJsonObject>
#include <QSettings>

//! Project Headers
#include "atomicdex/models/qt.global.coins.cfg.model.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

namespace
{
    QJsonObject
    to_qt_binding(const atomic_dex::coin_config& coin) 
    {
        QJsonObject j{
            {"active", coin.active},
            {"activation_status", atomic_dex::nlohmann_json_object_to_qt_json_object(coin.activation_status)},
            {"is_claimable", coin.is_claimable},
            {"minimal_balance_for_asking_rewards", QString::fromStdString(coin.minimal_claim_amount)},
            {"ticker", QString::fromStdString(coin.ticker)},
            {"name", QString::fromStdString(coin.name)},
            {"type", QString::fromStdString(coin.type)},
            {"livecoinwatch_id", QString::fromStdString(coin.livecoinwatch_id)},
            {"explorer_url", QString::fromStdString(coin.explorer_url)},
            {"tx_uri", QString::fromStdString(coin.tx_uri)},
            {"address_uri", QString::fromStdString(coin.address_url)},
            {"is_custom_coin", coin.is_custom_coin},
            {"is_enabled", coin.currently_enabled},
            {"has_parent_fees_ticker", coin.has_parent_fees_ticker},
            {"is_testnet", coin.is_testnet.value_or(false)},
            {"is_erc_family", coin.is_erc_family},
            {"is_zhtlc_family", coin.is_zhtlc_family},
            {"is_wallet_only", coin.wallet_only},
            {"checkpoint_height", coin.checkpoint_height},
            {"checkpoint_blocktime", coin.checkpoint_blocktime},
            {"has_memos", coin.has_memos},
            {"fees_ticker", QString::fromStdString(coin.fees_ticker)}};
        return j;
    }
} // namespace

//! Constructor
namespace atomic_dex
{
    global_coins_cfg_model::global_coins_cfg_model(entt::registry& entity_registry, QObject* parent) :
        QAbstractListModel(parent), m_entity_registry(entity_registry)
    {
        for (int i = 0; i < CoinType::Size; ++i)
        {
            m_proxies[i] = new global_coins_cfg_proxy_model(this, static_cast<::CoinType>(i));
            m_proxies[i]->setSourceModel(this);
            m_proxies[i]->setDynamicSortFilter(true);
            m_proxies[i]->setFilterRole(CoinsRoles::TickerAndNameRole);
            m_proxies[i]->setFilterCaseSensitivity(Qt::CaseInsensitive);
            m_proxies[i]->setSortRole(CoinsRoles::NameRole);

            m_proxies[i]->sort(0);
        }
    }
} // namespace atomic_dex

//! QAbstractListModel functions
namespace atomic_dex
{
    QVariant
    global_coins_cfg_model::data(const QModelIndex& index, int role) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()))
        {
            return {};
        }

        const coin_config& item = m_model_data.at(index.row());
        switch (static_cast<CoinsRoles>(role))
        {
        case TickerRole:
            return QString::fromStdString(item.ticker);
        case GuiTickerRole:
            return QString::fromStdString(item.gui_ticker);
        case NameRole:
            return QString::fromStdString(item.name);
        case IsClaimable:
            return item.is_claimable;
        case CurrentlyEnabled:
            return item.currently_enabled;
        case Active:
            return item.active;
        case ActivationStatus:
            return atomic_dex::nlohmann_json_object_to_qt_json_object(item.activation_status);
        case IsCustomCoin:
            return item.is_custom_coin;
        case Type:
            return QString::fromStdString(item.type);
        case CoinType:
            return static_cast<int>(item.coin_type);
        case TickerAndNameRole:
            return QString::fromStdString(item.ticker) + QString::fromStdString(item.name) + QString::fromStdString(item.type); ///! ETHethereumERC-20
        case Checked:
            return item.checked;
        }
        return {};
    }

    bool
    global_coins_cfg_model::setData(const QModelIndex& index, const QVariant& value, int role)
    {
        coin_config& item = m_model_data[index.row()];
        switch (static_cast<CoinsRoles>(role))
        {
        case CurrentlyEnabled:
            if (auto res = value.toBool(); item.currently_enabled != res)
            {
                item.currently_enabled = res;
                if (!item.currently_enabled)
                {
                    m_enabled_coins.erase(item.ticker);
                }
                else
                {
                    m_enabled_coins[item.ticker] = item;
                }
            }
            break;
        case Active:
            item.active = value.toBool();
            break;
        case Checked:
        {
            auto real_value = value.toBool();
            if (item.checked == real_value)
            {
                return false;
            }
            if (real_value)
            {
                auto enableable_coins_count = m_entity_registry.ctx<QSettings>().value("MaximumNbCoinsEnabled").toULongLong();
                if (enableable_coins_count <= get_enabled_coins().size() + m_checked_nb)
                {
                    return false;
                }
                item.checked = real_value;
                m_checked_nb++;
            }
            else
            {
                item.checked = real_value;
                m_checked_nb--;
            }
            emit checked_nbChanged();
            break;
        }
        default:
            return false;
        }

        emit dataChanged(index, index, {role});
        emit get_all_disabled_proxy()->lengthChanged();
        return true;
    }

    int
    global_coins_cfg_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return m_model_data.size();
    }

    QHash<int, QByteArray>
    global_coins_cfg_model::roleNames() const
    {
        return {{TickerRole, "ticker"}, {GuiTickerRole, "gui_ticker"},    {NameRole, "name"}, {IsClaimable, "is_claimable"}, {CurrentlyEnabled, "enabled"},
                {Active, "active"},     {IsCustomCoin, "is_custom_coin"}, {Type, "type"},     {Checked, "checked"}};
    }
} // namespace atomic_dex

//! Others
namespace atomic_dex
{
    void
    global_coins_cfg_model::initialize_model(std::vector<coin_config> cfg) 
    {
        m_enabled_coins.clear();
        m_all_coin_types.clear();
        for (auto&& cur: cfg)
        {
            // If a new coin type is detected, push the type to `m_all_coin_types` member.
            if (auto type = QString::fromStdString(cur.type); !m_all_coin_types.contains(type))
            {
                m_all_coin_types.push_back(type);
            }

            if (cur.currently_enabled)
            {
                m_enabled_coins[cur.ticker] = cur;
            }
        }
        cfg.push_back(coin_config{.ticker = "All", .active = true, .currently_enabled = true});
        SPDLOG_INFO("Initializing global coin cfg model with size {}", cfg.size());
        set_checked_nb(0);
        beginResetModel();
        m_model_data = std::move(cfg);
        endResetModel();
        emit lengthChanged();
        emit get_all_disabled_proxy()->lengthChanged();
    }

    template <typename TArray>
    void global_coins_cfg_model::update_status(const TArray& tickers, bool status)
    {
        auto update_functor = [this, status](QModelIndexList res, [[maybe_unused]] const QString& ticker) {
            // SPDLOG_INFO("Changing Active/CurrentlyEnabled status to {} for ticker {}", status, ticker.toStdString());
            const QModelIndex& idx = res.at(0);
            update_value(Active, status, idx, *this);
            update_value(CurrentlyEnabled, status, idx, *this);
        };

        for (auto&& ticker: tickers)
        {
            QString final_ticker = "";

            if constexpr (std::is_same_v<std::string, std::decay_t<decltype(ticker)>>)
            {
                final_ticker = QString::fromStdString(ticker);
            }
            else if constexpr (std::is_same_v<QString, std::decay_t<decltype(ticker)>>)
            {
                final_ticker = ticker;
            }

            if (const auto res = this->match(this->index(0, 0), TickerRole, final_ticker, 1, Qt::MatchFlag::MatchExactly); not res.isEmpty())
            {
                update_functor(res, final_ticker);
            }
        }
    }

    template void global_coins_cfg_model::update_status(const QStringList&, bool);
    template void global_coins_cfg_model::update_status(const std::vector<std::string>&, bool);
} // namespace atomic_dex

//! QML API
namespace atomic_dex
{
    QStringList
    global_coins_cfg_model::get_checked_coins() const 
    {
        QStringList result;

        for (auto&& coin_cfg: m_model_data)
        {
            if (coin_cfg.checked)
            {
                result.push_back(QString::fromStdString(coin_cfg.ticker));
            }
        }
        return result;
    }

    QVariant
    global_coins_cfg_model::get_coin_info(const QString& ticker) const 
    {
        return to_qt_binding(get_coin_info(ticker.toStdString()));
    }

    bool
    global_coins_cfg_model::is_coin_type(const QString& ticker) const 
    {
        return get_all_coin_types().contains(ticker);
    }
} // namespace atomic_dex

//! Getters/Setters
namespace atomic_dex
{
    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_disabled_proxy() const 
    {
        return m_proxies[CoinType::Disabled];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_proxy() const 
    {
        return m_proxies[CoinType::All];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_qrc20_proxy() const 
    {
        return m_proxies[CoinType::QRC20];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_erc20_proxy() const 
    {
        return m_proxies[CoinType::ERC20];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_ewt_proxy() const
    {
        return m_proxies[CoinType::EWT];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_bep20_proxy() const
    {
        return m_proxies[CoinType::BEP20];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_smartchains_proxy() const 
    {
        return m_proxies[CoinType::SmartChain];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_utxo_proxy() const 
    {
        return m_proxies[CoinType::UTXO];
    }


    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_slp_proxy() const
    {
        return m_proxies[CoinType::SLP];
    }

    global_coins_cfg_proxy_model*
    global_coins_cfg_model::get_all_zhtlc_proxy() const
    {
        return m_proxies[CoinType::ZHTLC];
    }

    int
    global_coins_cfg_model::get_length() const 
    {
        return rowCount();
    }

    int
    global_coins_cfg_model::get_checked_nb() const 
    {
        return m_checked_nb;
    }

    void
    global_coins_cfg_model::set_checked_nb(int value) 
    {
        if (value == m_checked_nb)
        {
            return;
        }
        m_checked_nb = value;
        emit checked_nbChanged();
    }

    const QStringList&
    global_coins_cfg_model::get_all_coin_types() const 
    {
        return m_all_coin_types;
    }

    const std::vector<coin_config>&
    global_coins_cfg_model::get_model_data() const 
    {
        return m_model_data;
    }

    coin_config
    global_coins_cfg_model::get_coin_info(const std::string& ticker) const 
    {
        if (const auto res = this->match(this->index(0, 0), TickerRole, QString::fromStdString(ticker), 1, Qt::MatchFlag::MatchExactly); not res.isEmpty())
        {
            const QModelIndex& idx  = res.at(0);
            const coin_config& item = m_model_data.at(idx.row());
            return item;
        }
        return {};
    }

    global_coins_cfg_model::t_enabled_coins_registry
    global_coins_cfg_model::get_enabled_coins() const 
    {
        return m_enabled_coins;
    }

    QString
    global_coins_cfg_model::get_parent_coin(const QString& ticker) const
    {
        auto cfg = get_coin_info(ticker.toStdString());
        return QString::fromStdString(cfg.fees_ticker);
    }
} // namespace atomic_dex
