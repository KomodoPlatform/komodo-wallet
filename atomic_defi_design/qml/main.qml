import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Controls.Universal 2.15

import "Screens"
import "Constants"

Qaterial.ApplicationWindow {
    id: window

    Universal.theme: Style.dark_theme ? Universal.Dark : Universal.Light
    Universal.accent: Style.colorQtThemeAccent
    Universal.foreground: Style.colorQtThemeForeground
    Universal.background: Style.colorQtThemeBackground

    visible: true
    minimumWidth: General.minimumWidth
    minimumHeight: General.minimumHeight
    title: qsTr("AtomicDEX Desktop")
    flags: Qt.Window | Qt.WindowFullscreenButtonHint

    property int real_visibility

    Component.onCompleted: showMaximized()

    onVisibilityChanged: {
        // 3 is minimized, ignore that
        if(visibility !== 3)
            real_visibility = visibility

        API.app.change_state(visibility)
    }

    App {
        anchors.fill: parent
    }
}
