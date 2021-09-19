# Default project values
set(DEX_PROJECT_NAME "smartdex-desktop")
set(DEX_DISPLAY_NAME "SmartDEX")
set(DEX_COMPANY "SmartFi")
set(DEX_WEBSITE "https://smartfi.com/")
set(DEX_MAINTENANCE_TOOL_NAME "SmartDEX Maintenance Tool")
set(DEX_SUPPORT_PAGE "https://help.smartfi.com/hc/en-us")
set(DEX_DISCORD "https://discord.gg/yrYDtEnsfg")
set(DEX_TWITTER "https://twitter.com/smartfiportal")
set(DEX_PRIMARY_COIN "SFUSD") ## Main coin of the DEX, will enable it by default and will be the default left ticker for trading
set(DEX_SECOND_PRIMARY_COIN "BNB")  ## Second main coin of the DEX, will enable it by default and will be the default right ticker for trading
option(DISABLE_GEOBLOCKING "Enable to disable geoblocking (for dev purpose)" ON)
set(DEX_REPOSITORY_OWNER ${DEX_COMPANY})
set(DEX_REPOSITORY_NAME "atomicDEX-Desktop")
set(DEX_CHECKSUM_API_URL "https://komodo.live/static/checksum.json")
if (APPLE)
    set(DEX_APPDATA_FOLDER "SmartDEX")
else ()
    set(DEX_APPDATA_FOLDER "smartdex")
endif ()
message(STATUS "APPDATA folder is ${DEX_APPDATA_FOLDER}")

if (UNIX AND NOT APPLE)
    set(DEX_LINUX_APP_ID "dex.desktop")
endif ()

# Erases default project values with environment variables if they exist.
if (DEFINED ENV{DEX_PROJECT_NAME})
    set(DEX_PROJECT_NAME $ENV{DEX_PROJECT_NAME})
endif ()
if (DEFINED ENV{DEX_DISPLAY_NAME})
    set(DEX_DISPLAY_NAME $ENV{DEX_DISPLAY_NAME})
endif ()
if (DEFINED ENV{DEX_COMPANY})
    set(DEX_COMPANY $ENV{DEX_COMPANY})
endif ()
if (DEFINED ENV{DEX_WEBSITE})
    set(DEX_WEBSITE $ENV{DEX_WEBSITE})
endif ()

# Shows project metadata
message(STATUS "Project Metadata: ${DEX_PROJECT_NAME}.${DEX_DISPLAY_NAME}.${DEX_COMPANY}.${DEX_WEBSITE}")

# Generates files which need to be configured with custom variables from env/CMake.
macro(generate_dex_project_metafiles)
    # Configures installers
    if (APPLE)
        generate_macos_metafiles()
    elseif (WIN32)
        generate_windows_metafiles()
    else ()
        generate_linux_metafiles()
    endif ()

    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo-sidebar.png
            ${CMAKE_CURRENT_LIST_DIR}/atomic_defi_design/assets/images/dex-logo-sidebar.png COPYONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.png
            ${CMAKE_CURRENT_LIST_DIR}/atomic_defi_design/assets/images/logo/dex-logo.png COPYONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo-sidebar-dark.png
            ${CMAKE_CURRENT_LIST_DIR}/atomic_defi_design/assets/images/dex-logo-sidebar-dark.png COPYONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-tray-icon.png
            ${CMAKE_CURRENT_LIST_DIR}/atomic_defi_design/assets/images/dex-tray-icon.png COPYONLY)
endmacro()

macro(generate_macos_metafiles)
    set(DEX_APP_DIR "@ApplicationsDir@")
    set(DEX_TARGET_DIR "@TargetDir@")
    set(DEX_RUN_CMD "@TargetDir@/${DEX_PROJECT_NAME}.app/Contents/MacOS/${DEX_PROJECT_NAME}")

    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/config/config.xml.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/config/config.xml)
    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/meta/package.xml.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/meta/package.xml)
    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/meta/installscript.qs.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/meta/installscript.qs)

    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.icns ${CMAKE_CURRENT_LIST_DIR}/cmake/install/macos/dex-logo.icns COPYONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.icns ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/config/install_icon.icns COPYONLY)               # Configures MacOS logo for the installer
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.png ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/osx/config/install_icon.png COPYONLY)
endmacro()

macro(generate_windows_metafiles)
    set(DEX_TARGET_DIR "@TargetDir@")
    set(DEX_START_MENU_DIR "@StartMenuDir@")
    set(DEX_DESKTOP_DIR "@DesktopDir@")
    set(DEX_ICON_DIR "@TargetDir@/${DEX_PROJECT_NAME}.ico")
    set(DEX_MANIFEST_DESCRIPTION "${DEX_DISPLAY_NAME}, a desktop wallet application")
    set(DEX_INSTALL_TARGET_DIR_WIN64 "@ApplicationsDirX64@")

    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/config/config.xml.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/config/config.xml)
    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/meta/package.xml.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/meta/package.xml)
    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/meta/installscript.qs.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/meta/installscript.qs)
    configure_file(${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/dex.exe.manifest.in
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data/${DEX_PROJECT_NAME}.exe.manifest)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.ico
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data/${DEX_PROJECT_NAME}.ico
            COPYONLY)

    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.ico ${CMAKE_CURRENT_LIST_DIR}/cmake/install/windows/dex-logo.ico COPYONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.ico ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/config/install_icon.ico COPYONLY)             # Configures Windows logo for the installer
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.png ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/installer/windows/config/install_icon.png COPYONLY)
endmacro()

macro(generate_linux_metafiles)
    configure_file(${CMAKE_SOURCE_DIR}/cmake/install/linux/dex.appdata.xml.in
            ${CMAKE_SOURCE_DIR}/cmake/install/linux/dex.appdata.xml)
    configure_file(${CMAKE_SOURCE_DIR}/cmake/install/linux/dex.desktop.in
            ${CMAKE_SOURCE_DIR}/cmake/install/linux/dex.desktop)

    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo-64.png ${CMAKE_CURRENT_LIST_DIR}/cmake/install/linux/dex-logo-64.png COPYONLY)                                  # Configures x64 Linux logo
    configure_file(${CMAKE_CURRENT_LIST_DIR}/assets/logo/dex-logo.png ${CMAKE_CURRENT_LIST_DIR}/cmake/install/linux/dex-logo.png COPYONLY)
endmacro()