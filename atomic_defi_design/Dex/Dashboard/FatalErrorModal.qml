import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Constants"
import App 1.0
import "../Components"

MultipageModal {
    id: root

    property string message

    function onFatalNotification(msg) {
        console.debug("Fatal error: " + msg)
        if (API.app.wallet_mgr.initial_loading_status !== "None") {
            API.app.disconnect()
            app.current_page = app.idx_login
            message = msg
            open()
        }
    }

    width: 900

    MultipageModalContent {
        titleText: qsTr("Fatal Error")

        DefaultText {
            text: message === "connection dropped" ? qsTr("Connection has been lost. You have been disconnected.") :
                                                     message
        }

        footer: [
            CancelButton {
                Layout.fillWidth: true
                text: qsTr("Close")
                onClicked: root.close()
            }
        ]
    }

    Component.onCompleted: {
        API.app.notification_mgr.fatalNotification.connect(onFatalNotification)
        console.debug("FatalErrorModal Constructed")
    }

    Component.onDestruction: {
        API.app.notification_mgr.fatalNotification.disconnect(onFatalNotification)
        console.debug("FatalErrorModal Destructed")
    }
}
