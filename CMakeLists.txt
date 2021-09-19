cmake_minimum_required(VERSION 3.15)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(project.metadata)           ##> generate_dex_project_metafiles()
generate_dex_project_metafiles()

include(build_type)
include(compiler_prerequisites)
include(vcpkg_prerequisites)
include(qt_prerequisites)
include(cfg_hash)

project(${DEX_PROJECT_NAME} LANGUAGES CXX VERSION 0.5.1)
message(STATUS "${PROJECT_NAME} is version ${PROJECT_VERSION}")

include(cmake_default_options)
include(ipo_prerequisites)

##! Options
option(PREFER_BOOST_FILESYSTEM "Enable to use boost filesystem instead of std::filesystem" OFF)
option(WITH_HOTRELOAD "Enable to use qml Hot reload" OFF)

if (NOT WITH_HOTRELOAD)
    message(STATUS "Hot Reload is not active download SortFilterProxyModel")
    include(FetchContent)

    set(SFPM_REPOSITORY "https://github.com/OlivierLDff/SortFilterProxyModel.git" CACHE STRING "SortFilterProxyModel repository url")
    set(SFPM_TAG master CACHE STRING "SortFilterProxyModel git tag")

    FetchContent_Declare(
            SortFilterProxyModel
            GIT_REPOSITORY ${SFPM_REPOSITORY}
            GIT_TAG        ${SFPM_TAG}
            GIT_SHALLOW    1
    )

    set(SFPM_FOLDER_PREFIX "Dependencies" CACHE STRING "Prefix folder for all SortFilterProxyModel generated targets in generated project (only decorative)")
    FetchContent_MakeAvailable(SortFilterProxyModel)
endif()

##! Antara
include(antara)
##! Calling this macros provided by the sdk will if you are on Apple init the environment for this OS (std::filesystem).
init_antara_env()


##! We include the module from CMake for fetching dependencies
include(FetchContent)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(LINUX TRUE)
endif ()

if (UNIX AND NOT APPLE)
    message("Forcing stdlib C++")
    #set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++ -lc++abi")
    #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif ()

##! We fetch our dependencies
if (APPLE)
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.1.4270/mm2-3a3f159bf-Darwin-Release.zip)
elseif (UNIX AND NOT APPLE)
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.1.4270/mm2-3a3f159bf-Linux-Release.zip)
else ()
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.1.4270/mm2-3a3f159bf-Windows_NT-Release.zip)
endif ()

#FetchContent_Declare(qmaterial URL https://github.com/KomodoPlatform/Qaterial/archive/last-clang-working-2.zip)

FetchContent_Declare(
        qmaterial
        GIT_REPOSITORY https://github.com/KomodoPlatform/Qaterial.git
        GIT_TAG 53669824261ae07bc0e8c2abb4b55431f65b2055
)

FetchContent_Declare(jl777-coins
        URL https://github.com/KomodoPlatform/coins/archive/master.zip)

#FetchContent_Declare(adex-generics-coins
#        URL https://github.com/KomodoPlatform/atomicdex-desktop-generics/archive/main.zip)

FetchContent_MakeAvailable(mm2 jl777-coins qmaterial)

##! Configure our needs.
if (UNIX)
    configure_file(assets/config/${PROJECT_VERSION}-coins.json ${CMAKE_CURRENT_SOURCE_DIR}/assets/config/${PROJECT_VERSION}-coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2 ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/mm2 COPYONLY)
else ()
    configure_file(assets/config/${PROJECT_VERSION}-coins.json ${CMAKE_BINARY_DIR}/bin/assets/config/${PROJECT_VERSION}-coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2.exe ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/mm2.exe COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/msvcp140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/msvcp140.dll COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/msvcr100.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/msvcr100.dll COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/vcruntime140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/vcruntime140.dll COPYONLY)
endif ()

add_subdirectory(vendor/antara-gaming_sdk/modules)

##! Osx bundle icon
set(ICON)
configure_icon_osx(${CMAKE_CURRENT_SOURCE_DIR}/cmake/install/macos/dex-logo.icns ICON dex-logo.icns)
##! End antara

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

add_subdirectory(src)

# Adds Qaterial hot reload to main executable
if (WITH_HOTRELOAD)
    FetchContent_Declare(
            qaterial_hotreload
            GIT_REPOSITORY https://github.com/KomodoPlatform/QaterialHotReload
            GIT_TAG ecffec6bd01d9a13561689283bc2a6a927957f64
    )
    set(QATERIALHOTRELOAD_ENABLE_HOTRELOAD_APP OFF CACHE BOOL "")
    FetchContent_MakeAvailable(qaterial_hotreload)
    target_link_libraries(${PROJECT_NAME} PUBLIC Qaterial::HotReload)
    target_compile_definitions(${PROJECT_NAME} PUBLIC ATOMICDEX_HOT_RELOAD)
endif ()

add_library(antara_qrcode STATIC)
target_sources(antara_qrcode PRIVATE vendor/qrcode/QrCode.cpp)
target_include_directories(antara_qrcode PUBLIC vendor/qrcode)
target_link_libraries(antara_qrcode PUBLIC antara::default_settings)
