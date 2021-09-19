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

//! Deps
#include <antara/gaming/ecs/system.hpp>
#include <boost/thread/synchronized_value.hpp>
#include <nlohmann/json_fwd.hpp>

//! Project Headers
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

namespace atomic_dex
{
    struct smartfi_data
    {
        t_float_50 last;
        t_float_50 lowest_ask;
        t_float_50 heighest_bid;
    };

    struct smartfi_result
    {
        std::unordered_map<std::string, smartfi_data> smartfi_data;
    };

    void from_json(const nlohmann::json& j, smartfi_result& result);
} // namespace atomic_dex

namespace atomic_dex
{
    class smartfi_price_service final : public ag::ecs::pre_update_system<smartfi_price_service>
    {
        using t_update_time_point          = std::chrono::high_resolution_clock::time_point;
        using t_smartfi_price_synchronized = boost::synchronized_value<smartfi_result>;

        t_update_time_point          m_update_clock;
        t_smartfi_price_synchronized m_smartfi_price_result;

        void                                 fetch_price() noexcept;
        pplx::task<web::http::http_response> async_fetch_price_result() noexcept;

      public:
        explicit smartfi_price_service(entt::registry& registry);
        ~smartfi_price_service() noexcept final = default;

        void update() noexcept final;

        //!
        std::string retrieve_if_this_ticker_supported(const std::string& ticker) const noexcept;
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::smartfi_price_service))