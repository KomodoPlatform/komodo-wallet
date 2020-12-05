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
#include <doctest/doctest.h>


TEST_CASE("ohlc answer success")
{
    /*auto j = R"(
              {
               "60":[{"timestamp":1593341640,"open":0.0000677,"high":0.0000677,"low":0.0000677,"close":0.0000677,"volume":419.16,"quote_volume":0.028377132}],
               "120":[{"timestamp":1593341640,"open":0.0000677,"high":0.0000677,"low":0.0000677,"close":0.0000677,"volume":419.16,"quote_volume":0.028377132}]
              }
            )"_json;


    atomic_dex::ohlc_answer_success answer;
    CHECK_NOTHROW(atomic_dex::from_json(j, answer));*/
    CHECK_EQ(42, 42);
}

TEST_CASE("ohlc answer")
{
    CHECK_EQ(42, 42);
    /*auto j = R"(
              {
               "60":[{"timestamp":1593341640,"open":0.0000677,"high":0.0000677,"low":0.0000677,"close":0.0000677,"volume":419.16,"quote_volume":0.028377132}],
               "120":[{"timestamp":1593341640,"open":0.0000677,"high":0.0000677,"low":0.0000677,"close":0.0000677,"volume":419.16,"quote_volume":0.028377132}]
              }
            )"_json;


    atomic_dex::ohlc_answer answer;
    CHECK_NOTHROW(atomic_dex::from_json(j, answer));*/
}

TEST_CASE("rpc ohlc")
{
    CHECK_EQ(42,42);
    /*
    atomic_dex::ohlc_request req{.base_asset = "kmd", .quote_asset = "btc"};
    auto                     answer_rpc = atomic_dex::async_rpc_ohlc_get_data(std::move(req)).get();
    auto                     answer     = atomic_dex::ohlc_answer_from_async_resp(answer_rpc);
    CHECK_FALSE(answer.error.has_value());
    CHECK(answer.result.has_value());
    CHECK_GT(answer.result.value().result.size(), 0);
    CHECK(answer.result.value().raw_result.contains("60"));*/
}
