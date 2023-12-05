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

//! STD
#include <unordered_set>

#include "atomicdex/config/app.cfg.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"

namespace atomic_dex
{
    class global_price_service final : public ag::ecs::pre_update_system<global_price_service>
    {
        using t_supported_fiat_registry = std::unordered_set<std::string>;
        using t_json_synchronized       = boost::synchronized_value<nlohmann::json>;
        using t_providers_registry      = std::unordered_map<std::string, std::string>;
        using t_update_time_point       = std::chrono::high_resolution_clock::time_point;

        ag::ecs::system_manager&  m_system_manager;
        atomic_dex::cfg&          m_cfg;
        t_supported_fiat_registry m_supported_fiat_registry{"USD", "EUR", "BTC", "KMD", "GBP", "HKD", "IDR", "ILS", "DKK", "INR", "CHF", "MXN",
                                                            "CZK", "SGD", "THB", "HRK", "MYR", "NOK", "CNY", "BGN", "PHP", "PLN", "ZAR", "CAD",
                                                            "ISK", "BRL", "RON", "NZD", "TRY", "JPY", "RUB", "KRW", "AUD", "HUF", "SEK", "LTC", "DOGE"};
        t_providers_registry      m_coin_rate_providers{};
        t_json_synchronized       m_other_fiats_rates;
        t_update_time_point       m_update_clock;
        mutable std::shared_mutex m_coin_rate_mutex;

        void refresh_other_coins_rates(const std::string& quote_id, const std::string& ticker, bool with_update_providers = false, std::atomic_uint16_t idx = 0);

      public:
        explicit global_price_service(entt::registry& registry, ag::ecs::system_manager& system_manager, atomic_dex::cfg& cfg);
        ~global_price_service()  final = default;

        //! Public override
        void update()  final;

        //! Public API
        std::string get_price_as_currency_from_tx(const std::string& currency, const std::string& ticker, const tx_infos& tx) const ;
        std::string get_price_in_fiat(const std::string& fiat, const std::string& ticker, std::error_code& ec, bool skip_precision = false) const ;
        std::string get_price_in_fiat_all(const std::string& fiat, std::error_code& ec) const ;
        std::string get_rate_conversion(const std::string& fiat, const std::string& ticker, bool adjusted = false) const ;
        std::string get_price_as_currency_from_amount(const std::string& currency, const std::string& ticker, const std::string& amount) const ;
        std::string get_cex_rates(const std::string& base, const std::string& rel) const;
        std::string get_fiat_rates(const std::string& fiat) const;
        std::string get_currency_rates(const std::string& currency) const;

        bool is_fiat_available(const std::string& fiat) const;
        bool is_currency_available(const std::string& currency) const;

        //! Events
        void on_force_update_providers([[maybe_unused]] const force_update_providers& evt);
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::global_price_service))
