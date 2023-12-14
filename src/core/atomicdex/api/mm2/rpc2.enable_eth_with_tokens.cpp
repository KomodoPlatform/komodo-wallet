#include <nlohmann/json.hpp>

#include "rpc2.enable_eth_with_tokens.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const enable_eth_with_tokens_request_rpc& in)
    {
        j["ticker"] = in.ticker;
        j["nodes"] = in.nodes;
        j["tx_history"] = in.tx_history;
        j["erc20_tokens_requests"]  = in.erc20_tokens_requests;
        if (in.required_confirmations.has_value())
            j["required_confirmations"] = in.required_confirmations.value();
        if (in.requires_notarization.has_value())
            j["requires_notarization"] = in.requires_notarization.value();

        switch (in.coin_type)
        {
            case CoinType::ERC20:
            {
                j["gas_station_url"]        = eth_gas_station_url;
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? erc_testnet_swap_contract_address : erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? erc_testnet_fallback_swap_contract_address : erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::Matic:
            {
                SPDLOG_INFO("MATIC");
                j["gas_station_url"]        = in.is_testnet.value_or(false) ? testnet_matic_gas_station_url : matic_gas_station_url;
                j["gas_station_decimals"]   = 9;
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? matic_erc_testnet_swap_contract_address : matic_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? matic_erc_testnet_fallback_swap_contract_address : matic_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::Arbitrum:
            {
                j["swap_contract_address"] = arbitrum_erc_swap_contract_address;
                j["fallback_swap_contract"] = arbitrum_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::BEP20:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? bnb_testnet_swap_contract_address : bnb_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? bnb_testnet_fallback_swap_contract_address : bnb_fallback_swap_contract_address;
                break;
            }
            case CoinType::AVX20:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? avax_erc_testnet_swap_contract_address : avax_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? avax_erc_testnet_fallback_swap_contract_address : avax_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::FTM20:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? ftm_erc_testnet_swap_contract_address : ftm_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? ftm_erc_testnet_fallback_swap_contract_address : ftm_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::HRC20:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? one_erc_testnet_swap_contract_address : one_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? one_erc_testnet_fallback_swap_contract_address : one_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::Ubiq:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? ubiq_erc_testnet_swap_contract_address : ubiq_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? ubiq_erc_testnet_fallback_swap_contract_address : ubiq_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::KRC20:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? krc_erc_testnet_swap_contract_address : krc_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? krc_erc_testnet_fallback_swap_contract_address : krc_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::Moonriver:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? movr_erc_testnet_swap_contract_address : movr_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? movr_erc_testnet_fallback_swap_contract_address : movr_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::Moonbeam:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? glmr_erc_testnet_swap_contract_address : glmr_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? glmr_erc_testnet_fallback_swap_contract_address : glmr_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::HecoChain:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? hco_erc_testnet_swap_contract_address : hco_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? hco_erc_testnet_fallback_swap_contract_address : hco_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::SmartBCH:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? sbch_erc_testnet_swap_contract_address : sbch_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? sbch_erc_testnet_fallback_swap_contract_address : sbch_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::EthereumClassic:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? etc_erc_testnet_swap_contract_address : etc_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? etc_erc_testnet_fallback_swap_contract_address : etc_erc_fallback_swap_contract_address;
                break;
            }
            case CoinType::RSK:
            {
                j["swap_contract_address"]  = in.is_testnet.value_or(false) ? rsk_erc_testnet_swap_contract_address : rsk_erc_swap_contract_address;
                j["fallback_swap_contract"] = in.is_testnet.value_or(false) ? rsk_erc_testnet_fallback_swap_contract_address : rsk_erc_fallback_swap_contract_address;
                break;
            }
            default:
                break;
        }
        SPDLOG_DEBUG("enable_erc20_with_tokens: {}", j.dump(4));
    }

    void to_json(nlohmann::json& j, const enable_eth_with_tokens_request_rpc::erc20_token_request_t& in)
    {
        j["ticker"] = in.ticker;
        if (in.required_confirmations)
            j["required_confirmations"] = in.required_confirmations.value();
    }

    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc& out)
    {
        out.current_block = json["current_block"];
        out.eth_addresses_infos = json["eth_addresses_infos"].get<typeof(out.eth_addresses_infos)>();
        out.erc20_addresses_infos = json["erc20_addresses_infos"].get<typeof(out.erc20_addresses_infos)>();
    }
    
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::derivation_method_t& out)
    {
        out.type = json["type"];
    }
    
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::eth_address_infos_t& out)
    {
        out.derivation_method = json["derivation_method"];
        out.pubkey = json["pubkey"];
        out.balances = json["balances"];
    }
    
    void from_json(const nlohmann::json& json, enable_eth_with_tokens_result_rpc::erc20_address_infos_t& out)
    {
        out.derivation_method = json["derivation_method"];
        out.pubkey = json["pubkey"];
        out.balances = json["balances"].get<typeof(out.balances)>();
    }
}