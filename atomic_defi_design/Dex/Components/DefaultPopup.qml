// Qt Imports
import QtQuick 2.12
import QtQuick.Controls 2.15 //> Popup

import Dex.Themes 1.0 as Dex
Popup
{
    id: popup
    property color bgColor: Dex.CurrentTheme.floatingBackgroundColor

    y: parent.height
    x: (parent.width / 2) - (width / 2)

    closePolicy: Popup.CloseOnPressOutsideParent | Popup.CloseOnEscape

    background: FloatingBackground { color: bgColor } 
}
