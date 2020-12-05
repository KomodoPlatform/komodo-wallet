import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"

BasicModal {
    id: root

    property var details

    onDetailsChanged: {
        if(!details) root.close()
    }

    onOpened: swap_progress.updateSimulatedTime()

    onClosed: details = undefined

    ModalContent {
        title: !details ? "" :
                details.is_swap ? qsTr("Swap Details") : qsTr("Order Details")

        // Complete image
        DefaultImage {
            visible: !details ? false :
                        details.is_swap && details.order_status === "successful"
            Layout.alignment: Qt.AlignHCenter
            source: General.image_path + "exchange-trade-complete.svg"
        }

        // Loading symbol
        DefaultBusyIndicator {
            visible: !details ? false :
                        details.is_swap &&
                        details.order_status !== "successful" &&
                        details.order_status !== "failed"
            Layout.alignment: Qt.AlignHCenter
        }

        // Status Text
        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            font.pixelSize: Style.textSize3
            visible: !details ? false :
                                details.is_swap || !details.is_maker
            color: !details ? "white" :
                    visible ? getStatusColor(details.order_status) : ''
            text_value: !details ? "" :
                        visible ? getStatusTextWithPrefix(details.order_status) : ''
        }

        OrderContent {
            Layout.topMargin: 25
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: Layout.leftMargin
            height: 120
            Layout.alignment: Qt.AlignHCenter
            details: root.details
            in_modal: true
        }

        HorizontalLine {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            color: Style.colorWhite8
        }

        // Maker/Taker
        DefaultText {
            text_value: !details ? "" :
                        details.is_maker ? qsTr("Maker Order"): qsTr("Taker Order")
            color: Style.colorThemeDarkLight
            Layout.alignment: Qt.AlignRight
        }

        // Refund state
        TextFieldWithTitle {
            Layout.topMargin: -20

            title: qsTr("Refund State")
            field.text: !details ? "" :
                        details.order_status === "refunding" ? qsTr("Your swap failed but the auto-refund process for your payment started already. Please wait and keep application opened until you receive your payment back") : ""
            field.readOnly: true

            visible: field.text !== ''
        }

        // Date
        TextEditWithTitle {
            title: qsTr("Date")
            text: !details ? "" :
                details.date
            visible: text !== ''
        }

        // ID
        TextEditWithTitle {
            title: qsTr("ID")
            text: !details ? "" :
                details.order_id
            visible: text !== ''
            privacy: true
        }

        // Payment ID
        TextEditWithTitle {
            title: !details ? "" :
                details.is_maker ? qsTr("Maker Payment Sent ID") : qsTr("Maker Payment Spent ID")
            text: !details ? "" :
                    details.maker_payment_id
            visible: text !== ''
            privacy: true
        }

        // Payment ID
        TextEditWithTitle {
            title: !details ? "" :
                    details.is_maker ? qsTr("Taker Payment Spent ID") : qsTr("Taker Payment Sent ID")
            text: !details ? "" :
                    details.taker_payment_id
            visible: text !== ''
            privacy: true
        }

        // Error ID
        TextEditWithTitle {
            title: qsTr("Error ID")
            text: !details ? "" :
                    details.order_error_state
            visible: text !== ''
        }

        // Error Details
        TextFieldWithTitle {
            title: qsTr("Error Log")
            field.text: !details ? "" :
                        details.order_error_message
            field.readOnly: true
            copyable: true

            visible: field.text !== ''
        }

        HorizontalLine {
            visible: swap_progress.visible
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: Layout.topMargin
            color: Style.colorWhite8
        }

        SwapProgress {
            id: swap_progress
            visible: General.exists(details) && details.order_status !== "matching"
            Layout.fillWidth: true
            details: root.details
        }

        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Close")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            // Cancel button
            DangerButton {
                visible: !details ? false :
                                    details.cancellable
                Layout.fillWidth: true
                text: qsTr("Cancel Order")
                onClicked: cancelOrder(details.order_id)
            },

            // Recover Funds button
            PrimaryButton {
                visible: !details ? false :
                                    details.recoverable && details.order_status !== "refunding"
                Layout.fillWidth: true
                text: qsTr("Recover Funds")
                onClicked: onRecoverFunds(details.order_id)
            },

            PrimaryButton {
                text: qsTr("View on Explorer")
                Layout.fillWidth: true
                visible: !details ? false :
                                    details.maker_payment_id !== '' || details.taker_payment_id !== ''
                onClicked: {
                    if(!details) return

                    const maker_id = details.maker_payment_id
                    const taker_id = details.taker_payment_id

                    if(maker_id !== '') General.viewTxAtExplorer(details.is_maker ? details.base_coin : details.rel_coin, maker_id)
                    if(taker_id !== '') General.viewTxAtExplorer(details.is_maker ? details.rel_coin : details.base_coin, taker_id)
                }
            }
        ]
    }
}
