// komodo-wallet
// Author(s): syl

#pragma once

#include <optional>

#include <nlohmann/json_fwd.hpp>

namespace atomic_dex::mm2
{
    struct paging_options
    {
        std::optional<std::string> from_id;
        std::optional<int>         page_number;
    };
    
    void to_json(nlohmann::json& j, const paging_options& in);
}