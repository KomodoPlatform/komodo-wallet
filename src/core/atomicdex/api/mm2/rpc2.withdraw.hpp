#pragma once

#include <optional>
#include <string>

//! Deps
#include <nlohmann/json_fwd.hpp>

//! Our Headers
#include "atomicdex/api/mm2/generic.error.hpp"
#include "atomicdex/api/mm2/transaction.data.hpp"

namespace atomic_dex::mm2
{
    struct withdraw_fees
    {
        std::string                type;      ///< UtxoFixed, UtxoPerKbyte, EthGas, Qrc20Gas
        std::optional<std::string> amount;    ///< Utxo only
        std::optional<std::string> gas_price; ///< price EthGas or Qrc20Gas
        std::optional<int>         gas_limit; ///< sets the gas limit for transaction
    };

    void to_json(nlohmann::json& j, const withdraw_fees& cfg);

    struct withdraw_request
    {
        std::string                  coin;
        std::string                  to;                 ///< coins will be withdraw to this address
        std::string                  amount;             ///< ignored if max is true
        std::optional<withdraw_fees> fees{std::nullopt}; ///< ignored if std::nullopt
        std::optional<std::string>   memo;               ///< memo for tendermint
        bool                         max{false};
    };

    void to_json(nlohmann::json& j, const withdraw_request& cfg);

    struct withdraw_answer
    {
        std::optional<transaction_data>     result;
        std::optional<generic_answer_error> error;
        std::string                         raw_result;      ///< internal
        int                                 rpc_result_code; ///< internal
    };

    void from_json(const nlohmann::json& j, withdraw_answer& answer);
} // namespace atomic_dex::mm2

namespace atomic_dex
{
    using t_withdraw_request = mm2::withdraw_request;
    using t_withdraw_fees    = mm2::withdraw_fees;
    using t_withdraw_answer  = mm2::withdraw_answer;
} // namespace atomic_dex