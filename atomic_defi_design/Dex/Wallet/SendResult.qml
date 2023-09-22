import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

MultipageModalContent
{
    id: root

    property var    result
    property alias  address: address.text_value
    property string custom_amount
    property alias  tx_hash: tx_hash.text_value

    titleText: qsTr("Transaction Complete!")

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
        text_box_width: 560
        onCopyNotificationTitle: qsTr("%1 txid", "TICKER").arg(api_wallet_page.ticker)
        onCopyNotificationMsg: qsTr("copied to clipboard.")
        privacy: true
    }

    // Address
    TitleText
    {
        text: qsTr("Recipient's address")
        Layout.fillWidth: true
        visible: text !== ""
        color: Dex.CurrentTheme.foregroundColor2
    }

    TextEditWithCopy
    {
        id: address
        font_size: 13
        align_left: true
        text_box_width: 560
        onCopyNotificationTitle: qsTr("%1 address", "TICKER").arg(api_wallet_page.ticker)
        onCopyNotificationMsg: qsTr("copied to clipboard.")
        privacy: true
    }

    // Amount
    TextEditWithTitle
    {
        title: qsTr("Amount")

        text:
        {
            let amount = custom_amount !== "" ? custom_amount : result.withdraw_answer.my_balance_change
            !amount ? "" : General.formatCrypto(
                '',
                amount,
                api_wallet_page.ticker,
                API.app.get_fiat_from_amount(api_wallet_page.ticker, amount),
                API.app.settings_pg.current_fiat
            )
        }
    }

    // Memo
    TextEditWithTitle
    {
        title: qsTr("Memo")
        visible: result.withdraw_answer.memo

        text:
        {
            result.withdraw_answer.memo
        }
    }

    // Fees
    TextEditWithTitle
    {
        title: qsTr("Fees")

        text:
        {
            let amount = result.withdraw_answer.fee_details.amount
            !amount ? "" : General.formatCrypto(
                '',
                amount,
                current_ticker_infos.fee_ticker,
                API.app.get_fiat_from_amount(current_ticker_infos.fee_ticker, amount),
                API.app.settings_pg.current_fiat
            )
        }
    }

    // Date
    TextEditWithTitle
    {
        title: qsTr("Date")
        text: result.withdraw_answer.date
    }


    // Buttons
    footer:
    [
        CancelButton
        {
            Layout.fillWidth: true
            text: qsTr("Close")
            radius: 18
            onClicked: close()
        },
        DexAppOutlineButton
        {
            Layout.fillWidth: true
            text: qsTr("View on Explorer")
            radius: 18
            onClicked: General.viewTxAtExplorer(api_wallet_page.ticker, tx_hash.text_value)
        }
    ]
}
