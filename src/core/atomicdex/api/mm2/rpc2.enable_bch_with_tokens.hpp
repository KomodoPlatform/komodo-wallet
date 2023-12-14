#pragma once

#include <vector>

#include "rpc.hpp"
#include "balance_info.hpp"
#include "atomicdex/config/electrum.cfg.hpp"

namespace atomic_dex::mm2
{
    struct enable_bch_with_tokens_rpc
    {
        static constexpr auto endpoint = "enable_bch_with_tokens";
        static constexpr bool is_v2     = true;

        struct expected_request_type
        {
            struct mode_t
            {
                struct data { std::vector<electrum_server> servers; };

                std::string rpc{"Electrum"};
                data        rpc_data;
            };
            struct slp_token_request_t
            {
                std::string         ticker;
                std::optional<int>  required_confirmations;
            };
            struct address_format_t
            {
                std::string format;
                std::string network;
            };
            struct utxo_merge_params_t
            {
                int merge_at;
                int check_every;
                int max_merge_at_once;
            };

            std::string                         ticker;
            std::optional<bool>                 allow_slp_unsafe_conf{false};
            std::vector<std::string>            bchd_urls;
            mode_t                              mode;
            bool                                tx_history{true};
            std::vector<slp_token_request_t>    slp_tokens_requests;
            std::optional<int>                  required_confirmations;
            std::optional<bool>                 requires_notarization;
            std::optional<address_format_t>     address_format;
            std::optional<utxo_merge_params_t>  utxo_merge_params;
        };
        
        struct expected_result_type
        {
            struct derivation_method_t { std::string type; };
            struct bch_address_infos_t
            {
                derivation_method_t derivation_method;
                std::string         pubkey;
                balance_info        balances;
            };
            struct slp_address_infos_t
            {
                derivation_method_t                             derivation_method;
                std::string                                     pubkey;
                std::unordered_map<std::string, balance_info>   balances;
            };

            std::size_t current_block;
            std::unordered_map<std::string, bch_address_infos_t> bch_addresses_infos;
            std::unordered_map<std::string, slp_address_infos_t> slp_addresses_infos;
        };

        using expected_error_type = rpc_basic_error_type;

        expected_request_type                   request;
        std::optional<expected_result_type>     result;
        std::optional<expected_error_type>      error;
    };

    using enable_bch_with_tokens_request_rpc    = enable_bch_with_tokens_rpc::expected_request_type;
    using enable_bch_with_tokens_result_rpc     = enable_bch_with_tokens_rpc::expected_result_type;
    using enable_bch_with_tokens_error_rpc      = enable_bch_with_tokens_rpc::expected_error_type;

    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc& in);
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::mode_t& in);
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::mode_t::data& in);
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::address_format_t& in);
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::slp_token_request_t& in);
    void to_json(nlohmann::json& j, const enable_bch_with_tokens_request_rpc::utxo_merge_params_t& in);
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc& out);
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::derivation_method_t& out);
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::bch_address_infos_t& out);
    void from_json(const nlohmann::json& json, enable_bch_with_tokens_result_rpc::slp_address_infos_t& out);
}