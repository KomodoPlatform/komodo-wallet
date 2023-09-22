import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../Constants" as Dex
import Dex.Components 1.0 as Dex

Dex.MultipageModal
{
    property string assetTicker

    Dex.MultipageModalContent
    {
        Layout.fillWidth: true
        titleText: qsTr("Enable " + assetTicker)

        Dex.Text
        {
            Layout.fillWidth: true
            text: qsTr("The selected address belongs to a disabled asset, you need to enabled it before sending.")
        }

        footer:
        [
            // Enable button
            Dex.Button
            {
                text: qsTr("Enable")

                onClicked:
                {
                    Dex.API.app.enable_coin(assetTicker)
                    close()
                }
            },

            // Cancel button
            Dex.CancelButton
            {
                Layout.rightMargin: 5
                text: qsTr("Cancel")

                onClicked: close()
            }
        ]
    }
}
