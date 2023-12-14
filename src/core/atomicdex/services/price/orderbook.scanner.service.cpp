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

//! Project Headers
#include "atomicdex/api/mm2/rpc2.best.orders.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/orderbook.scanner.service.hpp"

//! Constructor
namespace atomic_dex
{
    orderbook_scanner_service::orderbook_scanner_service(entt::registry& registry, ag::ecs::system_manager& system_manager) :
        system(registry), m_system_manager(system_manager)
    {
        SPDLOG_INFO("orderbook_scanner_service created");
        m_update_clock      = std::chrono::high_resolution_clock::now();
        m_best_orders_infos = nlohmann::json::object();
    }
} // namespace atomic_dex

//! Private member functions
namespace atomic_dex
{
    void
    orderbook_scanner_service::process_best_orders() 
    {
        if (m_bestorders_rpc_busy)
        {
            // SPDLOG_INFO("process_best_orders is busy - skipping");
            return;
        }

        // SPDLOG_INFO("process_best_orders processing");
        if (m_system_manager.has_system<mm2_service>())
        {
            auto& mm2_system = m_system_manager.get_system<mm2_service>();
            if (mm2_system.is_mm2_running() && mm2_system.is_orderbook_thread_active())
            {
                // SPDLOG_INFO("process_best_orders");
                using namespace std::string_literals;
                const auto&           trading_pg = m_system_manager.get_system<trading_page>();
                auto                  volume     = trading_pg.get_volume().toStdString();
                auto                  action     = trading_pg.get_market_mode() == MarketMode::Buy ? "buy"s : "sell"s;
                auto                  coin       = trading_pg.get_market_pairs_mdl()->get_left_selected_coin().toStdString();
                t_best_orders_request req{.coin = std::move(coin), .volume = std::move(volume), .action = std::move(action)};

                //! Prepare request
                nlohmann::json batch                = nlohmann::json::array();
                nlohmann::json best_orders_req_json = mm2::template_request("best_orders", true);
                to_json(best_orders_req_json, req);
                batch.push_back(best_orders_req_json);

                // best_orders_req_json["userpass"] = "*****";
                // SPDLOG_INFO("best_orders request: {}", best_orders_req_json.dump(4));

                this->m_bestorders_rpc_busy = true;
                emit trading_pg.get_orderbook_wrapper()->bestOrdersBusyChanged();
                //! Treat answer
                auto answer_functor = [this, &trading_pg](web::http::http_response resp) {
                    std::string body = TO_STD_STR(resp.extract_string(true).get());
                    if (resp.status_code() == 200)
                    {
                        auto answers           = nlohmann::json::parse(body);
                        auto best_order_answer = mm2::rpc_process_answer_batch<t_best_orders_answer>(answers[0], "best_orders");
                        if (best_order_answer.result.has_value())
                        {
                            this->m_best_orders_infos = best_order_answer.result.value();
                        }
                    }
                    this->m_bestorders_rpc_busy = false;
                    this->dispatcher_.trigger<process_orderbook_finished>(false);
                    emit trading_pg.get_orderbook_wrapper()->bestOrdersBusyChanged();
                };

                mm2_system.get_mm2_client().async_rpc_batch_standalone(batch)
                    .then(answer_functor)
                    .then([this](pplx::task<void> previous_task) {
                        try
                        {
                            previous_task.wait();
                        }
                        catch (const std::exception& e)
                        {
                            SPDLOG_ERROR("pplx task error in [process_best_orders]: {}", e.what());
                            this->m_bestorders_rpc_busy = false;
                            this->dispatcher_.trigger<process_orderbook_finished>(true);
                        }
                    });
            }
            else
            {
                SPDLOG_WARN("MM2 Service not launched yet - skipping process_best_orders");
            }
        }
        else
        {
            SPDLOG_WARN("MM2 Service not created yet - skipping process_best_orders");
        }
    }
} // namespace atomic_dex

//! Override member
namespace atomic_dex
{
    void
    orderbook_scanner_service::update() 
    {
        //! Scan orderbook widget every 30 seconds if there is not any update
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 30s)
        {
            process_best_orders();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    bool
    orderbook_scanner_service::is_best_orders_busy() const 
    {
        return m_bestorders_rpc_busy.load();
    }

    t_orders_contents
    orderbook_scanner_service::get_data() const 
    {
        return m_best_orders_infos.get().result;
    }
} // namespace atomic_dex