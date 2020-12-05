message(STATUS "Hello world")

get_filename_component(PROJECT_ROOT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
if (EXISTS ${PROJECT_ROOT_DIR}/build-Release)
    message(STATUS "from ci tools, readjusting")
    get_filename_component(PROJECT_ROOT_DIR ${PROJECT_ROOT_DIR} DIRECTORY)
endif ()

message(STATUS "PROJECT_ROOT_DIR -> ${PROJECT_ROOT_DIR}")

set(PROJECT_APP_DIR bin)
set(PROJECT_APP_PATH ${CMAKE_SOURCE_DIR}/${PROJECT_APP_DIR})
set(TARGET_APP_PATH ${PROJECT_ROOT_DIR}/bundled/windows)

if (EXISTS ${PROJECT_APP_PATH})
    message(STATUS "PROJECT_APP_PATH path is -> ${PROJECT_APP_PATH}")
    message(STATUS "TARGET_APP_PATH path is -> ${TARGET_APP_PATH}")
else ()
    message(FATAL_ERROR "Didn't find ${PROJECT_APP_PATH}")
endif ()

if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bin.zip)
	execute_process(COMMAND powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('bin', 'bin.zip'); }"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			ECHO_OUTPUT_VARIABLE
			ECHO_ERROR_VARIABLE
		)
else()
	message(STATUS "bin.zip already present - skipping")
endif()

if (NOT EXISTS ${TARGET_APP_PATH}/bin.zip)
	message(STATUS "Copying ${CMAKE_SOURCE_DIR}/bin.zip to ${TARGET_APP_PATH}/atomicdex-desktop.zip")
	file(COPY ${CMAKE_SOURCE_DIR}/bin.zip DESTINATION ${TARGET_APP_PATH})
else()
	message(STATUS "${TARGET_APP_PATH}/atomicdex-desktop.zip exists - skipping")
endif()

message(STATUS "Creating Installer")
set(IFW_BINDIR $ENV{QT_ROOT}/Tools/QtInstallerFramework/4.0/bin)
message(STATUS "IFW_BIN PATH IS ${IFW_BINDIR}")
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bin/atomicdex_desktop.7z)
	execute_process(COMMAND ${IFW_BINDIR}/archivegen.exe atomicdex_desktop.7z .
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
		ECHO_OUTPUT_VARIABLE
		ECHO_ERROR_VARIABLE
		RESULT_VARIABLE ARCHIVE_RESULT
		OUTPUT_VARIABLE ARCHIVE_OUTPUT
		ERROR_VARIABLE ARCHIVE_ERROR)
else()
	message(STATUS "atomicdex_desktop.7z already exists skipping")
endif()

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/bin/atomicdex_desktop.7z DESTINATION ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/packages/com.komodoplatform.atomicdex/data)

execute_process(COMMAND ${IFW_BINDIR}/binarycreator.exe -c ./config/config.xml -p ./packages/ atomicdex_desktop_installer.exe
	WORKING_DIRECTORY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows
	ECHO_OUTPUT_VARIABLE
	ECHO_ERROR_VARIABLE)
file(COPY ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/installer/windows/atomicdex_desktop_installer.exe DESTINATION ${TARGET_APP_PATH})