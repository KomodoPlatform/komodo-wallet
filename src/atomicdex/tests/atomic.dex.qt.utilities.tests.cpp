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

//! Deps
/*#include <nlohmann/json.hpp>

#include "src/atomicdex/pch.hpp"
#include "src/atomicdex/utilities/qt.utilities.hpp"*/
#include <doctest/doctest.h>

TEST_CASE("simple ping")
{
    CHECK(42 == 42);
    //CHECK(atomic_dex::am_i_able_to_reach_this_endpoint("www.google.com"));
    //WARN(atomic_dex::am_i_able_to_reach_this_endpoint("8.8.8.8"));
}
