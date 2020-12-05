import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"

// Open Transaction Details Modal
BasicModal {
    id: root

    function reset() {

    }

    property var details

    onClosed: {
        if(notes.field.enabled) notes.save_button.clicked()
        details = undefined
    }

    ModalContent {
        title: qsTr("Transaction Details")

        // Amount
        TextEditWithTitle {
            title: qsTr("Amount")
            text: !details ? "" :
                    General.formatCrypto(!details.am_i_sender, details.amount, api_wallet_page.ticker, details.amount_fiat, API.app.settings_pg.current_currency)
            value_color: !details ? "white" :
                         details.am_i_sender ? Style.colorRed : Style.colorGreen
            privacy: true
        }

        // Fees
        TextEditWithTitle {
            title: qsTr("Fees")
            text: !details ? "" :
                    General.formatCrypto(parseFloat(details.fees) < 0, Math.abs(parseFloat(details.fees)), current_ticker_infos.fee_ticker)
            value_color: !details ? "white" :
                         parseFloat(details.fees) > 0 ? Style.colorRed : Style.colorGreen
            privacy: true
        }

        // Date
        TextEditWithTitle {
            title: qsTr("Date")
            text: !details ? "" :
                    details.timestamp === 0 ? qsTr("Unconfirmed"):  details.date
        }

        // Transaction Hash
        TextEditWithTitle {
            title: qsTr("Transaction Hash")
            text: !details ? "" :
                    details.tx_hash
            privacy: true
        }

        // Confirmations
        TextEditWithTitle {
            title: qsTr("Confirmations")
            text: !details ? "" :
                    details.confirmations
        }

        // Block Height
        TextEditWithTitle {
            title: qsTr("Block Height")
            text: !details ? "" :
                    details.blockheight
        }

        AddressList {
            title: qsTr("From")
            model: !details ? [] :
                    details.from
        }

        AddressList {
            title: qsTr("To")
            model: !details ? [] :
                    details.to
        }

        // Notes
        TextAreaWithTitle {
            id: notes
            title: qsTr("Notes")
            remove_newline: false
            field.text: !details ? "" :
                        details.transaction_note


            property string prev_text: ""
            field.onTextChanged: {
                if(field.text.length > 500)
                    field.text = prev_text
                else prev_text = field.text
            }

            onSaved: details.transaction_note = field.text
            saveable: true
        }

        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Close")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            DangerButton {
                visible: !details ? false :
                         !details.am_i_sender

                text: qsTr("Refund")
                Layout.fillWidth: true
                onClicked: {
                    const address = details.from[0]
                    const amount = details.amount
                    root.close()
                    send_modal.address_field.text = address
                    send_modal.amount_field.text = amount
                    send_modal.open()
                }
            },

            PrimaryButton {
                text: qsTr("View on Explorer")
                Layout.fillWidth: true
                onClicked: General.viewTxAtExplorer(api_wallet_page.ticker, details.tx_hash, false)
            }
        ]
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:600;width:1200}
}
##^##*/
