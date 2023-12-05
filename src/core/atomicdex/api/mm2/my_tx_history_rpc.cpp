// komodo-wallet
// Author(s): syl

#include <nlohmann/json.hpp>

#include "my_tx_history_rpc.hpp"

namespace atomic_dex::mm2
{
    void to_json(nlohmann::json& j, const my_tx_history_request_rpc& in)
    {
        j["coin"] = in.coin;
        j["limit"] = in.limit;
        j["paging_options"] = nlohmann::json::object();
        if (in.paging_options.from_id)
        {
            j["paging_options"]["FromId"] = *in.paging_options.from_id;
        }
        if (in.paging_options.page_number)
        {
            j["paging_options"]["PageNumber"] = *in.paging_options.page_number;
        }
    }
    
    void from_json(const nlohmann::json& json, my_tx_history_result_rpc& out)
    {
        out.coin = json["coin"];
        out.current_block = json["current_block"];
        out.transactions = json["transactions"].get<std::vector<transaction_data>>();
    }
}