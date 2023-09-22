#include <nlohmann/json.hpp>

#include "rpc2.enable_tendermint_token.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const enable_tendermint_token_rpc_request& request)
    {
        j["ticker"] = request.ticker;
        if (request.activation_params.required_confirmations)
        {
            j["activation_params"]["required_confirmations"] = *request.activation_params.required_confirmations;
        }
        else
        {
            j["activation_params"] = nlohmann::json::object();
        }
    }

    void from_json(const nlohmann::json& j, enable_tendermint_token_rpc_result& in)
    {
        j.at("platform_coin").get_to(in.platform_coin);
        j.at("balances").get_to<std::unordered_map<std::string, balance_info>>(in.balances);
    }
}