/******************************************************************************
 * Copyright © 2013-2021 The Komodo Platform Developers.                      *
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
#include <QSettings>

//! Project Headers
#include "atomicdex/api/mm2/rpc.buy.hpp"
#include "atomicdex/api/mm2/rpc.sell.hpp"
#include "atomicdex/api/mm2/rpc.trade.preimage.hpp"
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/pages/qt.settings.page.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/services/mm2/auto.update.maker.order.service.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"
#include "atomicdex/utilities/qt.download.manager.hpp"

//! Constructor / Destructor
namespace atomic_dex
{
    trading_page::trading_page(
        entt::registry& registry, ag::ecs::system_manager& system_manager, std::atomic_bool& exit_status, portfolio_model* portfolio, QObject* parent) :
        QObject(parent),
        system(registry), m_system_manager(system_manager),
        m_about_to_exit_the_app(exit_status), m_models{
                                                  {new qt_orderbook_wrapper(m_system_manager, dispatcher_, this),
                                                   new market_pairs(m_system_manager, portfolio, this), new qt_orders_widget(m_system_manager, this)}}
    {
        //! Sets default trading mode to the last saved one.
        set_current_trading_mode((TradingMode)entity_registry_.template ctx<QSettings>().value("DefaultTradingMode", 1).toInt());
    }
} // namespace atomic_dex

//! Events callback
namespace atomic_dex
{
    void
    trading_page::on_process_orderbook_finished_event(const atomic_dex::process_orderbook_finished& evt)
    {
        if (!m_about_to_exit_the_app)
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
    trading_page::get_raw_mm2_coin_cfg(const QString& ticker) const
    {
        QVariant       out;
        nlohmann::json j = m_system_manager.get_system<mm2_service>().get_raw_mm2_ticker_cfg(ticker.toStdString());
        out              = nlohmann_json_object_to_qt_json_object(j);
        return out;
    }

    void
    trading_page::set_current_orderbook(const QString& base, const QString& rel)
    {
        if (base.toStdString() == "" || rel.toStdString() == "")
        {
            return;
        }
        if (bool is_wallet_only = m_system_manager.get_system<mm2_service>().get_coin_info(base.toStdString()).wallet_only; is_wallet_only)
        {
            SPDLOG_WARN("{} is wallet only - skipping", base.toStdString());
            return;
        }
        SPDLOG_DEBUG("Setting current orderbook: {} / {}", base.toStdString(), rel.toStdString());
        auto* market_selector_mdl = get_market_pairs_mdl();

        const bool to_change = base != market_selector_mdl->get_left_selected_coin() || rel != market_selector_mdl->get_right_selected_coin();
        market_selector_mdl->set_left_selected_coin(base);
        market_selector_mdl->set_right_selected_coin(rel);
        market_selector_mdl->set_base_selected_coin(m_market_mode == MarketMode::Sell ? base : rel);
        market_selector_mdl->set_rel_selected_coin(m_market_mode == MarketMode::Sell ? rel : base);

        if (to_change && m_current_trading_mode != TradingModeGadget::Simple)
        {
            SPDLOG_DEBUG("set_current_orderbook");
            this->get_orderbook_wrapper()->clear_orderbook();
            this->clear_forms("set_current_orderbook");
        }

        emit mm2MinTradeVolChanged();
        dispatcher_.trigger<orderbook_refresh>(base.toStdString(), rel.toStdString());
    }

    void
    trading_page::swap_market_pair()
    {
        const auto* market_selector_mdl = get_market_pairs_mdl();
        set_current_orderbook(market_selector_mdl->get_right_selected_coin(), market_selector_mdl->get_left_selected_coin());
    }

    void
    trading_page::on_gui_enter_dex()
    {
        SPDLOG_DEBUG("Enter DEX");
        dispatcher_.trigger<gui_enter_trading>();
        if (this->m_system_manager.has_system<auto_update_maker_order_service>() && m_system_manager.get_system<mm2_service>().is_orderbook_thread_active())
        {
            this->m_system_manager.get_system<auto_update_maker_order_service>().force_update();
        }
    }

    void
    trading_page::on_gui_leave_dex()
    {
        m_system_manager.get_system<settings_page>().garbage_collect_qml();
        dispatcher_.trigger<gui_leave_trading>();
    }

    void
    trading_page::place_buy_order(const QString& base_nota, const QString& base_confs)
    {
        this->set_buy_sell_rpc_busy(true);
        this->set_buy_sell_last_rpc_data(QJsonObject{{}});

        auto&       mm2_system        = m_system_manager.get_system<mm2_service>();
        const auto* market_selector   = get_market_pairs_mdl();
        const auto& base              = market_selector->get_left_selected_coin();
        const auto& rel               = market_selector->get_right_selected_coin();
        const bool  is_selected_order = m_preferred_order.has_value();
        const bool  is_max            = m_max_volume == m_volume;
        const bool  is_selected_min_max =
            is_selected_order && m_preferred_order->at("base_min_volume").get<std::string>() == m_preferred_order->at("base_max_volume").get<std::string>();
        const bool is_selected_max  = is_selected_order && is_max;
        t_float_50 rel_min_trade    = safe_float(get_orderbook_wrapper()->get_rel_min_taker_vol().toStdString());
        t_float_50 rel_min_volume_f = safe_float(get_min_trade_vol().toStdString());
        if (is_selected_order)
        {
            SPDLOG_DEBUG(
                "max_volume: {} volume: {} order_volume: {}, order_volume_8_digit: {}, order_volume_8_digit_extracted: {}", m_max_volume.toStdString(),
                m_volume.toStdString(), m_preferred_order->at("base_max_volume").get<std::string>(),
                utils::adjust_precision(m_preferred_order->at("base_max_volume").get<std::string>()),
                utils::extract_large_float(m_preferred_order->at("base_max_volume").get<std::string>()));
        }

        t_buy_request req{
            .base                           = base.toStdString(),
            .rel                            = rel.toStdString(),
            .price                          = is_selected_order ? m_preferred_order->at("price").get<std::string>() : m_price.toStdString(),
            .volume                         = m_volume.toStdString(),
            .is_created_order               = not is_selected_order,
            .price_denom                    = is_selected_order ? m_preferred_order->at("price_denom").get<std::string>() : "",
            .price_numer                    = is_selected_order ? m_preferred_order->at("price_numer").get<std::string>() : "",
            .volume_denom                   = is_selected_order ? m_preferred_order->at("base_max_volume_denom").get<std::string>() : "",
            .volume_numer                   = is_selected_order ? m_preferred_order->at("base_max_volume_numer").get<std::string>() : "",
            .is_exact_selected_order_volume = is_selected_max && m_max_volume.toStdString() == utils::extract_large_float(m_preferred_order->at("base_max_volume").get<std::string>()),
            .base_nota                      = base_nota.isEmpty() ? std::optional<bool>{std::nullopt} : boost::lexical_cast<bool>(base_nota.toStdString()),
            .base_confs                     = base_confs.isEmpty() ? std::optional<std::size_t>{std::nullopt} : base_confs.toUInt(),
            .min_volume = (rel_min_volume_f <= rel_min_trade) ? std::optional<std::string>{std::nullopt} : get_min_trade_vol().toStdString()};

        if (is_selected_min_max || is_selected_order)
        {
            req.min_volume = std::optional<std::string>{std::nullopt};
        }

        if (m_preferred_order.has_value())
        {
            if (req.is_exact_selected_order_volume)
            {
                //! Selected order and we keep the exact volume (Basically swallow the order)
                SPDLOG_DEBUG("swallowing the order from the orderbook");
                req.volume_numer = m_preferred_order->at("base_max_volume_numer").get<std::string>();
                req.volume_denom = m_preferred_order->at("base_max_volume_denom").get<std::string>();
            }
            else if (
                is_max && !req.is_exact_selected_order_volume && m_preferred_order->contains("max_volume_numer") &&
                m_preferred_order->contains("max_volume_denom"))
            {
                SPDLOG_DEBUG("cannot swallow the selected order from the orderbook, use our theoretical max_volume for it");
                //! Selected order but we cannot swallow (not enough funds) set our theoretical max_volume_numer and max_volume_denom
                req.volume_numer = m_preferred_order->at("max_volume_numer").get<std::string>();
                req.volume_denom = m_preferred_order->at("max_volume_denom").get<std::string>();
            }
            else
            {
                SPDLOG_DEBUG("Selected order, but changing manually the volume, use input_volume");
                req.selected_order_use_input_volume = true;
            }
        }
        
        nlohmann::json batch;
        nlohmann::json buy_request = mm2::template_request("buy");
        mm2::to_json(buy_request, req);
        batch.push_back(buy_request);
        buy_request["userpass"] = "*******";

        //! Answer
        SPDLOG_DEBUG("buy_request is : {}", buy_request.dump(4));
        auto answer_functor = [this](const web::http::http_response& resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == web::http::status_codes::OK)
            {
                if (body.find("error") == std::string::npos)
                {
                    auto           answers = nlohmann::json::parse(body);
                    nlohmann::json answer  = answers[0];
                    this->set_buy_sell_last_rpc_data(nlohmann_json_object_to_qt_json_object(answer));
                    auto& cur_mm2_system = m_system_manager.get_system<mm2_service>();
                    SPDLOG_DEBUG("order successfully placed, refreshing orders and swap");
                    cur_mm2_system.batch_fetch_orders_and_swap();
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
            this->clear_forms("place_buy_order");
        };

        //! Async call
        mm2_system.get_mm2_client()
            .async_rpc_batch_standalone(batch)
            .then(answer_functor)
            .then(
                [this]([[maybe_unused]] pplx::task<void> previous_task)
                {
                    try
                    {
                        previous_task.wait();
                    }
                    catch (const std::exception& e)
                    {
                        SPDLOG_ERROR("pplx task error: {}", e.what());
                        auto error_json = QJsonObject({{"error_code", web::http::status_codes::InternalError}, {"error_message", e.what()}});
                        this->set_buy_sell_last_rpc_data(error_json);
                        this->set_buy_sell_rpc_busy(false);
                        this->clear_forms("place_buy_order");
                    }
                });
    }

    void
    trading_page::place_sell_order(const QString& rel_nota, const QString& rel_confs)
    {
        this->set_buy_sell_rpc_busy(true);
        this->set_buy_sell_last_rpc_data(QJsonObject{{}});

        auto&       mm2_system                   = m_system_manager.get_system<mm2_service>();
        const auto* market_selector              = get_market_pairs_mdl();
        const auto& base                         = market_selector->get_left_selected_coin();
        const auto& rel                          = market_selector->get_right_selected_coin();
        const bool  is_selected_order            = m_preferred_order.has_value();
        const bool  is_max                       = m_max_volume == m_volume;
        QString     orderbook_available_quantity = is_selected_order ? QString::fromStdString(m_preferred_order->at("base_max_volume").get<std::string>()) : "";
        const bool  is_selected_min_max =
            is_selected_order && m_preferred_order->at("base_min_volume").get<std::string>() == m_preferred_order->at("base_max_volume").get<std::string>();
        const bool is_selected_max = is_selected_order && m_volume.toStdString() == utils::extract_large_float(orderbook_available_quantity.toStdString());
        t_float_50 base_min_trade  = safe_float(get_orderbook_wrapper()->get_base_min_taker_vol().toStdString());
        t_float_50 cur_min_trade   = safe_float(get_min_trade_vol().toStdString());

        SPDLOG_DEBUG("base_min_trade: {}, cur_min_trade: {}", base_min_trade.str(), cur_min_trade.str());
        SPDLOG_DEBUG(
            "volume: {}, orderbook_available_quantity: {}, is_selected_max: {}", m_volume.toStdString(), orderbook_available_quantity.toStdString(),
            is_selected_max);
        t_sell_request req{
            .base                           = base.toStdString(),
            .rel                            = rel.toStdString(),
            .price                          = is_selected_order ? m_preferred_order->at("price").get<std::string>() : m_price.toStdString(),
            .volume                         = m_volume.toStdString(),
            .is_created_order               = not is_selected_order,
            .price_denom                    = is_selected_order ? m_preferred_order->at("price_denom").get<std::string>() : "",
            .price_numer                    = is_selected_order ? m_preferred_order->at("price_numer").get<std::string>() : "",
            .volume_denom                   = is_selected_order ? m_preferred_order->at("base_max_volume_denom").get<std::string>() : "",
            .volume_numer                   = is_selected_order ? m_preferred_order->at("base_max_volume_numer").get<std::string>() : "",
            .is_exact_selected_order_volume = is_selected_order && is_selected_max,
            .rel_nota                       = rel_nota.isEmpty() ? std::optional<bool>{std::nullopt} : boost::lexical_cast<bool>(rel_nota.toStdString()),
            .rel_confs                      = rel_confs.isEmpty() ? std::optional<std::size_t>{std::nullopt} : rel_confs.toUInt(),
            .is_max                         = is_max,
            .min_volume = cur_min_trade <= base_min_trade ? std::optional<std::string>{std::nullopt} : m_minimal_trading_amount.toStdString()};

        if (m_current_trading_mode == TradingModeGadget::Simple)
        {
            SPDLOG_DEBUG("Simple trading mode, using FillOrKill order");
            req.order_type                 = nlohmann::json::object();
            req.order_type.value()["type"] = "FillOrKill";
            req.min_volume                 = std::optional<std::string>{std::nullopt};
        }

        if (is_selected_min_max)
        {
            req.min_volume = std::optional<std::string>{std::nullopt};
        }

        auto max_taker_vol_json_obj = get_orderbook_wrapper()->get_base_max_taker_vol().toJsonObject();
        
        if (is_selected_order)
        {
            SPDLOG_DEBUG(
                "The order is a selected order, treating it, input_vol: {} orderbook_max_vol {}", m_volume.toStdString(),
                orderbook_available_quantity.toStdString());

            const auto base_min_vol_orderbook = m_preferred_order->at("base_min_volume").get<std::string>();

            if (t_float_50 base_min_vol_orderbook_f = safe_float(base_min_vol_orderbook); cur_min_trade <= base_min_vol_orderbook_f)
            {
                SPDLOG_DEBUG("The selected order min_vol input is too low, using null field instead");
                req.min_volume = std::optional<std::string>{std::nullopt};
            }

            if (req.is_exact_selected_order_volume)
            {
                //! Selected order and we keep the exact volume (Basically swallow the order)
                SPDLOG_DEBUG("swallowing the order from the orderbook");
                req.volume_numer = m_preferred_order->at("base_max_volume_numer").get<std::string>();
                req.volume_denom = m_preferred_order->at("base_max_volume_denom").get<std::string>();
            }
            else if (is_max && !req.is_exact_selected_order_volume && get_current_trading_mode() != TradingModeGadget::Simple) ///< this one is a bit dangerous,
                                                                                                                               ///< let's forbid it in simple
                                                                                                                               ///< view
            {
                SPDLOG_DEBUG("cannot swallow the selected order from the orderbook, use max_taker_volume for it");
                req.volume_denom = max_taker_vol_json_obj["denom"].toString().toStdString();
                req.volume_numer = max_taker_vol_json_obj["numer"].toString().toStdString();
            }
            else
            {
                SPDLOG_DEBUG("Selected order, but changing manually the volume, use input_volume");
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
        nlohmann::json sell_request = mm2::template_request("sell");
        mm2::to_json(sell_request, req);
        batch.push_back(sell_request);

        sell_request["userpass"] = "******";
        SPDLOG_DEBUG("sell request: {}", sell_request.dump(4));

        //! Answer
        auto answer_functor = [this](web::http::http_response resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                if (body.find("error") == std::string::npos)
                {
                    auto           answers = nlohmann::json::parse(body);
                    nlohmann::json answer  = answers[0];
                    this->set_buy_sell_last_rpc_data(nlohmann_json_object_to_qt_json_object(answer));
                    auto& cur_mm2_system = m_system_manager.get_system<mm2_service>();
                    SPDLOG_DEBUG("order successfully placed, refreshing orders and swap");
                    cur_mm2_system.batch_fetch_orders_and_swap();
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
            this->clear_forms("place_sell_order");
            this->set_buy_sell_rpc_busy(false);
        };

        //! Async call
        mm2_system.get_mm2_client()
            .async_rpc_batch_standalone(batch)
            .then(answer_functor)
            .then(
                [this]([[maybe_unused]] pplx::task<void> previous_task)
                {
                    try
                    {
                        previous_task.wait();
                    }
                    catch (const std::exception& e)
                    {
                        SPDLOG_ERROR("pplx task error: {}", e.what());
                        auto error_json = QJsonObject({{"error_code", 500}, {"error_message", e.what()}});
                        this->set_buy_sell_last_rpc_data(error_json);
                        this->set_buy_sell_rpc_busy(false);
                        this->clear_forms("place_sell_order");
                    }
                });
    }
} // namespace atomic_dex

//! Public API
namespace atomic_dex
{
    void
    trading_page::disable_coins(const QStringList& coins)
    {
        for (auto&& coin: coins)
        {
            auto* market_selector_mdl = get_market_pairs_mdl();
            if (market_selector_mdl->get_left_selected_coin() == coin)
            {
                market_selector_mdl->set_left_selected_coin(DEX_SECOND_PRIMARY_COIN);
                market_selector_mdl->set_right_selected_coin(DEX_PRIMARY_COIN);
            }
            else if (market_selector_mdl->get_right_selected_coin() == coin)
            {
                market_selector_mdl->set_left_selected_coin(DEX_SECOND_PRIMARY_COIN);
                market_selector_mdl->set_right_selected_coin(DEX_PRIMARY_COIN);
            }
            set_current_orderbook(market_selector_mdl->get_left_selected_coin(), market_selector_mdl->get_right_selected_coin());
        }
    }

    void
    trading_page::clear_models() const
    {
        get_market_pairs_mdl()->reset();
    }

    void
    trading_page::update()
    {
        //! Virtual function, need to be empty.
    }

    void
    trading_page::connect_signals()
    {
        dispatcher_.sink<process_orderbook_finished>().connect<&trading_page::on_process_orderbook_finished_event>(*this);
    }

    void
    trading_page::disconnect_signals()
    {
        dispatcher_.sink<process_orderbook_finished>().disconnect<&trading_page::on_process_orderbook_finished_event>(*this);
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
                    // SPDLOG_DEBUG("[process_action::post_process_orderbook_finished]");
                    auto* wrapper = get_orderbook_wrapper();
                    m_models_actions[orderbook_need_a_reset] ? wrapper->reset_orderbook(result) : wrapper->refresh_orderbook(result);

                    if (m_models_actions[orderbook_need_a_reset] && this->m_current_trading_mode == TradingModeGadget::Pro)
                    {
                        // This goes to a function which looks like it is for bot trading. We dont need to run it at this stage.
                        this->set_preferred_settings();
                    }
                    else
                    {
                        const auto base_max_taker_vol = safe_float(wrapper->get_base_max_taker_vol().toJsonObject()["decimal"].toString().toStdString());
                        // SPDLOG_DEBUG("[base_max_taker_vol]: {}", wrapper->get_base_max_taker_vol().toJsonObject()["decimal"].toString().toStdString());
                        auto       rel_max_taker      = wrapper->get_rel_max_taker_vol().toJsonObject()["decimal"].toString().toStdString();
                        // SPDLOG_DEBUG("[rel_max_taker]: {}", wrapper->get_rel_max_taker_vol().toJsonObject()["decimal"].toString().toStdString());

                        if (rel_max_taker.empty())
                        {
                            rel_max_taker = "0";
                        }

                        const auto rel_max_taker_vol = safe_float(rel_max_taker);
                        t_float_50 min_vol           = safe_float(m_minimal_trading_amount.toStdString());
                        // SPDLOG_DEBUG("[min_vol]: {}", m_minimal_trading_amount.toStdString());

                        auto       adjust_functor    = [this, wrapper]()
                        {
                            if (m_post_clear_forms && this->m_current_trading_mode == TradingModeGadget::Pro)
                            {
                                this->determine_max_volume();
                                this->set_volume(get_max_volume());
                                this->set_min_trade_vol(wrapper->get_current_min_taker_vol());
                                m_post_clear_forms = false;
                            }
                        };
                        if ((m_market_mode == MarketMode::Buy && rel_max_taker_vol > 0 && min_vol <= 0) ||
                            (m_market_mode == MarketMode::Sell && base_max_taker_vol > 0 && min_vol <= 0))
                        {
                            // SPDLOG_DEBUG("[adjust_functor()]: Adjusting....");
                            adjust_functor();
                        }
                    }

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
    trading_page::get_orderbook_wrapper() const
    {
        return qobject_cast<qt_orderbook_wrapper*>(m_models[models::orderbook]);
    }

    qt_orders_widget*
    trading_page::get_orders_widget() const
    {
        return qobject_cast<qt_orders_widget*>(m_models[models::orders]);
    }

    market_pairs*
    trading_page::get_market_pairs_mdl() const
    {
        return qobject_cast<market_pairs*>(m_models[models::market_selector]);
    }

    bool
    trading_page::is_buy_sell_rpc_busy() const
    {
        return m_rpc_buy_sell_busy.load();
    }

    void
    trading_page::set_buy_sell_rpc_busy(bool status)
    {
        if (m_rpc_buy_sell_busy != status)
        {
            m_rpc_buy_sell_busy = status;
            emit buySellRpcStatusChanged();
        }
    }

    QVariant
    trading_page::get_buy_sell_last_rpc_data() const
    {
        return m_rpc_buy_sell_result.get();
    }

    void
    trading_page::set_buy_sell_last_rpc_data(const QVariant& rpc_data)
    {
        m_rpc_buy_sell_result = rpc_data.toJsonObject();
        emit buySellLastRpcDataChanged();
    }
} // namespace atomic_dex

//! Properties related to trading
namespace atomic_dex
{
    MarketMode
    trading_page::get_market_mode() const
    {
        return m_market_mode;
    }

    void
    trading_page::set_market_mode(MarketMode market_mode)
    {
        if (this->m_market_mode != market_mode)
        {
            this->m_market_mode = market_mode;
            SPDLOG_DEBUG("switching market_mode, new mode: {}", m_market_mode == MarketMode::Buy ? "buy" : "sell");
            this->clear_forms("set_market_mode");
            const auto* market_selector_mdl = get_market_pairs_mdl();
            set_current_orderbook(market_selector_mdl->get_left_selected_coin(), market_selector_mdl->get_right_selected_coin());
            emit marketModeChanged();
            
            if (m_market_mode == MarketMode::Buy)
            {
                this->get_orderbook_wrapper()->get_best_orders()->get_orderbook_proxy()->sort(0, Qt::AscendingOrder);
            }
            else
            {
                this->get_orderbook_wrapper()->get_best_orders()->get_orderbook_proxy()->sort(0, Qt::DescendingOrder);
            }
        }
    }

    QString
    trading_page::get_price() const
    {
        return m_price;
    }

    void
    trading_page::set_price(QString price)
    {
        if (price.isEmpty())
        {
            price = "0";
        }
        
        if (m_price != price)
        {
            m_price = std::move(price);
            if (this->m_preferred_order.has_value() && this->m_preferred_order->contains("locked"))
            {
                SPDLOG_WARN("releasing preferred order because price has been modified");
                this->m_preferred_order = std::nullopt;
                emit prefferedOrderChanged();
            }

            //! When price change in MarketMode::Buy you want to redetermine max_volume
            if (m_market_mode == MarketMode::Buy)
            {
                this->determine_max_volume();
            }

            this->determine_total_amount();

            if (this->m_preferred_order.has_value())
            {
                this->m_preferred_order.value()["locked"] = true;
            }
            this->determine_cex_rates();
            emit priceChanged();
            emit priceReversedChanged();
            emit get_orderbook_wrapper()->currentMinTakerVolChanged();
            get_orderbook_wrapper()->adjust_min_vol();
        }
    }

    void
    trading_page::clear_forms(QString from)
    {
        if (!this->m_system_manager.has_system<mm2_service>())
        {
            SPDLOG_WARN("MM2 service not available, required to clear forms - skipping");
            return;
        }
        SPDLOG_DEBUG("clearing forms : {}", from.toStdString());

        if (m_preferred_order.has_value() && m_current_trading_mode == TradingModeGadget::Simple &&
            m_selected_order_status == SelectedOrderGadget::OrderNotExistingAnymore)
        {
            SPDLOG_DEBUG("Simple view cancel order, keeping important data");
            this->set_volume(QString::fromStdString(m_preferred_order->at("initial_input_volume").get<std::string>()));
            const auto max_taker_vol = get_orderbook_wrapper()->get_base_max_taker_vol().toJsonObject()["decimal"].toString();
            this->set_max_volume(max_taker_vol);
            this->set_price("0");
        }
        else
        {
            this->set_price("0");
            this->set_max_volume("0");
            m_minimal_trading_amount = "0.0001";
            emit minTradeVolChanged();
            this->set_volume("0");
        }
        
        this->set_total_amount("0");
        this->set_trading_error(TradingError::None);
        this->m_preferred_order  = std::nullopt;
        this->m_fees             = QVariantMap();
        this->m_cex_price        = "0";
        this->m_post_clear_forms = true;
        this->set_selected_order_status(SelectedOrderStatus::None);
        this->reset_fees();
        this->determine_cex_rates();
        emit cexPriceChanged();
        emit invalidCexPriceChanged();
        emit cexPriceReversedChanged();
        emit feesChanged();
        emit prefferedOrderChanged();
        emit priceChanged();
        emit priceReversedChanged();
    }

    QString
    trading_page::get_volume() const
    {
        return m_volume;
    }

    void
    trading_page::set_volume(QString volume)
    {
        if (m_volume != volume && !volume.isEmpty())
        {
            if (safe_float(volume.toStdString()) < 0)
            {
                volume = "0";
            }
            m_volume = std::move(volume);
            SPDLOG_DEBUG("volume is : [{}]", m_volume.toStdString());

            this->determine_total_amount();
            emit volumeChanged();
            this->cap_volume();

            this->get_orderbook_wrapper()->refresh_best_orders();
        }
    }

    QString
    trading_page::get_max_volume() const
    {
        return m_max_volume;
    }

    void
    trading_page::set_max_volume(QString max_volume)
    {
        if (m_max_volume != max_volume)
        {
            max_volume   = QString::fromStdString(utils::extract_large_float(max_volume.toStdString()));
            m_max_volume = std::move(max_volume);
            SPDLOG_DEBUG("max_volume is [{}]", m_max_volume.toStdString());
            emit maxVolumeChanged();
        }
    }

    void
    trading_page::determine_max_volume()
    {
        if (this->m_market_mode == MarketMode::Sell)
        {
            //! In MarketMode::Sell mode max volume is just the base_max_taker_vol
            const auto max_taker_vol_obj  = get_orderbook_wrapper()->get_base_max_taker_vol().toJsonObject();
            const auto max_taker_vol      = max_taker_vol_obj["decimal"].toString().toStdString();
            const auto max_taker_vol_coin = max_taker_vol_obj["coin"].toString().toStdString();
            const auto base               = get_market_pairs_mdl()->get_left_selected_coin().toStdString();


            if (!max_taker_vol.empty())
            {
                if (safe_float(max_taker_vol) <= 0 || base != max_taker_vol_coin)
                {
                    this->set_max_volume("0");
                }
                else
                {
                    auto max_vol_str = utils::format_float(safe_float(max_taker_vol));
                    if (m_preferred_order.has_value() && !m_preferred_order->empty() && m_preferred_order->contains("base_max_volume"))
                    {
                        auto       available_quantity       = m_preferred_order->at("base_max_volume").get<std::string>();
                        t_float_50 available_quantity_order = safe_float(available_quantity);
                        SPDLOG_DEBUG(
                            "available_quantity_order: {}, max_volume: {}, max_taker_vol: {}", utils::format_float(safe_float(available_quantity)),
                            get_max_volume().toStdString(), max_taker_vol);
                        if (available_quantity_order < safe_float(max_taker_vol) && !m_preferred_order->at("capped").get<bool>())
                        {
                            max_vol_str                         = available_quantity;
                            m_preferred_order.value()["capped"] = true;
                            this->set_max_volume(QString::fromStdString(max_vol_str));
                        }
                        else
                        {
                            if (!m_preferred_order->at("capped").get<bool>())
                            {
                                SPDLOG_DEBUG("Selected order capping to max_taker_vol because our max_taker_volume is < base_max_volume");
                                m_preferred_order.value()["capped"] = true;
                                this->set_max_volume(QString::fromStdString(max_vol_str));
                            }
                        }
                    }
                    else
                    {
                        //! max_volume is max_taker_vol
                        this->set_max_volume(QString::fromStdString(max_vol_str));
                    }
                }

                //! Capping it
                this->cap_volume();
            }
            else
            {
                SPDLOG_WARN("max_taker_vol cannot be empty, is it called before being determined ?");
            }
        }
        else
        {
            //! In MarketMode::Buy mode the max volume is rel_max_taker_vol / price
            if (!m_price.isEmpty())
            {
                t_float_50 price_f = safe_float(m_price.toStdString());
                //! It's selected let's use rat price
                if (m_preferred_order.has_value())
                {
                    const auto& rel_max_taker_json_obj = get_orderbook_wrapper()->get_rel_max_taker_vol().toJsonObject();
                    const auto& denom                  = rel_max_taker_json_obj["denom"].toString().toStdString();
                    const auto& numer                  = rel_max_taker_json_obj["numer"].toString().toStdString();
                    if (t_float_50 res_f = safe_float(rel_max_taker_json_obj["decimal"].toString().toStdString()); res_f <= 0)
                    {
                        res_f = 0;
                        this->set_max_volume(QString::fromStdString(utils::format_float(res_f)));
                    }
                    else
                    {
                        auto rel_max_vol  = m_preferred_order->at("rel_max_volume").get<std::string>();
                        auto base_max_vol = m_preferred_order->at("base_max_volume").get<std::string>();
                        if (res_f >= safe_float(rel_max_vol))
                        {
                            this->set_max_volume(QString::fromStdString(utils::extract_large_float(base_max_vol)));
                        }
                        else
                        {
                            t_rational rel_max_taker_rat((boost::multiprecision::cpp_int(numer)), boost::multiprecision::cpp_int(denom));
                            if (price_f > t_float_50(0))
                            {
                                const auto price_denom = m_preferred_order->at("price_denom").get<std::string>();
                                const auto price_numer = m_preferred_order->at("price_numer").get<std::string>();
                                t_rational price_orderbook_rat((boost::multiprecision::cpp_int(price_numer)), (boost::multiprecision::cpp_int(price_denom)));
                                t_rational res                                      = rel_max_taker_rat / price_orderbook_rat;
                                res_f                                               = res.convert_to<t_float_50>();
                                this->m_preferred_order.value()["max_volume_denom"] = boost::multiprecision::denominator(res).str();
                                this->m_preferred_order.value()["max_volume_numer"] = boost::multiprecision::numerator(res).str();
                            }
                            this->set_max_volume(QString::fromStdString(utils::format_float(res_f)));
                        }
                    }
                    this->cap_volume();
                }
                else
                {
                    t_float_50 max_vol = safe_float(get_orderbook_wrapper()->get_rel_max_taker_vol().toJsonObject()["decimal"].toString().toStdString());
                    max_vol            = std::max(t_float_50(0), max_vol);
                    t_float_50 res     = price_f > t_float_50(0) ? max_vol / price_f : t_float_50(0);
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
    trading_page::cap_volume()
    {
        /*
         * cap_volume is called only in MarketMode::Buy, and in Sell mode if preferred order
         * if the current volume text field is > the new max_volume then set volume to max_volume
         */
        if (auto std_volume = this->get_volume().toStdString();
            !std_volume.empty() && safe_float(std_volume) > safe_float(this->get_max_volume().toStdString()))
        {
            auto max_volume = this->get_max_volume();
            if (!max_volume.isEmpty() && max_volume != "0")
            {
                SPDLOG_DEBUG("capping volume because {} (volume) > {} (max_volume)", std_volume, max_volume.toStdString());
                this->set_volume(get_max_volume());
            }
        }
    }

    TradingError
    trading_page::get_trading_error() const
    {
        return m_last_trading_error;
    }

    void
    trading_page::set_trading_error(TradingError trading_error)
    {
        if (m_last_trading_error != trading_error)
        {
            m_last_trading_error = trading_error;
            switch (m_last_trading_error)
            {
            case TradingErrorGadget::None:
                SPDLOG_INFO("last_trading_error is None");
                break;
            case TradingErrorGadget::TotalFeesNotEnoughFunds:
                SPDLOG_WARN("last_trading_error is TotalFeesNotEnoughFunds");
                break;
            case TradingErrorGadget::BalanceIsLessThanTheMinimalTradingAmount:
                SPDLOG_WARN("last_trading_error is BalanceIsLessThanTheMinimalTradingAmount");
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
            case TradingErrorGadget::LeftParentChainNotEnabled:
                SPDLOG_WARN("last_trading_error is LeftParentChainNotEnabled");
                break;
            case TradingErrorGadget::LeftParentChainNotEnoughBalance:
                SPDLOG_WARN("last_trading_error is LeftParentChainNotEnoughBalance");
                break;
            case TradingErrorGadget::RightParentChainNotEnoughBalance:
                SPDLOG_WARN("last_trading_error is RightParentChainNotEnoughBalance");
                break;
            case TradingErrorGadget::RightParentChainNotEnabled:
                SPDLOG_WARN("last_trading_error is RightParentChainNotEnabled");
                break;
            case TradingErrorGadget::LeftZhtlcChainNotEnabled:
                SPDLOG_WARN("last_trading_error is LeftZhtlcChainNotEnabled");
                break;
            case TradingErrorGadget::RightZhtlcChainNotEnabled:
                SPDLOG_WARN("last_trading_error is RightZhtlcChainNotEnabled");
                break;
            default:
                break;
            }
            emit tradingErrorChanged();
        }
    }

    TradingMode
    trading_page::get_current_trading_mode() const
    {
        return m_current_trading_mode;
    }

    void
    trading_page::set_current_trading_mode(TradingMode trading_mode)
    {
        if (m_current_trading_mode != trading_mode)
        {
            this->clear_forms("set_current_trading_mode");
            this->set_market_mode(MarketMode::Sell);
            m_current_trading_mode = trading_mode;
            entity_registry_.template ctx<QSettings>().setValue("DefaultTradingMode", m_current_trading_mode);
            // get_market_pairs_mdl()->get_left_selection_box()->set_with_fiat_balance(m_current_trading_mode == TradingMode::Simple);
            get_market_pairs_mdl()->get_left_selection_box()->set_with_balance(m_current_trading_mode == TradingMode::Simple);
            SPDLOG_DEBUG("Set trading mode to: {}", QMetaEnum::fromType<TradingMode>().valueToKey(trading_mode));
            emit tradingModeChanged();
        }
    }

    bool
    trading_page::set_pair(bool is_left_side, const QString& changed_ticker)
    {
        // SPDLOG_DEBUG("Changed ticker: {}", changed_ticker.toStdString());
        const auto* market_pair = get_market_pairs_mdl();
        auto        base        = market_pair->get_left_selected_coin();
        auto        rel         = market_pair->get_right_selected_coin();

        bool is_swap = false;
        if (!changed_ticker.isEmpty())
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
            if (base == rel || base.isEmpty() || rel.isEmpty())
            {
                set_current_orderbook(DEX_PRIMARY_COIN, DEX_SECOND_PRIMARY_COIN);
            }
            else
            {
                set_current_orderbook(base, rel);
            }
        }
        this->determine_cex_rates();
        emit priceChanged();
        emit priceReversedChanged();
        return true;
    }

    QVariantMap
    trading_page::get_preferred_order() const
    {
        if (m_preferred_order.has_value())
        {
            return nlohmann_json_object_to_qt_json_object(m_preferred_order.value()).toVariantMap();
        }

        return {};
    }

    void trading_page::set_preferred_order(const QVariantMap& price_object)
    {
        auto preferred_order = nlohmann::json::parse(QString(QJsonDocument(QJsonObject::fromVariantMap(price_object)).toJson()).toStdString());
        if (preferred_order == m_preferred_order)
        {
            return;
        }
        SPDLOG_DEBUG("preferred_order: {}", preferred_order.dump(-1));
        m_preferred_order = std::move(preferred_order);
        emit prefferedOrderChanged();
        if (!m_preferred_order->empty() && m_preferred_order->contains("price"))
        {
            m_preferred_order->operator[]("capped") = false;
            this->set_price(QString::fromStdString(utils::format_float(safe_float(m_preferred_order->at("price").get<std::string>()))));
            this->determine_max_volume();
            QString min_vol = QString::fromStdString(utils::format_float(safe_float(m_preferred_order->at("base_min_volume").get<std::string>())));
            this->set_min_trade_vol(min_vol);

            if (this->m_current_trading_mode == TradingModeGadget::Pro)
            {
                auto available_quantity = m_preferred_order->at("base_max_volume").get<std::string>();
                this->set_volume(QString::fromStdString(utils::extract_large_float(available_quantity)));
            }
            else if (this->m_current_trading_mode == TradingModeGadget::Simple && m_preferred_order->contains("initial_input_volume"))
            {
                SPDLOG_DEBUG("From simple view, using initial_input_volume from selection to use.");
                this->set_volume(QString::fromStdString(m_preferred_order->at("initial_input_volume").get<std::string>()));
            }
            this->get_orderbook_wrapper()->refresh_best_orders();
            this->determine_fees();
            emit preferredOrderChangeFinished();
        }
    }

    QString
    trading_page::get_total_amount() const
    {
        return m_total_amount;
    }

    void
    trading_page::set_total_amount(QString total_amount)
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
    trading_page::determine_total_amount()
    {
        if (!m_price.isEmpty() && !m_volume.isEmpty())
        {
            this->set_total_amount(calculate_total_amount(m_price, m_volume));
            if (const std::string max_dust_str =
                    ((m_market_mode == MarketMode::Sell) ? get_orderbook_wrapper()->get_base_max_taker_vol() : get_orderbook_wrapper()->get_rel_max_taker_vol())
                        .toJsonObject()["decimal"]
                        .toString()
                        .toStdString();
                !max_dust_str.empty())
            {
                this->determine_error_cases();
            }
        }
    }

    QString
    trading_page::get_base_amount() const
    {
        return m_market_mode == MarketMode::Sell ? m_volume : m_total_amount;
    }

    QString
    trading_page::get_rel_amount() const
    {
        return m_market_mode == MarketMode::Sell ? m_total_amount : m_volume;
    }

    QVariantMap
    trading_page::get_fees() const
    {
        return m_fees.get();
    }

    void
    trading_page::set_fees(const QVariantMap& fees)
    {
        if (fees != m_fees)
        {
            m_fees = fees;
            emit feesChanged();
        }
    }

    void
    trading_page::determine_fees()
    {
        if (!this->m_system_manager.has_system<mm2_service>())
        {
            SPDLOG_WARN("MM2 Service not available, cannot determine fees - skipping");
            return;
        }
        const auto* market_pair = get_market_pairs_mdl();
        using namespace std::string_literals;
        auto&       mm2         = this->m_system_manager.get_system<mm2_service>();
        // TODO: there is a race condition that sometimes results in base == rel after switching base/rel tickers
        const auto  base        = market_pair->get_left_selected_coin().toStdString();
        const auto  rel         = market_pair->get_right_selected_coin().toStdString();
        const auto  swap_method = m_market_mode == MarketMode::Sell ? "sell"s : "buy"s;
        std::string volume      = get_volume().toStdString();
        std::string price       = get_price().toStdString();

        if (base == rel) // trade_preimage::BaseEqualRel 
        {
            return;
        }
        if (volume == "0") // trade_preimage::VolumeTooLow (can also occur if trade vol + fees is > balance)
        {
            return;
        }
        if (std::stof(price) < 0.00000001) // trade_preimage::PriceTooLow
        {
            return;
        }

        t_trade_preimage_request req{
            .base_coin = base,
            .rel_coin = rel,
            .swap_method = swap_method,
            .volume = volume,
            .price = price
        };

        nlohmann::json batch;
        nlohmann::json preimage_request = mm2::template_request("trade_preimage");
        mm2::to_json(preimage_request, req);
        batch.push_back(preimage_request);
        preimage_request["userpass"] = "******";
        SPDLOG_DEBUG("trade_preimage request: {}", preimage_request.dump(4));

        this->set_preimage_busy(true);
        auto answer_functor = [this, &mm2](web::http::http_response resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            SPDLOG_INFO("[determine_fees] trade_preimage answer received: {}", body);
            if (resp.status_code() == web::http::status_codes::OK)
            {
                auto           answers               = nlohmann::json::parse(body);
                nlohmann::json answer                = answers[0];
                auto           trade_preimage_answer = mm2::rpc_process_answer_batch<t_trade_preimage_answer>(answer, "trade_preimage");
                if (trade_preimage_answer.error.has_value())
                {
                    auto        error_answer = trade_preimage_answer.error.value();
                    QVariantMap fees;
                    fees["error"] = QString::fromStdString(error_answer);
                    this->set_fees(fees);
                }
                
                if (trade_preimage_answer.result.has_value())
                {
                    auto        success_answer = trade_preimage_answer.result.value();
                    QVariantMap fees;

                    const auto trading_fee_ticker = QString::fromStdString(success_answer.taker_fee.value().coin);

                    //! Trading fee are taker_fee
                    fees["trading_fee"]        = QString::fromStdString(utils::adjust_precision(success_answer.taker_fee.value().amount));
                    fees["trading_fee_ticker"] = trading_fee_ticker;

                    fees["base_transaction_fees"]        = QString::fromStdString(utils::adjust_precision(success_answer.base_coin_fee.amount));
                    fees["base_transaction_fees_ticker"] = QString::fromStdString(success_answer.base_coin_fee.coin);

                    fees["rel_transaction_fees"]        = QString::fromStdString(success_answer.rel_coin_fee.amount);
                    fees["rel_transaction_fees_ticker"] = QString::fromStdString(success_answer.rel_coin_fee.coin);

                    //! We are always in buy or sell mode, in this case show the fees
                    fees["fee_to_send_taker_fee"]        = QString::fromStdString(utils::adjust_precision(success_answer.fee_to_send_taker_fee.value().amount));
                    fees["fee_to_send_taker_fee_ticker"] = QString::fromStdString(success_answer.fee_to_send_taker_fee.value().coin);

                    for (auto&& cur: success_answer.total_fees)
                    {
                        if (!mm2.do_i_have_enough_funds(cur.at("coin").get<std::string>(), safe_float(cur.at("required_balance").get<std::string>())))
                        {
                            fees["error_fees"] = atomic_dex::nlohmann_json_object_to_qt_json_object(cur);
                            break;
                        }
                    }
                    fees["total_fees"] = atomic_dex::nlohmann_json_array_to_qt_json_array(success_answer.total_fees);

                    this->set_fees(fees);
                }
            }
            this->set_preimage_busy(false);
        };
        mm2.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(&handle_exception_pplx_task);
    }

    void
    trading_page::determine_error_cases()
    {
        if (!m_system_manager.has_system<mm2_service>())
            return;
        TradingError current_trading_error = TradingError::None;

        //! Check minimal trading amount
        const std::string base                     = this->get_market_pairs_mdl()->get_base_selected_coin().toStdString();
        const std::string left                     = this->get_market_pairs_mdl()->get_left_selected_coin().toStdString();
        const std::string right                    = this->get_market_pairs_mdl()->get_right_selected_coin().toStdString();
        t_float_50        max_balance_without_dust = this->get_max_balance_without_dust();
        const auto&       rel_min_taker_vol        = get_orderbook_wrapper()->get_rel_min_taker_vol().toStdString();
        const auto        regular_min_taker_vol    = m_market_mode == MarketMode::Sell ? get_min_trade_vol().toStdString() : rel_min_taker_vol;
        const auto&       cur_min_taker_vol        = get_min_trade_vol().toStdString();
        const auto&       mm2                      = m_system_manager.get_system<mm2_service>();
        const auto        left_cfg                 = mm2.get_coin_info(left);
        const auto        right_cfg                = mm2.get_coin_info(right);
        const bool        has_preferred_order      = m_preferred_order.has_value();
        const bool        is_selected_min_max =
            has_preferred_order && m_preferred_order->at("base_min_volume").get<std::string>() == m_preferred_order->at("base_max_volume").get<std::string>();
        
        if (left_cfg.has_parent_fees_ticker && left_cfg.ticker != "QTUM")
        {
            const auto left_fee_cfg = mm2.get_coin_info(left_cfg.fees_ticker);
            if (!left_fee_cfg.currently_enabled)
            {
                current_trading_error = TradingError::LeftParentChainNotEnabled;
            }
            else if (mm2.get_balance(left_fee_cfg.ticker) <= 0)
            {
                current_trading_error = TradingError::LeftParentChainNotEnoughBalance;
            }
        }
        else if (right_cfg.has_parent_fees_ticker && right_cfg.ticker != "QTUM")
        {
            const auto right_fee_cfg = mm2.get_coin_info(right_cfg.fees_ticker);
            if (!right_fee_cfg.currently_enabled)
            {
                current_trading_error = TradingError::RightParentChainNotEnabled;
            }
            else if (mm2.get_balance(right_fee_cfg.ticker) <= 0)
            {
                current_trading_error = TradingError::RightParentChainNotEnoughBalance;
            }
        }
        else if (!mm2.is_zhtlc_coin_ready(left))
        {
            current_trading_error = TradingError::LeftZhtlcChainNotEnabled;
        }
        else if (!mm2.is_zhtlc_coin_ready(right))
        {
            current_trading_error = TradingError::RightZhtlcChainNotEnabled;
        }

        if (current_trading_error == TradingError::None)
        {
            if (max_balance_without_dust < safe_float(regular_min_taker_vol)) //<! Checking balance < minimal_trading_amount
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
            else if (safe_float(m_volume.toStdString()) < safe_float(cur_min_taker_vol) && !is_selected_min_max)
            {
                current_trading_error = TradingError::VolumeIsLowerThanTheMinimum;
            }
            else if (safe_float(m_total_amount.toStdString()) < safe_float(rel_min_taker_vol))
            {
                current_trading_error = TradingError::ReceiveVolumeIsLowerThanTheMinimum;
            }
            else
            {
                if (!get_fees().empty())
                {
                    current_trading_error = generate_fees_error(get_fees());
                }
            }
        }

        //! Check for base coin
        this->set_trading_error(current_trading_error);
    }

    void
    trading_page::determine_cex_rates()
    {
        const auto& price_service   = m_system_manager.get_system<global_price_service>();
        const auto* market_selector = get_market_pairs_mdl();
        const auto& base            = market_selector->get_left_selected_coin();
        const auto& rel             = market_selector->get_right_selected_coin();
        
        if (auto cex_price = QString::fromStdString(price_service.get_cex_rates(base.toStdString(), rel.toStdString())); cex_price != m_cex_price)
        {
            m_cex_price = std::move(cex_price);
            emit cexPriceChanged();
            emit invalidCexPriceChanged();
            emit cexPriceReversedChanged();
        }
        emit cexPriceDiffChanged();
    }

    QString
    trading_page::get_cex_price() const
    {
        return m_cex_price;
    }

    bool
    trading_page::get_invalid_cex_price() const
    {
        return m_cex_price == "0" || m_cex_price == "0.00" || m_cex_price.isEmpty();
    }

    QString
    trading_page::get_price_reversed() const
    {
        if (!m_price.isEmpty() && safe_float(m_price.toStdString()) > 0)
        {
            t_float_50 reversed_price = t_float_50(1) / safe_float(m_price.toStdString());
            return QString::fromStdString(utils::format_float(reversed_price));
        }

        return "0";
    }

    QString
    trading_page::get_cex_price_reversed() const
    {
        if (!get_invalid_cex_price())
        {
            t_float_50 reversed_cex_price = t_float_50(1) / safe_float(m_cex_price.toStdString());
            return QString::fromStdString(utils::format_float(reversed_cex_price));
        }
        return "0";
    }

    QString
    trading_page::get_cex_price_diff() const
    {
        if (bool is_invalid = get_invalid_cex_price(); is_invalid || safe_float(m_price.toStdString()) <= 0)
        {
            return "0";
        }
        const bool is_buy     = m_market_mode == MarketMode::Buy;
        t_float_50 price      = safe_float(m_price.toStdString());
        t_float_50 cex_price  = safe_float(m_cex_price.toStdString());
        t_float_50 price_diff = t_float_50(100) * (t_float_50(1) - price / cex_price) * (!is_buy ? t_float_50(1) : t_float_50(-1));
        return QString::fromStdString(utils::format_float(price_diff));
    }

    t_float_50
    trading_page::get_max_balance_without_dust(const std::optional<QString>& trade_with) const
    {
        if (!trade_with.has_value())
        {
            const std::string max_dust_str =
                ((m_market_mode == MarketMode::Sell) ? get_orderbook_wrapper()->get_base_max_taker_vol() : get_orderbook_wrapper()->get_rel_max_taker_vol())
                    .toJsonObject()["decimal"]
                    .toString()
                    .toStdString();
            if (max_dust_str.empty())
            {
                return t_float_50(0);
            }
            t_float_50 max_balance_without_dust = safe_float(max_dust_str);
            return max_balance_without_dust;
        }

        return t_float_50(0);
    }

    TradingError
    trading_page::generate_fees_error(QVariantMap fees) const
    {
        TradingError last_trading_error = TradingError::None;
        const auto&  mm2                = m_system_manager.get_system<mm2_service>();

        if (fees.contains("error_fees"))
        {
            auto&& cur_obj = fees.value("error_fees").toJsonObject();
            if (!mm2.do_i_have_enough_funds(cur_obj["coin"].toString().toStdString(), safe_float(cur_obj["required_balance"].toString().toStdString())))
            {
                last_trading_error = TradingError::TotalFeesNotEnoughFunds;
            }
        }
        return last_trading_error;
    }

    bool
    trading_page::get_skip_taker() const
    {
        return m_skip_taker;
    }

    void
    trading_page::set_skip_taker(bool skip_taker)
    {
        if (m_skip_taker != skip_taker)
        {
            m_skip_taker = skip_taker;
            emit skipTakerChanged();
        }
    }

    QString
    trading_page::get_min_trade_vol() const
    {
        return m_minimal_trading_amount;
    }

    void
    trading_page::set_min_trade_vol(QString min_trade_vol)
    {
        //! KMD<->DOGE Buy -> base_min_vol, sell base_min_vol ->
        //! base_min_vol -> 0.0001 KMD
        //! rel_min_vol -> 10 DOGE
        t_float_50   min_trade_vol_f         = safe_float(min_trade_vol.toStdString());
        const auto&  current_min_taker_vol   = get_orderbook_wrapper()->get_current_min_taker_vol().toStdString();
        t_float_50   current_min_taker_vol_f = safe_float(current_min_taker_vol);
        const auto&  base_min_taker_vol      = get_orderbook_wrapper()->get_base_min_taker_vol().toStdString();
        t_float_50   base_min_taker_vol_f    = safe_float(base_min_taker_vol);

        if (min_trade_vol_f < base_min_taker_vol_f)
        {
            min_trade_vol = QString::fromStdString(base_min_taker_vol);
            min_trade_vol_f = base_min_taker_vol_f;
        }

        if (min_trade_vol != m_minimal_trading_amount)
        {
            min_trade_vol            = QString::fromStdString(utils::adjust_precision(min_trade_vol.toStdString()));
            m_minimal_trading_amount = std::move(min_trade_vol);
            emit minTradeVolChanged();
            this->determine_error_cases();
        }
    }

    void
    trading_page::reset_order()
    {
        this->clear_forms("reset_order");
    }

    bool
    trading_page::is_preimage_busy() const
    {
        return m_rpc_preimage_busy.load();
    }

    void
    trading_page::set_preimage_busy(bool status)
    {
        if (status != m_rpc_preimage_busy)
        {
            m_rpc_preimage_busy = status;
            emit preImageRpcStatusChanged();
        }
    }
    void
    trading_page::reset_fees()
    {
        SPDLOG_DEBUG("reset_fees");
        this->set_fees(QVariantMap());
        this->determine_error_cases();
    }
} // namespace atomic_dex

namespace atomic_dex
{
    QString
    trading_page::calculate_total_amount(QString price, QString volume)
    {
        t_float_50 price_f(safe_float(price.toStdString()));
        t_float_50 volume_f(safe_float(volume.toStdString()));
        t_float_50 total_amount_f = volume_f * price_f;
        return QString::fromStdString(atomic_dex::utils::format_float(total_amount_f));
    }

    void
    trading_page::set_preferred_settings()
    {
        auto&         settings            = entity_registry_.ctx<QSettings>();
        const auto*   market_selector_mdl = get_market_pairs_mdl();
        const auto    left                = market_selector_mdl->get_left_selected_coin();
        const auto    right               = market_selector_mdl->get_right_selected_coin();
        const auto    category_settings   = left + "_" + right;
        const QString target_settings     = "Disabled";
        settings.beginGroup(category_settings);
        const bool is_disabled        = settings.value(target_settings, true).toBool();
        t_float_50 spread             = settings.value("Spread", 1.0).toDouble();
        t_float_50 min_volume_percent = settings.value("MinVolume", 10.0).toDouble() / 100; ///< min volume is always 10% of the order or more
        settings.endGroup();
        
        if (!is_disabled)
        {
            SPDLOG_WARN("{}/{} have trading settings - using them", left.toStdString(), right.toStdString());
            const auto& price_service = m_system_manager.get_system<global_price_service>();
            t_float_50  cex_price     = safe_float(price_service.get_cex_rates(left.toStdString(), right.toStdString()));
            t_float_50  percent       = spread / 100;
            t_float_50  target_price =
                (m_market_mode == MarketMode::Sell) ? t_float_50(cex_price + (cex_price * percent)) : t_float_50(cex_price - (cex_price * percent));

            this->set_price(QString::fromStdString(utils::format_float(target_price)));
            this->determine_max_volume();
            this->set_volume(get_max_volume());
            t_float_50 volume     = safe_float(get_volume().toStdString());
            t_float_50 min_volume = volume * min_volume_percent;
            this->set_min_trade_vol(QString::fromStdString(utils::format_float(min_volume)));
        }
        else
        {
            SPDLOG_WARN("{}/{} doesn't have any trading settings - skipping", left.toStdString(), right.toStdString());
        }
    }

    std::optional<nlohmann::json>
    trading_page::get_raw_preferred_order() const
    {
        return m_preferred_order;
    }

    SelectedOrderStatus
    trading_page::get_selected_order_status() const
    {
        return m_selected_order_status;
    }

    void
    trading_page::set_selected_order_status(SelectedOrderStatus order_status)
    {
        if (m_selected_order_status != order_status)
        {
            m_selected_order_status = order_status;
            SPDLOG_DEBUG("Set selected order status to: {}", QMetaEnum::fromType<SelectedOrderStatus>().valueToKey(order_status));
            emit selectedOrderStatusChanged();
        }
    }
} // namespace atomic_dex
