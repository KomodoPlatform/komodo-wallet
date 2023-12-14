#pragma once

//! Qt
#include <QFile>
#include <QJsonDocument>

//! Deps
#include <antara/gaming/core/real.path.hpp>
#include <nlohmann/json.hpp>

//! Project
#include "atomicdex/api/mm2/mm2.constants.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

#ifndef NLOHMANN_OPT_HELPER
#    define NLOHMANN_OPT_HELPER
namespace nlohmann
{
    template <typename T>
    struct adl_serializer<std::optional<T>>
    {
        static void
        to_json(json& j, const std::optional<T>& opt)
        {
            if (opt.has_value())
            {
                j = opt.value();
            }
        }

        static std::optional<T>
        from_json(const json& j)
        {
            return j.is_null() ? std::optional<T>{std::nullopt} : j.get<T>();
        }
    };
} // namespace nlohmann
#endif

namespace atomic_dex
{
    using nlohmann::json;

    inline json
    get_untyped(const json& j, const char* property)
    {
        if (j.find(property) != j.end())
        {
            return j.at(property).get<json>();
        }
        return json();
    }

    inline json
    get_untyped(const json& j, std::string property)
    {
        return get_untyped(j, property.data());
    }

    template <typename T>
    inline std::optional<T>
    get_optional(const json& j, const char* property)
    {
        if (j.contains(property))
        {
            return j.at(property).get<std::optional<T>>();
        }
        return std::optional<T>();
    }

    template <typename T>
    inline std::optional<T>
    get_optional(const json& j, std::string property)
    {
        return get_optional<T>(j, property.data());
    }

    struct address_format_t
    {
        std::string                format;
        std::optional<std::string> network{std::nullopt};
    };

    struct coin_element
    {
        std::string                     coin;
        std::optional<std::string>      name{std::nullopt};
        std::optional<std::string>      fname{std::nullopt};
        std::optional<std::string>      etomic{std::nullopt};
        std::optional<int64_t>          chain_id{std::nullopt};
        std::optional<int64_t>          rpcport{std::nullopt};
        std::optional<int64_t>          pubtype{std::nullopt};
        std::optional<int64_t>          p2_shtype{std::nullopt};
        std::optional<int64_t>          wiftype{std::nullopt};
        std::optional<int64_t>          txfee{std::nullopt};
        std::optional<std::string>      confpath{std::nullopt};
        std::optional<int64_t>          mm2{std::nullopt};
        std::optional<int64_t>          required_confirmations{std::nullopt};
        std::optional<std::string>      asset{std::nullopt};
        std::optional<int64_t>          txversion{std::nullopt};
        std::optional<int64_t>          overwintered{std::nullopt};
        std::optional<bool>             requires_notarization{std::nullopt};
        std::optional<int64_t>          is_po_s{std::nullopt};
        std::optional<bool>             segwit{std::nullopt};
        std::optional<address_format_t> address_format{std::nullopt};
        std::optional<std::string>      estimate_fee_mode{std::nullopt};
        std::optional<int64_t>          taddr{std::nullopt};
        std::optional<int64_t>          decimals{std::nullopt};
        std::optional<bool>             force_min_relay_fee{std::nullopt};
        std::optional<int64_t>          p2_p{std::nullopt};
        std::optional<std::string>      magic{std::nullopt};
        std::optional<std::string>      n_spv{std::nullopt};
        std::optional<std::string>      version_group_id{std::nullopt};
        std::optional<std::string>      consensus_branch_id{std::nullopt};
        std::optional<double>           avg_blocktime{std::nullopt};
        std::optional<int64_t>          dust{std::nullopt};
        nlohmann::json                  protocol;
    };

    using coins = std::vector<coin_element>;
} // namespace atomic_dex

namespace atomic_dex
{
    using t_mm2_raw_coins          = std::vector<coin_element>;
    using t_mm2_raw_coins_registry = std::unordered_map<std::string, coin_element>;
} // namespace atomic_dex

namespace atomic_dex
{
    void from_json(const json& j, atomic_dex::address_format_t& x);
    void to_json(json& j, const atomic_dex::address_format_t& x);

    void from_json(const json& j, atomic_dex::coin_element& x);
    void to_json(json& j, const atomic_dex::coin_element& x);

    inline void
    from_json(const json& j, atomic_dex::address_format_t& x)
    {
        x.format  = j.at("format").get<std::string>();
        x.network = atomic_dex::get_optional<std::string>(j, "network");
    }

    inline void
    to_json(json& j, const atomic_dex::address_format_t& x)
    {
        j           = json::object();
        j["format"] = x.format;
        if (x.network.has_value())
        {
            j["network"] = x.network.value();
        }
    }

    inline void
    from_json(const json& j, atomic_dex::coin_element& x)
    {
        x.coin                   = j.at("coin").get<std::string>();
        x.name                   = atomic_dex::get_optional<std::string>(j, "name");
        x.fname                  = atomic_dex::get_optional<std::string>(j, "fname");
        x.etomic                 = atomic_dex::get_optional<std::string>(j, "etomic");
        x.chain_id               = atomic_dex::get_optional<int64_t>(j, "chain_id");
        x.rpcport                = atomic_dex::get_optional<int64_t>(j, "rpcport"); // j.at("rpcport").get<int64_t>();
        x.pubtype                = atomic_dex::get_optional<int64_t>(j, "pubtype");
        x.p2_shtype              = atomic_dex::get_optional<int64_t>(j, "p2shtype");
        x.wiftype                = atomic_dex::get_optional<int64_t>(j, "wiftype");
        x.txfee                  = atomic_dex::get_optional<int64_t>(j, "txfee");
        x.confpath               = atomic_dex::get_optional<std::string>(j, "confpath");
        x.mm2                    = atomic_dex::get_optional<int64_t>(j, "mm2");
        x.required_confirmations = atomic_dex::get_optional<int64_t>(j, "required_confirmations");
        x.asset                  = atomic_dex::get_optional<std::string>(j, "asset");
        x.txversion              = atomic_dex::get_optional<int64_t>(j, "txversion");
        x.overwintered           = atomic_dex::get_optional<int64_t>(j, "overwintered");
        x.requires_notarization  = atomic_dex::get_optional<bool>(j, "requires_notarization");
        x.is_po_s                = atomic_dex::get_optional<int64_t>(j, "isPoS");
        x.segwit                 = atomic_dex::get_optional<bool>(j, "segwit");
        x.address_format         = atomic_dex::get_optional<atomic_dex::address_format_t>(j, "address_format");
        x.estimate_fee_mode      = atomic_dex::get_optional<std::string>(j, "estimate_fee_mode");
        x.taddr                  = atomic_dex::get_optional<int64_t>(j, "taddr");
        x.decimals               = atomic_dex::get_optional<int64_t>(j, "decimals");
        x.force_min_relay_fee    = atomic_dex::get_optional<bool>(j, "force_min_relay_fee");
        x.p2_p                   = atomic_dex::get_optional<int64_t>(j, "p2p");
        x.magic                  = atomic_dex::get_optional<std::string>(j, "magic");
        x.n_spv                  = atomic_dex::get_optional<std::string>(j, "nSPV");
        x.version_group_id       = atomic_dex::get_optional<std::string>(j, "version_group_id");
        x.consensus_branch_id    = atomic_dex::get_optional<std::string>(j, "consensus_branch_id");
        x.dust                   = atomic_dex::get_optional<int64_t>(j, "dust");
        x.avg_blocktime          = atomic_dex::get_optional<double>(j, "avg_blocktime");
        x.protocol               = j.at("protocol");
    }

    inline void
    to_json(json& j, const atomic_dex::coin_element& x)
    {
        j                    = json::object();
        auto to_json_functor = [&j](const std::string field_name, const auto& field)
        {
            if (field.has_value())
            {
                j[field_name] = field.value();
            }
        };

        j["coin"] = x.coin;
        to_json_functor("name", x.name);
        to_json_functor("fname", x.fname);
        to_json_functor("etomic", x.etomic);
        to_json_functor("chain_id", x.chain_id);
        to_json_functor("rpcport", x.rpcport);
        to_json_functor("pubtype", x.pubtype);
        to_json_functor("p2shtype", x.p2_shtype);
        to_json_functor("wiftype", x.wiftype);
        to_json_functor("txfee", x.txfee);
        to_json_functor("confpath", x.confpath);
        to_json_functor("mm2", x.mm2);
        to_json_functor("required_confirmations", x.required_confirmations);
        to_json_functor("asset", x.asset);
        to_json_functor("txversion", x.txversion);
        to_json_functor("overwintered", x.overwintered);
        to_json_functor("requires_notarization", x.requires_notarization);
        to_json_functor("overwintered", x.overwintered);
        to_json_functor("isPoS", x.is_po_s);
        to_json_functor("segwit", x.segwit);
        to_json_functor("address_format", x.address_format);
        to_json_functor("estimate_fee_mode", x.estimate_fee_mode);
        to_json_functor("taddr", x.taddr);
        to_json_functor("decimals", x.decimals);
        to_json_functor("force_min_relay_fee", x.force_min_relay_fee);
        to_json_functor("p2p", x.p2_p);
        to_json_functor("magic", x.magic);
        to_json_functor("nSPV", x.n_spv);
        to_json_functor("version_group_id", x.version_group_id);
        to_json_functor("consensus_branch_id", x.consensus_branch_id);
        to_json_functor("dust", x.dust);
        to_json_functor("avg_blocktime", x.avg_blocktime);
        j["protocol"] = x.protocol;
    }

    inline t_mm2_raw_coins_registry
    parse_raw_mm2_coins_file()
    {
        SPDLOG_INFO("parse_raw_mm2_coins_file");
        t_mm2_raw_coins_registry out;
        std::filesystem::path                 file_path{atomic_dex::utils::get_current_configs_path() / "coins.json"};
        if (not std::filesystem::exists(file_path))
        {
            std::filesystem::path original_mm2_coins_path{ag::core::assets_real_path() / "tools" / "mm2" / "coins"};
            //! Copy our json to current version
            LOG_PATH_CMP("Copying mm2 coins cfg: {} to {}", original_mm2_coins_path, file_path);

            std::filesystem::copy_file(original_mm2_coins_path, file_path, std::filesystem::copy_options::overwrite_existing);
        }

        QFile file;
        file.setFileName(std_path_to_qstring(file_path));
        file.open(QIODevice::ReadOnly | QIODevice::Text);
        QString val = file.readAll();
        file.close();

        try
        {
            nlohmann::json j = nlohmann::json::parse(val.toStdString());
            // ifs >> j;
            t_mm2_raw_coins coins = j;
            out.reserve(coins.size());
            for (auto&& coin: coins) { out[coin.coin] = coin; }
            LOG_PATH("successfully parsed: {}", file_path);
            SPDLOG_INFO("coins size mm2: {}", coins.size());
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("parse error: {}", error.what());
            LOG_PATH("cannot parse mm2 raw cfg file: {}", file_path);
        }
        return out;
    }
} // namespace atomic_dex
