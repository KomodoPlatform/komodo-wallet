import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Constants"

ColumnLayout {
    property alias title: title.text
    property bool expandable: false
    property bool expanded: false
    readonly property bool show_content: !expandable || expanded

    RowLayout {
        id: row_layout
        Layout.fillWidth: true

        Arrow {
            id: arrow_icon
            visible: expandable
            up: expanded
            color: mouse_area.containsMouse ? Style.colorOrange : expanded ? Style.colorRed : Style.colorGreen
            Layout.alignment: Qt.AlignVCenter
        }

        TitleText {
            id: title
            Layout.fillWidth: true

            color: !expandable ? Style.colorText : Qt.lighter(Style.colorWhite4, mouse_area.containsMouse ? Style.hoverLightMultiplier : 1.0)

            DefaultMouseArea {
                id: mouse_area
                enabled: expandable
                anchors.fill: parent
                anchors.leftMargin: -arrow_icon.width - row_layout.spacing
                hoverEnabled: true
                onClicked: expanded = !expanded
            }
        }
    }
}
