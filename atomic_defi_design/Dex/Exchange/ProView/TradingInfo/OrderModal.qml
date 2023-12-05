import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import "../../../Components"
import "../../../Constants"
import App 1.0

MultipageModal
{
    id: root

    property var details
    width: 720
    horizontalPadding: 40
    verticalPadding: 30

    onDetailsChanged: { if (!details) root.close() }
    onOpened:
    {
        swapProgress.updateSimulatedTime()
        swapProgress.updateCountdownTime()
    }
    onClosed: details = undefined

    MultipageModalContent
    {
        titleText: !details ? "" : visible ? getStatusText(details.order_status) : ''
        title.font.pixelSize: Style.textSize2
        titleAlignment: Qt.AlignHCenter
        titleTopMargin: 0
        topMarginAfterTitle: 8
        flickMax: window.height - 450

        header: [
            // Complete image
            DefaultImage
            {
                visible: !details ? false : details.is_swap && details.order_status === "successful"
                Layout.alignment: Qt.AlignHCenter
                source: General.image_path + "exchange-trade-complete.png"
                Layout.preferredHeight: 60
                Layout.preferredWidth: 60
            },

            // Loading symbol
            DefaultBusyIndicator
            {
                visible: !details ? false :
                            details.is_swap && !["successful", "failed"].includes(details.order_status)
                running: visible && Qt.platform.os != "osx"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 60
                Layout.preferredWidth: 60
            },
            
            RowLayout
            {
                id: dex_pair_badges
                Layout.preferredHeight: 70
                Layout.fillWidth: true


                PairItemBadge
                {
                    ticker: details ? details.base_coin : ""
                    fullname: details ? General.coinName(details.base_coin) : ""
                    amount: details ? details.base_amount : ""
                    Layout.preferredHeight: 70
                }

                Item { Layout.fillWidth: true }

                Qaterial.Icon
                {
                    Layout.preferredHeight: 70
                    Layout.alignment: Qt.AlignVCenter
                    color: Dex.CurrentTheme.foregroundColor
                    icon: Qaterial.Icons.swapHorizontal
                }

                Item { Layout.fillWidth: true }

                PairItemBadge
                {
                    ticker: details ? details.rel_coin : ""
                    fullname: details ? General.coinName(details.rel_coin) : ""
                    amount: details ? details.rel_amount : ""
                    Layout.preferredHeight: 70
                }

            },

            DefaultText
            {
                Layout.alignment: Qt.AlignHCenter
                visible: text_value != ""
                font.pixelSize: Style.textSizeSmall2
                text_value: !details ? "" : details.order_status === "refunding" ? swapProgress.getRefundText() : ""
                height: 25
            }
        ]

        ColumnLayout
        {
            id: details_column
            Layout.fillWidth: true
            spacing: 12

            // Maker/Taker
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Order Type")
                text: !details ? "" : details.is_maker ? qsTr("Maker Order") : qsTr("Taker Order")
                label.font.pixelSize: 13
            }

            // Refund state
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Refund State")
                text: !details ? "" : details.order_status === "refunding" ? qsTr("Your swap failed but the auto-refund process for your payment started already. Please wait and keep application opened until you receive your payment back") : ""
                label.font.pixelSize: 13
                visible: text !== ''
            }

            // Date
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Date")
                text: !details ? "" : details.date.replace("    ",  " ")
                label.font.pixelSize: 13
                visible: text !== ''
            }

            // ID
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Swap ID")
                text: !details ? "" : details.order_id
                label.font.pixelSize: 13
                visible: text !== ''
                copy: true
                privacy: true
                onCopyNotificationTitle: qsTr("Swap ID")
            }

            // Payment ID
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: !details ? "" : details.is_maker ? qsTr("Maker Payment Sent Transaction ID") : qsTr("Maker Payment Spent Transaction ID")
                text: !details ? "" : details.maker_payment_id
                label.font.pixelSize: 12
                visible: text !== ''
                copy: true
                linkURL: text !== '' ? General.getTxExplorerURL(details.is_maker ? details.base_coin : details.rel_coin, details.maker_payment_id) : ''
                privacy: true
                onCopyNotificationTitle: qsTr("Maker Payment TXID")
            }

            // Payment ID
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: !details ? "" : details.is_maker ? qsTr("Taker Payment Spent Transaction ID") : qsTr("Taker Payment Sent Transaction ID")
                text: !details ? "" : details.taker_payment_id
                label.font.pixelSize: 12
                visible: text !== ''
                copy: true
                privacy: true
                onCopyNotificationTitle: qsTr("Taker Payment TXID")
                linkURL: text !== '' ? General.getTxExplorerURL(details.is_maker ? details.rel_coin : details.base_coin, details.taker_payment_id) : ''
            }

            // Error ID
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Error ID")
                text: !details ? "" : details.order_error_state
                label.font.pixelSize: 13
                visible: text !== ''
            }

            // Error Details
            TextEditWithTitle
            {
                Layout.fillWidth: true
                title: qsTr("Error Log")
                text: !details ? "" : details.order_error_message
                label.font.pixelSize: 13
                visible: text !== ''
                copy: true
                onCopyNotificationTitle: qsTr("Error Log")
            }

            HorizontalLine
            {
                visible: swapProgress.visible
                Layout.fillWidth: true
                Layout.topMargin: 10
            }

            SwapProgress
            {
                id: swapProgress
                Layout.fillWidth: true
                visible: General.exists(details) && details.order_status !== "matching"
                details: root.details
            }
        }

        // Buttons
        footer:
        [
            Item
            {
                visible: refund_button.visible || cancel_order_button.visible
                Layout.fillWidth: true
            },

            // Recover Funds button
            DefaultButton
            {
                id: refund_button
                leftPadding: 15
                rightPadding: 15
                radius: 18
                enabled: !API.app.orders_mdl.recover_fund_busy
                visible: !details ? false :
                    details.recoverable && details.order_status !== "refunding"
                text: enabled ? qsTr("Recover Funds") : qsTr("Refunding...")
                font: DexTypo.body2
                onClicked: API.app.orders_mdl.recover_fund(details.order_id)
                Layout.preferredHeight: 50
            },

            // Cancel button
            DexAppOutlineButton
            {
                id: cancel_order_button
                visible: !details ? false : details.cancellable
                leftPadding: 15
                rightPadding: 15
                radius: 18
                text: qsTr("Cancel Order")
                font: DexTypo.body2
                onClicked: cancelOrder(details.order_id)
                Layout.preferredHeight: 50
            },

            Item { Layout.fillWidth: true },

            DexAppOutlineButton
            {
                id: explorer_button
                text: qsTr("View on Explorer")
                font: DexTypo.body2
                Layout.preferredHeight: 50
                leftPadding: 15
                rightPadding: 15
                radius: 18
                visible: !details ? false : details.maker_payment_id !== '' || details.taker_payment_id !== ''
                onClicked:
                {
                    if (!details) return

                    const maker_id = details.maker_payment_id
                    const taker_id = details.taker_payment_id

                    if (maker_id !== '') General.viewTxAtExplorer(details.is_maker ? details.base_coin : details.rel_coin, maker_id)
                    if (taker_id !== '') General.viewTxAtExplorer(details.is_maker ? details.rel_coin : details.base_coin, taker_id)
                }
            },

            Item
            {
                visible: close_order_button.visible && explorer_button.visible
                Layout.fillWidth: true
            },

            CancelButton
            {
                id: close_order_button
                text: qsTr("Close")
                font: DexTypo.body2
                leftPadding: 15
                rightPadding: 15
                radius: 18
                onClicked: root.close()
                Layout.preferredHeight: 50
            },

            Item
            {
                visible: close_order_button.visible || explorer_button.visible
                Layout.fillWidth: true
            }
        ]
    }
}
