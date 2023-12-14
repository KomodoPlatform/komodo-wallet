#pragma once

#include <optional>
#include <string>

#include <nlohmann/json_fwd.hpp>

#include "transaction.data.hpp"
#include "paging_options.hpp"

namespace atomic_dex::mm2
{
    struct tx_history_request
    {
        std::string                   coin;
        std::size_t                   limit;
        std::optional<paging_options_t> paging_options;
    };

    void to_json(nlohmann::json& j, const tx_history_request& cfg);

    struct sync_status_additional_error
    {
        std::string message;
        int         code;
    };

    void from_json(const nlohmann::json& j, sync_status_additional_error& answer);

    struct sync_status_eth_erc_20_coins
    {
        std::size_t blocks_left;
    };

    void from_json(const nlohmann::json& j, sync_status_eth_erc_20_coins& answer);

    struct sync_status_regular_coins
    {
        std::size_t transactions_left;
    };

    void from_json(const nlohmann::json& j, sync_status_regular_coins& answer);

    struct sync_status_additional_infos
    {
        std::optional<sync_status_additional_error> error;         ///< in case of error
        std::optional<sync_status_eth_erc_20_coins> erc_infos;     ///< eth/erc20 related coins
        std::optional<sync_status_regular_coins>    regular_infos; ///< kmd/btc/utxo related coins
    };

    void from_json(const nlohmann::json& j, sync_status_additional_infos& answer);

    struct t_sync_status
    {
        std::string                                 state; ///< NotEnabled, NotStarted, InProgress, Error, Finished
        std::optional<sync_status_additional_infos> additional_info;
    };

    void from_json(const nlohmann::json& j, t_sync_status& answer);

    struct tx_history_answer_success
    {
        std::string                   from_id;
        std::size_t                   skipped;
        std::size_t                   limit;
        std::size_t                   current_block;
        std::size_t                   total;
        std::vector<transaction_data> transactions;
        t_sync_status                 sync_status;
    };

    void from_json(const nlohmann::json& j, tx_history_answer_success& answer);

    struct tx_history_answer
    {
        std::optional<std::string>               error;
        std::optional<tx_history_answer_success> result;
        std::string                              raw_result;      ///< internal
        int                                      rpc_result_code; ///< internal
    };

    void from_json(const nlohmann::json& j, tx_history_answer& answer);
} // namespace atomic_dex::mm2

namespace atomic_dex
{
    using t_tx_history_request = mm2::tx_history_request;
}