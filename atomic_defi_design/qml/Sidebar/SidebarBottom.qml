import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Constants"

ColumnLayout {
    id: window_layout

    transformOrigin: Item.Center
    spacing: 0

    SidebarLine {
        dashboard_index: General.idx_dashboard_settings
        text_value: qsTr("Settings")
        image: General.image_path + "menu-settings-white.svg"
        Layout.fillWidth: true
        separator: false
    }

    SidebarLine {
        dashboard_index: General.idx_dashboard_support
        text_value: qsTr("Support")
        image: General.image_path + "menu-support-white.png"
        Layout.fillWidth: true
        separator: false
    }

    SidebarLine {
        dashboard_index: General.idx_dashboard_privacy_mode
        text_value: qsTr("Privacy")
        image: ""
        Layout.fillWidth: true
        separator: false
        checked: General.privacy_mode
    }

    SidebarLine {
        dashboard_index: General.idx_dashboard_light_ui
        text_value: qsTr("Light UI")
        image: ""
        Layout.fillWidth: true
        separator: false
        checked: !Style.dark_theme
    }
}









/*##^##
Designer {
    D{i:0;autoSize:true;height:264;width:150}
}
##^##*/
