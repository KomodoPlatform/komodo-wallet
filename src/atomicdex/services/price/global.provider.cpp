#include "src/atomicdex/pch.hpp"

//! Project Headers
#include "atomicdex/services/price/coinpaprika/coinpaprika.provider.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/services/price/oracle/band.provider.hpp"

namespace
{
    t_http_client_ptr g_openrates_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR("https://api.openrates.io"));

    pplx::task<web::http::http_response>
    async_fetch_fiat_rates()
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        req.set_request_uri(FROM_STD_STR("/latest?base=USD"));
        return g_openrates_client->request(req);
    }

    nlohmann::json
    process_fetch_fiat_answer(web::http::http_response resp)
    {
        nlohmann::json answer;
        if (resp.status_code() == 200)
        {
            answer = nlohmann::json::parse(TO_STD_STR(resp.extract_string(true).get()));
            return answer;
        }

        SPDLOG_WARN("unable to fetch last open rates");
        return answer;
    }
} // namespace

namespace
{
    std::string
    compute_result(const std::string& amount, const std::string& price, const std::string& currency, atomic_dex::cfg& cfg)
    {
        const t_float_50 amount_f(amount);
        const t_float_50 current_price_f(price);
        const t_float_50 final_price       = amount_f * current_price_f;
        std::size_t      default_precision = atomic_dex::is_this_currency_a_fiat(cfg, currency) ? 2 : 8;
        std::string      result;

        if (auto final_price_str = final_price.str(default_precision, std::ios_base::fixed); final_price_str == "0.00" && final_price > 0.00000000)
        {
            const auto retry = [&result, &final_price, &default_precision]() { result = final_price.str(default_precision, std::ios_base::fixed); };

            result = final_price.str(default_precision);
            if (result.find("e") != std::string::npos)
            {
                //! We have scientific notations lets get ride of that
                do
                {
                    default_precision += 1;
                    retry();
                } while (t_float_50(result) <= 0);
            }
        }
        else
        {
            result = final_price.str(default_precision, std::ios_base::fixed);
        }

        boost::trim_right_if(result, boost::is_any_of("0"));
        boost::trim_right_if(result, boost::is_any_of("."));
        return result;
    }
} // namespace


namespace atomic_dex
{
    void
    global_price_service::refresh_other_coins_rates(const std::string& quote_id, const std::string& ticker, bool with_update_providers)
    {
        using namespace std::chrono_literals;
        coinpaprika::api::price_converter_request request{.base_currency_id = "usd-us-dollars", .quote_currency_id = quote_id};
        coinpaprika::api::async_price_converter(request)
            .then([this, quote_id, ticker, with_update_providers](web::http::http_response resp) {
                auto answer = coinpaprika::api::process_generic_resp<t_price_converter_answer>(resp);
                if (answer.rpc_result_code == e_http_code::too_many_requests)
                {
                    std::this_thread::sleep_for(1s);
                    this->refresh_other_coins_rates(quote_id, ticker);
                }
                else
                {
                    if (answer.raw_result.find("error") == std::string::npos)
                    {
                        if (not answer.price.empty())
                        {
                            this->m_coin_rate_providers.insert_or_assign(ticker, answer.price);
                        }
                    }
                    else
                    {
                        this->m_coin_rate_providers.insert_or_assign(ticker, "0.00");
                    }
                }
                if (with_update_providers)
                {
                    this->m_system_manager.get_system<coinpaprika_provider>().update_ticker_and_provider();
                }
            })
            .then(&handle_exception_pplx_task);
    }

    global_price_service::global_price_service(entt::registry& registry, ag::ecs::system_manager& system_manager, atomic_dex::cfg& cfg) :
        system(registry), m_system_manager(system_manager), m_cfg(cfg)
    {
        m_update_clock = std::chrono::high_resolution_clock::now();
        async_fetch_fiat_rates()
            .then([this](web::http::http_response resp) {
                this->m_other_fiats_rates = process_fetch_fiat_answer(resp);
                refresh_other_coins_rates("kmd-komodo", "KMD");
                refresh_other_coins_rates("btc-bitcoin", "BTC");
            })
            .then(&handle_exception_pplx_task);
    }
} // namespace atomic_dex

namespace atomic_dex
{
    void
    global_price_service::update() noexcept
    {
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 2min)
        {
            async_fetch_fiat_rates()
                .then([this](web::http::http_response resp) {
                    this->m_other_fiats_rates = process_fetch_fiat_answer(resp);
                    refresh_other_coins_rates("kmd-komodo", "KMD");
                    refresh_other_coins_rates("btc-bitcoin", "BTC", true);
                })
                .then(&handle_exception_pplx_task);

            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }

    std::string
    global_price_service::get_rate_conversion(const std::string& fiat, const std::string& ticker, std::error_code& ec, bool adjusted) const noexcept
    {
        //! FIXME: fix zatJum crash report, frontend QML try to retrieve price before program is even launched
        if (ticker.empty())
            return "0";
        auto&       paprika         = m_system_manager.get_system<coinpaprika_provider>();
        auto&       band_service    = m_system_manager.get_system<band_oracle_price_service>();
        std::string current_price   = band_service.retrieve_if_this_ticker_supported(ticker);
        bool        is_oracle_ready = band_service.is_oracle_ready();
        if (current_price.empty())
        {
            current_price = paprika.get_rate_conversion("USD", ticker, ec);
        }

        if (fiat != "KMD" && fiat != "BTC" && fiat != "USD")
        {
            t_float_50 tmp_current_price = t_float_50(current_price) * m_other_fiats_rates->at("rates").at(fiat).get<double>();
            current_price                = tmp_current_price.str();
        }

        if ((fiat == "KMD" && not is_oracle_ready) || (fiat == "BTC" && not is_oracle_ready))
        {
            t_float_50 tmp_current_price = t_float_50(current_price) * t_float_50(m_coin_rate_providers.at(fiat));
            current_price                = tmp_current_price.str();
        }
        else if ((fiat == "BTC" || fiat == "KMD") && is_oracle_ready)
        {
            t_float_50 tmp_current_price = t_float_50(current_price) * band_service.retrieve_rates(fiat);
            current_price                = tmp_current_price.str();
        }

        if (adjusted)
        {
            std::size_t default_precision = is_this_currency_a_fiat(m_cfg, fiat) ? 2 : 8;

            t_float_50 current_price_f(current_price);
            if (is_this_currency_a_fiat(m_cfg, fiat))
            {
                if (current_price_f < 1.0)
                {
                    default_precision = 5;
                }
            }
            //! Trick: If there conversion in a fixed representation is 0.00 then use a default precision to 2 without fixed ios flags
            if (auto fixed_str = current_price_f.str(default_precision, std::ios_base::fixed); fixed_str == "0.00" && current_price_f > 0.00000000)
            {
                return current_price_f.str(default_precision);
            }
            return current_price_f.str(default_precision, std::ios::fixed);
        }
        return current_price;
    }

    std::string
    global_price_service::get_price_as_currency_from_tx(
        const std::string& currency, const std::string& ticker, const tx_infos& tx, std::error_code& ec) const noexcept
    {
        auto& mm2_instance = m_system_manager.get_system<mm2_service>();

        if (mm2_instance.get_coin_info(ticker).coinpaprika_id == "test-coin")
        {
            return "0.00";
        }
        const auto amount        = tx.am_i_sender ? tx.my_balance_change.substr(1) : tx.my_balance_change;
        const auto current_price = get_rate_conversion(currency, ticker, ec);
        if (ec)
        {
            return "0.00";
        }
        return compute_result(amount, current_price, currency, this->m_cfg);
    }

    std::string
    global_price_service::get_price_in_fiat_all(const std::string& fiat, std::error_code& ec) const noexcept
    {
        auto&   mm2_instance = m_system_manager.get_system<mm2_service>();
        t_coins coins        = mm2_instance.get_enabled_coins();
        try
        {
            t_float_50        final_price_f = 0;
            std::string       current_price = "0.00";
            std::stringstream ss;

            for (auto&& current_coin: coins)
            {
                if (current_coin.coinpaprika_id == "test-coin")
                {
                    continue;
                }

                current_price = get_price_in_fiat(fiat, current_coin.ticker, ec, true);

                if (ec)
                {
                    //SPDLOG_WARN("error when converting {} to {}, err: {}", current_coin.ticker, fiat, ec.message());
                    ec.clear(); //! Reset
                    continue;
                }

                if (not current_price.empty())
                {
                    const auto current_price_f = t_float_50(current_price);
                    final_price_f += current_price_f;
                }
            }

            std::size_t default_precision = is_this_currency_a_fiat(m_cfg, fiat) ? 2 : 8;
            ss.precision(default_precision);
            ss << std::fixed << final_price_f;
            std::string result = ss.str();
            boost::trim_right_if(result, boost::is_any_of("0"));
            boost::trim_right_if(result, boost::is_any_of("."));
            return result;
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("exception caught in func[{}] line[{}] file[{}] error[{}]", 
                        __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string(), error.what());
            return "0.00";
        }
    }

    std::string
    global_price_service::get_price_as_currency_from_amount(
        const std::string& currency, const std::string& ticker, const std::string& amount, std::error_code& ec) const noexcept
    {
        auto& mm2_instance = m_system_manager.get_system<mm2_service>();

        if (mm2_instance.get_coin_info(ticker).coinpaprika_id == "test-coin")
        {
            return "0.00";
        }

        const auto current_price = get_rate_conversion(currency, ticker, ec);

        if (ec)
        {
            return "0.00";
        }

        return compute_result(amount, current_price, currency, this->m_cfg);
    }

    std::string
    global_price_service::get_price_in_fiat(const std::string& fiat, const std::string& ticker, std::error_code& ec, bool skip_precision) const noexcept
    {
        auto& mm2_instance = m_system_manager.get_system<mm2_service>();

        if (mm2_instance.get_coin_info(ticker).coinpaprika_id == "test-coin")
        {
            return "0.00";
        }

        if (m_supported_fiat_registry.count(fiat) == 0u)
        {
            ec = dextop_error::invalid_fiat_for_rate_conversion;
            return "0.00";
        }

        const auto price = get_rate_conversion(fiat, ticker, ec);

        if (ec)
        {
            return "0.00";
        }

        std::error_code t_ec;
        const auto      amount = mm2_instance.my_balance(ticker, t_ec);

        if (t_ec)
        {
            ec = t_ec;
            SPDLOG_ERROR("my_balance error: {}", t_ec.message());
            return "0.00";
        }

        if (not skip_precision)
        {
            return compute_result(amount, price, fiat, this->m_cfg);
        }

        const t_float_50  price_f(price);
        const t_float_50  amount_f(amount);
        const t_float_50  final_price = price_f * amount_f;
        std::stringstream ss;

        ss << std::fixed << final_price;

        return ss.str() == "0" ? "0.00" : ss.str();
    }

    std::string
    global_price_service::get_cex_rates(const std::string& base, const std::string& rel, std::error_code& ec) const noexcept
    {
        std::string base_rate_str = get_rate_conversion("USD", base, ec, false);

        if (ec)
        {
            return "0.00";
        }

        std::string rel_rate_str = get_rate_conversion("USD", rel, ec, false);

        if (ec)
        {
            return "0.00";
        }

        if (base_rate_str == "0.00" || rel_rate_str == "0.00")
        {
            //! One of the rate is not available
            return "0.00";
        }

        t_float_50  base_rate_f(base_rate_str);
        t_float_50  rel_rate_f(rel_rate_str);
        t_float_50  result     = base_rate_f / rel_rate_f;
        std::string result_str = result.str(8, std::ios_base::fixed);
        boost::trim_right_if(result_str, boost::is_any_of("0"));
        boost::trim_right_if(result_str, boost::is_any_of("."));
        return result_str;
    }
} // namespace atomic_dex
