import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0

MultipageModal {
    id: root

    property bool wrong_password: false

    width: 1100

    onClosed: {
        wrong_password = false
        input_password.reset()
    }

    MultipageModalContent {
        titleText: qsTr("Delete Wallet")

        FloatingBackground {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10

            color: Style.colorRed2

            width: parent.width - 5
            height: warning_texts.height + 20

            Column {
                id: warning_texts
                anchors.centerIn: parent
                width: parent.width
                spacing: 10

                DefaultText {
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    text_value: qsTr("Are you sure you want to delete %1 wallet?", "WALLET_NAME").arg(API.app.wallet_mgr.wallet_default_name)
                    font.pixelSize: Style.textSize2
                }

                DefaultText {
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    text_value: qsTr("If so, make sure you record your seed phrase in order to restore your wallet in the future.")
                }
            }
        }

        PasswordForm {
            id: input_password
            Layout.fillWidth: true
            confirm: false
            field.placeholderText: qsTr("Enter your wallet password")
        }

        DefaultText {
            text_value: qsTr("Wrong Password")
            color: Style.colorRed
            visible: wrong_password
        }

        // Buttons
        footer: [
            CancelButton {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            DangerButton {
                text: qsTr("Delete")
                Layout.fillWidth: true
                enabled: input_password.isValid()
                onClicked: {
                    if(API.app.wallet_mgr.confirm_password(API.app.wallet_mgr.wallet_default_name, input_password.field.text)) {
                        root.close()
                        wrong_password = false

                        API.app.wallet_mgr.delete_wallet(API.app.wallet_mgr.wallet_default_name)
                        setting_modal.close()
                        disconnect()
                    }
                    else {
                        wrong_password = true
                    }
                }
            }
        ]
    }
}
