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

#include(${PROJECT_SOURCE_DIR}/cmake/Dependencies.cmake)

find_package(Qt5 REQUIRED COMPONENTS
  Core
  Gui
  Qml
  Quick
  QuickControls2
  Svg
  Xml
  QuickCompiler
)

find_package(Qt5 QUIET COMPONENTS
  Charts
  DataVisualization
  VirtualKeyboard
  WebChannel
  WebSockets
  WebEngine

  3DCore
  3DRender
  3DInput
  3DLogic
  3DExtras
  3DAnimation

  Quick3D
  Quick3DAssetImport
  Quick3DRender
  Quick3DRuntimeRender
  Quick3DUtils
)

include(${PROJECT_SOURCE_DIR}/hot_reload/cmake/FetchQtGeneratorCMake.cmake)
include(${PROJECT_SOURCE_DIR}/hot_reload/cmake/FetchSortFilterProxyModel.cmake)
#include(${PROJECT_SOURCE_DIR}/cmake/FetchQaterial.cmake)
