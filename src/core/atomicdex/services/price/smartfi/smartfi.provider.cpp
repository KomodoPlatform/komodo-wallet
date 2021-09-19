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

//! Deps
#include <boost/algorithm/string.hpp>
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/services/price/smartfi/smartfi.provider.hpp"

namespace
{
    t_http_client_ptr g_smartfi_http_client{std::make_unique<t_http_client>(FROM_STD_STR("https://node1.smartfi.com/market/get-market-summary"))};
} // namespace

namespace atomic_dex
{
    void
    from_json(const nlohmann::json& j, smartfi_result& result)
    {
        auto extract_key_functor = [](std::string key) -> std::pair<std::string, std::string> {
            std::vector<std::string> out;
            boost::algorithm::split(out, key, boost::is_any_of("_"));
            if (out.size() >= 2)
            {
                const auto base_coin = out[0];
                const auto rel_coin  = out[1];
                if (base_coin == "USD" || base_coin == "USDT")
                {
                    return std::make_pair(base_coin, rel_coin);
                }
                else
                {
                    return std::make_pair("", "");
                }
            }
            return std::make_pair("", "");
        };

        if (j.at("status").get<std::string>() == "Success")
        {
            for (auto&& [key, value]: j.at("data").items())
            {
                // SPDLOG_INFO("key: {}, value: {}", key, value.dump(4));
                auto&& [base_coin, rel_coin] = extract_key_functor(key);
                if (!base_coin.empty() && !rel_coin.empty())
                {
                    // SPDLOG_INFO("base_coin: {} rel_coin: {}", base_coin, rel_coin);
                    if (const auto last_price = value.at("Last").get<double>(); last_price > 0)
                    {
                        smartfi_data data;
                        data.last                     = last_price;
                        result.smartfi_data[rel_coin] = std::move(data);
                    }
                }
            }
        }
    }
} // namespace atomic_dex

//! Constructor
namespace atomic_dex
{
    smartfi_price_service::smartfi_price_service(entt::registry& registry) : system(registry)
    {
        SPDLOG_INFO("smartfi_price_service created");
        m_update_clock = std::chrono::high_resolution_clock::now();
        this->fetch_price();
    }
} // namespace atomic_dex

//! Private member functions
namespace atomic_dex
{
    pplx::task<web::http::http_response>
    smartfi_price_service::async_fetch_price_result() noexcept
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        return g_smartfi_http_client->request(req);
    }

    void
    smartfi_price_service::fetch_price() noexcept
    {
        SPDLOG_INFO("start fetching smartfi price");
        async_fetch_price_result()
            .then([this](web::http::http_response resp) {
                SPDLOG_INFO("fetching smartfi price finished");
                auto body = TO_STD_STR(resp.extract_string(true).get());
                if (resp.status_code() == 200)
                {
                    nlohmann::json j = nlohmann::json::parse(body);
                    smartfi_result result;
                    from_json(j, result);
                    this->m_smartfi_price_result = std::move(result);
                }
                else
                {
                    SPDLOG_ERROR("Cannot fetch smartfi price: {}", body);
                }
            })
            .then(&handle_exception_pplx_task);
    }
} // namespace atomic_dex

//! Override
namespace atomic_dex
{
    void
    smartfi_price_service::update() noexcept
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 1min)
        {
            fetch_price();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    std::string
    smartfi_price_service::retrieve_if_this_ticker_supported(const std::string& ticker) const noexcept
    {
        const auto underlying_map = m_smartfi_price_result.get().smartfi_data;
        if (const auto it = underlying_map.find(ticker); it != underlying_map.cend())
        {
            return it->second.last.str();
        }
        return "";
    }
} // namespace atomic_dex