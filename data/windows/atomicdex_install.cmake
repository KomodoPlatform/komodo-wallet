if (WIN32)
    message(STATUS "Windows")
	install(SCRIPT ${CMAKE_SOURCE_DIR}/data/windows/windows_post_install.cmake)
endif()