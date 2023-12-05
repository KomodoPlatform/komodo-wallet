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

#pragma once

//! Deps
#include <antara/gaming/world/world.app.hpp>

//! Project
#include "atomicdex/events/events.hpp"
#include "atomicdex/managers/qt.wallet.manager.hpp"
#include "atomicdex/pages/qt.portfolio.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"

struct tests_context : public antara::gaming::world::app
{
  private:
    std::atomic_bool         m_test_context_ready{false};
    std::atomic_bool         m_extra_coins_ready{false};
    std::vector<std::string> m_extra_coins{"DOC", "MARTY"};

  public:
    void
    on_coin_initialized(const atomic_dex::coin_fully_initialized& evt)
    {
        if (std::any_of(begin(evt.tickers), end(evt.tickers), [this](auto&& item) { return item == this->m_extra_coins[0]; }))
        {
            SPDLOG_INFO("extra coins {} enabled", fmt::format("{}", fmt::join(evt.tickers, ", ")));
            m_extra_coins_ready = true;
        }
        else
        {
            SPDLOG_INFO("{} enabled", fmt::format("{}", fmt::join(evt.tickers, ", ")));
            m_test_context_ready = true;
        }
    }


    tests_context([[maybe_unused]] char** argv)
    {
#if !defined(WIN32) && !defined(_WIN32)
        this->dispatcher_.sink<atomic_dex::coin_fully_initialized>().connect<&tests_context::on_coin_initialized>(*this);
        //! Creates mm2 service.
        auto& mm2 = system_manager_.create_system<atomic_dex::mm2_service>(system_manager_);

        //! Creates special wallet for the unit tests then logs to it.
        auto& wallet_manager = system_manager_.create_system<atomic_dex::qt_wallet_manager>(system_manager_);
        system_manager_.create_system<atomic_dex::portfolio_page>(system_manager_);

        const char* test_seed     = std::getenv("ATOMICDEX_TEST_SEED");
        const char* test_password = std::getenv("ATOMICDEX_PASSWORD");

        if (test_seed != nullptr)
        {
            SPDLOG_INFO("Using environment seed from ATOMICDEX_TEST_SEED variable");
        }
        else
        {
            SPDLOG_INFO("Using default seed from the application");
        }

        if (test_password != nullptr)
        {
            SPDLOG_INFO("Using environment password from ATOMICDEX_PASSWORD variable");
        }
        else
        {
            SPDLOG_INFO("Using default password from the application");
        }

        if (not wallet_manager.get_wallets().contains("komodo-wallet_tests"))
        {
            wallet_manager.create(
                test_password != nullptr ? test_password : "fakepasswordtemporary", test_seed != nullptr ? test_seed : "fake seed", "komodo-wallet_tests");
        }
        else
        {
            SPDLOG_INFO("komodo-wallet_tests already exists - skipping");
        }
        wallet_manager.login(test_password != nullptr ? test_password : "fakepasswordtemporary", "komodo-wallet_tests");

        //! Waits for mm2 to be initialized before running tests
        while (!mm2.is_mm2_running() && !m_test_context_ready) { std::this_thread::sleep_for(std::chrono::milliseconds(100)); }
        const auto& enabled_coins = mm2.get_enabled_coins();
        bool        found =
            std::any_of(enabled_coins.begin(), enabled_coins.end(), [](const auto& item) -> bool { return item.ticker == "tBTC-TEST" || item.ticker == "tQTUM"; });
        if (!found)
        {
            SPDLOG_INFO("Extra coins not enabled yet, enabling now");
           mm2.enable_coins(m_extra_coins);
        }
        while (!m_extra_coins_ready) { std::this_thread::sleep_for(std::chrono::milliseconds(100)); }
        //! At this point BTC/KMD are enabled but we need ERC20 and QRC20 too / change login behaviour ?
#endif
    }

    antara::gaming::ecs::system_manager&
    system_manager() 
    {
        return system_manager_;
    }
};

extern std::unique_ptr<tests_context> g_context;
