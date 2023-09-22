import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0

MultipageModal
{
    id: root

    width: 800

    onClosed: input_password_suffix.reset()

    MultipageModalContent
    {
        titleText: qsTr("Setup Camouflage Password")

        FloatingBackground
        {
            id: warning_bg
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10

            width: parent.width - 5
            height: warning_texts.height + 20

            Column
            {
                id: warning_texts
                anchors.centerIn: parent
                width: parent.width
                spacing: 10

                DefaultText
                {
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    text_value: qsTr("Camouflage Password is a secret password for emergency situations.")
                    font: DexTypo.subtitle2
                }

                DefaultText
                {
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font: DexTypo.subtitle2
                    text_value: qsTr("Using it to login will display your balance lower than it actually is.")
                }

                DefaultText
                {
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font: DexTypo.subtitle2
                    text_value: qsTr("Here you enter the suffix and at login you need to enter {real_password}{suffix}")
                }
            }
        }

        PasswordForm
        {
            id: input_password_suffix
            Layout.fillWidth: true
            field_title: qsTr("Password suffix")
            confirm_field_title: qsTr("Confirm pasword suffix")
            field.placeholderText: qsTr("Enter a password suffix")
            confirm_field.placeholderText: qsTr("Enter the same password suffix to confirm")
            high_security: false
        }

        // Buttons
        footer:
        [
            CancelButton
            {
                text: qsTr("Cancel")
                leftPadding: 40
                rightPadding: 40
                radius: 20
                onClicked: root.close()
            },
            Item { Layout.fillWidth: true },
            DexAppOutlineButton
            {
                text: qsTr("Save")
                leftPadding: 40
                rightPadding: 40
                radius: 20
                enabled: input_password_suffix.isValid()
                onClicked:
                {
                    API.app.wallet_mgr.set_emergency_password(input_password_suffix.field.text)
                    root.close()
                }
            }
        ]
    }
}
