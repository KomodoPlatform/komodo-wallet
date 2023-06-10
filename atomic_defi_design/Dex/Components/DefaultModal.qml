import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

Popup
{
    id: root

    property int radius: 18

    anchors.centerIn: Overlay.overlay
    horizontalPadding: 40
    verticalPadding: 25

    modal: true
    focus: true

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: DefaultRectangle { radius: root.radius; color: Dex.CurrentTheme.floatingBackgroundColor }

    Overlay.modal: DefaultRectangle { color: "#AA000000" }

    // Fade in animation
    onVisibleChanged:
    {
        if (visible)
        {
            opacity = 0
            fadeAnimation.start()
        }
    }

    NumberAnimation
    {
        id: fadeAnimation
        target: root
        property: "opacity"
        duration: Style.animationDuration
        to: 1
    }
}
