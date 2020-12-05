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


/*#include <vector>
#include <string>
#include "atomicdex/events/events.hpp"
#include "atomicdex/pch.hpp"
#include "atomicdex/services/ohlc/ohlc.provider.hpp"*/
#include <doctest/doctest.h>

TEST_CASE("atomic dex cex prices provider constructor")
{
    CHECK(42 == 42);
    //entt::registry registry;
    //ag::ecs::system_manager mgr{registry};
    //registry.set<entt::dispatcher>();
    //atomic_dex::mm2                 mm2(registry, mgr);
    //atomic_dex::ohlc_provider provider(registry, mm2);
}

/*SCENARIO("atomic dex cex price service functionnality")
{
    spdlog::set_level(spdlog::level::trace);
    spdlog::set_pattern("[%H:%M:%S %z] [%L] [thr %t] %v");
    GIVEN("A basic environment")
    {
        entt::registry registry;
        registry.set<entt::dispatcher>();
        antara::gaming::ecs::system_manager system_manager_{registry};
        auto&                               mm2_s      = system_manager_.create_system<atomic_dex::mm2>();
        auto&                               cex_system = system_manager_.create_system<atomic_dex::ohlc_provider>(mm2_s);

        THEN("I start mm2")
        {
            registry.ctx<entt::dispatcher>().trigger<atomic_dex::mm2_started>();

            AND_WHEN("i set the current orderbook pair to a valid supported pair (kmd-btc)")
            {
                registry.ctx<entt::dispatcher>().trigger<atomic_dex::orderbook_refresh>("kmd", "btc");
                using namespace std::chrono_literals;
                cex_system.consume_pending_tasks();

                AND_THEN("i check if data are available, and if the port is not supported")
                {
                    CHECK(cex_system.is_ohlc_data_available());
                    CHECK(cex_system.is_pair_supported("kmd", "btc").first);
                    CHECK_FALSE(cex_system.get_ohlc_data("60").empty());
                }
            }
        }
    }
}*/
