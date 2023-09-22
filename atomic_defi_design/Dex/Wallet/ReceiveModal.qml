import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0

MultipageModal
{
    id: root

    function reset() { }

    width: 800

    MultipageModalContent
    {
        titleText: qsTr("Receive %1", "TICKER").arg(api_wallet_page.ticker)
        subtitleText: qsTr("Only send %1 to this address", "TICKER").arg(api_wallet_page.ticker)
        titleAlignment: Qt.AlignHCenter
        subtitleAlignment: Qt.AlignHCenter
        topMarginAfterTitle: 15

        TextEditWithCopy
        {
            text_value: current_ticker_infos.address
            font_size: 13
            text_box_width:
            {
                let char_len = current_ticker_infos.address.length
                if (char_len > 70) return 560
                if (char_len > 50) return 450
                if (char_len > 40) return 400
                return 300
            }
            onCopyNotificationTitle: qsTr("%1 address", "TICKER").arg(api_wallet_page.ticker)
            onCopyNotificationMsg: qsTr("copied to clipboard.")
            privacy: true
        }

        DefaultImage
        {
            Layout.topMargin: 15
            Layout.bottomMargin: 15
            Layout.alignment: Qt.AlignHCenter

            source: current_ticker_infos.qrcode_address

            sourceSize.width: 350
            sourceSize.height: 350
        }

        // Buttons
        footer:
        [
            Item { Layout.fillWidth: true },
            CancelButton
            {
                text: qsTr("Close")
                Layout.fillWidth: true
                onClicked: root.close()
            },
            Item { Layout.fillWidth: true }
        ]
    }
}
