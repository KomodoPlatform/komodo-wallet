#include <doctest/doctest.h>

#include "atomicdex/api/mm2/rpc2.enable_bch_with_tokens.hpp"

TEST_CASE("enable_bch_with_tokens_request_rpc serialization")
{
    using namespace atomic_dex::mm2;
    
    nlohmann::json                      result;
    enable_bch_with_tokens_request_rpc  data
    {
        .ticker = "BCH",
        .allow_slp_unsafe_conf = false,
        .bchd_urls = {"https://bchd.imaginary.cash:8335/"},
        .mode =
        {
            .rpc = "Electrum",
            .rpc_data =
            {
                .servers = { { .url = "electrum1.cipig.net:10055" }, { .url = "electrum1.cipig.net:20055", .protocol = "SSL" } }
            }
        },
        .tx_history = true,
        .slp_tokens_requests = { { .ticker = "ASLP", .required_confirmations = 4 } },
        .required_confirmations = 5,
        .requires_notarization = false,
        .address_format = enable_bch_with_tokens_request_rpc::address_format_t{ .format = "cashaddress", .network = "bitcoincash" },
        .utxo_merge_params = enable_bch_with_tokens_request_rpc::utxo_merge_params_t{ .merge_at = 50, .check_every = 10, .max_merge_at_once = 25 }
    };
    
    nlohmann::to_json(result, data);
    
    CHECK_EQ(result["ticker"], "BCH");
    CHECK_FALSE(result["allow_slp_unsafe_conf"]);
    CHECK_EQ(result["bchd_urls"].size(), 1);
    CHECK_EQ(result["bchd_urls"][0].get<std::string>(), "https://bchd.imaginary.cash:8335/");
    CHECK(result["tx_history"]);
    CHECK_EQ(result["slp_tokens_requests"].size(), 1);
    CHECK_EQ(result["slp_tokens_requests"][0]["ticker"], "ASLP");
    CHECK_EQ(result["slp_tokens_requests"][0]["required_confirmations"], 4);
    CHECK_EQ(result["required_confirmations"], 5);
    CHECK_FALSE(result["requires_notarization"]);
    CHECK_EQ(result["address_format"]["format"], "cashaddress");
    CHECK_EQ(result["address_format"]["network"], "bitcoincash");
    CHECK_EQ(result["utxo_merge_params"]["merge_at"], 50);
    CHECK_EQ(result["utxo_merge_params"]["check_every"], 10);
    CHECK_EQ(result["utxo_merge_params"]["max_merge_at_once"], 25);
}

TEST_CASE("enable_bch_with_tokens_result_rpc deserialization")
{
    using namespace atomic_dex::mm2;
    
    enable_bch_with_tokens_result_rpc   result;
    nlohmann::json                      json = nlohmann::json::parse(R"(
    {
        "current_block":1480481,
        "bch_addresses_infos": {
            "bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj": {
                "derivation_method": {
                    "type":"Iguana"
                },
                "pubkey":"036879df230663db4cd083c8eeb0f293f46abc460ad3c299b0089b72e6d472202c",
                "balances": {
                    "spendable":"0.11398301",
                    "unspendable":"0.00001"
                }
            }
        },
        "slp_addresses_infos": {
            "simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v":{
                "derivation_method": {
                    "type":"Iguana"
                },
                "pubkey":"036879df230663db4cd083c8eeb0f293f46abc460ad3c299b0089b72e6d472202c",
                "balances": {
                    "ASLP":{
                        "spendable":"5.2974",
                        "unspendable":"0"
                    }
                }
            }
        }
    })");
    
    nlohmann::from_json(json, result);
    
    CHECK_EQ(result.current_block, 1480481);
    CHECK_EQ(result.bch_addresses_infos.size(), 1);
    CHECK(result.bch_addresses_infos.contains("bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj"));
    CHECK_EQ(result.bch_addresses_infos["bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj"].derivation_method.type, "Iguana");
    CHECK_EQ(result.bch_addresses_infos["bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj"].pubkey, "036879df230663db4cd083c8eeb0f293f46abc460ad3c299b0089b72e6d472202c");
    CHECK_EQ(result.bch_addresses_infos["bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj"].balances.spendable, "0.11398301");
    CHECK_EQ(result.bch_addresses_infos["bitcoincash:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5qx64fztj"].balances.unspendable, "0.00001");
    CHECK_EQ(result.slp_addresses_infos.size(), 1);
    CHECK(result.slp_addresses_infos.contains("simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"));
    CHECK_EQ(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].derivation_method.type, "Iguana");
    CHECK_EQ(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].pubkey, "036879df230663db4cd083c8eeb0f293f46abc460ad3c299b0089b72e6d472202c");
    CHECK_EQ(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].balances.size(), 1);
    CHECK(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].balances.contains("ASLP"));
    CHECK_EQ(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].balances["ASLP"].spendable, "5.2974");
    CHECK_EQ(result.slp_addresses_infos["simpleledger:qrf5vpn78s7rjexrjhlwyzzeg7gw98k7t5va3wuz4v"].balances["ASLP"].unspendable, "0");
}