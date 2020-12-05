//! PCH
#include "atomicdex/pch.hpp"

//! Project Headers
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/version/version.hpp"

namespace {
    constexpr size_t g_qsize_spdlog             = 10240;
    constexpr size_t g_spdlog_thread_count      = 2;
    constexpr size_t g_spdlog_max_file_size     = 7777777;
    constexpr size_t g_spdlog_max_file_rotation = 3;
}
namespace atomic_dex::utils
{
    std::string
    get_formated_float(t_float_50 value)
    {
        std::stringstream ss;
        ss.precision(8);
        ss << std::fixed << value;
        return ss.str();
    }

    std::string format_float(t_float_50 value)
    {
        std::string result = value.str(8, std::ios_base::fixed);
        boost::trim_right_if(result, boost::is_any_of("0"));
        boost::trim_right_if(result, boost::is_any_of("."));
        return result;
    }

    std::string
    adjust_precision(const std::string& current)
    {
        std::string       result;
        std::stringstream ss;
        t_float_50        current_f(current);

        ss << std::fixed << std::setprecision(8) << current_f;
        result = ss.str();

        boost::trim_right_if(result, boost::is_any_of("0"));
        boost::trim_right_if(result, boost::is_any_of("."));
        return result;
    }

    void
    create_if_doesnt_exist(const fs::path& path)
    {
        if (not fs::exists(path))
        {
            fs::create_directories(path);
        }
    }

    double
    determine_balance_factor(bool with_pin_cfg)
    {
        if (not with_pin_cfg)
        {
            return 1.0;
        }

        std::random_device               rd;
        std::mt19937                     gen(rd());
        std::uniform_real_distribution<> distr(0.01, 0.05);
        return distr(gen);
    }

    fs::path
    get_atomic_dex_data_folder()
    {
        fs::path appdata_path;
#if defined(_WIN32) || defined(WIN32)
        appdata_path = fs::path(std::getenv("APPDATA")) / "atomic_qt";
#else
        appdata_path = fs::path(std::getenv("HOME")) / ".atomic_qt";
#endif
        return appdata_path;
    }

    fs::path
    get_runtime_coins_path() noexcept
    {
        const auto fs_coins_path = get_atomic_dex_data_folder() / "custom_coins_icons";
        create_if_doesnt_exist(fs_coins_path);
        return fs_coins_path;
    }

    fs::path
    get_atomic_dex_logs_folder() noexcept
    {
        const auto fs_logs_path = get_atomic_dex_data_folder() / "logs";
        create_if_doesnt_exist(fs_logs_path);
        return fs_logs_path;
    }

    ENTT_API fs::path
             get_atomic_dex_current_log_file()
    {
        using namespace std::chrono;
        using namespace date;
        static auto              timestamp = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        static date::sys_seconds tp{seconds{timestamp}};
        static std::string       s        = date::format("%Y-%m-%d-%H-%M-%S", tp);
        static const fs::path    log_path = get_atomic_dex_logs_folder() / (s + ".log");
        return log_path;
    }

    fs::path
    get_mm2_atomic_dex_current_log_file()
    {
        using namespace std::chrono;
        using namespace date;
        static auto              timestamp = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        static date::sys_seconds tp{seconds{timestamp}};
        static std::string       s        = date::format("%Y-%m-%d-%H-%M-%S", tp);
        static const fs::path    log_path = get_atomic_dex_logs_folder() / (s + ".mm2.log");
        return log_path;
    }

    fs::path
    get_atomic_dex_config_folder()
    {
        const auto fs_cfg_path = get_atomic_dex_data_folder() / "config";
        create_if_doesnt_exist(fs_cfg_path);
        return fs_cfg_path;
    }

    std::string
    minimal_trade_amount_str()
    {
        return "0.00777";
    }

    const t_float_50
    minimal_trade_amount()
    {
        return t_float_50(minimal_trade_amount_str());
    }

    fs::path
    get_atomic_dex_export_folder()
    {
        const auto fs_export_folder = get_atomic_dex_data_folder() / "exports";
        create_if_doesnt_exist(fs_export_folder);
        return fs_export_folder;
    }

    fs::path
    get_atomic_dex_current_export_recent_swaps_file()
    {
        return get_atomic_dex_export_folder() / ("swap-export.json");
    }

    std::string
    dex_sha256(const std::string& str)
    {
        QString res = QString(QCryptographicHash::hash((str.c_str()), QCryptographicHash::Keccak_256).toHex());
        return res.toStdString();
    }

    void
    to_eth_checksum(std::string& address)
    {
        address                = address.substr(2);
        auto hex_str           = dex_sha256(address);
        auto final_eth_address = std::string("0x");

        for (std::string::size_type i = 0; i < address.size(); i++)
        {
            std::string actual(1, hex_str[i]);
            try
            {
                auto value = std::stoi(actual, nullptr, 16);
                if (value >= 8)
                {
                    final_eth_address += toupper(address[i]);
                }
                else
                {
                    final_eth_address += address[i];
                }
            }
            catch (const std::invalid_argument& e)
            {
                final_eth_address += address[i];
            }
        }
        address = final_eth_address;
    }

    fs::path
    get_current_configs_path()
    {
        const auto fs_raw_mm2_shared_folder = get_atomic_dex_data_folder() / get_raw_version() / "configs";
        create_if_doesnt_exist(fs_raw_mm2_shared_folder);
        return fs_raw_mm2_shared_folder;
    }
    std::shared_ptr<spdlog::logger>
    register_logger()
    {
        //! Log Initialization
        std::string path = atomic_dex::utils::get_atomic_dex_current_log_file().string();
        spdlog::init_thread_pool(g_qsize_spdlog, g_spdlog_thread_count);
        auto tp            = spdlog::thread_pool();
        auto stdout_sink   = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        auto rotating_sink = std::make_shared<spdlog::sinks::rotating_file_sink_mt>(path.c_str(), g_spdlog_max_file_size, g_spdlog_max_file_rotation);

        std::vector<spdlog::sink_ptr> sinks{stdout_sink, rotating_sink};
        auto logger = std::make_shared<spdlog::async_logger>("log_mt", sinks.begin(), sinks.end(), tp, spdlog::async_overflow_policy::block);
        spdlog::register_logger(logger);
        spdlog::set_default_logger(logger);
        spdlog::set_level(spdlog::level::trace);
        spdlog::set_pattern("[%T] [%^%l%$] [%s:%#]: %v");
        SPDLOG_INFO("Logger successfully initialized");

        return logger;
    }
} // namespace atomic_dex::utils

namespace atomic_dex::utils
{
    bool
    my_json_sax::binary([[maybe_unused]] binary_t& val)
    {
        return true;
    }

    bool
    my_json_sax::null()
    {
        return true;
    }

    bool
    my_json_sax::boolean([[maybe_unused]] bool val)
    {
        return true;
    }

    bool
    my_json_sax::number_integer([[maybe_unused]] number_integer_t val)
    {
        return true;
    }

    bool
    my_json_sax::number_unsigned([[maybe_unused]] number_unsigned_t val)
    {
        return true;
    }

    bool
    my_json_sax::number_float([[maybe_unused]] number_float_t val, const string_t& s)
    {
        this->float_as_string = s;
        return true;
    }

    bool
    my_json_sax::string([[maybe_unused]] string_t& val)
    {
        return true;
    }

    bool
    my_json_sax::start_object([[maybe_unused]] std::size_t elements)
    {
        return true;
    }

    bool
    my_json_sax::key([[maybe_unused]] string_t& val)
    {
        return true;
    }

    bool
    my_json_sax::end_object()
    {
        return true;
    }

    bool
    my_json_sax::start_array([[maybe_unused]] std::size_t elements)
    {
        return true;
    }

    bool
    my_json_sax::end_array()
    {
        return true;
    }

    bool
    my_json_sax::parse_error(
        [[maybe_unused]] std::size_t position, [[maybe_unused]] const std::string& last_token, [[maybe_unused]] const nlohmann::detail::exception& ex)
    {
        return false;
    }

    void
    timed_waiter::interrupt()
    {
        auto l      = lock();
        interrupted = true;
        cv.notify_one();
    }

    template <class Rep, class Period>
    bool
    timed_waiter::wait_for(std::chrono::duration<Rep, Period> how_long) const
    {
        auto l = lock();
        return cv.wait_for(l, how_long, [&] { return interrupted; });
    }

    std::unique_lock<std::mutex>
    timed_waiter::lock() const
    {
        return std::unique_lock<std::mutex>(m, std::try_to_lock);
    }
} // namespace atomic_dex::utils
