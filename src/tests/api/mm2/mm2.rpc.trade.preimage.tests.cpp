//
// Created by Roman Szterg on 13/02/2021.
//

#include "atomicdex/pch.hpp"

//! STD
#include <iostream>

//! Deps
#include "doctest/doctest.h"
#include <nlohmann/json.hpp>

//! Tests
#include "../../atomic.dex.tests.hpp"

//! Project Headers
#include "atomicdex/api/mm2/mm2.hpp"
#include "atomicdex/api/mm2/rpc.trade.preimage.hpp"

//! Constants
namespace
{
    const nlohmann::json g_preimage_request_buy_kmd_btc = R"(
                                    {
                                        "base": "KMD",
                                        "rel": "BTC",
                                        "swap_method": "buy",
                                        "volume": "10"
                                    }
                                    )"_json;
    const nlohmann::json g_coin_fee_answer              = R"(
                                    {
                                        "amount":"0.00042049",
                                        "amount_fraction":{
                                            "denom":"100000000",
                                            "numer":"42049"
                                          },
                                        "amount_rat":[[1,[42049]],[1,[100000000]]],
                                        "coin":"BTC"
                                    }
                                    )"_json;
    const nlohmann::json g_preimage_answer_success_buy  = R"(
                                     {
                                        "base_coin_fee": {
                                          "amount":"0",
                                          "amount_fraction":{
                                            "denom":"1",
                                            "numer":"0"
                                          },
                                          "amount_rat":[[0,[]],[1,[1]]],
                                          "coin":"BTC"
                                        },
                                        "rel_coin_fee": {
                                          "amount":"0.0001",
                                          "amount_fraction":{
                                            "denom":"10000",
                                            "numer":"1"
                                          },
                                          "amount_rat":[[1,[1]],[1,[10000]]],
                                          "coin":"DOC"
                                        },
                                         "taker_fee": {
                                           "coin": "MYCOIN1",
                                           "amount": "0.02",
                                           "amount_fraction": { "numer": "1", "denom": "7770" }
                                        },
                                        "fee_to_send_taker_fee":{
                                          "amount":"0.0001",
                                          "amount_fraction":{
                                            "denom":"10000",
                                            "numer":"1"
                                          },
                                          "amount_rat":[[1,[1]],[1,[10000]]],
                                          "coin":"DOC"
                                        }
                                    }
                                    )"_json;
    const nlohmann::json g_preimage_answer_setprice     = R"(
                                     {
                                        "result":{
                                            "base_coin_fee": {
                                              "amount":"0.00042049",
                                              "amount_fraction":{
                                                "denom":"100000000",
                                                "numer":"42049"
                                              },
                                              "amount_rat":[[1,[42049]],[1,[100000000]]],
                                              "coin":"BTC"
                                            },
                                            "rel_coin_fee": {
                                              "amount":"0",
                                              "amount_fraction":{
                                                "denom":"1",
                                                "numer":"0"
                                              },
                                              "amount_rat":[[0,[]],[1,[1]]],
                                              "coin":"DOC"
                                            }
                                          }
                                    }
                                    )"_json;
    const nlohmann::json g_preimage_answer_buy          = R"(
                                    {
                                      "result":{
                                        "base_coin_fee": {
                                          "amount":"0",
                                          "amount_fraction":{
                                            "denom":"1",
                                            "numer":"0"
                                          },
                                          "amount_rat":[[0,[]],[1,[1]]],
                                          "coin":"BTC"
                                        },
                                        "rel_coin_fee": {
                                          "amount":"0.0001",
                                          "amount_fraction":{
                                            "denom":"10000",
                                            "numer":"1"
                                          },
                                          "amount_rat":[[1,[1]],[1,[10000]]],
                                          "coin":"DOC"
                                        },
                                        "taker_fee": {
                                          "amount":"0.0001",
                                          "amount_fraction":{
                                            "denom":"10000",
                                            "numer":"1"
                                          },
                                          "amount_rat":[[1,[1]],[1,[10000]]],
                                          "coin":"DOC"
                                        },

                                        "fee_to_send_taker_fee":{
                                          "amount":"0.0001",
                                          "amount_fraction":{
                                            "denom":"10000",
                                            "numer":"1"
                                          },
                                          "amount_rat":[[1,[1]],[1,[10000]]],
                                          "coin":"DOC"
                                        }
                                      }
                                    }
                                    )"_json;
    const nlohmann::json g_preimage_answer_sell_max     = R"(
                                    {
                                      "result":{
                                        "base_coin_fee": {
                                          "amount":"0.00042049",
                                          "amount_fraction":{
                                            "denom":"100000000",
                                            "numer":"42049"
                                          },
                                          "amount_rat":[[1,[42049]],[1,[100000000]]],
                                          "coin":"BTC"
                                        },
                                        "rel_coin_fee": {
                                          "amount":"0",
                                          "amount_fraction":{
                                            "denom":"1",
                                            "numer":"0"
                                          },
                                          "amount_rat":[[0,[]],[1,[1]]],
                                          "coin":"DOC"
                                        },
                                        "volume":"2.21363478",
                                        "volume_fraction":{
                                          "denom":"50000000",
                                          "numer":"110681739"
                                        },
                                         "taker_fee": {
                                          "amount":"0",
                                          "amount_fraction":{
                                            "denom":"1",
                                            "numer":"0"
                                          },
                                          "amount_rat":[[0,[]],[1,[1]]],
                                          "coin":"DOC"
                                        },
                                        "fee_to_send_taker_fee":{
                                          "amount":"0.00033219",
                                          "amount_fraction":{
                                            "denom":"100000000",
                                            "numer":"33219"
                                          },
                                          "amount_rat":[[1,[33219]],[1,[100000000]]],
                                          "coin":"BTC"
                                        }
                                      }
                                    })"_json;

    const nlohmann::json g_preimage_answer_setprice_erc               = R"(
                                    {
                                      "result":{
                                        "base_coin_fee": {
                                          "amount":"0.0045",
                                          "amount_fraction":{
                                            "denom":"2000",
                                            "numer":"9"
                                          },
                                          "amount_rat":[[1,[9]],[1,[2000]]],
                                          "coin":"ETH"
                                        },
                                        "rel_coin_fee": {
                                          "amount":"0",
                                          "amount_fraction":{
                                            "denom":"1",
                                            "numer":"0"
                                          },
                                          "amount_rat":[[0,[]],[1,[1]]],
                                          "coin":"DOC"
                                        }
                                      }
                                    })"_json;
    const nlohmann::json g_preimage_request_buy_DOC_MARTY_real       = R"(
                                    {
                                      "base": "DOC",
                                      "method": "trade_preimage",
                                      "rel": "MARTY",
                                      "swap_method": "buy",
                                      "userpass": "",
                                      "volume": "1",
                                      "price": "1"
                                    })"_json;
    const nlohmann::json g_preimage_request_buy_DOC_nonexistent_real = R"(
                                    {
                                      "base": "DOC",
                                      "method": "trade_preimage",
                                      "rel": "NONEXISTENT",
                                      "swap_method": "buy",
                                      "userpass": "",
                                      "volume": "1"
                                    })"_json;
} // namespace

TEST_CASE("atomic_dex::mm2::preimage_request serialisation")
{
    atomic_dex::t_trade_preimage_request request{.base_coin = "KMD", .rel_coin = "BTC", .swap_method = "buy", .volume = "10"};
    nlohmann::json                       j;
    atomic_dex::mm2::to_json(j, request);
    CHECK_EQ(j, g_preimage_request_buy_kmd_btc);
}

TEST_CASE("atomic_dex::mm2::coin_fee deserialization")
{
    atomic_dex::mm2::coin_fee answer;
    atomic_dex::mm2::from_json(g_coin_fee_answer, answer);
    CHECK_EQ("0.00042049", answer.amount);
    CHECK_EQ("BTC", answer.coin);
    CHECK_EQ("100000000", answer.amount_fraction.denom);
}

TEST_CASE("atomic_dex::mm2::preimage_answer_success deserialization from buy")
{
    atomic_dex::mm2::trade_preimage_answer_success answer;
    atomic_dex::mm2::from_json(g_preimage_answer_success_buy, answer);
    CHECK(answer.taker_fee.has_value());
    CHECK(answer.fee_to_send_taker_fee.has_value());
}

TEST_SUITE("atomic_dex::mm2::preimage_answer deserialization test suites")
{
    TEST_CASE("setprice BTC/DOC")
    {
        atomic_dex::t_trade_preimage_answer answer;
        atomic_dex::mm2::from_json(g_preimage_answer_setprice, answer);
        CHECK(answer.result.has_value());
        CHECK_FALSE(answer.error.has_value());
        CHECK_FALSE(answer.result.value().fee_to_send_taker_fee.has_value());
    }

    TEST_CASE("buy BTC/DOC")
    {
        atomic_dex::t_trade_preimage_answer answer;
        atomic_dex::mm2::from_json(g_preimage_answer_buy, answer);
        CHECK(answer.result.has_value());
        CHECK_FALSE(answer.error.has_value());
        CHECK(answer.result.value().fee_to_send_taker_fee.has_value());
    }

    TEST_CASE("sell max BTC/DOC")
    {
        atomic_dex::t_trade_preimage_answer answer;
        atomic_dex::mm2::from_json(g_preimage_answer_sell_max, answer);
        CHECK(answer.result.has_value());
        CHECK_FALSE(answer.error.has_value());
        CHECK(answer.result.value().fee_to_send_taker_fee.has_value());
    }

    TEST_CASE("setprice ERC20 BAT/DOC")
    {
        atomic_dex::t_trade_preimage_answer answer;
        atomic_dex::mm2::from_json(g_preimage_answer_setprice_erc, answer);
        CHECK(answer.result.has_value());
        CHECK_FALSE(answer.error.has_value());
        CHECK_FALSE(answer.result.value().fee_to_send_taker_fee.has_value());
        CHECK_EQ(answer.result.value().base_coin_fee.coin, "ETH");
    }
}

#if !defined(WIN32) && !defined(_WIN32)
/**
 * To add a new test file -> CMakeLists.txt -> line 338, add the sources at the good place
 * Recompile
 *
 * add the headers at the top of the file:
 *
 *
    #include "atomicdex/pch.hpp"

    //! STD
    #include <iostream>

    //! Deps
    #include "doctest/doctest.h"
    #include <nlohmann/json.hpp>

    //! Tests
    #include "atomicdex/tests/atomic.dex.tests.hpp"

    //! Project Headers
    #include "atomicdex/api/mm2/mm2.hpp"
    #include "atomicdex/api/mm2/rpc.trade.preimage.hpp" ///< replace this one by your current rpc file
 */
SCENARIO("atomic_dex::mm2::preimage scenario")
{
    /**
     * Checking that the test context is valid
     */
    CHECK(g_context != nullptr);

    //! Preparing Empty batch request
    nlohmann::json batch = nlohmann::json::array();
    CHECK(batch.is_array());

    //! Prepare request template
    nlohmann::json request_json = atomic_dex::mm2::template_request("trade_preimage");

    //! Retrieve mm2 service
    auto& mm2 = g_context->system_manager().get_system<atomic_dex::mm2_service>();

    //! Generic resp functor that will be used in every tests
    auto generic_resp_process = [&mm2, &batch]() {
        //! Process the actual request
        const auto resp = mm2.get_mm2_client().async_rpc_batch_standalone(batch).get();

        //! Retrieve the body
        std::string body = TO_STD_STR(resp.extract_string(true).get());

        //! Check the status code
        THEN("I expect the status code to be 200") { CHECK_EQ(resp.status_code(), 200); }

        //! Check if the body is non empty
        THEN("I expect the body to be non empty")
        {
            CHECK_FALSE(body.empty());

            //! Log the body in the test
            SPDLOG_INFO("resp: {}", body);
        }

        //! Parse body into JSON
        auto answers = nlohmann::json::parse(body);

        //! Clean the batch request
        batch.clear();
        CHECK(batch.empty());

        //! Give the concrete C++ type - here it's atomic_dex::t_trade_preimage_answer
        return atomic_dex::mm2::rpc_process_answer_batch<atomic_dex::t_trade_preimage_answer>(answers[0], "trade_preimage");
    };

    //! A test with DOC/MARTY
    GIVEN("Preparing a simple buy request DOC/MARTY")
    {
        //! Request values
        atomic_dex::t_trade_preimage_request request{.base_coin = "DOC", .rel_coin = "MARTY", .swap_method = "buy", .volume = "1", .price = "1"};

        //! Transform request into json
        atomic_dex::mm2::to_json(request_json, request);

        //! Add it to the batch request
        batch.push_back(request_json);

        //! Check request without userpass against a constants at the top of the file
        auto copy_request        = request_json;
        copy_request["userpass"] = "";
        CHECK_EQ(copy_request, g_preimage_request_buy_DOC_MARTY_real);

        //! A Test Case
        WHEN("I execute the request")
        {
            //! We call our generic functor here
            const atomic_dex::t_trade_preimage_answer answer = generic_resp_process();

            //! Differents assertion checks
            CHECK_FALSE(answer.error.has_value());
            CHECK(answer.result.has_value());
            CHECK(answer.result.value().fee_to_send_taker_fee.has_value());
            CHECK(answer.result.value().taker_fee.has_value());
        }
    }

    //! See above
    GIVEN("Preparing a wrong request DOC/NONEXISTENT coin")
    {
        atomic_dex::t_trade_preimage_request request{.base_coin = "DOC", .rel_coin = "NONEXISTENT", .swap_method = "buy", .volume = "1"};
        atomic_dex::mm2::to_json(request_json, request);
        batch.push_back(request_json);
        auto copy_request        = request_json;
        copy_request["userpass"] = "";
        CHECK_EQ(copy_request, g_preimage_request_buy_DOC_nonexistent_real);
        WHEN("I execute the request")
        {
            const atomic_dex::t_trade_preimage_answer answer = generic_resp_process();
            CHECK(answer.error.has_value());
            CHECK_FALSE(answer.result.has_value());
        }
    }
}
#endif
