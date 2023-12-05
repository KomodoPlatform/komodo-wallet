include(${CMAKE_CURRENT_LIST_DIR}/../../project.metadata.cmake)
message(STATUS "===== Starting Windows Post Install =====")

message(STATUS "PROJECT_ROOT_DIR (before readjusting) -> ${PROJECT_ROOT_DIR}")
get_filename_component(PROJECT_ROOT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
if (EXISTS ${PROJECT_ROOT_DIR}/build-Release OR EXISTS ${PROJECT_ROOT_DIR}/build-Debug)
    message(STATUS "from ci tools, readjusting")
    get_filename_component(PROJECT_ROOT_DIR ${PROJECT_ROOT_DIR} DIRECTORY)
endif ()
message(STATUS "PROJECT_ROOT_DIR (after readjusting) -> ${PROJECT_ROOT_DIR}")

set(PROJECT_APP_PATH ${CMAKE_SOURCE_DIR}/bin)
set(TARGET_APP_PATH ${PROJECT_ROOT_DIR}/bundled/windows)

message(STATUS "VCPKG package manager enabled")
message(STATUS "PROJECT_QML_DIR -> ${PROJECT_QML_DIR}")
message(STATUS "CMAKE_SOURCE_DIR -> ${CMAKE_SOURCE_DIR}")
message(STATUS "CMAKE_CURRENT_SOURCE_DIR -> ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "DEX_PROJECT_NAME -> ${DEX_PROJECT_NAME}")

if (EXISTS ${PROJECT_APP_PATH})
    message(STATUS "PROJECT_APP_PATH path -> ${PROJECT_APP_PATH}")
    message(STATUS "TARGET_APP_PATH path -> ${TARGET_APP_PATH}")
else ()
    message(FATAL_ERROR "Didn't find ${PROJECT_APP_PATH}")
endif ()

if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bin.zip)
	message(STATUS "Creating bin.zip...")
	execute_process(COMMAND powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('bin', 'bin.zip'); }"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			ECHO_OUTPUT_VARIABLE
			ECHO_ERROR_VARIABLE
		)
else()
	message(STATUS "bin.zip already present - skipping")
endif()

if (NOT EXISTS ${TARGET_APP_PATH}/bin.zip)
	message(STATUS "Copying ${CMAKE_SOURCE_DIR}/bin.zip to ${TARGET_APP_PATH}/${DEX_PROJECT_NAME}.zip")
	file(COPY ${CMAKE_SOURCE_DIR}/bin.zip DESTINATION ${TARGET_APP_PATH}/${DEX_PROJECT_NAME}.zip)
else()
	message(STATUS "${TARGET_APP_PATH}/${DEX_PROJECT_NAME}.zip exists - skipping")
endif()

message(STATUS "Embedding the manifest")
if (NOT EXISTS ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data/${DEX_PROJECT_NAME}.exe.manifest)
	message(WARNING "${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data/${DEX_PROJECT_NAME}.exe.manifest doesn't exist - aborting")
endif()
file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data/${DEX_PROJECT_NAME}.exe.manifest DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/bin)

#FILE(GLOB CURDIR RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/ ${CMAKE_CURRENT_SOURCE_DIR}/bin/*)

message(STATUS "curdir: ${CURDIR}")

#message(STATUS "Executing: [mt.exe -manifest \"${DEX_PROJECT_NAME}.exe.manifest\" -outputresource:\"${DEX_PROJECT_NAME}.exe\";\#1] from directory: ${CMAKE_CURRENT_SOURCE_DIR}/bin")

set(DEX_OUT "${CMAKE_CURRENT_SOURCE_DIR}\\bin\\${DEX_PROJECT_NAME}.exe")
set(DEX_IN "${CMAKE_CURRENT_SOURCE_DIR}\\bin\\${DEX_PROJECT_NAME}.exe.manifest")
cmake_path(CONVERT ${DEX_OUT} TO_NATIVE_PATH_LIST DEX_OUT_NATIVE)
cmake_path(CONVERT ${DEX_IN} TO_NATIVE_PATH_LIST DEX_IN_NATIVE)

#message(STATUS "mt.exe -manifest ${DEX_IN_NATIVE} -outputresource:${DEX_OUT_NATIVE}")

execute_process(COMMAND powershell.exe -File ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/ci_scripts/mt_wrapper.ps1 ${DEX_IN} ${DEX_OUT}
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
		ECHO_ERROR_VARIABLE
		RESULT_VARIABLE MANIFEST_RESULT
		OUTPUT_VARIABLE MANIFEST_OUTPUT
		ERROR_VARIABLE MANIFEST_ERROR)
message(STATUS "manifest output: ${MANIFEST_RESULT} ${MANIFEST_OUTPUT} ${MANIFEST_ERROR}")

# Set the path to the ifw root directory
set(IFW_ROOT "$ENV{QT_ROOT}/Tools/QtInstallerFramework")
message(STATUS "IFW_ROOT PATH IS ${IFW_ROOT}")
execute_process(COMMAND ls "${IFW_ROOT}")
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
set(IFW_BINDIR ${IFW_ROOT}/${IFW_VERSION}/bin)
message(STATUS "IFW_BIN PATH IS ${IFW_BINDIR}")
execute_process(COMMAND ls "${IFW_BINDIR}")
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${DEX_PROJECT_NAME}.7z)
	message(STATUS "Contents of folder: ls ${CMAKE_CURRENT_SOURCE_DIR}")
	execute_process(COMMAND ls "${CMAKE_CURRENT_SOURCE_DIR}")
	message(STATUS "Contents of folder: ls ${CMAKE_CURRENT_SOURCE_DIR}/bin")
	execute_process(COMMAND ls "${CMAKE_CURRENT_SOURCE_DIR}/bin")
	message(STATUS "Contents of folder: ls ${CMAKE_CURRENT_SOURCE_DIR}/bundled")
	execute_process(COMMAND ls "${PROJECT_ROOT_DIR}/bundled")
	message(STATUS "command is: [${IFW_BINDIR}/archivegen.exe ${DEX_PROJECT_NAME}.7z ${PROJECT_APP_PATH} WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/bundled]")
	execute_process(COMMAND
		${IFW_BINDIR}/archivegen.exe ${DEX_PROJECT_NAME}.7z ${PROJECT_APP_PATH}
		WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/bundled
		ECHO_OUTPUT_VARIABLE
		ECHO_ERROR_VARIABLE
		RESULT_VARIABLE ARCHIVE_RESULT
		OUTPUT_VARIABLE ARCHIVE_OUTPUT
		ERROR_VARIABLE ARCHIVE_ERROR)
	message(STATUS "archivegen output: ${ARCHIVE_OUTPUT} ${ARCHIVE_ERROR}")
else()
	message(STATUS "${DEX_PROJECT_NAME}.7z already exists skipping")
endif()

message(STATUS "Contents of folder: ls ${PROJECT_APP_PATH}")
execute_process(COMMAND ls "${PROJECT_APP_PATH}")

file(COPY ${PROJECT_ROOT_DIR}/bundled/${DEX_PROJECT_NAME}.7z DESTINATION ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data)

execute_process(COMMAND ${IFW_BINDIR}/binarycreator.exe -c ./config/config.xml -p ./packages/ ${DEX_PROJECT_NAME}_installer.exe
	WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows
	ECHO_OUTPUT_VARIABLE
	ECHO_ERROR_VARIABLE)
file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/${DEX_PROJECT_NAME}_installer.exe DESTINATION ${TARGET_APP_PATH})

message(STATUS "Contents of folder: ls ${TARGET_APP_PATH}")
execute_process(COMMAND ls "${TARGET_APP_PATH}")

message(STATUS "===== Windows Post Install Complete =====")