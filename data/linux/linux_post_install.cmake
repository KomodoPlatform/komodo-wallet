message(STATUS "Hello post install ${CMAKE_SOURCE_DIR}")

## 2 case root_dir/build_folder root_dir/ci_tools/build_folder
execute_process(COMMAND bash -c "echo -n `git rev-parse --short HEAD`"
        OUTPUT_VARIABLE VERSION_ID
        )

get_filename_component(PROJECT_ROOT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
if (EXISTS ${PROJECT_ROOT_DIR}/build-Release)
    message(STATUS "from ci tools, readjusting")
    get_filename_component(PROJECT_ROOT_DIR ${PROJECT_ROOT_DIR} DIRECTORY)
endif ()

message(STATUS "PROJECT_ROOT_DIR -> ${PROJECT_ROOT_DIR}")
set(PROJECT_QML_DIR ${PROJECT_ROOT_DIR}/atomic_defi_design/qml)
message(STATUS "PROJECT_QML_DIR -> ${PROJECT_QML_DIR}")
set(PROJECT_APP_DIR AntaraAtomicDexAppDir)
set(PROJECT_APP_PATH ${CMAKE_SOURCE_DIR}/bin/${PROJECT_APP_DIR})
set(PROJECT_BIN_PATH ${PROJECT_APP_PATH}/usr/bin/atomicdex-desktop)
set(PROJECT_LIB_PATH ${PROJECT_APP_PATH}/usr/lib)
set(TARGET_APP_PATH ${PROJECT_ROOT_DIR}/bundled/linux)
if (EXISTS ${PROJECT_APP_PATH})
    message(STATUS "PROJECT_APP_PATH path is -> ${PROJECT_APP_PATH}")
    message(STATUS "PROJECT_BIN_PATH path is -> ${PROJECT_BIN_PATH}")
    message(STATUS "PROJECT_LIB_PATH path is -> ${PROJECT_LIB_PATH}")
    message(STATUS "TARGET_APP_PATH path is -> ${TARGET_APP_PATH}")
else ()
    message(FATAL_ERROR "Didn't find ${PROJECT_APP_PATH}")
endif ()

message(STATUS "VCPKG package manager enabled")
set(LINUX_DEPLOY_PATH ${PROJECT_ROOT_DIR}/ci_tools_atomic_dex/linux_misc/linuxdeployqt-7-x86_64.AppImage)

if (EXISTS ${LINUX_DEPLOY_PATH})
    message(STATUS "linuxdeployqt path is -> ${LINUX_DEPLOY_PATH}")
else ()
    message(FATAL_ERROR "Didn't find ${LINUX_DEPLOY_PATH}")
endif ()


message(STATUS "Copying required libraries for QtWebEngine")
list(APPEND LIST_LIBS
        "/usr/lib/x86_64-linux-gnu/libsmime3.so"
        "/usr/lib/x86_64-linux-gnu/libssl3.so"
        "/usr/lib/x86_64-linux-gnu/nss/libfreebl3.chk"
        "/usr/lib/x86_64-linux-gnu/nss/libfreebl3.so"
        "/usr/lib/x86_64-linux-gnu/nss/libnssckbi.so"
        "/usr/lib/x86_64-linux-gnu/nss/libnssdbm3.chk"
        "/usr/lib/x86_64-linux-gnu/nss/libnssdbm3.so"
        "/usr/lib/x86_64-linux-gnu/nss/libsoftokn3.chk"
        "/usr/lib/x86_64-linux-gnu/nss/libsoftokn3.so")
file(COPY ${PROJECT_APP_PATH}/usr/share/icons/default/64x64/apps/atomicdex-desktop-64.png DESTINATION ${PROJECT_APP_PATH})
file(COPY ${PROJECT_APP_PATH}/usr/share/applications/atomicdex-desktop.desktop DESTINATION ${PROJECT_APP_PATH})
foreach (current_lib ${LIST_LIBS})
    message(STATUS "copying ${current_lib} to ${PROJECT_LIB_PATH}")
    file(COPY ${current_lib} DESTINATION ${PROJECT_LIB_PATH})
endforeach ()
message(STATUS "Executing linuxdeployqt to fix dependencies")
message(STATUS "Executing cmd: [${LINUX_DEPLOY_PATH} ${PROJECT_BIN_PATH} -qmldir=${PROJECT_QML_DIR} -bundle-non-qt-libs -exclude-libs="libnss3.so,libnssutil3.so" -unsupported-allow-new-glibc -no-copy-copyright-files -verbose=1 -extra-plugins=iconengines,platformthemes/libqgtk3.so -appimage]")
execute_process(COMMAND ${LINUX_DEPLOY_PATH} ${PROJECT_BIN_PATH} -qmldir=${PROJECT_QML_DIR} -bundle-non-qt-libs -exclude-libs="libnss3.so,libnssutil3.so" -unsupported-allow-new-glibc -no-copy-copyright-files -verbose=1 -extra-plugins=iconengines,platformthemes/libqgtk3.so -appimage
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)
message(STATUS "Copying ${PROJECT_APP_PATH} to ${TARGET_APP_PATH}/${PROJECT_APP_DIR}")
file(COPY ${PROJECT_APP_PATH} DESTINATION ${TARGET_APP_PATH})
execute_process(COMMAND zip -r atomicdex-desktop-linux-${VERSION_ID}.zip AntaraAtomicDexAppDir
        WORKING_DIRECTORY ${TARGET_APP_PATH}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)
execute_process(COMMAND tar --zstd -cf atomicdex-desktop-linux-${VERSION_ID}.tar.zst AntaraAtomicDexAppDir
        WORKING_DIRECTORY ${TARGET_APP_PATH}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE)
file(COPY ${CMAKE_SOURCE_DIR}/atomicdex-desktop-${VERSION_ID}-x86_64.AppImage DESTINATION ${TARGET_APP_PATH})