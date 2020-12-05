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

//! Project Headers
#include "atomicdex/api/mm2/mm2.hpp"
#include "atomicdex/utilities/global.utilities.hpp"

//! Utilities
namespace
{
    template <typename RpcSuccessReturnType, typename RpcReturnType>
    void
    extract_rpc_json_answer(const nlohmann::json& j, RpcReturnType& answer)
    {
        if (j.contains("error") && j.at("error").is_string())
        {
            answer.error = j.at("error").get<std::string>();
        }
        else if (j.contains("result"))
        {
            answer.result = j.at("result").get<RpcSuccessReturnType>();
        }
    }
} // namespace

//! Implementation RPC [max_taker_vol]
namespace mm2::api
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const max_taker_vol_request& cfg)
    {
        j["coin"] = cfg.coin;
        if (cfg.trade_with.has_value())
        {
            j["trade_with"] = cfg.trade_with.value();
        }
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, max_taker_vol_answer_success& cfg)
    {
        j.at("denom").get_to(cfg.denom);
        j.at("numer").get_to(cfg.numer);
        t_rational rat(boost::multiprecision::cpp_int(cfg.numer), boost::multiprecision::cpp_int(cfg.denom));
        t_float_50 res = rat.convert_to<t_float_50>();
        cfg.decimal    = res.str(8);
    }

    void
    from_json(const nlohmann::json& j, max_taker_vol_answer& answer)
    {
        extract_rpc_json_answer<max_taker_vol_answer_success>(j, answer);
    }

    //! Rpc Call
    max_taker_vol_answer
    rpc_max_taker_vol(max_taker_vol_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<max_taker_vol_request, max_taker_vol_answer>(std::forward<max_taker_vol_request>(request), "max_taker_vol", mm2_client);
    }
} // namespace mm2::api

//! Implementation RPC [enable]
namespace mm2::api
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const enable_request& cfg)
    {
        j["coin"] = cfg.coin_name;
        if (cfg.coin_type == atomic_dex::ERC20)
        {
            j["gas_station_url"]       = cfg.gas_station_url;
            j["swap_contract_address"] = cfg.erc_swap_contract_address;
            j["urls"]                  = cfg.urls;
        }
        j["tx_history"] = cfg.with_tx_history;
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, enable_answer& cfg)
    {
        j.at("address").get_to(cfg.address);
        j.at("balance").get_to(cfg.balance);
        j.at("result").get_to(cfg.result);
    }
} // namespace mm2::api

//! Implementation RPC [electrum]
namespace mm2::api
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const electrum_request& cfg)
    {
        j["coin"]       = cfg.coin_name;
        j["servers"]    = cfg.servers;
        j["tx_history"] = cfg.with_tx_history;
        if (cfg.coin_type == atomic_dex::QRC20)
        {
            j["swap_contract_address"] = cfg.is_testnet ? cfg.testnet_qrc_swap_contract_address : cfg.mainnet_qrc_swap_contract_address;
        }
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, electrum_answer& cfg)
    {
        j.at("address").get_to(cfg.address);
        j.at("balance").get_to(cfg.balance);
        j.at("result").get_to(cfg.result);
    }
} // namespace mm2::api

//! Implementation RPC [disable_coin]
namespace mm2::api
{
    //! Serialization
    void
    to_json(nlohmann::json& j, const disable_coin_request& req)
    {
        j["coin"] = req.coin;
    }

    //! Deserialization
    void
    from_json(const nlohmann::json& j, disable_coin_answer_success& resp)
    {
        j.at("coin").get_to(resp.coin);
    }

    void
    from_json(const nlohmann::json& j, disable_coin_answer& resp)
    {
        extract_rpc_json_answer<disable_coin_answer_success>(j, resp);
    }
} // namespace mm2::api

namespace mm2::api
{
    void
    to_json(nlohmann::json& j, const balance_request& cfg)
    {
        j["coin"] = cfg.coin;
    }

    void
    from_json(const nlohmann::json& j, balance_answer& cfg)
    {
        j.at("address").get_to(cfg.address);
        j.at("balance").get_to(cfg.balance);
        cfg.balance = atomic_dex::utils::adjust_precision(cfg.balance);
        j.at("coin").get_to(cfg.coin);
        if (cfg.coin == "BCH")
        {
            cfg.address = cfg.address.substr(sizeof("bitcoincash"));
        }
    }

    void
    from_json(const nlohmann::json& j, fee_regular_coin& cfg)
    {
        j.at("amount").get_to(cfg.amount);
    }

    void
    from_json(const nlohmann::json& j, fee_erc_coin& cfg)
    {
        j.at("coin").get_to(cfg.coin);
        j.at("gas").get_to(cfg.gas);
        j.at("gas_price").get_to(cfg.gas_price);
        j.at("total_fee").get_to(cfg.total_fee);
    }

    void
    from_json(const nlohmann::json& j, fee_qrc_coin& cfg)
    {
        j.at("coin").get_to(cfg.coin);
        j.at("gas_limit").get_to(cfg.gas_limit);
        j.at("gas_price").get_to(cfg.gas_price);
        j.at("miner_fee").get_to(cfg.miner_fee);
        j.at("total_gas_fee").get_to(cfg.total_gas_fee);
    }

    void
    from_json(const nlohmann::json& j, fees_data& cfg)
    {
        if (j.count("amount") == 1)
        {
            cfg.normal_fees = fee_regular_coin{};
            from_json(j, cfg.normal_fees.value());
        }
        else if (j.at("coin").get<std::string>() == "ETH")
        {
            cfg.erc_fees = fee_erc_coin{};
            from_json(j, cfg.erc_fees.value());
        }
        else if (j.at("coin").get<std::string>() == "QTUM" || j.at("coin").get<std::string>() == "tQTUM")
        {
            cfg.qrc_fees = fee_qrc_coin{};
            from_json(j, cfg.qrc_fees.value());
        }
    }

    void
    to_json(nlohmann::json& j, const tx_history_request& cfg)
    {
        j["coin"]  = cfg.coin;
        j["limit"] = cfg.limit;
    }

    void
    from_json(const nlohmann::json& j, transaction_data& cfg)
    {
        j.at("block_height").get_to(cfg.block_height);
        j.at("coin").get_to(cfg.coin);
        if (j.count("confirmations") == 1)
        {
            cfg.confirmations = j.at("confirmations").get<std::size_t>();
        }
        j.at("fee_details").get_to(cfg.fee_details);
        j.at("from").get_to(cfg.from);
        j.at("internal_id").get_to(cfg.internal_id);
        j.at("my_balance_change").get_to(cfg.my_balance_change);
        j.at("received_by_me").get_to(cfg.received_by_me);
        j.at("spent_by_me").get_to(cfg.spent_by_me);
        j.at("timestamp").get_to(cfg.timestamp);
        j.at("to").get_to(cfg.to);
        j.at("total_amount").get_to(cfg.total_amount);
        j.at("tx_hash").get_to(cfg.tx_hash);
        j.at("tx_hex").get_to(cfg.tx_hex);

        std::string s         = atomic_dex::utils::to_human_date<std::chrono::seconds>(cfg.timestamp, "%e %b %Y, %H:%M");
        cfg.timestamp_as_date = std::move(s);
    }

    void
    from_json(const nlohmann::json& j, sync_status_additional_error& answer)
    {
        j.at("code").get_to(answer.code);
        j.at("message").get_to(answer.message);
    }


    void
    from_json(const nlohmann::json& j, sync_status_eth_erc_20_coins& answer)
    {
        j.at("blocks_left").get_to(answer.blocks_left);
    }

    void
    from_json(const nlohmann::json& j, sync_status_regular_coins& answer)
    {
        j.at("transactions_left").get_to(answer.transactions_left);
    }

    void
    from_json(const nlohmann::json& j, sync_status_additional_infos& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.get<sync_status_additional_error>();
        }
        else if (j.count("blocks_left") == 1)
        {
            answer.erc_infos = j.get<sync_status_eth_erc_20_coins>();
        }
        else if (j.count("transactions_left") == 1)
        {
            answer.regular_infos = j.get<sync_status_regular_coins>();
        }
    }

    void
    from_json(const nlohmann::json& j, t_sync_status& answer)
    {
        j.at("state").get_to(answer.state);
        if (j.count("additional_info") == 1)
        {
            answer.additional_info = j.at("additional_info").get<sync_status_additional_infos>();
        }
    }

    void
    from_json(const nlohmann::json& j, tx_history_answer_success& answer)
    {
        if (j.contains("from_id"))
        {
            if (not j.at("from_id").is_null())
                j.at("from_id").get_to(answer.from_id);
        }
        if (j.contains("current_block"))
        {
            j.at("current_block").get_to(answer.current_block);
        }
        j.at("limit").get_to(answer.limit);
        j.at("skipped").get_to(answer.skipped);
        if (j.contains("sync_status"))
        {
            j.at("sync_status").get_to(answer.sync_status);
        }
        j.at("total").get_to(answer.total);
        j.at("transactions").get_to(answer.transactions);
    }

    void
    from_json(const nlohmann::json& j, tx_history_answer& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.at("result").get<tx_history_answer_success>();
        }
    }

    void
    to_json(nlohmann::json& j, const recover_funds_of_swap_request& cfg)
    {
        j["params"]         = nlohmann::json::object();
        j["params"]["uuid"] = cfg.swap_uuid;
    }

    void
    from_json(const nlohmann::json& j, recover_funds_of_swap_answer_success& answer)
    {
        j.at("action").get_to(answer.action);
        j.at("coin").get_to(answer.coin);
        j.at("tx_hash").get_to(answer.tx_hash);
        j.at("tx_hex").get_to(answer.tx_hex);
    }

    void
    from_json(const nlohmann::json& j, recover_funds_of_swap_answer& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.at("result").get<recover_funds_of_swap_answer_success>();
        }
    }

    void
    to_json(nlohmann::json& j, const withdraw_fees& cfg)
    {
        j["type"] = cfg.type;
        if (cfg.type == "EthGas")
        {
            j["gas"]       = cfg.gas_limit.value_or(55000);
            j["gas_price"] = cfg.gas_price.value();
        }
        else if (cfg.type == "Qrc20Gas")
        {
            j["gas_limit"] = cfg.gas_limit.value_or(40);
            j["gas_price"] = std::stoi(cfg.gas_price.value());
        }
        else
        {
            j["amount"] = cfg.amount.value();
        }
    }

    void
    to_json(nlohmann::json& j, const withdraw_request& cfg)
    {
        j["coin"]   = cfg.coin;
        j["amount"] = cfg.amount;
        j["to"]     = cfg.to;
        j["max"]    = cfg.max;
        if (cfg.fees.has_value())
        {
            j["fee"] = cfg.fees.value();
        }
    }

    void
    from_json(const nlohmann::json& j, withdraw_answer& answer)
    {
        if (j.count("error") >= 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.get<transaction_data>();
        }
    }

    void
    to_json(nlohmann::json& j, const send_raw_transaction_request& cfg)
    {
        j["coin"]   = cfg.coin;
        j["tx_hex"] = cfg.tx_hex;
    }

    void
    from_json(const nlohmann::json& j, send_raw_transaction_answer& answer)
    {
        j.at("tx_hash").get_to(answer.tx_hash);
    }

    void
    to_json(nlohmann::json& j, const orderbook_request& request)
    {
        j["base"] = request.base;
        j["rel"]  = request.rel;
    }

    void
    to_json(nlohmann::json& j, const trade_fee_request& cfg)
    {
        j["coin"] = cfg.coin;
    }

    void
    from_json(const nlohmann::json& j, order_contents& contents)
    {
        j.at("coin").get_to(contents.coin);
        j.at("address").get_to(contents.address);
        j.at("price").get_to(contents.price);
        // contents.price = t_float_50(contents.price).str(8, std::ios_base::fixed);
        j.at("price_fraction").at("numer").get_to(contents.price_fraction_numer);
        j.at("price_fraction").at("denom").get_to(contents.price_fraction_denom);
        j.at("max_volume_fraction").at("numer").get_to(contents.max_volume_fraction_numer);
        j.at("max_volume_fraction").at("denom").get_to(contents.max_volume_fraction_denom);
        j.at("maxvolume").get_to(contents.maxvolume);
        j.at("pubkey").get_to(contents.pubkey);
        j.at("age").get_to(contents.age);
        j.at("zcredits").get_to(contents.zcredits);
        j.at("uuid").get_to(contents.uuid);
        j.at("is_mine").get_to(contents.is_mine);

        if (contents.price.find('.') != std::string::npos)
        {
            boost::trim_right_if(contents.price, boost::is_any_of("0"));
            contents.price = contents.price;
        }
        contents.maxvolume = atomic_dex::utils::adjust_precision(contents.maxvolume);
        t_float_50 total_f = t_float_50(contents.price) * t_float_50(contents.maxvolume);
        contents.total     = atomic_dex::utils::adjust_precision(total_f.str());
    }

    void
    from_json(const nlohmann::json& j, orderbook_answer& answer)
    {
        using namespace date;

        j.at("base").get_to(answer.base);
        j.at("rel").get_to(answer.rel);
        j.at("askdepth").get_to(answer.askdepth);
        j.at("biddepth").get_to(answer.biddepth);
        j.at("bids").get_to(answer.bids);
        j.at("asks").get_to(answer.asks);
        j.at("numasks").get_to(answer.numasks);
        j.at("numbids").get_to(answer.numbids);
        j.at("netid").get_to(answer.netid);
        j.at("timestamp").get_to(answer.timestamp);

        answer.human_timestamp = atomic_dex::utils::to_human_date(answer.timestamp, "%Y-%m-%d %I:%M:%S");

        t_float_50 result_asks_f("0");
        for (auto&& cur_asks: answer.asks) { result_asks_f = result_asks_f + t_float_50(cur_asks.maxvolume); }

        answer.asks_total_volume = result_asks_f.str();

        t_float_50 result_bids_f("0");
        for (auto& cur_bids: answer.bids)
        {
            cur_bids.total        = cur_bids.maxvolume;
            t_float_50 new_volume = t_float_50(cur_bids.maxvolume) / t_float_50(cur_bids.price);
            cur_bids.maxvolume    = atomic_dex::utils::adjust_precision(new_volume.str());
            result_bids_f         = result_bids_f + t_float_50(cur_bids.maxvolume);
        }

        answer.bids_total_volume = result_bids_f.str();
        for (auto&& cur_asks: answer.asks)
        {
            t_float_50 percent_f   = t_float_50(cur_asks.maxvolume) / result_asks_f;
            cur_asks.depth_percent = atomic_dex::utils::adjust_precision(percent_f.str());
        }

        for (auto&& cur_bids: answer.bids)
        {
            t_float_50 percent_f   = t_float_50(cur_bids.maxvolume) / result_bids_f;
            cur_bids.depth_percent = atomic_dex::utils::adjust_precision(percent_f.str());
        }
    }

    void
    from_json(const nlohmann::json& j, trade_fee_answer& cfg)
    {
        j.at("result").at("amount").get_to(cfg.amount);
        j.at("result").at("coin").get_to(cfg.coin);
    }

    void
    to_json(nlohmann::json& j, const setprice_request& request)
    {
        j["base"]            = request.base;
        j["price"]           = request.price;
        j["rel"]             = request.rel;
        j["volume"]          = request.volume;
        j["cancel_previous"] = request.cancel_previous;
        j["max"]             = request.max;
    }

    void
    from_json(const nlohmann::json& j, trading_order_contents& contents)
    {
        j.at("base").get_to(contents.base);
        j.at("base_amount").get_to(contents.base_amount);
        j.at("rel").get_to(contents.rel);
        j.at("rel_amount").get_to(contents.rel_amount);
        j.at("method").get_to(contents.method);
        j.at("action").get_to(contents.action);
        j.at("uuid").get_to(contents.uuid);
        j.at("sender_pubkey").get_to(contents.sender_pubkey);
        j.at("dest_pub_key").get_to(contents.dest_pub_key);
    }

    void
    from_json(const nlohmann::json& j, buy_answer_success& contents)
    {
        j.get_to(contents.contents);
    }

    void
    from_json(const nlohmann::json& j, buy_answer& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.at("result").get<buy_answer_success>();
        }
    }

    void
    to_json(nlohmann::json& j, const buy_request& request)
    {
        j["base"]   = request.base;
        j["price"]  = request.price;
        j["rel"]    = request.rel;
        j["volume"] = request.volume;
        if (request.base_nota.has_value())
        {
            j["base_nota"] = request.base_nota.value();
        }
        if (request.base_confs.has_value())
        {
            j["base_confs"] = request.base_confs.value();
        }
        if (not request.is_created_order)
        {
            //! From orderbook
            nlohmann::json price_fraction_repr = nlohmann::json::object();
            price_fraction_repr["numer"]       = request.price_numer;
            price_fraction_repr["denom"]       = request.price_denom;
            j["price"]                         = price_fraction_repr;
            nlohmann::json volume_fraction_repr = nlohmann::json::object();
            if (not request.selected_order_use_input_volume)
            {
                volume_fraction_repr["numer"] = request.volume_numer;
                volume_fraction_repr["denom"] = request.volume_denom;
                j["volume"]                   = volume_fraction_repr;
            }
            SPDLOG_INFO("The order is picked from the orderbook price: {}, volume: {}", j.at("price").dump(4), j.at("volume").dump(4));
        }
        else
        {
            SPDLOG_INFO("The order is not picked from orderbook we create it from volume = {}, price = {}", j.at("volume").dump(4), request.price);
        }
    }

    void
    to_json(nlohmann::json& j, const sell_request& request)
    {
        SPDLOG_DEBUG("price: {}, volume: {}", request.price, request.volume);

        auto volume_fraction_functor = [&request]() {
            nlohmann::json volume_fraction_repr = nlohmann::json::object();
            volume_fraction_repr["numer"]       = request.volume_numer;
            volume_fraction_repr["denom"]       = request.volume_denom;
            return volume_fraction_repr;
        };

        j["base"]   = request.base;
        j["rel"]    = request.rel;
        j["volume"] = request.volume; //< First take the user input
        if (request.is_max)           //< It's a real max means user want to sell his base_max_taker_vol let's take the fraction repr
        {
            j["volume"] = volume_fraction_functor();
        }
        j["price"] = request.price;
        if (request.rel_nota.has_value())
        {
            j["rel_nota"] = request.rel_nota.value();
        }
        if (request.rel_confs.has_value())
        {
            j["rel_confs"] = request.rel_confs.value();
        }

        if (not request.is_created_order)
        {
            //! From orderbook
            nlohmann::json price_fraction_repr = nlohmann::json::object();
            price_fraction_repr["numer"]       = request.price_numer;
            price_fraction_repr["denom"]       = request.price_denom;
            j["price"]                         = price_fraction_repr;
            if (request.is_exact_selected_order_volume)
            {
                j["volume"] = volume_fraction_functor();
            }
            SPDLOG_INFO("The order is picked from the orderbook price: {}, volume: {}", j.at("price").dump(4), j.at("volume").dump(4));
        }
        else
        {
            SPDLOG_INFO("The order is not picked from orderbook we create it from volume = {}, price = {}", j.at("volume").dump(4), request.price);
        }
    }

    void
    from_json(const nlohmann::json& j, sell_answer_success& contents)
    {
        j.get_to(contents.contents);
    }

    void
    from_json(const nlohmann::json& j, sell_answer& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.at("result").get<sell_answer_success>();
        }
    }

    void
    to_json(nlohmann::json& j, const cancel_order_request& request)
    {
        j["uuid"] = request.uuid;
    }

    void
    from_json(const nlohmann::json& j, cancel_order_answer& answer)
    {
        if (j.count("error") == 1)
        {
            answer.error = j.at("error").get<std::string>();
        }
        else
        {
            answer.result = j.at("result").get<std::string>();
        }
    }

    void
    to_json(nlohmann::json& j, const cancel_data& cfg)
    {
        if (cfg.pair.has_value())
        {
            auto [base, rel] = cfg.pair.value();
            j["base"]        = base;
            j["rel"]         = rel;
        }
        else if (cfg.ticker.has_value())
        {
            j["ticker"] = cfg.ticker.value();
        }
    }

    void
    to_json(nlohmann::json& j, const cancel_type& cfg)
    {
        j["type"] = cfg.type;
        if (cfg.type not_eq "All" and cfg.data.has_value())
        {
            j["data"] = cfg.data.value();
        }
    }

    void
    to_json(nlohmann::json& j, const cancel_all_orders_request& cfg)
    {
        j["cancel_by"] = cfg.cancel_by;
    }

    void
    from_json(const nlohmann::json& j, cancel_all_orders_answer& answer)
    {
        j.at("result").at("cancelled").get_to(answer.cancelled);
        j.at("result").at("currently_matching").get_to(answer.currently_matching);
    }

    void
    from_json(const nlohmann::json& j, my_orders_answer& answer)
    {
        static_cast<void>(answer);
        // clang-format off
        auto filler_functor = [](const std::string& key, const nlohmann::json& value, std::map<std::string, my_order_contents>& out, bool is_maker)
        {
          using namespace date;
          const auto        time_key = value.at("created_at").get<std::size_t>();

          std::string action = "";
          if (not is_maker)
          {
             value.at("request").at("action").get_to(action);
          }
          my_order_contents contents{
              .order_id         = key,
              .price            = is_maker ? atomic_dex::utils::adjust_precision(value.at("price").get<std::string>()) : "0",
              .base             = is_maker ? value.at("base").get<std::string>() : value.at("request").at("base").get<std::string>(),
              .rel              = is_maker ? value.at("rel").get<std::string>() : value.at("request").at("rel").get<std::string>(),
              .cancellable      = value.at("cancellable").get<bool>(),
              .timestamp        = time_key,
              .order_type       = is_maker ? "maker" : "taker",
              .base_amount      = is_maker ? value.at("available_amount").get<std::string>() : value.at("request").at("base_amount").get<std::string>(),
              .rel_amount       = is_maker ? (t_float_50(contents.price) * t_float_50(contents.base_amount)).convert_to<std::string>() : value.at("request").at("rel_amount").get<std::string>(),
              .human_timestamp  = atomic_dex::utils::to_human_date<std::chrono::seconds>(time_key / 1000, "%F    %T"),
              .action = action};
          out.try_emplace(contents.order_id, std::move(contents));
        };
        // clang-format on

        for (auto&& [key, value]: j.at("result").at("maker_orders").items()) { filler_functor(key, value, answer.maker_orders, true); }
        for (auto&& [key, value]: j.at("result").at("taker_orders").items()) { filler_functor(key, value, answer.taker_orders, false); }
    }

    void
    to_json(nlohmann::json& j, const my_recent_swaps_request& request)
    {
        j["limit"] = request.limit;
        if (request.from_uuid.has_value())
        {
            j["from_uuid"] = request.from_uuid.value();
        }
    }

    void
    from_json(const nlohmann::json& j, swap_contents& contents)
    {
        using namespace date;
        using namespace std::chrono;

        j.at("error_events").get_to(contents.error_events);
        j.at("success_events").get_to(contents.success_events);
        j.at("uuid").get_to(contents.uuid);
        j.at("taker_coin").get_to(contents.taker_coin);
        j.at("maker_coin").get_to(contents.maker_coin);
        j.at("taker_amount").get_to(contents.taker_amount);
        j.at("maker_amount").get_to(contents.maker_amount);
        j.at("type").get_to(contents.type);
        j.at("recoverable").get_to(contents.funds_recoverable);

        contents.taker_amount = atomic_dex::utils::adjust_precision(contents.taker_amount);
        contents.maker_amount = atomic_dex::utils::adjust_precision(contents.maker_amount);
        contents.events       = nlohmann::json::array();
        if (j.contains("my_info"))
        {
            contents.my_info = j.at("my_info");
            if (not contents.my_info.is_null())
            {
                contents.my_info["other_amount"] = atomic_dex::utils::adjust_precision(contents.my_info["other_amount"].get<std::string>());
                contents.my_info["my_amount"]    = atomic_dex::utils::adjust_precision(contents.my_info["my_amount"].get<std::string>());
            }
        }
        using t_event_timestamp_registry = std::unordered_map<std::string, std::uint64_t>;
        t_event_timestamp_registry event_timestamp_registry;
        double                     total_time_in_ms = 0.00;

        std::size_t idx    = 0;
        const auto& events = j.at("events");
        for (auto&& content: events)
        {
            const nlohmann::json& j_evt      = content.at("event");
            auto                  timestamp  = content.at("timestamp").get<std::size_t>();
            std::string           human_date = atomic_dex::utils::to_human_date<std::chrono::seconds>(timestamp / 1000, "%F    %H:%M:%S");
            auto                  evt_type   = j_evt.at("type").get<std::string>();

            auto rate_bundler = [&event_timestamp_registry,
                                 &total_time_in_ms](nlohmann::json& jf_evt, const std::string& event_type, const std::string& previous_event) {
                if (event_timestamp_registry.count(previous_event) != 0)
                {
                    std::int64_t ts                         = event_timestamp_registry.at(previous_event);
                    jf_evt["started_at"]                    = ts;
                    std::int64_t                        ts2 = jf_evt.at("timestamp").get<std::int64_t>();
                    sys_time<std::chrono::milliseconds> t1{std::chrono::milliseconds{ts}};
                    sys_time<std::chrono::milliseconds> t2{std::chrono::milliseconds{ts2}};
                    double                              res = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
                    jf_evt["time_diff"]                     = res;
                    event_timestamp_registry[event_type]    = ts2; // Negotiated finished at this time
                    total_time_in_ms += res;
                }
            };

            if (j_evt.count("data") == 0)
            {
                nlohmann::json jf_evt = {{"state", evt_type}, {"human_timestamp", human_date}, {"timestamp", timestamp}};

                if (idx > 0)
                {
                    rate_bundler(jf_evt, evt_type, events[idx - 1].at("event").at("type").get<std::string>());
                }

                contents.events.push_back(jf_evt);
            }
            else
            {
                nlohmann::json jf_evt = {{"state", evt_type}, {"human_timestamp", human_date}, {"data", j_evt.at("data")}, {"timestamp", timestamp}};
                if (evt_type == "Started")
                {
                    std::int64_t ts                         = jf_evt.at("data").at("started_at").get<std::int64_t>() * 1000;
                    jf_evt["started_at"]                    = ts;
                    std::int64_t                        ts2 = jf_evt.at("timestamp").get<std::int64_t>();
                    sys_time<std::chrono::milliseconds> t1{std::chrono::milliseconds{ts}};
                    sys_time<std::chrono::milliseconds> t2{std::chrono::milliseconds{ts2}};
                    double                              res = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
                    jf_evt["time_diff"]                     = res;
                    event_timestamp_registry["Started"]     = ts2; // Started finished at this time
                    total_time_in_ms += res;
                }

                if (idx > 0)
                {
                    rate_bundler(jf_evt, evt_type, events[idx - 1].at("event").at("type").get<std::string>());
                }

                contents.events.push_back(jf_evt);
            }
            idx += 1;
        }
        contents.total_time_in_ms = total_time_in_ms;
    }

    void
    from_json(const nlohmann::json& j, my_recent_swaps_answer_success& results)
    {
        j.at("swaps").get_to(results.swaps);
        j.at("limit").get_to(results.limit);
        j.at("skipped").get_to(results.skipped);
        j.at("total").get_to(results.total);
        results.average_events_time = nlohmann::json::object();

        std::unordered_map<std::string, std::vector<double>> events_time_registry;
        for (auto&& cur_swap: results.swaps)
        {
            for (auto&& cur_event: cur_swap.events)
            {
                if (cur_event.contains("time_diff"))
                {
                    events_time_registry[cur_event.at("state").get<std::string>()].push_back(cur_event.at("time_diff").get<double>());
                }
            }
        }

        for (auto&& [evt_name, values]: events_time_registry)
        {
            double sum = 0;
            for (auto&& cur_value: values) { sum += cur_value; }
            double average                        = sum / values.size();
            results.average_events_time[evt_name] = average;
        }
    }

    void
    from_json(const nlohmann::json& j, my_recent_swaps_answer& answer)
    {
        if (j.find("result") != j.end())
        {
            answer.result                    = j.at("result").get<my_recent_swaps_answer_success>();
            answer.result.value().raw_result = answer.raw_result;
        }
        else if (j.find("error") != j.end())
        {
            answer.error = j.at("error").get<std::string>();
        }
    }

    enable_answer
    rpc_enable(enable_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<enable_request, enable_answer>(std::forward<enable_request>(request), "enable", mm2_client);
    }

    electrum_answer
    rpc_electrum(electrum_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<electrum_request, electrum_answer>(std::forward<electrum_request>(request), "electrum", mm2_client);
    }

    balance_answer
    rpc_balance(balance_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<balance_request, balance_answer>(std::forward<balance_request>(request), "my_balance", mm2_client);
    }

    tx_history_answer
    rpc_my_tx_history(tx_history_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<tx_history_request, tx_history_answer>(std::forward<tx_history_request>(request), "my_tx_history", mm2_client);
    }

    withdraw_answer
    rpc_withdraw(withdraw_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<withdraw_request, withdraw_answer>(std::forward<withdraw_request>(request), "withdraw", mm2_client);
    }

    send_raw_transaction_answer
    rpc_send_raw_transaction(send_raw_transaction_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        using atomic_dex::t_broadcast_answer;
        using atomic_dex::t_broadcast_request;

        return process_rpc<t_broadcast_request, t_broadcast_answer>(std::forward<t_broadcast_request>(request), "send_raw_transaction", mm2_client);
    }

    trade_fee_answer
    rpc_get_trade_fee(trade_fee_request&& req, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<trade_fee_request, trade_fee_answer>(std::forward<trade_fee_request>(req), "get_trade_fee", mm2_client);
    }

    orderbook_answer
    rpc_orderbook(orderbook_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<orderbook_request, orderbook_answer>(std::forward<orderbook_request>(request), "orderbook", mm2_client);
    }

    buy_answer
    rpc_buy(buy_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<buy_request, buy_answer>(std::forward<buy_request>(request), "buy", mm2_client);
    }

    sell_answer
    rpc_sell(sell_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<sell_request, sell_answer>(std::forward<sell_request>(request), "sell", mm2_client);
    }

    cancel_order_answer
    rpc_cancel_order(cancel_order_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<cancel_order_request, cancel_order_answer>(std::forward<cancel_order_request>(request), "cancel_order", mm2_client);
    }

    cancel_all_orders_answer
    rpc_cancel_all_orders(cancel_all_orders_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<cancel_all_orders_request, cancel_all_orders_answer>(
            std::forward<cancel_all_orders_request>(request), "cancel_all_orders", mm2_client);
    }

    disable_coin_answer
    rpc_disable_coin(disable_coin_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<disable_coin_request, disable_coin_answer>(std::forward<disable_coin_request>(request), "disable_coin", mm2_client);
    }

    recover_funds_of_swap_answer
    rpc_recover_funds(recover_funds_of_swap_request&& request, std::shared_ptr<t_http_client> mm2_client)
    {
        return process_rpc<recover_funds_of_swap_request, recover_funds_of_swap_answer>(
            std::forward<recover_funds_of_swap_request>(request), "recover_funds_of_swap", mm2_client);
    }

    template <typename TRequest, typename TAnswer>
    static TAnswer
    process_rpc(TRequest&& request, std::string rpc_command, std::shared_ptr<t_http_client> mm2_http_client)
    {
        SPDLOG_INFO("Processing rpc call: {}", rpc_command);

        nlohmann::json json_data = template_request(rpc_command);

        to_json(json_data, request);

        auto json_copy        = json_data;
        json_copy["userpass"] = "*******";
        SPDLOG_DEBUG("request: {}", json_copy.dump());

        if (mm2_http_client != nullptr)
        {
            web::http::http_request request(web::http::methods::POST);
            request.headers().set_content_type(FROM_STD_STR("application/json"));
            request.set_body(json_data.dump());
            auto resp = mm2_http_client->request(request).get();
            return rpc_process_answer<TAnswer>(resp, rpc_command);
        }

        return TAnswer{};
    }

    nlohmann::json
    template_request(std::string method_name) noexcept
    {
        return {{"method", std::move(method_name)}, {"userpass", get_rpc_password()}};
    }

    std::string
    rpc_version()
    {
        nlohmann::json json_data = template_request("version");
        try
        {
            auto                    client = std::make_unique<web::http::client::http_client>(FROM_STD_STR("http://127.0.0.1:7783"));
            web::http::http_request request;
            request.set_method(web::http::methods::POST);
            request.set_body(json_data.dump());
            web::http::http_response resp = client->request(request).get();
            if (resp.status_code() == 200)
            {
                std::string    body      = TO_STD_STR(resp.extract_string(true).get());
                nlohmann::json body_json = nlohmann::json::parse(body);
                return body_json.at("result").get<std::string>();
            }

            return "error occured during rpc_version";
        }
        catch (const web::http::http_exception& exception)
        {
            return "error occured during rpc_version";
        }
        return "";
    }

    kmd_rewards_info_answer
    process_kmd_rewards_answer(nlohmann::json result)
    {
        kmd_rewards_info_answer out;
        out.result                                       = result;
        auto transform_timestamp_into_human_date_functor = [](nlohmann::json& obj, const std::string& field) {
            if (obj.contains(field))
            {
                auto obj_timestamp         = obj.at(field).get<std::size_t>();
                obj[field + "_human_date"] = atomic_dex::utils::to_human_date<std::chrono::seconds>(obj_timestamp, "%e %b %Y, %H:%M");
            }
        };

        for (auto&& obj: out.result.at("result"))
        {
            for (const auto& field: {"accrue_start_at", "accrue_stop_at", "locktime"}) { transform_timestamp_into_human_date_functor(obj, field); }
        }
        return out;
    }

    pplx::task<web::http::http_response>
    async_rpc_batch_standalone(nlohmann::json batch_array, std::shared_ptr<t_http_client> mm2_http_client, pplx::cancellation_token token)
    {
        if (mm2_http_client != nullptr)
        {
            web::http::http_request request;
            request.set_method(web::http::methods::POST);
            request.set_body(batch_array.dump());
            auto resp = mm2_http_client->request(request, token);
            return resp;
        }
        return {};
    }

    nlohmann::json
    basic_batch_answer(const web::http::http_response& resp)
    {
        nlohmann::json answer;
        std::string    body = TO_STD_STR(resp.extract_string(true).get());
        try
        {
            answer = nlohmann::json::parse(body);
        }
        catch (const nlohmann::detail::parse_error& err)
        {
            SPDLOG_ERROR("exception caught {}, body: {}", err.what(), body);
            answer["error"] = body;
        }
        return answer;
    }

    nlohmann::json
    rpc_batch_standalone(nlohmann::json batch_array, std::shared_ptr<t_http_client> mm2_http_client)
    {
        if (mm2_http_client != nullptr)
        {
            web::http::http_request request;
            request.set_method(web::http::methods::POST);
            request.set_body(batch_array.dump());
            auto resp = mm2_http_client->request(request).get();


            SPDLOG_INFO("{} resp code: {}", __FUNCTION__, resp.status_code());

            nlohmann::json answer;
            std::string    body = TO_STD_STR(resp.extract_string(true).get());
            try
            {
                answer = nlohmann::json::parse(body);
            }
            catch (const nlohmann::detail::parse_error& err)
            {
                SPDLOG_ERROR("{}, body: {}", err.what(), body);
                answer["error"] = body;
            }
            return answer;
        }
        return nlohmann::json::array();
    }

    static inline std::string&
    access_rpc_password() noexcept
    {
        static std::string rpc_password;
        return rpc_password;
    }

    void
    set_rpc_password(std::string rpc_password) noexcept
    {
        access_rpc_password() = std::move(rpc_password);
    }

    const std::string&
    get_rpc_password() noexcept
    {
        return access_rpc_password();
    }
} // namespace mm2::api
