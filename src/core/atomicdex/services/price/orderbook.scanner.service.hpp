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
#include <antara/gaming/ecs/system.manager.hpp>
#include <boost/thread/synchronized_value.hpp>
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/api/mm2/rpc2.best.orders.hpp"

//! Namespace declaration
namespace atomic_dex
{
    //! Class declaration
    class orderbook_scanner_service final : public ag::ecs::pre_update_system<orderbook_scanner_service>
    {
        //! Private typedefs
        using t_update_time_point        = std::chrono::high_resolution_clock::time_point;
        using t_best_orders_synchronized = boost::synchronized_value<t_best_orders_answer_success>;

        //! Private member fields
        ag::ecs::system_manager&   m_system_manager;
        t_best_orders_synchronized m_best_orders_infos;
        t_update_time_point        m_update_clock;
        std::atomic_bool           m_bestorders_rpc_busy{false};
        std::atomic_bool           m_orderbook_rpc_busy{false};

      public:
        //! Constructor
        explicit orderbook_scanner_service(entt::registry& registry, ag::ecs::system_manager& system_manager);

        //! Destructor
        ~orderbook_scanner_service()  final = default;

        //! Public override
        void update()  final;

        //! Public functions
        void process_best_orders() ;

        [[nodiscard]] bool is_best_orders_busy() const;
        [[nodiscard]] bool is_orderbook_busy() const;

        [[nodiscard]] t_orders_contents get_bestorders_data() const;
    };
} // namespace atomic_dex

REFL_AUTO(type(atomic_dex::orderbook_scanner_service))
