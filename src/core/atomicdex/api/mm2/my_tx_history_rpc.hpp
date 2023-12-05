// komodo-wallet
// Author(s): syl

#include <string>

#include "paging_options.hpp"
#include "transaction.data.hpp"
#include "rpc.hpp"

#pragma once

namespace atomic_dex::mm2
{
    struct my_tx_history_rpc
    {
        static constexpr auto endpoint = "my_tx_history";
        static constexpr bool is_v2     = true;
        
        struct expected_request_type
        {
            std::string     coin;
            int             limit;
            paging_options  paging_options;
        };
        
        struct expected_result_type
        {
            std::string                     coin;
            std::size_t                     current_block;
            std::vector<transaction_data>   transactions;
        };

        using expected_error_type = rpc_basic_error_type;

        expected_request_type                   request;
        std::optional<expected_result_type>     result;
        std::optional<expected_error_type>      error;
    };
    
    using my_tx_history_request_rpc    = my_tx_history_rpc::expected_request_type;
    using my_tx_history_result_rpc     = my_tx_history_rpc::expected_result_type;
    using my_tx_history_error_rpc      = my_tx_history_rpc::expected_error_type;
    
    void to_json(nlohmann::json& j, const my_tx_history_request_rpc& in);
    void from_json(const nlohmann::json& json, my_tx_history_result_rpc& out);
}