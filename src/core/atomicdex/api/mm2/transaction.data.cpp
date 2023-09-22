#include <nlohmann/json.hpp>

#include "atomicdex/api/mm2/transaction.data.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

namespace atomic_dex::mm2
{
    void from_json(const nlohmann::json& j, fee_regular_coin& cfg)
    {
        j.at("amount").get_to(cfg.amount);
    }

    void from_json(const nlohmann::json& j, fee_erc_coin& cfg)
    {
        j.at("coin").get_to(cfg.coin);
        j.at("gas").get_to(cfg.gas);
        j.at("gas_price").get_to(cfg.gas_price);
        j.at("total_fee").get_to(cfg.total_fee);
    }

    void from_json(const nlohmann::json& j, fee_tendermint_coin& cfg)
    {
        j.at("coin").get_to(cfg.coin);
        j.at("type").get_to(cfg.type);
        j.at("amount").get_to(cfg.amount);
        j.at("gas_limit").get_to(cfg.gas_limit);
    }

    void from_json(const nlohmann::json& j, fee_qrc_coin& cfg)
    {
        j.at("coin").get_to(cfg.coin);
        j.at("gas_limit").get_to(cfg.gas_limit);
        j.at("gas_price").get_to(cfg.gas_price);
        j.at("miner_fee").get_to(cfg.miner_fee);
        j.at("total_gas_fee").get_to(cfg.total_gas_fee);
    }

    void from_json(const nlohmann::json& j, fees_data& cfg)
    {
        if (j.count("amount") == 1)
        {
            cfg.normal_fees = fee_regular_coin{};
            from_json(j, cfg.normal_fees.value());
        }
        else if (j.at("coin").get<std::string>() == "QTUM" || j.at("coin").get<std::string>() == "tQTUM")
        {
            cfg.qrc_fees = fee_qrc_coin{};
            from_json(j, cfg.qrc_fees.value());
        }
        else
        {
            cfg.erc_fees = fee_erc_coin{};
            from_json(j, cfg.erc_fees.value());
        }
    }

    void from_json(const nlohmann::json& j, transaction_data& cfg)
    {
        j.at("block_height").get_to(cfg.block_height);
        j.at("coin").get_to(cfg.coin);
        j.at("from").get_to(cfg.from);
        j.at("to").get_to(cfg.to);
        j.at("tx_hash").get_to(cfg.tx_hash);
        j.at("my_balance_change").get_to(cfg.my_balance_change);
        j.at("received_by_me").get_to(cfg.received_by_me);
        j.at("spent_by_me").get_to(cfg.spent_by_me);
        j.at("timestamp").get_to(cfg.timestamp);

        // internal_id is numeric for ZHTLC - needs conversion
        //if (j.contains("internal_id"))
        //{
        //    cfg.internal_id = j.at("internal_id").get<std::string>();
        //}
        if (j.at("timestamp").get<std::size_t>() != 0)
        {
            cfg.timestamp = j.at("timestamp").get<std::size_t>();
        }
        else
        {
            using namespace std::chrono;
            cfg.timestamp      = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        }

        if (j.contains("confirmations"))
        {
            cfg.confirmations = j.at("confirmations").get<std::size_t>();
        }

        // API returns null if no memo
        if (j.contains("memo"))
        {
            try
            {
                cfg.memo = j.at("memo").get<std::string>();
            }
            catch (const std::exception& ex)
            {
                cfg.memo = "";
                //SPDLOG_ERROR("Error parsing memo: {}", ex.what());
            }
        }

        if (cfg.from.empty())
        {
            if (cfg.coin == "FIRO")
            {
                cfg.from.emplace_back("Lelantusjsplit (Hidden)");
            }
            else
            {
                cfg.from.emplace_back("Shielded");
            }
        }

        if (j.contains("transaction_type"))
        {
            cfg.transaction_type = j.at("transaction_type").get<std::string>();
        }

        // transaction_fee only in ZHTLC response
        if (j.contains("transaction_fee"))
        {
            cfg.transaction_fee = j.at("transaction_fee").get<std::string>();
        }
        else if (j.contains("fee_details"))
        {
            j.at("fee_details").get_to(cfg.fee_details);
        }

        // total_amount not in ZHTLC response
        if (j.contains("total_amount"))
        {
            j.at("total_amount").get_to(cfg.total_amount);
        }

        // tx_hex not in ZHTLC response
        if (j.contains("tx_hex"))
        {
            j.at("tx_hex").get_to(cfg.tx_hex);
        }

        std::string s         = atomic_dex::utils::to_human_date<std::chrono::seconds>(cfg.timestamp, "%e %b %Y, %H:%M");
        cfg.timestamp_as_date = std::move(s);
    }
} // namespace atomic_dex::mm2