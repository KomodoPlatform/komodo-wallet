#pragma once

#include <vector>

#include "rpc.hpp"
#include "balance_info.hpp"
#include "atomicdex/config/electrum.cfg.hpp"

namespace atomic_dex::mm2
{
    struct enable_tendermint_with_assets_rpc
    {
        static constexpr auto endpoint = "enable_tendermint_with_assets";
        static constexpr bool is_v2     = true;

        struct expected_request_type
        {
            struct tendermint_token_request_t
            {
                std::string         ticker;
                std::optional<int>  required_confirmations;
            };

            std::string                                     ticker;
            std::vector<std::string>                        rpc_urls;
            bool                                            tx_history{true};
            std::vector<tendermint_token_request_t>         tokens_params;
            std::optional<int>                              required_confirmations;
            std::optional<bool>                             requires_notarization;
        };
        
        struct expected_result_type
        {
            struct tendermint_balance_infos_t
            {
                balance_info        balances;
            };

            std::string                                                       address;
            std::size_t                                                       current_block;
            tendermint_balance_infos_t                                        tendermint_balances_infos;
            std::unordered_map<std::string, balance_info>                     tendermint_token_balances_infos;
        };

        using expected_error_type = rpc_basic_error_type;

        expected_request_type                   request;
        std::optional<expected_result_type>     result;
        std::optional<expected_error_type>      error;
    };

    using enable_tendermint_with_assets_request_rpc    = enable_tendermint_with_assets_rpc::expected_request_type;
    using enable_tendermint_with_assets_result_rpc     = enable_tendermint_with_assets_rpc::expected_result_type;
    using enable_tendermint_with_assets_error_rpc      = enable_tendermint_with_assets_rpc::expected_error_type;

    void to_json(nlohmann::json& j, const enable_tendermint_with_assets_request_rpc& in);
    void to_json(nlohmann::json& j, const enable_tendermint_with_assets_request_rpc::tendermint_token_request_t& in);
    void from_json(const nlohmann::json& json, enable_tendermint_with_assets_result_rpc& out);
    void from_json(const nlohmann::json& json, enable_tendermint_with_assets_result_rpc::tendermint_balance_infos_t& out);
}