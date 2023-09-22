import QtQuick 2.15
import QtQuick.Layouts 1.15

MultipageModal {
    id: root

    property alias header: modal_content.titleText
    property alias field: text_area.field

    MultipageModalContent {
        id: modal_content

        TextAreaWithTitle {
            id: text_area
            Layout.fillWidth: true
            field.readOnly: true
            copyable: true
            remove_newline: false
            title: ""
        }

        // Buttons
        footer: [
            CancelButton {
                text: qsTr("Close")
                Layout.fillWidth: true
                onClicked: root.close()
            }
        ]
    }
}
