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

//! Qt
#include <QAbstractListModel>

//! Absl
// TODO: When absl fix std::result_of switch to flat_hash_map
#include <unordered_map>
//#include <absl/container/flat_hash_map.h>

//! Deps
#include <entt/core/attribute.h>
#include <entt/entity/registry.hpp>

//! Project Headers
#include "atomicdex/config/coins.cfg.hpp"
#include "atomicdex/models/qt.global.coins.cfg.proxy.filter.model.hpp"

namespace atomic_dex
{
    class ENTT_API global_coins_cfg_model final : public QAbstractListModel
    {
        // Tells QT this class uses signal/slots mechanisms and/or has GUI elements.
        Q_OBJECT

        using t_enabled_coins_registry = std::unordered_map<std::string, coin_config>;

      public:
        // Available Qt roles.
        enum CoinsRoles
        {
            TickerRole = Qt::UserRole + 1,
            GuiTickerRole,
            NameRole,
            TickerAndNameRole,
            IsClaimable,
            CurrentlyEnabled,
            Active,
            IsCustomCoin,
            Type,
            CoinType,
            Checked,
            ActivationStatus
        };
        Q_ENUMS(CoinsRoles)

        // Constructor/Destructor
        explicit global_coins_cfg_model(entt::registry& entity_registry, QObject* parent = nullptr);
        ~global_coins_cfg_model() final = default;

        void initialize_model(std::vector<coin_config> cfg);

        template <typename TArray>
        void update_status(const TArray& tickers, bool status);

        // QAbstractListModel functions
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role) const final;
        bool                                 setData(const QModelIndex& index, const QVariant& value, int role) final;
        [[nodiscard]] int                    rowCount(const QModelIndex& parent = QModelIndex()) const final;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const final;

        // Getters/Setters
        [[nodiscard]] const std::vector<coin_config>& get_model_data() const;
        [[nodiscard]] coin_config                     get_coin_info(const std::string& ticker) const;
        [[nodiscard]] t_enabled_coins_registry        get_enabled_coins() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_disabled_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_qrc20_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_erc20_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_ewt_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_bep20_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_smartchains_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_utxo_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_slp_proxy() const;
        [[nodiscard]] global_coins_cfg_proxy_model*   get_all_zhtlc_proxy() const;
        [[nodiscard]] int                             get_length() const;
        [[nodiscard]] int                             get_checked_nb() const;
        void                                          set_checked_nb(int value);
        [[nodiscard]] const QStringList&              get_all_coin_types() const;

        // QML API functions
        [[nodiscard]] Q_INVOKABLE QStringList get_checked_coins() const;
        [[nodiscard]] Q_INVOKABLE QVariant    get_coin_info(const QString& ticker) const;
        [[nodiscard]] Q_INVOKABLE QString     get_parent_coin(const QString& ticker) const;
        [[nodiscard]] Q_INVOKABLE bool        is_coin_type(const QString& ticker) const;      // Tells if the given string is a valid coin type (e.g. QRC-20)

        // QML API properties
        Q_PROPERTY(global_coins_cfg_proxy_model* all_disabled_proxy    READ get_all_disabled_proxy    NOTIFY all_disabled_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_proxy             READ get_all_proxy             NOTIFY all_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_qrc20_proxy       READ get_all_qrc20_proxy       NOTIFY all_qrc20_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_erc20_proxy       READ get_all_erc20_proxy       NOTIFY all_erc20_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_ewt_proxy         READ get_all_ewt_proxy         NOTIFY all_ewt_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_bep20_proxy       READ get_all_bep20_proxy       NOTIFY all_bep20_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_smartchains_proxy READ get_all_smartchains_proxy NOTIFY all_smartchains_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_utxo_proxy        READ get_all_utxo_proxy        NOTIFY all_utxo_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_slp_proxy         READ get_all_slp_proxy         NOTIFY all_slp_proxyChanged)
        Q_PROPERTY(global_coins_cfg_proxy_model* all_zhtlc_proxy       READ get_all_zhtlc_proxy       NOTIFY all_zhtlc_proxyChanged)
        Q_PROPERTY(int                           length                READ get_length                NOTIFY lengthChanged)
        Q_PROPERTY(int                           checked_nb            READ get_checked_nb            WRITE set_checked_nb NOTIFY checked_nbChanged)
        Q_PROPERTY(QStringList                   all_coin_types        READ get_all_coin_types)

        // QML API properties signals
      signals:
        void all_disabled_proxyChanged();
        void all_proxyChanged();
        void all_qrc20_proxyChanged();
        void all_erc20_proxyChanged();
        void all_ewt_proxyChanged();
        void all_bep20_proxyChanged();
        void all_smartchains_proxyChanged();
        void all_utxo_proxyChanged();
        void all_slp_proxyChanged();
        void all_zhtlc_proxyChanged();
        void lengthChanged();
        void checked_nbChanged();

      private:
        std::vector<coin_config> m_model_data;    // Contains all the data
        t_enabled_coins_registry m_enabled_coins; // Currently enabled_coins

        std::array<global_coins_cfg_proxy_model*, ::CoinType::Size> m_proxies;

        int m_checked_nb{0}; // Number of coins that are currently checked

        QStringList m_all_coin_types; // Contains every supported coin type (e.g. UTXO, SmartChain)

        entt::registry& m_entity_registry;
    };
} // namespace atomic_dex
