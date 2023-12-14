#include <nlohmann/json.hpp>

#include "rpc2.enable_bch_with_tokens.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc& in)
    {
        j["ticker"] = in.ticker;
        j["bchd_urls"] = in.bchd_urls;
        j["tx_history"] = in.tx_history;
        j["allow_slp_unsafe_conf"] = in.allow_slp_unsafe_conf.value_or(false);
        j["mode"] = in.mode;
        j["slp_tokens_requests"] = in.slp_tokens_requests;
        if (in.required_confirmations.has_value())
            j["required_confirmations"] = in.required_confirmations.value();
        if (in.requires_notarization.has_value())
            j["requires_notarization"] = in.requires_notarization.value();
        if (in.address_format.has_value())
            j["address_format"] = in.address_format.value();
        if (in.utxo_merge_params.has_value())
            j["utxo_merge_params"] = in.utxo_merge_params.value();
    }
    
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::mode_t& in)
    {
        j["rpc"] = in.rpc;
        j["rpc_data"] = in.rpc_data;
    }
    
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::mode_t::data& in)
    {
        j["servers"] = in.servers;
    }
    
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::address_format_t& in)
    {
        j["format"] = in.format;
        j["network"] = in.network;
    }
    
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::slp_token_request_t& in)
    {
        j["ticker"] = in.ticker;
        if (in.required_confirmations)
            j["required_confirmations"] = in.required_confirmations.value();
    }
    
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::utxo_merge_params_t& in)
    {
        j["merge_at"] = in.merge_at;
        j["check_every"] = in.check_every;
        j["max_merge_at_once"] = in.max_merge_at_once;
    }

    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc& out)
    {
        out.current_block = json["current_block"];
        out.bch_addresses_infos = json["bch_addresses_infos"].get<typeof(out.bch_addresses_infos)>();
        out.slp_addresses_infos = json["slp_addresses_infos"].get<typeof(out.slp_addresses_infos)>();
    }
    
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::derivation_method_t& out)
    {
        out.type = json["type"];
    }
    
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::bch_address_infos_t& out)
    {
        out.derivation_method = json["derivation_method"];
        out.pubkey = json["pubkey"];
        out.balances = json["balances"];
    }
    
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::slp_address_infos_t& out)
    {
        out.derivation_method = json["derivation_method"];
        out.pubkey = json["pubkey"];
        out.balances = json["balances"].get<typeof(out.balances)>();
    }
}