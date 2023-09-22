import QtQuick 2.15
import QtQuick.Layouts 1.15
import ModelHelper 0.1

import App 1.0
import Dex.Themes 1.0 as Dex
import "../Constants"
import "../Components"

MultipageModal {
    id: root

    property var   orders: API.app.orders_mdl.orders_proxy_mdl.ModelHelper

    MultipageModalContent {
        id: modal_content
        topMarginAfterTitle: 15
        titleText: qsTr("Exit %1 or go to login menu?").arg(API.app_name)

        // Swap in progress warning
        DefaultText
        {
            visible: orders
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            color: Dex.CurrentTheme.warningColor
            text_value:
            {
                for (let i = 0; i < orders.count; i++)
                {
                    let status = orders.data(i).order_status
                    switch (status) {
                        case "matched":
                        case "ongoing":
                            return qsTr("Warning: You currently have a swap in progress.\nLogging out may result in a failed swap.")
                        case "successful":
                        case "refunding":
                        case "failed":
                            break
                        default:
                            return qsTr("Warning: You currently have open maker orders.\nThey will be removed from the orderbook until you log in again.")
                    }
                }
                return ""
            }
        }

        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Login menu")
                Layout.fillWidth: true
                onClicked: 
                {
                    return_to_login()
                }
            },
            DefaultButton {
                text: qsTr("Exit")
                Layout.fillWidth: true
                onClicked: Qt.quit()
            },
            DefaultButton {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                onClicked: root.close()
            }
        ]
    }
}
