import QtQuick 2.12

import "../Components"
import Dex.Themes 1.0 as Dex

// FigurativeLine acts the same as Line but contains a figurative icon on the left of its label
Line
{
    property alias icon: _icon

    DefaultImage
    {
        id: _icon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18
        height: 16
    }

    DefaultColorOverlay
    {
        anchors.fill: _icon
        source: _icon
        color: !_icon.enabled ? Dex.CurrentTheme.textDisabledColor :
               mouseArea.containsMouse && currentLineType !== type       ? Dex.CurrentTheme.sidebarLineTextHovered :
               currentLineType === type && type != Main.LineType.Support ? Dex.CurrentTheme.sidebarLineTextSelected :
                                                                           Dex.CurrentTheme.foregroundColor
    }
}
