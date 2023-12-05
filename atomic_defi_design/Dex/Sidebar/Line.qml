//! Qt Imports.
import QtQuick 2.12

//! Project Imports.
import "../Components"
import "../Constants"
import Dex.Themes 1.0 as Dex

Item
{
    id: root

    property var type: Main.LineType.None

    property alias label: _label
    property alias mouseArea: _mouseArea

    signal clicked()

    height: lineHeight

    DexLabel
    {
        id: _label

        anchors.left: parent.left
        anchors.leftMargin: 45
        anchors.verticalCenter: parent.verticalCenter

        font: Qt.font
        ({
            pixelSize: 13 * DexTypo.fontDensity,
            letterSpacing: 0.25,
            family: DexTypo.fontFamily,
            weight: Font.Normal
        })
        style: Text.Normal
        color: !enabled                                                  ? Dex.CurrentTheme.textDisabledColor :
               _mouseArea.containsMouse && currentLineType !== type      ? Dex.CurrentTheme.sidebarLineTextHovered :
               currentLineType === type && type != Main.LineType.Support ? Dex.CurrentTheme.sidebarLineTextSelected :
                                                                           Dex.CurrentTheme.foregroundColor
    }

    DexMouseArea
    {
        id: _mouseArea
        hoverEnabled: true
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
