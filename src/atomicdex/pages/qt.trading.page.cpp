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

#include <QJsonDocument>

//! PCH
#include "src/atomicdex/pch.hpp"

//! Project Headers
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"
#include "qt.trading.page.hpp"

namespace
{
    void
    set_multi_ticker_data(
        const QString& ticker, atomic_dex::portfolio_model::PortfolioRoles role, QVariant data, atomic_dex::portfolio_proxy_model* multi_ticker_model)
    {
        if (const auto res = multi_ticker_model->sourceModel()->match(multi_ticker_model->index(0, 0), atomic_dex::portfolio_model::TickerRole, ticker);
            not res.isEmpty())
        {
            const QModelIndex& idx = res.at(0);
            multi_ticker_model->sourceModel()->setData(idx, data, role);
        }
    }

    template <typename T>
    T
    get_multi_ticker_data(const QString& ticker, atomic_dex::portfolio_model::PortfolioRoles role, atomic_dex::portfolio_proxy_model* multi_ticker_model)
    {
        if (const auto res = multi_ticker_model->sourceModel()->match(multi_ticker_model->index(0, 0), atomic_dex::portfolio_model::TickerRole, ticker);
            not res.isEmpty())
        {
            const QModelIndex& idx = res.at(0);
            return multi_ticker_model->sourceModel()->data(idx, role).value<T>();
        }
        return T{};
    }

    QString
    calculate_total_amount(QString price, QString volume)
    {
        t_float_50 price_f(price.toStdString());
        t_float_50 volume_f(volume.toStdString());
        t_float_50 total_amount_f = volume_f * price_f;
        return QString::fromStdString(atomic_dex::utils::format_float(total_amount_f));
    }

    QVariantMap
    generate_fees_infos(const QString& base, const QString& rel, bool is_max, const QString& total_amount, const atomic_dex::mm2_service& mm2)
    {
        //! 1 / 777 * total_amount (if max is true, total_amount will be the balance);
        const t_float_50 trade_fee_f = mm2.get_trading_fees(base.toStdString(), total_amount.toStdString(), is_max);

        //! Transaction Fees
        const auto answer   = mm2.get_transaction_fees(base.toStdString());
        t_float_50 tx_fee_f = 0;

        //! If answer is valid
        if (!answer.amount.empty())
        {
            tx_fee_f = t_float_50(answer.amount) * 2;
        }

        t_float_50        specific_fees(0);
        const std::string extra_fees_ticker = mm2.apply_specific_fees(rel.toStdString(), specific_fees);

        //! Write output
        QVariantMap fees;

        fees["trading_fee"] = QString::fromStdString(atomic_dex::utils::format_float(trade_fee_f));

        //! for BCH <-> ETH, trading_fee_ticker will be BCH
        fees["trading_fee_ticker"] = base;

        //! Base transaction fees
        fees["base_transaction_fees"]        = QString::fromStdString(atomic_dex::utils::format_float(tx_fee_f));
        fees["base_transaction_fees_ticker"] = QString::fromStdString(answer.coin);

        if (not extra_fees_ticker.empty())
        {
            fees["rel_transaction_fees"]        = QString::fromStdString(atomic_dex::utils::format_float(specific_fees));
            fees["rel_transaction_fees_ticker"] = QString::fromStdString(extra_fees_ticker);
        }

        if (base.toStdString() == answer.coin)
        {
            //! It's the same coin for trading_fees and transaction fees let's add a total
            t_float_50 total_base_fees_f = trade_fee_f + tx_fee_f;
            fees["total_base_fees"]      = QString::fromStdString(atomic_dex::utils::format_float(total_base_fees_f));
            fees["total_base_fees_fp"]   = QString::fromStdString(total_base_fees_f.str(50, std::ios_base::fixed));
        }
        return fees;
    }
} // namespace

//! Consttructor / Destructor
namespace atomic_dex
{
    trading_page::trading_page(
        entt::registry& registry, ag::ecs::system_manager& system_manager, std::atomic_bool& exit_status, portfolio_model* portfolio, QObject* parent) :
        QObject(parent),
        system(registry), m_system_manager(system_manager),
        m_about_to_exit_the_app(exit_status), m_models{{new qt_orderbook_wrapper(m_system_manager, this), new market_pairs(portfolio, this)}}
    {
        //!
    }
} // namespace atomic_dex

//! Events callback
namespace atomic_dex
{
    void
    trading_page::on_process_orderbook_finished_event(const atomic_dex::process_orderbook_finished& evt) noexcept
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        if (not m_about_to_exit_the_app)
        {
            m_actions_queue.push(trading_actions::post_process_orderbook_finished);
            m_models_actions[orderbook_need_a_reset] = evt.is_a_reset;
            determine_max_volume();
        }
    }
} // namespace atomic_dex

//! Public QML API
namespace atomic_dex
{
    QVariant
    trading_page::get_raw_mm2_coin_cfg(const QString& ticker) const noexcept
    {
        QVariant       out;
        nlohmann::json j = m_system_manager.get_system<mm2_service>().get_raw_mm2_ticker_cfg(ticker.toStdString());
        out              = nlohmann_json_object_to_qt_json_object(j);
        return out;
    }

    void
    trading_page::set_current_orderbook(const QString& base, const QString& rel)
    {
        auto* market_selector_mdl = get_market_pairs_mdl();

        if (base != market_selector_mdl->get_left_selected_coin() || rel != market_selector_mdl->get_right_selected_coin())
        {
            this->clear_forms();
        }
        market_selector_mdl->set_left_selected_coin(base);
        market_selector_mdl->set_right_selected_coin(rel);

        market_selector_mdl->set_base_selected_coin(m_market_mode == MarketMode::Sell ? base : rel);
        market_selector_mdl->set_rel_selected_coin(m_market_mode == MarketMode::Sell ? rel : base);
        dispatcher_.trigger<orderbook_refresh>(base.toStdString(), rel.toStdString());
    }

    void
    trading_page::swap_market_pair()
    {
        auto* market_selector_mdl = get_market_pairs_mdl();
        set_current_orderbook(market_selector_mdl->get_right_selected_coin(), market_selector_mdl->get_left_selected_coin());
    }

    void
    trading_page::on_gui_enter_dex()
    {
        dispatcher_.trigger<gui_enter_trading>();
    }

    void
    trading_page::on_gui_leave_dex()
    {
        dispatcher_.trigger<gui_leave_trading>();
    }

    void
    trading_page::cancel_order(const QStringList& orders_id)
    {
        nlohmann::json batch = nlohmann::json::array();
        for (auto&& order_id: orders_id)
        {
            ::mm2::api::cancel_all_orders_request req;
            nlohmann::json                        cancel_request = ::mm2::api::template_request("cancel_order");
            ::mm2::api::cancel_order_request      cancel_req{order_id.toStdString()};
            to_json(cancel_request, cancel_req);
            batch.push_back(cancel_request);
        }
        nlohmann::json my_orders_request = ::mm2::api::template_request("my_orders");
        batch.push_back(my_orders_request);
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), pplx::cancellation_token::none())
            .then([this](web::http::http_response resp) {
                auto& mm2_system       = m_system_manager.get_system<mm2_service>();
                auto  answers          = ::mm2::api::basic_batch_answer(resp);
                auto  my_orders_answer = ::mm2::api::rpc_process_answer_batch<t_my_orders_answer>(answers[answers.size() - 1], "my_orders");
                mm2_system.add_orders_answer(my_orders_answer);
                // SPDLOG_DEBUG("refreshing orderbook after cancelling order: {}", answers.dump(4));
                mm2_system.process_orderbook(false);
            })
            .then(&handle_exception_pplx_task);
    }

    void
    trading_page::common_cancel_all_orders(bool by_coin, const QString& ticker)
    {
        nlohmann::json batch          = nlohmann::json::array();
        nlohmann::json cancel_request = ::mm2::api::template_request("cancel_all_orders");
        if (by_coin && not ticker.isEmpty())
        {
            ::mm2::api::cancel_data cd;
            cd.ticker = ticker.toStdString();
            ::mm2::api::cancel_all_orders_request req{{"Coin", cd}};
            ::mm2::api::to_json(cancel_request, req);
        }
        else
        {
            ::mm2::api::cancel_data cd;
            cd.ticker = ticker.toStdString();
            ::mm2::api::cancel_all_orders_request req_all;
            ::mm2::api::to_json(cancel_request, req_all);
        }

        batch.push_back(cancel_request);
        nlohmann::json my_orders_request = ::mm2::api::template_request("my_orders");
        batch.push_back(my_orders_request);
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), pplx::cancellation_token::none())
            .then([this](web::http::http_response resp) {
                auto& mm2_system       = m_system_manager.get_system<mm2_service>();
                auto  answers          = ::mm2::api::basic_batch_answer(resp);
                auto  my_orders_answer = ::mm2::api::rpc_process_answer_batch<t_my_orders_answer>(answers[1], "my_orders");
                mm2_system.add_orders_answer(my_orders_answer);
            })
            .then(&handle_exception_pplx_task);
    }

    void
    trading_page::cancel_all_orders()
    {
        common_cancel_all_orders();
    }

    void
    trading_page::cancel_all_orders_by_ticker(const QString& ticker)
    {
        common_cancel_all_orders(true, ticker);
    }

    void
    trading_page::fetch_additional_fees(const QString& ticker) noexcept
    {
        //! Async start
        this->set_fetching_multi_ticker_fees_busy(true);

        //! Batch preparation
        nlohmann::json          batch = nlohmann::json::array();
        t_get_trade_fee_request req_base{.coin = ticker.toStdString()};
        nlohmann::json          current_request = ::mm2::api::template_request("get_trade_fee");
        ::mm2::api::to_json(current_request, req_base);
        batch.push_back(current_request);

        //! System
        auto& mm2_system = m_system_manager.get_system<mm2_service>();

        auto answer_functor = [this, ticker_std = ticker.toStdString()](web::http::http_response resp) {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                auto           answers               = nlohmann::json::parse(body);
                nlohmann::json answer                = answers[0];
                auto&          mm2_system            = this->m_system_manager.get_system<mm2_service>();
                auto           trade_fee_base_answer = ::mm2::api::rpc_process_answer_batch<t_get_trade_fee_answer>(answer, "get_trade_fee");
                mm2_system.add_get_trade_fee_answer(ticker_std, trade_fee_base_answer);
            }
            this->set_fetching_multi_ticker_fees_busy(false);
            this->determine_multi_ticker_fees(QString::fromStdString(ticker_std));
        };

        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), mm2_system.get_cancellation_token())
            .then(answer_functor)
            .then(&handle_exception_pplx_task);
    }

    void
    trading_page::place_buy_order(const QString& base_nota, const QString& base_confs)
    {
        this->set_buy_sell_rpc_busy(true);
        this->set_buy_sell_last_rpc_data(QJsonObject{{}});

        const auto* market_selector   = get_market_pairs_mdl();
        const auto& base              = market_selector->get_left_selected_coin();
        const auto& rel               = market_selector->get_right_selected_coin();
        const bool  is_selected_order = m_preffered_order.has_value();
        const bool  is_selected_max =
            is_selected_order ? QString::fromStdString(utils::format_float(t_float_50(m_preffered_order->at("quantity").get<std::string>()))) == m_volume
                               : false;
        const bool is_my_max = m_volume == m_max_volume;
        const bool is_exact_selected_order_volume =
            (is_selected_order && m_preffered_order->at("coin").get<std::string>() == base.toStdString()) ? is_selected_max : false;

        /*SPDLOG_INFO(
            "volume: {} max_volume: {} is_selecter_order: {}, is_selected_max: {}, is_my_max: {}, is_exact_selected_order_volume {}", m_volume.toStdString(),
        m_max_volume.toStdString(), is_selected_order, is_selected_max, is_my_max, is_exact_selected_order_volume); if (is_selected_order)
        {
            SPDLOG_INFO("selected order infos: {}", m_preffered_order.value().dump(4));
        }*/
        t_buy_request req{
            .base                           = base.toStdString(),
            .rel                            = rel.toStdString(),
            .price                          = is_selected_order ? m_preffered_order->at("price").get<std::string>() : m_price.toStdString(),
            .volume                         = m_volume.toStdString(),
            .is_created_order               = not is_selected_order,
            .price_denom                    = is_selected_order ? m_preffered_order->at("price_denom").get<std::string>() : "",
            .price_numer                    = is_selected_order ? m_preffered_order->at("price_numer").get<std::string>() : "",
            .volume_denom                   = is_selected_order ? m_preffered_order->at("quantity_denom").get<std::string>() : "",
            .volume_numer                   = is_selected_order ? m_preffered_order->at("quantity_numer").get<std::string>() : "",
            .is_exact_selected_order_volume = is_exact_selected_order_volume,
            .base_nota                      = base_nota.isEmpty() ? std::optional<bool>{std::nullopt} : boost::lexical_cast<bool>(base_nota.toStdString()),
            .base_confs                     = base_confs.isEmpty() ? std::optional<std::size_t>{std::nullopt} : base_confs.toUInt()};

        if (m_preffered_order.has_value())
        {
            if (req.is_exact_selected_order_volume)
            {
                //! Selected order and we keep the exact volume (Basically swallow the order)
                SPDLOG_INFO("swallowing the order from the orderbook");
                req.volume_numer = m_preffered_order->at("quantity_numer").get<std::string>();
                req.volume_denom = m_preffered_order->at("quantity_denom").get<std::string>();
            }
            else if (is_my_max && !req.is_exact_selected_order_volume)
            {
                SPDLOG_INFO("cannot swallow the selected order from the orderbook, use our theorical max_volume for it");
                //! Selected order but we cannot swallow (not enough funds) set our theorical max_volume_numer and max_volume_denom
                req.volume_numer = m_preffered_order->at("max_volume_numer").get<std::string>();
                req.volume_denom = m_preffered_order->at("max_volume_denom").get<std::string>();
            }
            else
            {
                SPDLOG_INFO("Selected order, but changing manually the volume, use input_volume");
                req.selected_order_use_input_volume = true;
            }
        }
        nlohmann::json batch;
        nlohmann::json buy_request = ::mm2::api::template_request("buy");
        ::mm2::api::to_json(buy_request, req);
        batch.push_back(buy_request);
        auto& mm2_system = m_system_manager.get_system<mm2_service>();

        //! Answer
        // SPDLOG_INFO("buy_request is : {}", batch.dump(4));
        auto answer_functor = [this](web::http::http_response resp) {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                if (body.find("error") == std::string::npos)
                {
                    this->clear_forms();
                    auto           answers = nlohmann::json::parse(body);
                    nlohmann::json answer  = answers[0];
                    this->set_buy_sell_last_rpc_data(nlohmann_json_object_to_qt_json_object(answer));
                    auto& mm2_system = m_system_manager.get_system<mm2_service>();
                    SPDLOG_DEBUG("order successfully placed, refreshing orders and swap");
                    mm2_system.batch_fetch_orders_and_swap();
                }
                else
                {
                    auto error_json = QJsonObject({{"error_code", -1}, {"error_message", QString::fromStdString(body)}});
                    SPDLOG_ERROR("error place_buy_order: {}", body);
                    this->set_buy_sell_last_rpc_data(error_json);
                }
            }
            else
            {
                auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
                this->set_buy_sell_last_rpc_data(error_json);
            }
            this->set_buy_sell_rpc_busy(false);
        };

        //! Async call
        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), mm2_system.get_cancellation_token())
            .then(answer_functor)
            .then(&handle_exception_pplx_task);
    }

    void
    trading_page::place_sell_order(const QString& rel_nota, const QString& rel_confs)
    {
        this->set_buy_sell_rpc_busy(true);
        this->set_buy_sell_last_rpc_data(QJsonObject{{}});

        const auto* market_selector   = get_market_pairs_mdl();
        const auto& base              = market_selector->get_left_selected_coin();
        const auto& rel               = market_selector->get_right_selected_coin();
        const bool  is_selected_order = m_preffered_order.has_value();
        const bool  is_max            = m_max_volume == m_volume;
        const bool  is_selected_max =
            is_selected_order ? QString::fromStdString(utils::format_float(t_float_50(m_preffered_order->at("quantity").get<std::string>()))) == m_volume
                               : false;

        t_sell_request req{
            .base             = base.toStdString(),
            .rel              = rel.toStdString(),
            .price            = is_selected_order ? m_preffered_order->at("price").get<std::string>() : m_price.toStdString(),
            .volume           = m_volume.toStdString(),
            .is_created_order = not is_selected_order,
            .price_denom      = is_selected_order ? m_preffered_order->at("price_denom").get<std::string>() : "",
            .price_numer      = is_selected_order ? m_preffered_order->at("price_numer").get<std::string>() : "",
            .volume_denom     = is_selected_order ? m_preffered_order->at("quantity_denom").get<std::string>() : "",
            .volume_numer     = is_selected_order ? m_preffered_order->at("quantity_numer").get<std::string>() : "",
            .is_exact_selected_order_volume =
                (is_selected_order && m_preffered_order->at("coin").get<std::string>() == base.toStdString()) ? is_selected_max : false,
            .rel_nota  = rel_nota.isEmpty() ? std::optional<bool>{std::nullopt} : boost::lexical_cast<bool>(rel_nota.toStdString()),
            .rel_confs = rel_confs.isEmpty() ? std::optional<std::size_t>{std::nullopt} : rel_confs.toUInt(),
            .is_max    = is_max};

        auto max_taker_vol_json_obj = get_orderbook_wrapper()->get_base_max_taker_vol().toJsonObject();
        if (m_preffered_order.has_value())
        {
            if (req.is_exact_selected_order_volume)
            {
                //! Selected order and we keep the exact volume (Basically swallow the order)
                SPDLOG_INFO("swallowing the order from the orderbook");
                req.volume_numer = m_preffered_order->at("quantity_numer").get<std::string>();
                req.volume_denom = m_preffered_order->at("quantity_denom").get<std::string>();
            }
            else if (is_max && !req.is_exact_selected_order_volume)
            {
                SPDLOG_INFO("cannot swallow the selected order from the orderbook, use max_taker_volume for it");
                //! Selected order but we cannot swallow (not enough funds) set our max_volume_numer and max_volume_denom
                req.volume_denom = max_taker_vol_json_obj["denom"].toString().toStdString();
                req.volume_numer = max_taker_vol_json_obj["numer"].toString().toStdString();
            }
            else
            {
                SPDLOG_INFO("Selected order, but changing manually the volume, use input_volume");
                req.selected_order_use_input_volume = true;
            }
        }
        else
        {
            if (is_max)
            {
                req.volume_denom = max_taker_vol_json_obj["denom"].toString().toStdString();
                req.volume_numer = max_taker_vol_json_obj["numer"].toString().toStdString();
            }
        }

        nlohmann::json batch;
        nlohmann::json sell_request = ::mm2::api::template_request("sell");
        ::mm2::api::to_json(sell_request, req);
        batch.push_back(sell_request);
        auto& mm2_system = m_system_manager.get_system<mm2_service>();

        //SPDLOG_INFO("batch sell request: {}", batch.dump(4));
        //! Answer
        auto answer_functor = [this](web::http::http_response resp) {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                if (body.find("error") == std::string::npos)
                {
                    this->clear_forms();
                    auto           answers = nlohmann::json::parse(body);
                    nlohmann::json answer  = answers[0];
                    this->set_buy_sell_last_rpc_data(nlohmann_json_object_to_qt_json_object(answer));
                    auto& mm2_system = m_system_manager.get_system<mm2_service>();
                    SPDLOG_DEBUG("order successfully placed, refreshing orders and swap");
                    mm2_system.batch_fetch_orders_and_swap();
                }
                else
                {
                    auto error_json = QJsonObject({{"error_code", -1}, {"error_message", QString::fromStdString(body)}});
                    this->set_buy_sell_last_rpc_data(error_json);
                }
            }
            else
            {
                auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
                this->set_buy_sell_last_rpc_data(error_json);
            }
            this->set_buy_sell_rpc_busy(false);
        };

        //! Async call
        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), mm2_system.get_cancellation_token())
            .then(answer_functor)
            .then(&handle_exception_pplx_task);
    }
} // namespace atomic_dex

//! Public API
namespace atomic_dex
{
    void
    trading_page::disable_coins(const QStringList& coins) noexcept
    {
        for (auto&& coin: coins)
        {
            auto* market_selector_mdl = get_market_pairs_mdl();
            if (market_selector_mdl->get_left_selected_coin() == coin)
            {
                market_selector_mdl->set_left_selected_coin("BTC");
                market_selector_mdl->set_right_selected_coin("KMD");
            }
            else if (market_selector_mdl->get_right_selected_coin() == coin)
            {
                market_selector_mdl->set_left_selected_coin("BTC");
                market_selector_mdl->set_right_selected_coin("KMD");
            }
            set_current_orderbook(market_selector_mdl->get_left_selected_coin(), market_selector_mdl->get_right_selected_coin());
        }
    }

    void
    trading_page::clear_models()
    {
        get_market_pairs_mdl()->reset();
    }

    void
    trading_page::update() noexcept
    {
    }

    void
    trading_page::connect_signals()
    {
        dispatcher_.sink<process_orderbook_finished>().connect<&trading_page::on_process_orderbook_finished_event>(*this);
        dispatcher_.sink<multi_ticker_enabled>().connect<&trading_page::on_multi_ticker_enabled>(*this);
    }

    void
    atomic_dex::trading_page::disconnect_signals()
    {
        dispatcher_.sink<process_orderbook_finished>().disconnect<&trading_page::on_process_orderbook_finished_event>(*this);
        dispatcher_.sink<multi_ticker_enabled>().disconnect<&trading_page::on_multi_ticker_enabled>(*this);
    }

    void
    trading_page::process_action()
    {
        if (m_actions_queue.empty() || m_about_to_exit_the_app)
        {
            return;
        }
        const auto&     mm2_system = m_system_manager.get_system<mm2_service>();
        trading_actions last_action;
        this->m_actions_queue.pop(last_action);
        if (mm2_system.is_mm2_running())
        {
            switch (last_action)
            {
            case trading_actions::post_process_orderbook_finished:
            {
                std::error_code    ec;
                t_orderbook_answer result = mm2_system.get_orderbook(ec);
                if (!ec)
                {
                    auto* wrapper = get_orderbook_wrapper();
                    m_models_actions[orderbook_need_a_reset] ? wrapper->reset_orderbook(result) : wrapper->refresh_orderbook(result);
                    this->determine_error_cases();
                }
                break;
            }
            default:
                break;
            }
        }
    }
} // namespace atomic_dex

//! Properties
namespace atomic_dex
{
    qt_orderbook_wrapper*
    trading_page::get_orderbook_wrapper() const noexcept
    {
        return qobject_cast<qt_orderbook_wrapper*>(m_models[models::orderbook]);
    }

    market_pairs*
    trading_page::get_market_pairs_mdl() const noexcept
    {
        return qobject_cast<market_pairs*>(m_models[models::market_selector]);
    }

    bool
    trading_page::is_buy_sell_rpc_busy() const noexcept
    {
        return m_rpc_buy_sell_busy.load();
    }

    void
    trading_page::set_buy_sell_rpc_busy(bool status) noexcept
    {
        if (m_rpc_buy_sell_busy != status)
        {
            m_rpc_buy_sell_busy = status;
            emit buySellRpcStatusChanged();
        }
    }

    QVariant
    trading_page::get_buy_sell_last_rpc_data() const noexcept
    {
        return m_rpc_buy_sell_result.get();
    }

    void
    trading_page::set_buy_sell_last_rpc_data(QVariant rpc_data) noexcept
    {
        m_rpc_buy_sell_result = rpc_data.toJsonObject();
        emit buySellLastRpcDataChanged();
    }

    bool
    trading_page::is_fetching_multi_ticker_fees_busy() const noexcept
    {
        return m_fetching_multi_ticker_fees_busy.load();
    }

    void
    trading_page::set_fetching_multi_ticker_fees_busy(bool status) noexcept
    {
        if (m_fetching_multi_ticker_fees_busy != status)
        {
            m_fetching_multi_ticker_fees_busy = status;
            emit multiTickerFeesStatusChanged();
        }
    }

    void
    trading_page::on_multi_ticker_enabled(const multi_ticker_enabled& evt) noexcept
    {
        this->fetch_additional_fees(evt.ticker);
    }

    void
    trading_page::place_multiple_sell_order() noexcept
    {
        nlohmann::json         batch    = nlohmann::json::array();
        portfolio_proxy_model* model    = this->get_market_pairs_mdl()->get_multiple_selection_box();
        int                    nb_items = model->rowCount();
        for (int cur_idx = 0; cur_idx < nb_items; ++cur_idx)
        {
            QModelIndex idx                  = model->index(cur_idx, 0);
            bool        multi_ticker_enabled = model->data(idx, portfolio_model::PortfolioRoles::MultiTickerCurrentlyEnabled).toBool();
            std::string ticker               = model->data(idx, portfolio_model::PortfolioRoles::TickerRole).toString().toStdString();
            if (multi_ticker_enabled)
            {
                QJsonObject obj = model->data(idx, portfolio_model::PortfolioRoles::MultiTickerData).toJsonObject();
                if (not obj.isEmpty())
                {
                    nlohmann::json json = nlohmann::json::parse(QJsonDocument(obj).toJson(QJsonDocument::Compact).toStdString());
                    t_sell_request req{
                        .base             = json.at("base").get<std::string>(),
                        .rel              = json.at("rel").get<std::string>(),
                        .price            = json.at("price").get<std::string>(),
                        .volume           = json.at("volume").get<std::string>(),
                        .is_created_order = json.at("is_created_order").get<bool>(),
                        .price_denom      = "",
                        .price_numer      = "",
                        .rel_nota         = "",
                        .rel_confs        = 0};
                    nlohmann::json sell_request = ::mm2::api::template_request("sell");
                    ::mm2::api::to_json(sell_request, req);
                    batch.push_back(sell_request);
                }
                else
                {
                    SPDLOG_ERROR("empty json send from the front end for ticker: {} - ignoring", ticker);
                }
            }
        }

        auto& mm2_system     = m_system_manager.get_system<mm2_service>();
        auto  answer_functor = [](web::http::http_response resp) {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                auto answers = nlohmann::json::parse(body);
            }
            else
            {
                auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
            }
        };

        ::mm2::api::async_rpc_batch_standalone(batch, mm2_system.get_mm2_client(), mm2_system.get_cancellation_token())
            .then(answer_functor)
            .then(&handle_exception_pplx_task);
    }

} // namespace atomic_dex

//! Properties related to trading
namespace atomic_dex
{
    MarketMode
    trading_page::get_market_mode() const noexcept
    {
        return m_market_mode;
    }

    void
    trading_page::set_market_mode(MarketMode market_mode) noexcept
    {
        if (this->m_market_mode != market_mode)
        {
            this->m_market_mode = market_mode;
            SPDLOG_INFO("switching market_mode, new mode: {}", m_market_mode == MarketMode::Buy ? "buy" : "sell");
            this->clear_forms();
            auto* market_selector_mdl = get_market_pairs_mdl();
            set_current_orderbook(market_selector_mdl->get_left_selected_coin(), market_selector_mdl->get_right_selected_coin());
            emit marketModeChanged();
        }
    }

    QString
    trading_page::get_price() const noexcept
    {
        return m_price;
    }
    void
    trading_page::set_price(QString price) noexcept
    {
        if (price.isEmpty())
        {
            price = "0";
        }
        if (m_price != price)
        {
            m_price = std::move(price);
            if (this->m_preffered_order.has_value() && this->m_preffered_order->contains("locked"))
            {
                SPDLOG_WARN("releasing preffered order because price has been modified");
                this->m_preffered_order = std::nullopt;
                emit prefferedOrderChanged();
            }
            SPDLOG_DEBUG("price is [{}]", m_price.toStdString());

            //! When price change in MarketMode::Buy you want to redetermine max_volume
            if (m_market_mode == MarketMode::Buy)
            {
                this->determine_max_volume();
            }
            this->determine_total_amount();

            if (this->m_preffered_order.has_value())
            {
                this->m_preffered_order.value()["locked"] = true;
            }
            this->determine_cex_rates();
            emit priceChanged();
            emit priceReversedChanged();
            if (this->m_last_trading_error == TradingError::None)
            {
                this->determine_all_multi_ticker_forms();
            }
        }
    }

    void
    trading_page::clear_forms() noexcept
    {
        SPDLOG_INFO("clearing forms");
        this->set_price("0");
        this->set_volume("0");
        this->set_max_volume("0");
        this->set_total_amount("0");
        this->set_trading_error(TradingError::None);
        this->set_multi_order_enabled(false);
        this->m_preffered_order = std::nullopt;
        this->m_fees            = QVariantMap();
        this->m_cex_price       = "0";
        emit cexPriceChanged();
        emit invalidCexPriceChanged();
        emit cexPriceReversedChanged();
        emit feesChanged();
        emit prefferedOrderChanged();
    }

    QString
    trading_page::get_volume() const noexcept
    {
        return m_volume;
    }
    void
    trading_page::set_volume(QString volume) noexcept
    {
        if (m_volume != volume && not volume.isEmpty())
        {
            if (t_float_50(volume.toStdString()) < 0)
            {
                volume = "0";
            }
            m_volume = std::move(volume);
            SPDLOG_DEBUG("volume is [{}]", m_volume.toStdString());
            this->determine_total_amount();
            emit volumeChanged();
            this->cap_volume();
        }
    }

    QString
    trading_page::get_max_volume() const noexcept
    {
        return m_max_volume;
    }

    void
    trading_page::set_max_volume(QString max_volume) noexcept
    {
        if (m_max_volume != max_volume)
        {
            m_max_volume = std::move(max_volume);
            SPDLOG_DEBUG("max_volume is [{}]", m_max_volume.toStdString());
            emit maxVolumeChanged();
        }
    }

    void
    trading_page::determine_max_volume() noexcept
    {
        if (this->m_market_mode == MarketMode::Sell)
        {
            //! In MarketMode::Sell mode max volume is just the base_max_taker_vol
            const auto max_taker_vol = get_orderbook_wrapper()->get_base_max_taker_vol().toJsonObject()["decimal"].toString().toStdString();
            if (not max_taker_vol.empty())
            {
                SPDLOG_INFO("max_taker_vol is valid, processing...");
                if (t_float_50(max_taker_vol) < 0)
                {
                    this->set_max_volume("0");
                }
                else
                {
                    const auto max_vol_str = utils::format_float(t_float_50(max_taker_vol));

                    //! max_volume is max_taker_vol
                    this->set_max_volume(QString::fromStdString(max_vol_str));
                }

                //! Capping it
                this->cap_volume();
            }
            else
            {
                SPDLOG_WARN("max_taker_vol cannot be empty, is it called before being determinated ?");
            }
        }
        else
        {
            //! In MarketMode::Buy mode the max volume is rel_max_taker_vol / price
            if (not m_price.isEmpty())
            {
                t_float_50 price_f(m_price.toStdString());
                //! It's selected let's use rat price
                if (m_preffered_order.has_value())
                {
                    const auto& rel_max_taker_json_obj = get_orderbook_wrapper()->get_rel_max_taker_vol().toJsonObject();
                    const auto& denom                  = rel_max_taker_json_obj["denom"].toString().toStdString();
                    const auto& numer                  = rel_max_taker_json_obj["numer"].toString().toStdString();
                    t_rational  rel_max_taker_rat((boost::multiprecision::cpp_int(numer)), boost::multiprecision::cpp_int(denom));
                    t_float_50  res_f = t_float_50(0);
                    if (price_f > t_float_50(0))
                    {
                        const auto price_denom = m_preffered_order->at("price_denom").get<std::string>();
                        const auto price_numer = m_preffered_order->at("price_numer").get<std::string>();
                        t_rational price_orderbook_rat((boost::multiprecision::cpp_int(price_numer)), (boost::multiprecision::cpp_int(price_denom)));

                        t_rational res = rel_max_taker_rat / price_orderbook_rat;
                        SPDLOG_INFO(
                            "rat should be: numerator {} denominator {}", boost::multiprecision::numerator(res).str(),
                            boost::multiprecision::denominator(res).str());
                        res_f                                               = res.convert_to<t_float_50>();
                        this->m_preffered_order.value()["max_volume_denom"] = boost::multiprecision::denominator(res).str();
                        this->m_preffered_order.value()["max_volume_numer"] = boost::multiprecision::numerator(res).str();
                    }
                    if (res_f < 0)
                    {
                        res_f = 0;
                    }
                    this->set_max_volume(QString::fromStdString(utils::format_float(res_f)));
                    this->cap_volume();
                }
                else
                {
                    t_float_50 max_vol(get_orderbook_wrapper()->get_rel_max_taker_vol().toJsonObject()["decimal"].toString().toStdString());
                    max_vol        = std::max(t_float_50(0), max_vol);
                    t_float_50 res = price_f > t_float_50(0) ? max_vol / price_f : t_float_50(0);
                    if (res < 0)
                    {
                        res = 0;
                    }
                    this->set_max_volume(QString::fromStdString(utils::format_float(res)));
                    this->cap_volume();
                }
            }
        }
    }

    void
    trading_page::cap_volume() noexcept
    {
        /*
         * cap_volume is called only in MarketMode::Buy, and in Sell mode if prefered order
         * if the current volume text field is > the new max_volume then set volume to max_volume
         */
        if (auto std_volume = this->get_volume().toStdString(); not std_volume.empty())
        {
            if (t_float_50(std_volume) > t_float_50(this->get_max_volume().toStdString()))
            {
                this->set_volume(this->get_max_volume());
            }
        }
    }

    TradingError
    trading_page::get_trading_error() const noexcept
    {
        return m_last_trading_error;
    }

    void
    trading_page::set_trading_error(TradingError trading_error) noexcept
    {
        if (m_last_trading_error != trading_error)
        {
            m_last_trading_error = trading_error;
            switch (m_last_trading_error)
            {
            case TradingErrorGadget::None:
                SPDLOG_INFO("last_trading_error is None");
                break;
            case TradingErrorGadget::BaseNotEnoughFunds:
                SPDLOG_WARN("last_trading_error is BaseNotEnoughFunds");
                break;
            case TradingErrorGadget::RelTransactionFeesNotEnough:
                SPDLOG_WARN("last_trading_error is RelTransactionFeesNotEnough");
                break;
            case TradingErrorGadget::BalanceIsLessThanTheMinimalTradingAmount:
                SPDLOG_WARN("last_trading_error is BalanceIsLessThanTheMinimalTradingAmount");
                break;
            case TradingErrorGadget::TradingFeesNotEnoughFunds:
                SPDLOG_WARN("last_trading_error is TradingFeesNotEnoughFunds");
                break;
            case TradingErrorGadget::BaseTransactionFeesNotEnough:
                SPDLOG_WARN("last_trading_error is BaseTransactionFeesNotEnough");
                break;
            case TradingErrorGadget::PriceFieldNotFilled:
                SPDLOG_WARN("last_trading_error is PriceFieldNotFilled");
                break;
            case TradingErrorGadget::VolumeFieldNotFilled:
                SPDLOG_WARN("last_trading_error is VolumeFieldNotFilled");
                break;
            case TradingErrorGadget::VolumeIsLowerThanTheMinimum:
                SPDLOG_WARN("last_trading_error is VolumeIsLowerThanTheMinimum");
                break;
            case TradingErrorGadget::ReceiveVolumeIsLowerThanTheMinimum:
                SPDLOG_WARN("last_trading_error is ReceiveVolumeIsLowerThanTheMinimum");
                break;
            }
            emit tradingErrorChanged();
        }
    }

    bool
    trading_page::set_pair(bool is_left_side, QString changed_ticker) noexcept
    {
        auto* const market_pair = get_market_pairs_mdl();
        auto        base        = market_pair->get_left_selected_coin();
        auto        rel         = market_pair->get_right_selected_coin();

        bool is_swap = false;
        if (not changed_ticker.isEmpty())
        {
            if (is_left_side)
            {
                if (base == changed_ticker)
                {
                    return false;
                }
                if (base != changed_ticker && rel == changed_ticker)
                {
                    is_swap = true;
                }
                else
                {
                    base = changed_ticker;
                }
            }
            else
            {
                if (rel == changed_ticker)
                {
                    return false;
                }
                if (rel != changed_ticker && base == changed_ticker)
                {
                    is_swap = true;
                }
                else
                {
                    rel = changed_ticker;
                }
            }
        }

        if (is_swap)
        {
            swap_market_pair();
            base = market_pair->get_left_selected_coin();
            rel  = market_pair->get_right_selected_coin();
        }
        else
        {
            set_current_orderbook(base, rel);
        }
        return true;
    }

    QVariantMap
    trading_page::get_preffered_order() noexcept
    {
        if (m_preffered_order.has_value())
        {
            return nlohmann_json_object_to_qt_json_object(m_preffered_order.value()).toVariantMap();
        }

        return QVariantMap();
    }

    void
    trading_page::set_preffered_order(QVariantMap price_object) noexcept
    {
        if (auto preffered_order = nlohmann::json::parse(QString(QJsonDocument(QJsonObject::fromVariantMap(price_object)).toJson()).toStdString());
            preffered_order != m_preffered_order)
        {
            m_preffered_order = std::move(preffered_order);
            emit prefferedOrderChanged();
            if (not m_preffered_order->empty() && m_preffered_order->contains("price"))
            {
                this->set_price(QString::fromStdString(utils::format_float(t_float_50(m_preffered_order->at("price").get<std::string>()))));
                this->set_volume(QString::fromStdString(utils::format_float(t_float_50(m_preffered_order->at("quantity").get<std::string>()))));
                this->determine_max_volume();
            }
        }
    }

    QString
    trading_page::get_total_amount() const noexcept
    {
        return m_total_amount;
    }

    void
    trading_page::set_total_amount(QString total_amount) noexcept
    {
        if (m_total_amount != total_amount)
        {
            m_total_amount = std::move(total_amount);
            SPDLOG_DEBUG("total_amount is [{}]", m_total_amount.toStdString());
            emit totalAmountChanged();
            emit baseAmountChanged();
            emit relAmountChanged();
        }
    }

    void
    trading_page::determine_total_amount() noexcept
    {
        if (not m_price.isEmpty() && not m_volume.isEmpty())
        {
            this->set_total_amount(calculate_total_amount(m_price, m_volume));
            this->determine_fees();
            if (const std::string max_dust_str =
                    ((m_market_mode == MarketMode::Sell) ? get_orderbook_wrapper()->get_base_max_taker_vol() : get_orderbook_wrapper()->get_rel_max_taker_vol())
                        .toJsonObject()["decimal"]
                        .toString()
                        .toStdString();
                not max_dust_str.empty())
            {
                this->determine_error_cases();
            }
        }
    }

    QString
    trading_page::get_base_amount() const noexcept
    {
        return m_market_mode == MarketMode::Sell ? m_volume : m_total_amount;
    }

    QString
    trading_page::get_rel_amount() const noexcept
    {
        return m_market_mode == MarketMode::Sell ? m_total_amount : m_volume;
    }

    QVariantMap
    trading_page::get_fees() const noexcept
    {
        return m_fees;
    }

    void
    trading_page::set_fees(QVariantMap fees) noexcept
    {
        if (fees != m_fees)
        {
            m_fees = std::move(fees);
            qDebug() << "fees are: [" << m_fees << "]";
            emit feesChanged();
        }
    }

    void
    trading_page::determine_fees() noexcept
    {
        const auto* market_pair = get_market_pairs_mdl();
        const auto& mm2         = this->m_system_manager.get_system<mm2_service>();
        //! Send
        const auto base = market_pair->get_base_selected_coin();

        //! Receive
        const auto rel = market_pair->get_rel_selected_coin();

        //! (send) BCH <-> ETH (receive)
        const bool is_max = m_market_mode == MarketMode::Sell && m_volume == m_max_volume;

        this->set_fees(generate_fees_infos(base, rel, is_max, m_total_amount, mm2));
    }

    void
    trading_page::determine_error_cases() noexcept
    {
        TradingError current_trading_error = TradingError::None;

        //! Check minimal trading amount
        const std::string base                     = this->get_market_pairs_mdl()->get_base_selected_coin().toStdString();
        t_float_50        max_balance_without_dust = this->get_max_balance_without_dust();

        if (max_balance_without_dust < utils::minimal_trade_amount()) //<! Checking balance < minimal_trading_amount
        {
            current_trading_error = TradingError::BalanceIsLessThanTheMinimalTradingAmount;
        }
        else if (m_volume.isEmpty() || m_volume == "0") ///< Volume is not set correctly
        {
            current_trading_error = TradingError::VolumeFieldNotFilled;
        }
        else if (m_price.isEmpty() || m_price == "0") ///< Price is not set correctly
        {
            current_trading_error = TradingError::PriceFieldNotFilled; ///< need to have for multi ticker check
        }
        else if (t_float_50(get_base_amount().toStdString()) < utils::minimal_trade_amount())
        {
            current_trading_error = TradingError::VolumeIsLowerThanTheMinimum;
        }
        else if (t_float_50(get_rel_amount().toStdString()) < utils::minimal_trade_amount())
        {
            current_trading_error = TradingError::ReceiveVolumeIsLowerThanTheMinimum; ///< need to have for multi ticker check
        }
        else
        {
            current_trading_error = generate_fees_error(m_fees, max_balance_without_dust);
        }

        //! Check for base coin
        this->set_trading_error(current_trading_error);
    }

    void
    trading_page::determine_cex_rates() noexcept
    {
        std::error_code ec;
        const auto&     price_service   = m_system_manager.get_system<global_price_service>();
        const auto*     market_selector = get_market_pairs_mdl();
        const auto&     base            = market_selector->get_left_selected_coin();
        const auto&     rel             = market_selector->get_right_selected_coin();
        const auto      cex_price       = QString::fromStdString(price_service.get_cex_rates(base.toStdString(), rel.toStdString(), ec));
        if (cex_price != m_cex_price && !ec)
        {
            m_cex_price = std::move(cex_price);
            emit cexPriceChanged();
            emit invalidCexPriceChanged();
            emit cexPriceReversedChanged();
        }
        emit cexPriceDiffChanged();
    }

    QString
    trading_page::get_cex_price() const noexcept
    {
        return m_cex_price;
    }

    bool
    trading_page::get_invalid_cex_price() const noexcept
    {
        return m_cex_price == "0" || m_cex_price == "0.00" || m_cex_price.isEmpty();
    }

    QString
    trading_page::get_price_reversed() const noexcept
    {
        if (not m_price.isEmpty() && t_float_50(m_price.toStdString()) > 0)
        {
            t_float_50 reversed_price = t_float_50(1) / t_float_50(m_price.toStdString());
            return QString::fromStdString(utils::format_float(reversed_price));
        }

        return "0";
    }

    QString
    trading_page::get_cex_price_reversed() const noexcept
    {
        if (not get_invalid_cex_price())
        {
            t_float_50 reversed_cex_price = t_float_50(1) / t_float_50(m_cex_price.toStdString());
            return QString::fromStdString(utils::format_float(reversed_cex_price));
        }
        return "0";
    }

    QString
    trading_page::get_cex_price_diff() const noexcept
    {
        t_float_50 price_diff = get_invalid_cex_price()
                                    ? t_float_50(0)
                                    : t_float_50(100) * (t_float_50(1) - t_float_50(m_price.toStdString()) / t_float_50(m_cex_price.toStdString())) *
                                          (m_market_mode == MarketMode::Sell ? t_float_50(1) : t_float_50(-1));
        return QString::fromStdString(utils::format_float(price_diff));
    }

    void
    trading_page::determine_multi_ticker_fees([[maybe_unused]] const QString& ticker)
    {
        const auto* market_selector = get_market_pairs_mdl();
        auto*       selection_box   = market_selector->get_multiple_selection_box();
        const auto& mm2             = m_system_manager.get_system<mm2_service>();
        auto        total_amount    = get_multi_ticker_data<QString>(ticker, portfolio_model::PortfolioRoles::MultiTickerReceiveAmount, selection_box);
        auto        fees            = generate_fees_infos(market_selector->get_left_selected_coin(), ticker, true, total_amount, mm2);
        qDebug() << "fees multi_ticker: " << fees;
        set_multi_ticker_data(ticker, portfolio_model::MultiTickerFeesInfo, fees, selection_box);
        this->determine_multi_ticker_error_cases(ticker, fees);
    }

    void
    trading_page::determine_multi_ticker_total_amount(const QString& ticker, [[maybe_unused]] const QString& price, bool enabled)
    {
        if (m_market_mode == MarketMode::Sell && not price.isEmpty() && not m_volume.isEmpty())
        {
            if (ticker != get_market_pairs_mdl()->get_left_selected_coin())
            {
                SPDLOG_INFO("setting total amount of {}", ticker.toStdString());
                //! If not enabled use generic volume
                if (not enabled)
                {
                    const auto total_amount = calculate_total_amount(price, m_volume);
                    SPDLOG_INFO("new total_amount: {}", total_amount.toStdString());
                    set_multi_ticker_data(
                        ticker, portfolio_model::MultiTickerReceiveAmount, total_amount, get_market_pairs_mdl()->get_multiple_selection_box());
                }
                else
                {
                    //! Use trade with later (instead of m_volume, use a fresh volume from max_taker_vol)
                    const auto total_amount = calculate_total_amount(price, m_volume);
                    SPDLOG_INFO("new total_amount: {}", total_amount.toStdString());
                    set_multi_ticker_data(
                        ticker, portfolio_model::MultiTickerReceiveAmount, total_amount, get_market_pairs_mdl()->get_multiple_selection_box());
                    //! Here we need to use the real volume with trade_with
                    this->determine_multi_ticker_fees(ticker);
                }
            }
            else
            {
                SPDLOG_WARN("Skipping for first multi-ticker element, it's the main trade info");
            }
        }
        else
        {
            SPDLOG_ERROR("multi_ticker order are not available in buy mode");
        }
    }

    void
    trading_page::determine_multi_ticker_error_cases([[maybe_unused]] const QString& ticker, QVariantMap fees)
    {
        auto*        selection_box        = get_market_pairs_mdl()->get_multiple_selection_box();
        TradingError last_trading_error   = TradingError::None;
        QString      input_price          = get_multi_ticker_data<QString>(ticker, portfolio_model::MultiTickerPrice, selection_box);
        QString      total_receive_amount = get_multi_ticker_data<QString>(ticker, portfolio_model::MultiTickerReceiveAmount, selection_box);
        if (input_price.isEmpty() || input_price == "0") ///< Price is not set correctly
        {
            last_trading_error = TradingError::PriceFieldNotFilled; ///< need to have for multi ticker check
        }
        else if (t_float_50(total_receive_amount.toStdString()) < utils::minimal_trade_amount())
        {
            last_trading_error = TradingError::ReceiveVolumeIsLowerThanTheMinimum; ///< need to have for multi ticker check
        }
        else
        {
            last_trading_error = generate_fees_error(fees, get_max_balance_without_dust());
        }
        set_multi_ticker_data(ticker, portfolio_model::MultiTickerError, static_cast<qint32>(last_trading_error), selection_box);
    }

    bool
    trading_page::get_multi_order_enabled() const noexcept
    {
        return m_multi_order_enabled;
    }

    void
    trading_page::set_multi_order_enabled(bool multi_order_enabled) noexcept
    {
        if (m_multi_order_enabled != multi_order_enabled)
        {
            this->m_multi_order_enabled = multi_order_enabled;
            if (m_multi_order_enabled == true)
            {
                this->determine_all_multi_ticker_forms();
            }
            emit multiOrderEnabledChanged();
        }
    }

    void
    trading_page::determine_all_multi_ticker_forms() noexcept
    {
        SPDLOG_INFO("determine all multi ticker forms");
        portfolio_proxy_model* model         = this->get_market_pairs_mdl()->get_multiple_selection_box();
        const auto&            price_service = this->m_system_manager.get_system<global_price_service>();
        const auto&            config        = this->m_system_manager.get_system<settings_page>().get_cfg();
        const auto             rel_ticker    = get_market_pairs_mdl()->get_right_selected_coin();
        int                    nb_items      = model->rowCount();

        for (int cur_idx = 0; cur_idx < nb_items; ++cur_idx)
        {
            //!
            QModelIndex idx    = model->index(cur_idx, 0);
            const auto  ticker = model->data(idx, portfolio_model::PortfolioRoles::TickerRole).toString();

            SPDLOG_INFO("setting info form ticker: {}", ticker.toStdString());
            if (ticker == rel_ticker)
            {
                set_multi_ticker_data(ticker, portfolio_model::PortfolioRoles::MultiTickerCurrentlyEnabled, true, model);
                set_multi_ticker_data(ticker, portfolio_model::PortfolioRoles::MultiTickerPrice, m_price, model);
                set_multi_ticker_data(ticker, portfolio_model::PortfolioRoles::MultiTickerReceiveAmount, m_total_amount, model);
                set_multi_ticker_data(ticker, portfolio_model::PortfolioRoles::MultiTickerFeesInfo, m_fees, model);
            }
            else
            {
                t_float_50      rel_price_for_one_unit(model->data(idx, portfolio_model::PortfolioRoles::MainFiatPriceForOneUnit).toString().toStdString());
                std::error_code ec;
                t_float_50      price_as_currency_from_amount(
                    price_service.get_price_as_currency_from_amount(config.current_fiat, rel_ticker.toStdString(), "1", ec));
                t_float_50 price_field_fiat       = t_float_50(m_price.toStdString()) * price_as_currency_from_amount;
                t_float_50 rel_price_relative     = rel_price_for_one_unit == t_float_50(0) ? t_float_50(0) : price_field_fiat / rel_price_for_one_unit;
                const auto rel_price_relative_str = QString::fromStdString(utils::format_float(rel_price_relative));
                if (rel_price_relative > 0) //< if there is no fiat data don't override it
                {
                    set_multi_ticker_data(ticker, portfolio_model::PortfolioRoles::MultiTickerPrice, rel_price_relative_str, model);
                }
            }
        }
    }

    t_float_50
    trading_page::get_max_balance_without_dust(std::optional<QString> trade_with) const noexcept
    {
        if (!trade_with.has_value())
        {
            const std::string max_dust_str =
                ((m_market_mode == MarketMode::Sell) ? get_orderbook_wrapper()->get_base_max_taker_vol() : get_orderbook_wrapper()->get_rel_max_taker_vol())
                    .toJsonObject()["decimal"]
                    .toString()
                    .toStdString();
            assert(not max_dust_str.empty());
            t_float_50 max_balance_without_dust(max_dust_str);
            return max_balance_without_dust;
        }
        //! if trade_with has value check in mm2 registry the base_max_taker_vol trade_with equivalent and process the same calculation;
        return t_float_50(0);
    }

    TradingError
    trading_page::generate_fees_error(QVariantMap fees, t_float_50 max_balance_without_dust) const noexcept
    {
        TradingError last_trading_error = TradingError::None;
        const auto&  mm2                = m_system_manager.get_system<mm2_service>();
        if (const auto trading_fee_ticker = fees["trading_fee_ticker"].toString();
            fees["trading_fee_ticker"] != fees["base_transaction_fees_ticker"] &&
            t_float_50(fees["trading_fee"].toString().toStdString()) > max_balance_without_dust)
        {
            last_trading_error = TradingError::TradingFeesNotEnoughFunds; ///< need to have for multi ticker check
        }
        else if (const auto transaction_fee_ticker = fees["trading_fee_ticker"].toString();
                 fees["trading_fee_ticker"] != fees["base_transaction_fees_ticker"] &&
                 not mm2.do_i_have_enough_funds(transaction_fee_ticker.toStdString(), t_float_50(fees["base_transaction_fees"].toString().toStdString())))
        {
            last_trading_error = TradingError::BaseTransactionFeesNotEnough; ///< need to have for multi ticker check
        }
        else if (fees.contains("total_base_fees") && t_float_50(fees["total_base_fees_fp"].toString().toStdString()) > max_balance_without_dust)
        {
            last_trading_error = TradingError::BaseNotEnoughFunds; ///< need to have for multi ticker check
        }
        else if (fees.contains("rel_transaction_fees_ticker")) //! Checking rel coin if specific fees aka: ETH, QTUM, QRC-20, ERC-20 ?
        {
            const auto rel_ticker = fees["rel_transaction_fees_ticker"].toString().toStdString();
            t_float_50 rel_amount(fees["rel_transaction_fees"].toString().toStdString());
            if (not mm2.do_i_have_enough_funds(rel_ticker, rel_amount))
            {
                last_trading_error = TradingError::RelTransactionFeesNotEnough; ///< need to have for multi ticker check
            }
        }
        return last_trading_error;
    }
} // namespace atomic_dex
