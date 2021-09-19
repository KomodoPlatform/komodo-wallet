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

//! PCH Headers
#include "atomicdex/pch.hpp"

//! C Headers
#include <csignal>

//! Qt
#include <QApplication>
#include <QDebug>
#include <QDesktopWidget>
#include <QQmlApplicationEngine>
#include <QScreen>
#include <QSettings>
#include <QWindow>
#include <QtGlobal>
#include <QtQml>
#include <QFontDatabase>
#include <QtWebEngine>

//! Qaterial
#include <Qaterial/Qaterial.hpp>
#if defined(ATOMICDEX_HOT_RELOAD)
#    include <Qaterial/HotReload/HotReload.hpp>
#    include <SortFilterProxyModel/SortFilterProxyModel.hpp>
#endif


//! Deps
#include <QSslSocket>
#include <sodium/core.h>
#include <wally.hpp>

#if defined(linux) || defined(__APPLE__)
#    define BOOST_STACKTRACE_USE_ADDR2LINE
#    if defined(__APPLE__)
#        define _GNU_SOURCE
#    endif
#    include <boost/stacktrace.hpp>
#endif

//! Project Headers
#include "app.hpp"
#include "atomicdex/constants/qt.wallet.enums.hpp"
#include "atomicdex/models/qt.portfolio.model.hpp"
#include "atomicdex/utilities/kill.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

#include "atomicdex/utilities/log.prerequisites.hpp"

#ifdef __APPLE__
#    include "atomicdex/platform/osx/manager.hpp"
#    include <sys/sysctl.h>
#endif

#if defined(ATOMICDEX_HOT_RELOAD)
void
installLoggers()
{
    qInstallMessageHandler(&qaterial::HotReload::log);
}
#endif

static void
qt_message_handler(QtMsgType type, [[maybe_unused]] const QMessageLogContext& context, const QString& msg)
{
    const auto localMsg = msg.toLocal8Bit();
    switch (type)
    {
    case QtDebugMsg:
        SPDLOG_DEBUG("{}", localMsg.constData());
        break;
    case QtInfoMsg:
        SPDLOG_INFO("{}", localMsg.constData());
        break;
    case QtWarningMsg:
        SPDLOG_WARN("{}", localMsg.constData());
        break;
    case QtCriticalMsg:
        SPDLOG_ERROR("{}", localMsg.constData());
        break;
    case QtFatalMsg:
        SPDLOG_ERROR("{}", localMsg.constData());
        abort();
    }
}

static void
signal_handler(int signal)
{
    SPDLOG_ERROR("sigabort received, cleaning mm2");
    atomic_dex::kill_executable("mm2");
#if defined(linux) || defined(__APPLE__)
    boost::stacktrace::safe_dump_to("./backtrace.dump");
    std::ifstream                 ifs("./backtrace.dump");
    boost::stacktrace::stacktrace st = boost::stacktrace::stacktrace::from_dump(ifs);
    SPDLOG_ERROR("stacktrace: {}", boost::stacktrace::to_string(st));
#endif
    std::exit(signal);
}

static void
connect_signals_handler()
{
    SPDLOG_INFO("connecting signal SIGABRT to the signal handler");
#if defined(linux) || defined(__APPLE__)
    if (fs::exists("./backtrace.dump"))
    {
        // there is a backtrace
        std::ifstream ifs("./backtrace.dump");

        boost::stacktrace::stacktrace st = boost::stacktrace::stacktrace::from_dump(ifs);
        std::cout << "Previous run crashed:\n" << st << std::endl;

        // cleaning up
        ifs.close();
        fs::remove("./backtrace.dump");
    }
#endif
    std::signal(SIGABRT, &signal_handler);
    std::signal(SIGSEGV, &signal_handler);
    std::signal(SIGTERM, &signal_handler);
}

static void
init_wally()
{
    [[maybe_unused]] auto wally_res = wally_init(0);
    assert(wally_res == WALLY_OK);
    SPDLOG_INFO("wally successfully initialized");
}

static void
init_sodium()
{
    //! Sodium Initialization
    [[maybe_unused]] auto sodium_return_value = sodium_init();
    assert(sodium_return_value == 0); //< This is not executed when build = Release
    SPDLOG_INFO("libsodium successfully initialized");
}

static void
clean_previous_run()
{
    SPDLOG_INFO("cleaning previous mm2 instance");
    atomic_dex::kill_executable("mm2");
}

static void
init_logging()
{
    auto logger = atomic_dex::utils::register_logger();
    if (spdlog::get("log_mt") == nullptr)
    {
        spdlog::register_logger(logger);
        spdlog::set_default_logger(logger);
        spdlog::set_level(spdlog::level::trace);
        spdlog::set_pattern("[%T] [%^%l%$] [%s:%#] [%t]: %v");
    }
}

static void
init_dpi()
{
    SPDLOG_INFO("initializing high dpi support");
    bool should_floor = false;
#if defined(_WIN32) || defined(WIN32) || defined(__linux__)
    {
        int          ac = 0;
        QApplication tmp(ac, nullptr);
        double       min_window_size = 800.0;
        auto         screens         = tmp.screens();
        for (auto&& cur_screen: screens)
        {
            SPDLOG_DEBUG("physical dpi: {}", cur_screen->physicalDotsPerInch());
            SPDLOG_DEBUG("logical dpi: {}", cur_screen->logicalDotsPerInch());
            double scale = cur_screen->logicalDotsPerInch() / 96.0;
            SPDLOG_DEBUG("scale: {}", scale);

            double height = cur_screen->availableSize().height();
            SPDLOG_DEBUG("height: {}", height);
            if (scale * min_window_size > height)
            {
                should_floor = true;
                SPDLOG_DEBUG("should floor");
            }
        }
    }
#endif
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        should_floor ? Qt::HighDpiScaleFactorRoundingPolicy::Floor : Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    QGuiApplication::setAttribute(should_floor ? Qt::AA_DisableHighDpiScaling : Qt::AA_EnableHighDpiScaling);
    SPDLOG_INFO("dpi settings finished");
}

static void
clean_wally()
{
    [[maybe_unused]] auto wallet_exit_res = wally_cleanup(0);
    assert(wallet_exit_res == WALLY_OK);
    SPDLOG_INFO("wally successfully cleaned");
}

static void
init_timezone_db()
{
    SPDLOG_INFO("Init timezone db");
#if defined(_WIN32) || defined(WIN32)
    try
    {
        using namespace std::string_literals;
        auto install_db_tz_path = std::make_unique<fs::path>(ag::core::assets_real_path() / "tools" / "timezone" / "tzdata");
        date::set_install(install_db_tz_path->string());
        SPDLOG_INFO("Timezone db successfully initialized");
    }
    catch (const std::exception& error)
    {
        SPDLOG_ERROR("Couldn't initialize timezone DB, you will get UTC time instead");
    }
#endif
}

static void
setup_default_themes()
{
    const fs::path theme_path = atomic_dex::utils::get_themes_path();
    fs::path       original_theme_path{ag::core::assets_real_path() / "themes"};
    fs_error_code  ec;

    LOG_PATH_CMP("Checking for setup default themes - theme_path: {} original_theme_path: {}", theme_path, original_theme_path);
    LOG_PATH("copying default themes into directory: {}", theme_path);
    //fs::remove_all(theme_path);
    fs::copy(original_theme_path, theme_path,  fs::copy_options::recursive | fs::copy_options::overwrite_existing, ec);
    if (ec)
    {
        SPDLOG_ERROR("fs::error: {}", ec.message());
    }

    ec.clear();

    //! Logo
    {
        const fs::path logo_path = atomic_dex::utils::get_logo_path();
        fs::path       original_logo_path{ag::core::assets_real_path() / "logo"};

        LOG_PATH_CMP("Checking for setup default logo - logo_path: {} original_logo_path: {}", logo_path, original_logo_path);
        //fs::remove_all(logo_path);
        fs::copy(original_logo_path, logo_path, fs::copy_options::recursive | fs::copy_options::overwrite_existing, ec);
        LOG_PATH("copying default logo into directory: {}", logo_path);
        if (ec)
        {
            SPDLOG_ERROR("fs::error: {}", ec.message());
        }
    }
}

static void
check_settings_reconfiguration(const fs::path& path)
{
    SPDLOG_INFO("Checking for settings ini reconfiguration");
    using namespace atomic_dex::utils;
    using namespace atomic_dex;
    const fs::path previous_path = get_atomic_dex_data_folder() / get_precedent_raw_version() / "configs" / "cfg.ini";
    if (fs::exists(previous_path) && !fs::exists(path))
    {
        fs_error_code ec;
        LOG_PATH_CMP("Copying {} to {}", previous_path, path);
        fs::copy(previous_path, path, ec);
        if (ec)
        {
            SPDLOG_ERROR("error occured when copying previous cfg.ini : {}", ec.message());
        }

        SPDLOG_INFO("Deleting previous cfg after reconfiguring it");
        ec.clear();
        fs::remove_all(get_atomic_dex_data_folder() / get_precedent_raw_version(), ec);
        if (ec)
        {
            SPDLOG_ERROR("error occured when deleting previous path");
        }
    }
    SPDLOG_INFO("reconfiguration for settings finished");
}

static void
handle_settings(QSettings& settings)
{
    auto create_settings_functor = [&settings](QString settings_name, QVariant value)
    {
        if (!settings.contains(settings_name))
        {
            SPDLOG_INFO("Settings {} doesn't exist yet for this application, creating now", settings_name.toStdString());
            settings.setValue(settings_name, value);
        }
        else
        {
            SPDLOG_INFO("Settings {} already exist - skipping", settings_name.toStdString());
        }
    };
    SPDLOG_INFO("file name settings: {}", settings.fileName().toStdString());
    create_settings_functor("CurrentTheme", QString("Dark.json"));

#if defined(_WIN32) || defined(WIN32)
    create_settings_functor("ThemePath", QString::fromStdWString(atomic_dex::utils::get_themes_path().wstring()));
#else
    create_settings_functor("ThemePath", QString::fromStdString(atomic_dex::utils::get_themes_path().string()));
#endif
    create_settings_functor("AutomaticUpdateOrderBot", QVariant(false));
    create_settings_functor("WalletChartsCategory", qint32(WalletChartsCategories::OneMonth));
    create_settings_functor("AvailableLang", QStringList{"en", "fr", "tr", "ru"});
    create_settings_functor("CurrentLang", QString("en"));
    create_settings_functor("2FA", 0);
    create_settings_functor("MaximumNbCoinsEnabled", 50);
    create_settings_functor("DefaultTradingMode", TradingMode::Simple);
    create_settings_functor("FontMode", QQuickWindow::TextRenderType::QtTextRendering);
}

inline int
run_app(int argc, char** argv)
{
#if !defined(ATOMICDEX_HOT_RELOAD)
    SPDLOG_INFO("Installing qt_message_handler");
    qInstallMessageHandler(&qt_message_handler);
#endif
    SPDLOG_INFO(
        "SSL: {} {} {}", QSslSocket::supportsSsl(), QSslSocket::sslLibraryBuildVersionString().toStdString(),
        QSslSocket::sslLibraryVersionString().toStdString());

#if defined(Q_OS_MACOS)
    // https://bugreports.qt.io/browse/QTBUG-89379
    qputenv("QT_ENABLE_GLYPH_CACHE_WORKAROUND", "1");
    qputenv("QML_USE_GLYPHCACHE_WORKAROUND", "1");

    fs::path old_path    = fs::path(std::getenv("HOME")) / ".atomic_qt";
    fs::path target_path = atomic_dex::utils::get_atomic_dex_data_folder();
    SPDLOG_INFO("{} exists -> {}", old_path.string(), fs::exists(old_path));
    SPDLOG_INFO("{} exists -> {}", target_path.string(), fs::exists(target_path));
    if (fs::exists(old_path) && !fs::exists(target_path))
    {
        SPDLOG_INFO("Renaming: {} to {}", old_path.string(), target_path.string());
        QDir dir;
        if (!dir.rename(QString::fromStdString(old_path.string()), QString::fromStdString(target_path.string())))
        {
            SPDLOG_ERROR("Cannot rename directory {} to {} - aborting", old_path.string(), target_path.string());
            exit(1);
        }
    }
#endif
    init_logging();
    connect_signals_handler();
    init_timezone_db();
    init_wally();
    init_sodium();
    clean_previous_run();
    setup_default_themes();
    fs::path settings_path = (atomic_dex::utils::get_current_configs_path() / "cfg.ini");
    check_settings_reconfiguration(settings_path);
    init_dpi();

    //! App declaration
    atomic_dex::application atomic_app;
    QSettings&              settings = atomic_app.get_registry().ctx<QSettings>();
    handle_settings(settings);
    atomic_app.post_handle_settings();

    int res = 0;

    //! Qt utilities declaration.
    atomic_dex::qt_utilities qt_utilities;

    //! QT
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QtWebEngine::initialize();
    std::shared_ptr<QApplication> app = std::make_shared<QApplication>(argc, argv);

    app->setWindowIcon(QIcon(":/atomic_defi_design/assets/images/logo/dex-logo.png"));
    app->setOrganizationName("KomodoPlatform");
    app->setOrganizationDomain("com");
    QQmlApplicationEngine engine;

    atomic_app.set_qt_app(app, &engine);
    SPDLOG_INFO("post set_qt_app");

    //! QT QML
    engine.addImportPath("qrc:///");
    qRegisterMetaType<MarketMode>("MarketMode");
    qmlRegisterUncreatableType<atomic_dex::MarketModeGadget>("AtomicDEX.MarketMode", 1, 0, "MarketMode", "Not creatable as it is an enum type");
    qRegisterMetaType<TradingMode>("TradingMode");
    qmlRegisterUncreatableType<atomic_dex::TradingModeGadget>("AtomicDEX.TradingMode", 1, 0, "TradingMode", "Not creatable as it is an enum type");
    qRegisterMetaType<TradingMode>("WalletChartsCategories");
    qmlRegisterUncreatableType<atomic_dex::WalletChartsCategoriesGadget>(
        "AtomicDEX.WalletChartsCategories", 1, 0, "WalletChartsCategories", "Not creatable as it is an enum type");
    qRegisterMetaType<TradingError>("TradingError");
    qRegisterMetaType<SelectedOrderStatus>("SelectedOrderStatus");
    qmlRegisterUncreatableType<atomic_dex::SelectedOrderGadget>(
        "AtomicDEX.SelectedOrderStatus", 1, 0, "SelectedOrderStatus", "Not creatable as it is an enum type");
    qmlRegisterUncreatableType<atomic_dex::TradingErrorGadget>("AtomicDEX.TradingError", 1, 0, "TradingError", "Not creatable as it is an enum type");
    qRegisterMetaType<CoinType>("CoinType");
    qmlRegisterUncreatableType<atomic_dex::CoinTypeGadget>("AtomicDEX.CoinType", 1, 0, "CoinType", "Not creatable as it is an enum type");
    SPDLOG_INFO("QML Enum created");

    const QFont fixedFont = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    engine.rootContext()->setContextProperty("atomic_fixed_font", fixedFont);
    engine.rootContext()->setContextProperty("atomic_app", &atomic_app);
    engine.rootContext()->setContextProperty("atomic_app_name", QString{DEX_NAME});
    engine.rootContext()->setContextProperty("atomic_app_website_url", QString{DEX_WEBSITE_URL});
    engine.rootContext()->setContextProperty("atomic_app_support_url", QString{DEX_SUPPORT_URL});
    engine.rootContext()->setContextProperty("atomic_app_discord_url", QString{DEX_DISCORD_URL});
    engine.rootContext()->setContextProperty("atomic_app_twitter_url", QString{DEX_TWITTER_URL});
    engine.rootContext()->setContextProperty("atomic_app_primary_coin", QString{DEX_PRIMARY_COIN});
    engine.rootContext()->setContextProperty("atomic_app_secondary_coin", QString{DEX_SECOND_PRIMARY_COIN});
    engine.rootContext()->setContextProperty("atomic_qt_utilities", &qt_utilities);
    #if defined(_WIN32) || defined(WIN32)
        engine.rootContext()->setContextProperty("atomic_cfg_file", QString::fromStdWString((atomic_dex::utils::get_current_configs_path() / "cfg.ini").wstring()));
        engine.rootContext()->setContextProperty("atomic_logo_path", QString::fromStdWString((atomic_dex::utils::get_atomic_dex_data_folder() / "logo").wstring()));
    #else
        engine.rootContext()->setContextProperty("atomic_cfg_file", QString::fromStdString((atomic_dex::utils::get_current_configs_path() / "cfg.ini").string()));
        engine.rootContext()->setContextProperty("atomic_logo_path", QString::fromStdString((atomic_dex::utils::get_atomic_dex_data_folder() / "logo").string()));
    #endif

    engine.rootContext()->setContextProperty("atomic_settings", &settings);
    engine.rootContext()->setContextProperty("dex_current_version", QString::fromStdString(atomic_dex::get_version()));
    engine.rootContext()->setContextProperty("qtversion", QString(qVersion()));
    SPDLOG_INFO("QML context properties created");
    // Load Qaterial.

    qaterial::loadQmlResources(false);
    qaterial::registerQmlTypes("Qaterial", 1, 0);
    // QQuickStyle::setStyle(QStringLiteral("Qaterial"));
    //  SPDLOG_INFO("{}",  QQuickStyle::ge))
    SPDLOG_INFO("Qaterial type created");

    engine.addImportPath("qrc:/atomic_defi_design/imports");
    engine.addImportPath("qrc:/atomic_defi_design/Constants");
    qmlRegisterSingletonType(QUrl("qrc:/atomic_defi_design/qml/Constants/DexTheme.qml"), "App", 1, 0, "DexTheme");
    qmlRegisterSingletonType(QUrl("qrc:/atomic_defi_design/qml/Constants/DexTypo.qml"), "App", 1, 0, "DexTypo");
    qmlRegisterSingletonType(QUrl("qrc:/atomic_defi_design/qml/Constants/General.qml"), "App", 1, 0, "General");
    qmlRegisterSingletonType(QUrl("qrc:/atomic_defi_design/qml/Constants/Style.qml"), "App", 1, 0, "Style");
    qmlRegisterSingletonType(QUrl("qrc:/atomic_defi_design/qml/Constants/API.qml"), "App", 1, 0, "API");
    qRegisterMetaType<t_portfolio_roles>("PortfolioRoles");
    SPDLOG_INFO("QML singleton created");

#if defined(ATOMICDEX_HOT_RELOAD)
    engine.rootContext()->setContextProperty("debug_bar", QVariant(true));
    engine.addImportPath("qrc:/");
    installLoggers();
    qaterial::registerQmlTypes();
    qaterial::HotReload::registerSingleton();
    qqsfpm::registerQmlTypes();
    engine.load(QUrl("qrc:/Qaterial/HotReload/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;
#else
    SPDLOG_INFO("Load qml engine");
    engine.rootContext()->setContextProperty("debug_bar", QVariant(false));
    const QUrl url(QStringLiteral("qrc:/atomic_defi_design/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, app.get(),
        [url](QObject* obj, const QUrl& objUrl)
        {
            if ((obj == nullptr) && url == objUrl)
            {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);

    engine.load(url);
    SPDLOG_INFO("qml engine successfully loaded");
#endif


#ifdef __APPLE__
#    if !defined(ATOMICDEX_HOT_RELOAD)
    QWindowList windows = QGuiApplication::allWindows();
    QWindow*    win     = windows.first();
    atomic_dex::mac_window_setup(win->winId());
#    endif
#endif
    atomic_app.launch();

    res = app->exec();

    clean_wally();
    return res;
}
