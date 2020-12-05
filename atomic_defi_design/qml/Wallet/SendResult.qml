import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"

ModalContent {
    property var result: ({ balance_change:"", fees: "", date: "", explorer_url: "" })
    property alias address: address.text
    property string custom_amount
    property alias tx_hash: tx_hash.text

    function onClose() {}

    title: qsTr("Transaction Complete!")

    // Address
    TextEditWithTitle {
        id: address
        title: qsTr("Recipient's address")
        visible: text !== ""
    }

    // Amount
    TextEditWithTitle {
        title: qsTr("Amount")
        text: General.formatCrypto("", custom_amount !== "" ? custom_amount : result.balance_change, api_wallet_page.ticker)
    }

    // Fees
    TextEditWithTitle {
        title: qsTr("Fees")
        text: General.formatCrypto("", result.fees, current_ticker_infos.fee_ticker)
    }

    // Date
    TextEditWithTitle {
        title: qsTr("Date")
        text: result.date
    }

    // Transaction Hash
    TextEditWithTitle {
        id: tx_hash
        title: qsTr("Transaction Hash")
    }

    // Buttons
    footer: [
        DefaultButton {
            text: qsTr("Close")
            Layout.fillWidth: true
            onClicked: onClose()
        },

        PrimaryButton {
            text: qsTr("View on Explorer")
            Layout.fillWidth: true
            onClicked: General.viewTxAtExplorer(api_wallet_page.ticker, tx_hash.text)
        }
    ]
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
