# MIT License
#
# Copyright (c) 2020 Olivier Le Doeuff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include(hot_reload/cmake/Version.cmake)

set(QATERIALHOTRELOAD_PROJECT "QaterialHotReload" CACHE STRING "Project Name")
set(QATERIALHOTRELOAD_FOLDER_PREFIX "Qaterial/HotReload" CACHE STRING "Prefix folder for all Qaterial generated targets in generated project (only decorative)")
set(QATERIALHOTRELOAD_BUILD_SHARED OFF CACHE BOOL "Build QaterialHotReloadApp as a shared library (for android)")
# Might be useful to disable if you only want the HotReload Gui to integrate into your project
set(QATERIALHOTRELOAD_ENABLE_HOTRELOAD_APP ON CACHE BOOL "Build Qaterial HotReload application")
set(QATERIALHOTRELOAD_IGNORE_ENV OFF CACHE BOOL "Ignore qt environment variables")
set(QATERIALHOTRELOAD_ENABLE_PCH ON CACHE BOOL
 "Enable precompile headers support for 'QaterialHotReload'. \"
 Only work if CMake support 'target_precompile_headers'. \"
 This can speed up compilation time.")

message(STATUS "------ ${QATERIALHOTRELOAD_PROJECT} Configuration ------")

message(STATUS "QATERIALHOTRELOAD_PROJECT                : ${QATERIALHOTRELOAD_PROJECT}")
message(STATUS "QATERIALHOTRELOAD_VERSION                : ${QATERIALHOTRELOAD_VERSION}")
message(STATUS "QATERIALHOTRELOAD_VERSION_TAG_HEX        : ${QATERIALHOTRELOAD_VERSION_TAG_HEX}")
message(STATUS "QATERIALHOTRELOAD_BUILD_SHARED           : ${QATERIALHOTRELOAD_BUILD_SHARED}")
message(STATUS "QATERIALHOTRELOAD_IGNORE_ENV             : ${QATERIALHOTRELOAD_IGNORE_ENV}")
message(STATUS "QATERIALHOTRELOAD_FOLDER_PREFIX          : ${QATERIALHOTRELOAD_FOLDER_PREFIX}")

message(STATUS "QATERIALHOTRELOAD_ENABLE_HOTRELOAD_APP   : ${QATERIALHOTRELOAD_ENABLE_HOTRELOAD_APP}")

message(STATUS "------ ${QATERIALHOTRELOAD_PROJECT} End Configuration ------")
