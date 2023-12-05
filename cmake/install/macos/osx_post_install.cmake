include(${CMAKE_CURRENT_LIST_DIR}/../../project.metadata.cmake)

message(STATUS "OSX POST INSTALL CMAKE")
message(STATUS "PROJECT_ROOT_DIR (before readjusting) -> ${PROJECT_ROOT_DIR}")

get_filename_component(PROJECT_ROOT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
if (EXISTS ${PROJECT_ROOT_DIR}/build-Release OR EXISTS ${PROJECT_ROOT_DIR}/build-Debug)
    message(STATUS "from ci tools, readjusting")
    get_filename_component(PROJECT_ROOT_DIR ${PROJECT_ROOT_DIR} DIRECTORY)
endif ()

set(BIN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(TARGET_APP_PATH ${PROJECT_ROOT_DIR}/bundled/osx/)
set(PROJECT_APP_DIR ${DEX_PROJECT_NAME}.app)
set(PROJECT_APP_PATH ${BIN_DIR}/${PROJECT_APP_DIR})
set(PROJECT_QML_DIR ${PROJECT_ROOT_DIR}/atomic_defi_design/Dex)
set(MAC_DEPLOY_PATH $ENV{QT_ROOT}/clang_64/bin/macdeployqt)

message(STATUS "VCPKG package manager enabled")
message(STATUS "QT_ROOT -> ${QT_ROOT}")
message(STATUS "BIN_DIR -> ${BIN_DIR}")
message(STATUS "TARGET_APP_PATH -> ${TARGET_APP_PATH}")
message(STATUS "PROJECT_APP_DIR -> ${PROJECT_APP_DIR}")
message(STATUS "PROJECT_QML_DIR -> ${PROJECT_QML_DIR}")
message(STATUS "PROJECT_ROOT_DIR (after readjusting) -> ${PROJECT_ROOT_DIR}")

if (EXISTS ${PROJECT_APP_PATH})
    message(STATUS "PROJECT_APP_PATH -> ${PROJECT_APP_PATH}")
else ()
    message(FATAL_ERROR "Didn't find PROJECT_APP_PATH")
endif ()

if (EXISTS ${MAC_DEPLOY_PATH})
    message(STATUS "MAC_DEPLOY_PATH -> ${MAC_DEPLOY_PATH}")
else ()
    message(FATAL_ERROR "Didn't find MAC_DEPLOY_PATH")
endif ()

message(STATUS "CREATING DMG")
if (NOT EXISTS ${CMAKE_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.dmg)
    message(STATUS "${MAC_DEPLOY_PATH} ${PROJECT_APP_PATH} -qmldir=${PROJECT_QML_DIR} -always-overwrite -sign-for-notarization=$ENV{MAC_SIGN_IDENTITY}  -verbose=3")
    execute_process(
            COMMAND
            ${MAC_DEPLOY_PATH} ${PROJECT_APP_PATH} -qmldir=${PROJECT_QML_DIR} -always-overwrite -codesign=$ENV{MAC_SIGN_IDENTITY} -timestamp -verbose=1
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE
            )
    message(STATUS "Fixing QTWebengineProcess")
    set(QTWEBENGINE_BUNDLED_PATH ${PROJECT_APP_PATH}/Contents/Frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess)
    message(STATUS "Executing: [install_name_tool -add_rpath @executable_path/../../../../../../Frameworks ${QTWEBENGINE_BUNDLED_PATH}]")
    execute_process(COMMAND install_name_tool -add_rpath "@executable_path/../../../../../../Frameworks" "${QTWEBENGINE_BUNDLED_PATH}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    execute_process(COMMAND codesign --deep --force -v -s "$ENV{MAC_SIGN_IDENTITY}" -o runtime --timestamp ${PROJECT_APP_PATH}/Contents/Resources/assets/tools/mm2/${DEX_API}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    execute_process(COMMAND codesign --deep --force -v -s "$ENV{MAC_SIGN_IDENTITY}" -o runtime --timestamp ${PROJECT_APP_PATH}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    message(STATUS "Fixing QtWebEngineProcess signature codesign --force --verify --verbose --sign \"$ENV{MAC_SIGN_IDENTITY}\" --entitlements ${PROJECT_ROOT_DIR}/cmake/install/macos/QtWebEngineProcess.entitlements --options runtime --timestamp ${PROJECT_APP_PATH}/Contents/Frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess")
    execute_process(COMMAND codesign --force --verify --verbose --sign "$ENV{MAC_SIGN_IDENTITY}" --entitlements ${PROJECT_ROOT_DIR}/cmake/install/macos/QtWebEngineProcess.entitlements --options runtime --timestamp ${PROJECT_APP_PATH}/Contents/Frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    message(STATUS "Packaging the DMG")
    set(PACKAGER_PATH ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/dmg-packager/package.sh)
    if (EXISTS ${PACKAGER_PATH})
        message(STATUS "packager path is -> ${PACKAGER_PATH}")
    else ()
        message(FATAL_ERROR "Didn't find PACKAGER_PATH")
    endif ()

    execute_process(COMMAND ${PACKAGER_PATH} ${DEX_PROJECT_NAME} ${DEX_PROJECT_NAME} ${CMAKE_SOURCE_DIR}/bin/
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    execute_process(COMMAND codesign --deep --force -v -s "$ENV{MAC_SIGN_IDENTITY}" -o runtime --timestamp ${CMAKE_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.dmg
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)

    execute_process(COMMAND ${PROJECT_ROOT_DIR}/cmake/install/macos/macos_notarize.sh --asc-public-id=$ENV{ASC_PUBLIC_ID} --app-specific-password=$ENV{APPLE_ATOMICDEX_PASSWORD} --apple-id=$ENV{APPLE_ID} --primary-bundle-id=com.komodoplatform.atomicdex --target-binary=${CMAKE_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.dmg
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)
else()
    message(STATUS "dmg already generated - skipping")
endif ()

file(COPY ${CMAKE_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.dmg DESTINATION ${TARGET_APP_PATH})

get_filename_component(QT_ROOT_DIR $ENV{QT_ROOT} DIRECTORY)
set(IFW_ROOT ${QT_ROOT_DIR}/Tools/QtInstallerFramework)
message(STATUS "IFW_ROOT PATH IS ${IFW_ROOT}")
execute_process(COMMAND ls ${IFW_ROOT})

# Find all subdirectories
file(GLOB subdirs "${IFW_ROOT}/*")
# Initialize variables to track the highest version and folder
set(IFW_VERSION "")
# Loop through the subdirectories
foreach(subdir ${subdirs})
    get_filename_component(folder_name ${subdir} NAME)
	message(STATUS "scanning: ${subdir} [${folder_name}]")
    # Use string manipulation to extract version from folder name
    string(REGEX MATCH "([0-9]+\\.[0-9]+\\.[0-9]+)" version ${folder_name})
    # Check if the extracted version is higher than the current highest
	# TODO: For some reason this var fails to populate in windows
    if(version STREQUAL "")
        continue()
    elseif(version STRGREATER IFW_VERSION)
        set(IFW_VERSION ${version})
    endif()
endforeach()
# Fallback to last scanned subfolder if variable empty. Usually there is only one folder.
if(version STREQUAL "")
	set(IFW_VERSION ${folder_name})
endif()

message(STATUS "===========================================")
message(STATUS "Creating Installer")
set(IFW_BINDIR ${IFW_ROOT}/${IFW_VERSION}/bin)
message(STATUS ">>>> IFW_BIN PATH IS ${IFW_BINDIR}")
execute_process(COMMAND ls "${IFW_BINDIR}")
message(STATUS ">>>> IFW_BIN PATH IS ${PROJECT_APP_PATH}")
execute_process(COMMAND ls "${PROJECT_APP_PATH}")
message(STATUS ">>>> IFW_BIN PATH IS ${CMAKE_SOURCE_DIR}")
execute_process(COMMAND ls "${CMAKE_SOURCE_DIR}")
message(STATUS ">>>> IFW_BIN PATH IS ${TARGET_APP_PATH}")
execute_process(COMMAND ls "${TARGET_APP_PATH}")
message(STATUS ">>>> IFW_BIN PATH IS ${CMAKE_CURRENT_SOURCE_DIR}")
execute_process(COMMAND ls "${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS ">>>> IFW_BIN PATH IS ${CMAKE_CURRENT_SOURCE_DIR}/bin")
execute_process(COMMAND ls "${CMAKE_CURRENT_SOURCE_DIR}/bin")
message(STATUS "===========================================")
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.7z)
    message(STATUS "command is: [${IFW_BINDIR}/archivegen ${DEX_PROJECT_NAME}.7z ${PROJECT_APP_PATH} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin]")
    execute_process(COMMAND
            ${IFW_BINDIR}/archivegen ${DEX_PROJECT_NAME}.7z ${PROJECT_APP_PATH}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
            ECHO_OUTPUT_VARIABLE
            ECHO_ERROR_VARIABLE)
else()
    message(STATUS "${DEX_PROJECT_NAME}.7z already created - skipping")
endif()
message(STATUS "===========================================")
execute_process(COMMAND ls ${CMAKE_CURRENT_SOURCE_DIR}/bin )
message(STATUS "Copying ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.7z TO ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/data")

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DEX_PROJECT_NAME}.7z DESTINATION ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/packages/com.komodoplatform.atomicdex/data)

execute_process(COMMAND ${IFW_BINDIR}/binarycreator -c ./config/config.xml -p ./packages/ ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer -s $ENV{MAC_SIGN_IDENTITY}
        WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)

execute_process(COMMAND codesign --deep --force -v -s "$ENV{MAC_SIGN_IDENTITY}" -o runtime --timestamp ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer.app
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)

execute_process(COMMAND ${PROJECT_ROOT_DIR}/cmake/install/macos/macos_notarize.sh --asc-public-id=$ENV{ASC_PUBLIC_ID} --app-specific-password=$ENV{APPLE_ATOMICDEX_PASSWORD} --apple-id=$ENV{APPLE_ID} --primary-bundle-id=com.komodoplatform.atomicdex --target-binary=${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer.app
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)

file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer.app DESTINATION ${TARGET_APP_PATH})


execute_process(COMMAND ${IFW_BINDIR}/archivegen ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer.7z ${DEX_PROJECT_NAME}_installer.app
        WORKING_DIRECTORY ${TARGET_APP_PATH}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)

file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/osx/${DEX_PROJECT_NAME}_installer.7z DESTINATION ${TARGET_APP_PATH})
