# Copyright 2019-2020 Olivier Le Doeuff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

message(STATUS "Generate Qaterial.HotReload qmldir")
qt_generate_qmldir(QATERIALHOTRELOAD_QMLDIR_FILE
 SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
 MODULE "Qaterial.HotReload"
)

message(STATUS "Generate Qaterial.HotReload.Images.qml")
qt_generate_qrc_alias_qt_object(QATERIALHOTRELOAD_IMAGES_QML
  SINGLETON
  SOURCE_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/Images
  NAME "${CMAKE_CURRENT_SOURCE_DIR}/Images.qml"
  PREFIX "Qaterial/HotReload/Images"
  GLOB_EXPRESSION "*png;*.svg"
  ALWAYS_OVERWRITE
)

message(STATUS "Generate QaterialHotReload.qrc")
qt_generate_qrc(QATERIALHOTRELOAD_QML_QRC
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  DEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/Generated
  NAME QaterialHotReload.qrc
  PREFIX "Qaterial/HotReload"
  GLOB_EXPRESSION "*.qml;qmldir;*.png;*.svg"
  ALWAYS_OVERWRITE
  RECURSE
)
qtquick_compiler_add_resources(QATERIALHOTRELOAD_QML_RES ${QATERIALHOTRELOAD_QML_QRC})

foreach(QATERIAL_CURRENT_QML_FILE ${QATERIALHOTRELOAD_QML_RES})
  source_group("Qml\\QtQuickCompiler Files" FILES ${QATERIAL_CURRENT_QML_FILE})
endforeach()


add_library(${QATERIALHOTRELOAD_LIB}Ui STATIC ${QATERIALHOTRELOAD_QML_RES})
add_library(Qaterial::HotReload::Ui ALIAS ${QATERIALHOTRELOAD_LIB}Ui)

set_target_properties(${QATERIALHOTRELOAD_LIB}Ui PROPERTIES AUTORCC TRUE)

target_link_libraries(${QATERIALHOTRELOAD_LIB}Ui PRIVATE
  Qt::Core
  Qt::Gui
  Qt::Svg
  Qt::Xml
  Qt::Qml
  Qt::Quick
  Qt::QuickControls2
)

if(QATERIALHOTRELOAD_FOLDER_PREFIX)
  set_target_properties(${QATERIALHOTRELOAD_LIB}Ui PROPERTIES FOLDER ${QATERIALHOTRELOAD_FOLDER_PREFIX})
endif()
