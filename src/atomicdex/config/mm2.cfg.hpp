/******************************************************************************
 * Copyright © 2013-2019 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

#pragma once

#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace atomic_dex
{
    using nlohmann::json;
    using namespace std::string_literals;

    struct mm2_config
    {
        std::string              gui{"AtomicDex Desktop "s + atomic_dex::get_version()};
        int64_t                  netid{7777};
        std::vector<std::string> seednodes{"195.201.91.96", "195.201.91.53", "168.119.174.126"};
#ifdef _WIN32
        std::string userhome{std::getenv("HOMEPATH")};
#else
        std::string userhome{std::getenv("HOME")};
#endif
        std::string passphrase;
        std::string dbdir{(utils::get_atomic_dex_data_folder() / "mm2" / "DB").string()};
        std::string rpc_password{"atomic_dex_mm2_passphrase"};
    };

    void from_json(const json& j, mm2_config& cfg);

    void to_json(json& j, const mm2_config& cfg);

    inline void
    from_json(const json& j, mm2_config& cfg)
    {
        cfg.gui          = j.at("gui").get<std::string>();
        cfg.netid        = j.at("netid").get<int64_t>();
        cfg.userhome     = j.at("userhome").get<std::string>();
        cfg.passphrase   = j.at("passphrase").get<std::string>();
        cfg.rpc_password = j.at("rpc_password").get<std::string>();
        cfg.dbdir        = j.at("dbdir").get<std::string>();
    }

    inline void
    to_json(json& j, const mm2_config& cfg)
    {
        j                 = json::object();
        j["gui"]          = cfg.gui;
        j["netid"]        = cfg.netid;
        j["userhome"]     = cfg.userhome;
        j["passphrase"]   = cfg.passphrase;
        j["rpc_password"] = cfg.rpc_password;
        j["dbdir"]        = cfg.dbdir;
        if (not cfg.seednodes.empty())
        {
            j["seednodes"] = cfg.seednodes;
        }
    }
} // namespace atomic_dex
