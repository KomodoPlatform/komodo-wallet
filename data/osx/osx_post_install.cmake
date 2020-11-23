message(STATUS "Hello post install ${CMAKE_SOURCE_DIR}")
get_filename_component(PROJECT_ROOT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
if (EXISTS ${PROJECT_ROOT_DIR}/build-Release)
    message(STATUS "from ci tools, readjusting")
    get_filename_component(PROJECT_ROOT_DIR ${PROJECT_ROOT_DIR} DIRECTORY)
endif ()

message(STATUS "PROJECT_ROOT_DIR -> ${PROJECT_ROOT_DIR}")
set(PROJECT_QML_DIR ${PROJECT_ROOT_DIR}/atomic_defi_design/qml)
message(STATUS "PROJECT_QML_DIR -> ${PROJECT_QML_DIR}")
set(TARGET_APP_PATH ${PROJECT_ROOT_DIR}/bundled/osx/)
set(PROJECT_APP_DIR atomicdex-desktop.app)
set(PROJECT_APP_PATH ${CMAKE_SOURCE_DIR}/bin/${PROJECT_APP_DIR})
if (EXISTS ${PROJECT_APP_PATH})
    message(STATUS "PROJECT_APP_PATH path is -> ${PROJECT_APP_PATH}")
else ()
    message(FATAL_ERROR "Didn't find PROJECT_APP_PATH")
endif ()


message(STATUS "VCPKG package manager enabled")

message(STATUS "Using QT tools from $HOME/QT")
set(MAC_DEPLOY_PATH $ENV{QT_ROOT}/clang_64/bin/macdeployqt)

if (EXISTS ${MAC_DEPLOY_PATH})
    message(STATUS "macdeployqt path is -> ${MAC_DEPLOY_PATH}")
else ()
    message(FATAL_ERROR "Didn't find macdeployqt")
endif ()

if (NOT EXISTS ${CMAKE_SOURCE_DIR}/bin/atomicdex-desktop.dmg)
    ##-------------------------------------------
    message(STATUS "Executing macdeployqt to fix dependencies")
    execute_process(COMMAND ${MAC_DEPLOY_PATH} ${PROJECT_APP_PATH} -qmldir=${PROJECT_QML_DIR} -always-overwrite
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE MACDEPLOYQT_RESULT
            OUTPUT_VARIABLE MACDEPLOYQT_OUTPUT
            ERROR_VARIABLE MACDEPLOYQT_ERROR)
    message(STATUS "Result -> ${MACDEPLOYQT_RESULT}")
    message(STATUS "Output -> ${MACDEPLOYQT_OUTPUT}")
    message(STATUS "Error -> ${MACDEPLOYQT_ERROR}")
    ##-------------------------------------------

    ##-------------------------------------------
    message(STATUS "Fixing QTWebengineProcess")
    set(QTWEBENGINE_BUNDLED_PATH ${PROJECT_APP_PATH}/Contents/Frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess)
    message(STATUS "Executing: [install_name_tool -add_rpath @executable_path/../../../../../../Frameworks ${QTWEBENGINE_BUNDLED_PATH}]")
    execute_process(COMMAND install_name_tool -add_rpath "@executable_path/../../../../../../Frameworks" "${QTWEBENGINE_BUNDLED_PATH}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE QTWEBENGINE_FIX_RESULT
            OUTPUT_VARIABLE QTWEBENGINE_FIX_OUTPUT
            ERROR_VARIABLE QTWEBENGINE_FIX_ERROR)

    message(STATUS "Result -> ${QTWEBENGINE_FIX_RESULT}")
    message(STATUS "Output -> ${QTWEBENGINE_FIX_OUTPUT}")
    message(STATUS "Error -> ${QTWEBENGINE_FIX_ERROR}")
    ##-------------------------------------------

    ##-------------------------------------------
    message(STATUS "Packaging the DMG")
    set(PACKAGER_PATH ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/dmg-packager/package.sh)
    if (EXISTS ${PACKAGER_PATH})
        message(STATUS "packager path is -> ${PACKAGER_PATH}")
    else ()
        message(FATAL_ERROR "Didn't find PACKAGER_PATH")
    endif ()

    execute_process(COMMAND ${PACKAGER_PATH} atomicdex-desktop atomicdex-desktop ${CMAKE_SOURCE_DIR}/bin/
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE PACKAGER_PATH_RESULT
            OUTPUT_VARIABLE PACKAGER_PATH_OUTPUT
            ERROR_VARIABLE PACKAGER_PATH_ERROR)

    message(STATUS "Result -> ${PACKAGER_PATH_RESULT}")
    message(STATUS "Output -> ${PACKAGER_PATH_OUTPUT}")
    message(STATUS "Error -> ${PACKAGER_PATH_ERROR}")
    ##-------------------------------------------
else()
    message(STATUS "dmg already generated - skipping")
endif ()

file(COPY ${CMAKE_SOURCE_DIR}/bin/atomicdex-desktop.dmg DESTINATION ${TARGET_APP_PATH})

get_filename_component(QT_ROOT_DIR  $ENV{QT_ROOT} DIRECTORY)
set(IFW_BINDIR ${QT_ROOT_DIR}/Tools/QtInstallerFramework/4.0/bin)
message(STATUS "IFW_BIN PATH IS ${IFW_BINDIR}")
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bin/atomicdex_desktop.7z)
    message(STATUS "Generating atomicdex_desktop.7z")
    execute_process(COMMAND ${IFW_BINDIR}/archivegen atomicdex_desktop.7z atomicdex-desktop.app
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)
else()
    message(STATUS "atomicdex_desktop.7z already created - skipping")
endif()

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/bin/atomicdex_desktop.7z DESTINATION ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/data)

execute_process(COMMAND ${IFW_BINDIR}/binarycreator -c ./config/config.xml -p ./packages/ atomicdex_desktop_installer
        WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)

file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/atomicdex_desktop_installer.app DESTINATION ${TARGET_APP_PATH})

execute_process(COMMAND ${IFW_BINDIR}/archivegen atomicdex_desktop_installer.7z atomicdex_desktop_installer.app
        WORKING_DIRECTORY ${TARGET_APP_PATH}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)