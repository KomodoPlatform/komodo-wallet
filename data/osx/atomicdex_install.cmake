if (APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
            MACOSX_BUNDLE_BUNDLE_NAME "${PROJECT_NAME}"
            RESOURCE data/osx/${PROJECT_NAME}.icns
            MACOSX_BUNDLE_ICON_FILE ${PROJECT_NAME}
            MACOSX_BUNDLE_SHORT_VERSION_STRING 0.0.1
            MACOSX_BUNDLE_LONG_VERSION_STRING 0.0.1
            MACOSX_BUNDLE_INFO_PLIST "${PROJECT_SOURCE_DIR}/cmake/MacOSXBundleInfo.plist.in")
    add_custom_command(TARGET ${PROJECT_NAME}
            POST_BUILD COMMAND
            ${CMAKE_INSTALL_NAME_TOOL} -add_rpath "@executable_path/../Frameworks/"
            $<TARGET_FILE:${PROJECT_NAME}>)
endif ()

macro(finalize_bundling)
    message(STATUS "Post bundling")
endmacro()

if (APPLE)
    install(SCRIPT ${CMAKE_SOURCE_DIR}/data/osx/osx_post_install.cmake)
endif ()