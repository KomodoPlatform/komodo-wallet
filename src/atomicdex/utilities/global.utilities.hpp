#pragma once

//! STD
#include <random>

//! Boost
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <boost/multiprecision/cpp_int.hpp>
using t_float_50 = boost::multiprecision::cpp_dec_float_50;
using t_rational = boost::multiprecision::cpp_rational;
#pragma clang diagnostic pop


//! QT Headers
#include <QCryptographicHash>
#include <QString>

//! Deps
#include <date/date.h>
#include <date/tz.h>
#include <nlohmann/json.hpp>
#include <entt/core/attribute.h>

namespace atomic_dex::utils
{
    //! Float numbers helpers
    std::string get_formated_float(t_float_50 value);
    std::string adjust_precision(const std::string& current);
    std::string format_float(t_float_50 value);

    //! Fs helpers
    void create_if_doesnt_exist(const fs::path& path);

    double determine_balance_factor(bool with_pin_cfg);

    template <typename TimeFormat = std::chrono::milliseconds>
    inline std::string
    to_human_date(std::size_t timestamp, std::string format)
    {
        using namespace date;

        const sys_time<TimeFormat> tp{TimeFormat{timestamp}};

        try
        {
            const auto tp_zoned = date::make_zoned(current_zone(), tp);
            return date::format(std::move(format), tp_zoned);
        }
        catch (const std::exception& error)
        {
            return date::format(std::move(format), tp);
        }
    }

    fs::path get_atomic_dex_data_folder();

    fs::path get_runtime_coins_path() noexcept;

    fs::path get_atomic_dex_logs_folder() noexcept;

    ENTT_API fs::path get_atomic_dex_current_log_file();
    ENTT_API std::shared_ptr<spdlog::logger> register_logger();

    fs::path get_current_configs_path();

    fs::path get_mm2_atomic_dex_current_log_file();

    fs::path get_atomic_dex_config_folder();

    std::string minimal_trade_amount_str();

    const t_float_50 minimal_trade_amount();

    fs::path get_atomic_dex_export_folder();

    fs::path get_atomic_dex_current_export_recent_swaps_file();

    std::string dex_sha256(const std::string& str);

    void to_eth_checksum(std::string& address);
} // namespace atomic_dex::utils


namespace atomic_dex::utils
{
    struct timed_waiter
    {
        void interrupt();

        template <class Rep, class Period>
        bool wait_for(std::chrono::duration<Rep, Period> how_long) const;

      private:
        std::unique_lock<std::mutex> lock() const;

        mutable std::mutex              m;
        mutable std::condition_variable cv;
        bool                            interrupted = false;
    };

    struct my_json_sax : nlohmann::json_sax<nlohmann::json>
    {
        bool binary([[maybe_unused]] binary_t& val) override;

        bool null() override;

        bool boolean([[maybe_unused]] bool val) override;

        bool number_integer([[maybe_unused]] number_integer_t val) override;

        bool number_unsigned([[maybe_unused]] number_unsigned_t val) override;

        bool number_float([[maybe_unused]] number_float_t val, [[maybe_unused]] const string_t& s) override;

        bool string([[maybe_unused]] string_t& val) override;

        bool start_object([[maybe_unused]] std::size_t elements) override;

        bool key([[maybe_unused]] string_t& val) override;

        bool end_object() override;

        bool start_array([[maybe_unused]] std::size_t elements) override;

        bool end_array() override;

        bool parse_error(
            [[maybe_unused]] std::size_t position, [[maybe_unused]] const std::string& last_token,
            [[maybe_unused]] const nlohmann::detail::exception& ex) override;

        std::string float_as_string;
    };
} // namespace atomic_dex::utils
