#include <nlohmann/json.hpp>

#include "rpc2.enable_tendermint_with_assets.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const enable_tendermint_with_assets_request_rpc& in)
    {
        j["ticker"] = in.ticker;
        j["rpc_urls"] = in.rpc_urls;
        j["tx_history"] = in.tx_history;
        j["tokens_params"] = in.tokens_params;
        if (in.required_confirmations.has_value())
            j["required_confirmations"] = in.required_confirmations.value();
        if (in.requires_notarization.has_value())
            j["requires_notarization"] = in.requires_notarization.value();
    }

    void to_json(nlohmann::json& j, const enable_tendermint_with_assets_request_rpc::tendermint_token_request_t& in)
    {
        j["ticker"] = in.ticker;
        if (in.required_confirmations)
            j["required_confirmations"] = in.required_confirmations.value();
    }

    void from_json(const nlohmann::json& json, enable_tendermint_with_assets_result_rpc& out)
    {
        out.address                          = json["address"];
        out.current_block                    = json["current_block"];
        out.tendermint_balances_infos        = json["balance"].get<typeof(out.tendermint_balances_infos)>();
        out.tendermint_token_balances_infos  = json["tokens_balances"].get<typeof(out.tendermint_token_balances_infos)>();
    }
    
    void from_json(const nlohmann::json& json, enable_tendermint_with_assets_result_rpc::tendermint_balance_infos_t& out)
    {
        out.balances.spendable = json["spendable"];
        out.balances.unspendable = json["unspendable"];
    }
}