// komodo-wallet
// Author(s): syl

#pragma once

#include <string>

#include "atomicdex/api/mm2/transaction.data.hpp"

namespace atomic_dex::mm2
{
    struct transactions_fetched_event
    {
        std::string                     ticker;
        std::vector<tx_infos>           transactions;
        bool                            has_error;
        std::string                     error_msg;
    };
}