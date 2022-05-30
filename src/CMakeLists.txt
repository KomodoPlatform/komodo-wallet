include(DEX_NEW_LIB)
include(dex_generate_qrc)

# Core target
DEX_NEW_LIB(core INTERFACE
        INTERFACE_DEPS
            cpprestsdk::cpprest Qt::Core Qt::Quick Qt::Svg Qt::Charts Qt::WebEngine Qt::WebEngineCore Qt::WebEngineWidgets
            Qt::Widgets nlohmann_json::nlohmann_json antara_qrcode spdlog::spdlog antara::world
            unofficial-btc::bitcoin komodo-date::date komodo-taskflow::taskflow
            Boost::random Boost::filesystem komodo-sodium::sodium antara::app::net
        INTERFACE_DEFS
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG> $<$<PLATFORM_ID:Windows>:HAS_REMOTE_API>
            $<$<PLATFORM_ID:Windows>:AUTO_DOWNLOAD>
            $<$<PLATFORM_ID:Windows>:NOMINMAX>
            $<$<PLATFORM_ID:Windows>:SPDLOG_WCHAR_TO_UTF8_SUPPORT>
            _TURN_OFF_PLATFORM_STRING
            DEX_NAME="${DEX_DISPLAY_NAME}" DEX_WEBSITE_URL="${DEX_WEBSITE}"
            DEX_SUPPORT_URL="${DEX_SUPPORT_PAGE}" DEX_DISCORD_URL="${DEX_DISCORD}" DEX_TWITTER_URL="${DEX_TWITTER}"
            DEX_PRIMARY_COIN="${DEX_PRIMARY_COIN}" DEX_SECOND_PRIMARY_COIN="${DEX_SECOND_PRIMARY_COIN}" #DEX_COMMON_DATA_FOLDER="${DEX_COMMON_DATA_FOLDER}"
            DEX_PROJECT_NAME="${DEX_PROJECT_NAME}" DEX_COMPANY_NAME="${DEX_COMPANY_NAME}"
            DEX_REPOSITORY_OWNER="${DEX_REPOSITORY_OWNER}" DEX_REPOSITORY_NAME="${DEX_REPOSITORY_NAME}"
            DEX_CHECKSUM_API_URL="${DEX_CHECKSUM_API_URL}" DEX_APPDATA_FOLDER="${DEX_APPDATA_FOLDER}"
        INTERFACE_DEFS
            ENTT_API_EXPORT)
target_precompile_headers(${PROJECT_NAME}_core INTERFACE core/atomicdex/pch.hpp)

if (APPLE)
    set_source_files_properties(core/atomicdex/platform/osx/manager.mm PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
    macro(adex_add_framework fwname appname)
        find_library(FRAMEWORK_${fwname}
                NAMES ${fwname}
                PATHS ${CMAKE_OSX_SYSROOT}/System/Library
                PATH_SUFFIXES Frameworks
                NO_DEFAULT_PATH)
        if( ${FRAMEWORK_${fwname}} STREQUAL FRAMEWORK_${fwname}-NOTFOUND)
            MESSAGE(ERROR ": Framework ${fwname} not found")
        else()
            TARGET_LINK_LIBRARIES(${appname} INTERFACE ${FRAMEWORK_${fwname}})
            MESSAGE(STATUS "Framework ${fwname} found at ${FRAMEWORK_${fwname}}")
        endif()
    endmacro()
    adex_add_framework(Security ${PROJECT_NAME}_core)
endif ()
if (DISABLE_GEOBLOCKING)
    message(STATUS "Disabling Geoblocking for dev purpose")
    target_compile_definitions(${PROJECT_NAME}_core INTERFACE -DDISABLE_GEOBLOCKING)
endif ()
target_link_libraries(${PROJECT_NAME}_core INTERFACE SortFilterProxyModel)


# Translation files
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM TRUE)
set(TS_FILES
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_en.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_fr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_tr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_ru.ts)
set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages)
qt5_create_translation(QM_FILES
        ${PROJECT_SOURCE_DIR}/atomic_defi_design/Dex
        ${PROJECT_SOURCE_DIR}/src
        ${TS_FILES}
        OPTIONS -source-language en_US -no-obsolete)
message(STATUS "QM FILES -> ${QM_FILES}")
message(STATUS "TS FILES -> ${TS_FILES}")

set(qml_qrc)
set(assets_qrc)
set(imports_qrc ${CMAKE_SOURCE_DIR}/atomic_defi_design/imports/qml.qrc)
dex_generate_qrc(${CMAKE_SOURCE_DIR}/atomic_defi_design/Dex qml_qrc 
    PATH_PREFIX "Dex"
    FILES_TO_EXCLUDE ".gitignore;.DS_Store")
dex_generate_qrc(${CMAKE_SOURCE_DIR}/atomic_defi_design/assets assets_qrc 
    PATH_PREFIX "assets"
    FILES_TO_EXCLUDE ".gitignore;.DS_Store;CONTRIBUTING.txt;FONTLOG.txt;LICENCE-FAQ.txt;LICENCE.txt;README.txt;TRADEMARKS.txt;.ts")

# Main executable
add_executable(${PROJECT_NAME}
        MACOSX_BUNDLE
        ${ICON}

        app/app.cpp
        app/main.cpp

        ${CMAKE_SOURCE_DIR}/cmake/install/windows/dex.rc

        ##! QRC
        ${qml_qrc}
        ${assets_qrc}
        ${imports_qrc}

        ##! Linguistic
        ${QM_FILES}
        ${TS_FILES})
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}::core Qaterial)
target_compile_definitions(${PROJECT_NAME} PRIVATE ENTT_API_IMPORT)
set_target_properties(${PROJECT_NAME}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/")

#set_target_properties(${PROJECT_NAME} PROPERTIES UNITY_BUILD ON)
if (APPLE)
    set_property(SOURCE core/atomicdex/platform/osx/manager.mm PROPERTY SKIP_UNITY_BUILD_INCLUSION ON)
endif ()

# Testing executable
add_executable(${PROJECT_NAME}_tests MACOSX_BUNDLE ${ICON}
        tests/atomic.dex.tests.cpp
        tests/atomic.dex.wallet.config.tests.cpp
        tests/atomic.dex.provider.cex.prices.tests.cpp
        tests/atomic.dex.qt.utilities.tests.cpp

        tests/config/coins.cfg.tests.cpp
        ##! API
        tests/api/coingecko/coingecko.tests.cpp
        tests/api/komodo_prices/komodo.prices.tests.cpp
        tests/api/mm2/mm2.rpc.trade.preimage.tests.cpp
        tests/api/mm2/mm2.fraction.tests.cpp
        #tests/api/github/github.api.tests.cpp
        #tests/api/checksum/checksum.api.tests.cpp

        ##! Utilities
        tests/utilities/qt.utilities.tests.cpp
        tests/utilities/global.utilities.tests.cpp

        ##! Managers
        tests/managers/addressbook.manager.tests.cpp

        ##! Models
        tests/models/qt.addressbook.contact.model.tests.cpp

        tests/atomic.dex.provider.cex.prices.api.tests.cpp)
target_link_libraries(${PROJECT_NAME}_tests
        PUBLIC
        ${PROJECT_NAME}::core
        doctest::doctest)
set_target_properties(${PROJECT_NAME}_tests
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/")
set_target_properties(${PROJECT_NAME}_tests PROPERTIES UNITY_BUILD ON)

# Main executable installation related
if (LINUX)
    get_target_property(exe_runtime_directory_at ${PROJECT_NAME} RUNTIME_OUTPUT_DIRECTORY)
    set(output_dir_at "${exe_runtime_directory_at}/AntaraAtomicDexAppDir")

    magic_game_app_image_generation("${CMAKE_SOURCE_DIR}/cmake/install/linux"
            "dex.desktop"
            "dex.appdata.xml"
            "dex-logo-64.png"
            ${PROJECT_NAME}
            AntaraAtomicDexAppDir
            ${CMAKE_SOURCE_DIR}/assets)

    magic_game_app_image_generation("${CMAKE_SOURCE_DIR}/cmake/install/linux"
            "dex.desktop"
            "dex.appdata.xml"
            "dex-logo-64.png"
            ${PROJECT_NAME}_tests
            AntaraAtomicDexTestsAppDir
            ${CMAKE_SOURCE_DIR}/assets)

    set(from_dir "${CMAKE_SOURCE_DIR}/cmake/install/linux")
    set(desktop_file "dex.desktop")
    set(appdata_file "dex.appdata.xml")
    set(app_icon "dex-logo-64.png")
    message(STATUS "${output_dir_at}")
    configure_file(${from_dir}/${desktop_file} ${output_dir_at}/usr/share/applications/${desktop_file} COPYONLY)
    configure_file(${from_dir}/${appdata_file} ${output_dir_at}/usr/share/metainfo/${appdata_file} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/hicolor/64x64/apps/${app_icon} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/default/64x64/apps/${app_icon} COPYONLY)
    include(${CMAKE_SOURCE_DIR}/cmake/install/linux/dex_install.cmake)
endif ()

if (WIN32)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    configure_file(${CMAKE_SOURCE_DIR}/wally/wally.dll ${CMAKE_BINARY_DIR}/bin/ COPYONLY)
    if (CMAKE_BUILD_TYPE MATCHES Release)
        message(STATUS "disabling console")
        target_compile_definitions(${PROJECT_NAME} PRIVATE WINDOWS_RELEASE_MAIN)
        target_compile_options(${PROJECT_NAME} PRIVATE -Wno-deprecated-declarations)
        target_link_options(${PROJECT_NAME} PUBLIC --for-linker -subsystem:windows)
    endif ()
    set(WINDEPLOYQT_PATH "")
    if (CONAN_ENABLED)
        set(WINDEPLOYQT_PATH ${CONAN_QT_ROOT}/bin/windeployqt.exe)
    else ()
        set(WINDEPLOYQT_PATH $ENV{QT_INSTALL_CMAKE_PATH}/bin/windeployqt.exe)
    endif ()

    if (EXISTS ${WINDEPLOYQT_PATH})
        message(STATUS "windeployqt path is -> ${WINDEPLOYQT_PATH}")
    else ()
        message(FATAL_ERROR "Didn't find windeployqt ${WINDEPLOYQT_PATH}")
    endif ()
    add_custom_command(TARGET ${PROJECT_NAME} PRE_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/windows_misc $<TARGET_FILE_DIR:${PROJECT_NAME}>)
    message(STATUS "${WINDEPLOYQT_PATH} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.exe --qmldir ${CMAKE_SOURCE_DIR}/atomic_defi_design/Dex")
    add_custom_command(TARGET ${PROJECT_NAME}
            POST_BUILD
            COMMAND ${WINDEPLOYQT_PATH} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.exe --qmldir ${CMAKE_SOURCE_DIR}/atomic_defi_design/Dex
            )
    include(${CMAKE_SOURCE_DIR}/cmake/install/windows/dex_install.cmake)

    # Configures OpenSSL
    set(DEX_OPENSSL_FOLDER ${CMAKE_SOURCE_DIR}/vendor/OpenSSL/Win_x64)
    configure_file(${DEX_OPENSSL_FOLDER}/libcrypto-1_1-x64.dll ${CMAKE_BINARY_DIR}/bin/ COPYONLY)
    configure_file(${DEX_OPENSSL_FOLDER}/libssl-1_1-x64.dll ${CMAKE_BINARY_DIR}/bin/ COPYONLY)
endif ()

if (APPLE)
    file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.app/Contents/Resources)
    file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}_tests.app/Contents/Resources)
    include(${CMAKE_SOURCE_DIR}/cmake/install/macos/dex_install.cmake)
endif ()
