#include <doctest/doctest.h>

#include "atomicdex/api/mm2/rpc2.enable_eth_with_tokens.hpp"

TEST_CASE("enable_eth_with_tokens_request_rpc serialization")
{
    using namespace atomic_dex::mm2;
    
    nlohmann::json                      result;
    enable_eth_with_tokens_request_rpc  data
    {
        .ticker = "ETH",
        .tx_history = true,
        .required_confirmations = 5,
        .requires_notarization = false,
        .nodes =
        {
            { .url = "https://eth1.cipig.net:8555" }, { .url = "https://eth2.cipig.net:8555" }, { .url = "https://eth3.cipig.net:8555" }
        },
        .erc20_tokens_requests = { { .ticker = "BAT-ERC20", .required_confirmations = 4 } },
    };
    
    nlohmann::to_json(result, data);
    
    CHECK_EQ(result["ticker"], "ETH");
    CHECK(result["tx_history"]);
    CHECK_EQ(result["erc20_tokens_requests"].size(), 1);
    CHECK_EQ(result["erc20_tokens_requests"][0]["ticker"], "BAT-ERC20");
    CHECK_EQ(result["erc20_tokens_requests"][0]["required_confirmations"], 4);
    CHECK_EQ(result["required_confirmations"], 5);
    CHECK_FALSE(result["requires_notarization"]);
}

TEST_CASE("enable_eth_with_tokens_result_rpc deserialization")
{
    using namespace atomic_dex::mm2;
    
    enable_eth_with_tokens_result_rpc   result;
    nlohmann::json                      json = nlohmann::json::parse(R"(
    {
        "mmrpc": "2.0",
        "result": {
            "current_block": 15905842,
            "eth_addresses_infos": {
                "0xaB95D01Bc8214E4D993043E8Ca1B68dB2c946498": {
                    "derivation_method": {
                        "type": "Iguana"
                    },
                    "pubkey": "04d8064eece4fa5c0f8dc0267f68cee9bdd527f9e88f3594a323428718c391ecc2a91c9ce32b6fc5489c49e33b688423b655177168afee1b128be9b2fee67e3f3b",
                    "balances": {
                        "spendable": "0",
                        "unspendable": "0"
                    }
                }
            },
            "erc20_addresses_infos": {
                "0xaB95D01Bc8214E4D993043E8Ca1B68dB2c946498": {
                    "derivation_method": {
                        "type": "Iguana"
                    },
                    "pubkey": "04d8064eece4fa5c0f8dc0267f68cee9bdd527f9e88f3594a323428718c391ecc2a91c9ce32b6fc5489c49e33b688423b655177168afee1b128be9b2fee67e3f3b",
                    "balances": {
                        "MINDS": {
                            "spendable": "0",
                            "unspendable": "0"
                        },
                        "BCH-ERC20": {
                            "spendable": "0",
                            "unspendable": "0"
                        },
                        "BUSD-ERC20": {
                            "spendable": "0",
                            "unspendable": "0"
                        },
                        "APE-ERC20": {
                            "spendable": "0",
                            "unspendable": "0"
                        }
                    }
                }
            }
        },
        "id": null
    })");
    
    nlohmann::from_json(json, result);
    
    CHECK_EQ(result.current_block, 15905842);
    CHECK_EQ(result.eth_addresses_infos.size(), 1);
    CHECK(result.eth_addresses_infos.contains("0xaB95D01Bc8214E4D993043E8Ca1B68dB2c946498"));
    CHECK_EQ(result.eth_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].derivation_method.type, "Iguana");
    CHECK_EQ(result.eth_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].pubkey, "04d8064eece4fa5c0f8dc0267f68cee9bdd527f9e88f3594a323428718c391ecc2a91c9ce32b6fc5489c49e33b688423b655177168afee1b128be9b2fee67e3f3b");
    CHECK_EQ(result.eth_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances.spendable, "0");
    CHECK_EQ(result.eth_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances.unspendable, "0");
    CHECK_EQ(result.erc20_addresses_infos.size(), 1);
    CHECK(result.erc20_addresses_infos.contains("0xab95d01bc8214e4d993043e8ca1b68db2c946498"));
    CHECK_EQ(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].derivation_method.type, "Iguana");
    CHECK_EQ(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].pubkey, "04d8064eece4fa5c0f8dc0267f68cee9bdd527f9e88f3594a323428718c391ecc2a91c9ce32b6fc5489c49e33b688423b655177168afee1b128be9b2fee67e3f3bv");
    CHECK_EQ(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances.size(), 1);
    CHECK(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances.contains("BAT-ERC20"));
    CHECK_EQ(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances["BAT-ERC20"].spendable, "0");
    CHECK_EQ(result.erc20_addresses_infos["0xab95d01bc8214e4d993043e8ca1b68db2c946498"].balances["BAT-ERC20"].unspendable, "0");
}