import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

// Open Transaction Details Modal
MultipageModal
{
    id: root
    width: 780

    function reset() { }

    property var details
    property bool is_spam: !details ? false : details.amount == 0

    onClosed:
    {
        if (notes.field.enabled) notes.save_button.clicked()
        details = undefined
    }

    MultipageModalContent
    {
        titleText: qsTr("Transaction Details")

        // Warning for spam/poison transactions
        DefaultText
        {
            id: warning_text
            visible: is_spam
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            wrapMode: Label.Wrap
            color: Style.colorOrange
            text_value: qsTr("This transaction has been identified as a potential address poisoning attack.")
        }

        // Warning for spam/poison transactions
        DefaultText
        {
            id: warning_text2
            visible: is_spam
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            wrapMode: Label.Wrap
            color: Style.colorOrange
            text_value: qsTr("Please see the Support FAQ for more information.")
        }

        // Transaction Hash
        TitleText
        {
            text: qsTr("Transaction Hash")
            Layout.fillWidth: true
            visible: text !== ""
            color: Dex.CurrentTheme.foregroundColor2
        }

        TextEditWithCopy
        {
            id: tx_hash
            font_size: 13
            align_left: true
            text_box_width: 600
            text_value: !details ? "" : details.tx_hash
            linkURL: !details ? "" :General.getTxExplorerURL(api_wallet_page.ticker, details.tx_hash, false)
            onCopyNotificationTitle:  qsTr("%1 txid", "TICKER").arg(api_wallet_page.ticker)
            onCopyNotificationMsg: qsTr("copied to clipboard.")
            privacy: true
        }

        // Amount
        TextEditWithTitle
        {
            title: qsTr("Amount")
            text: !details ? "" : General.formatCrypto(!details.am_i_sender, details.amount, api_wallet_page.ticker, details.amount_fiat, API.app.settings_pg.current_currency)
            value_color: !details ? "white" : details.am_i_sender ?  Dex.CurrentTheme.warningColor : Dex.CurrentTheme.okColor
            privacy: true
            label.font.pixelSize: 13
        }

        // Fees
        TextEditWithTitle
        {
            title: qsTr("Fees")
            text: !details ? "" : General.formatCrypto(parseFloat(details.fees) < 0, Math.abs(parseFloat(details.fees)), current_ticker_infos.fee_ticker, details.fees_amount_fiat, API.app.settings_pg.current_currency)
            value_color: !details ? "white" : parseFloat(details.fees) > 0 ? Dex.CurrentTheme.warningColor : Dex.CurrentTheme.okColor
            privacy: true
            label.font.pixelSize: 13
        }

        AddressList
        {
            width: parent.width
            title: qsTr("From")
            model: !details ? [] :
                    details.from
            linkURL: !details ? "" :General.getAddressExplorerURL(api_wallet_page.ticker, details.from)
            onCopyNotificationTitle: is_spam ? "" : qsTr("From address")
        }

        AddressList
        {
            width: parent.width
            title: qsTr("To")
            model: !details ?
                   [] : details.to.length > 1 ?
                   General.arrayExclude(details.to, details.from[0]) : details.to
            linkURL: !details ? ""
                    :  details.to.length > 1
                    ? General.getAddressExplorerURL(api_wallet_page.ticker, General.arrayExclude(details.to, details.from[0]))
                    : General.getAddressExplorerURL(api_wallet_page.ticker, details.to)
            onCopyNotificationTitle: is_spam ? "" : qsTr("To address")
        }

        // Date
        TextEditWithTitle
        {
            title: qsTr("Date")
            text: !details ? "" : details.timestamp === 0 ? qsTr("Unconfirmed"):  details.date
            label.font.pixelSize: 13
        }


        // Confirmations
        TextEditWithTitle
        {
            title: qsTr("Confirmations")
            text: !details ? "" : details.confirmations
            label.font.pixelSize: 13
        }

        // Block Height
        TextEditWithTitle
        {
            title: qsTr("Block Height")
            text: !details ? "" : details.blockheight
            label.font.pixelSize: 13
        }


        // Notes
        TextAreaWithTitle
        {
            id: notes

            property string prev_text: ""

            title: qsTr("Notes")
            titleColor: Dex.CurrentTheme.foregroundColor2
            remove_newline: false
            field.text: !details ? "" : details.transaction_note
            field.rightPadding: 0
            saveable: true

            field.onTextChanged:
            {
                if (field.text.length > 500) field.text = prev_text
                else prev_text = field.text
            }

            onSaved: details.transaction_note = field.text
        }

        // Buttons
        footer:
        [
            CancelButton
            {
                Layout.fillWidth: true
                text: qsTr("Close")
                leftPadding: 40
                rightPadding: 40
                radius: 18
                onClicked: root.close()
            },

            DexAppOutlineButton
            {
                Layout.fillWidth: true
                text: qsTr("View on Explorer")
                leftPadding: 40
                rightPadding: 40
                radius: 18
                onClicked: General.viewTxAtExplorer(api_wallet_page.ticker, details.tx_hash, false)
            }
        ]
    }
}
