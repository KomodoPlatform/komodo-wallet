import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"

ColumnLayout {
    id: root

    property bool is_asks: false
    property alias model: list.model

    spacing: 0

    // List header
    Item {
        Layout.fillWidth: true

        height: 40

        // Price
        DefaultText {
            id: price_header
            font.pixelSize: Style.textSizeSmall3

            text_value: is_asks ? qsTr("Ask Price") + "\n(" + right_ticker + ")":
                                  qsTr("Bid Price") + "\n(" + right_ticker + ")"

            color: is_asks ? Style.colorRed : Style.colorGreen
            horizontalAlignment: Text.AlignRight

            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.68

            anchors.verticalCenter: parent.verticalCenter
        }

        // Quantity
        DefaultText {
            id: quantity_header
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.35

            horizontalAlignment: price_header.horizontalAlignment

            font.pixelSize: price_header.font.pixelSize

            text_value: qsTr("Quantity") + "\n(" + left_ticker + ")"
            color: Style.colorWhite1
            anchors.verticalCenter: parent.verticalCenter
        }

        // Total
        DefaultText {
            id: total_header
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.02

            horizontalAlignment: price_header.horizontalAlignment

            font.pixelSize: price_header.font.pixelSize

            text_value: qsTr("Total") + "\n(" + right_ticker + ")"
            color: Style.colorWhite1
            anchors.verticalCenter: parent.verticalCenter
        }

        // Line
        HorizontalLine {
            width: parent.width
            color: Style.colorWhite5
            anchors.bottom: parent.bottom
        }
    }

    // List
    DefaultListView {
        id: list

        scrollbar_visible: false

        Layout.fillWidth: true
        Layout.fillHeight: true

        delegate: Item {
            width: root.width
            height: 20

            // Hover / My Order line
            AnimatedRectangle {
                visible: mouse_area.containsMouse || is_mine
                width: parent.width
                height: parent.height
                color: is_mine ? Style.colorOrange : Style.colorWhite1
                opacity: 0.1

                anchors.left: is_asks ? parent.left : undefined
                anchors.right: is_asks ? undefined : parent.right
            }

            // Depth line
            AnimatedRectangle {
                width: parent.width * depth
                height: parent.height
                color: price_value.color
                opacity: 0.1

                anchors.left: is_asks ? parent.left : undefined
                anchors.right: is_asks ? undefined : parent.right
            }

            DefaultMouseArea {
                id: mouse_area
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if(is_mine) return

                    selectOrder(is_asks, coin, price, quantity, price_denom, price_numer, quantity_denom, quantity_numer)
                }
            }

            // Price
            DefaultText {
                id: price_value

                anchors.right: parent.right
                anchors.rightMargin: price_header.anchors.rightMargin

                font.pixelSize: Style.textSizeSmall1

                text_value: General.formatDouble(price, General.amountPrecision, true)
                color: price_header.color
                anchors.verticalCenter: parent.verticalCenter
            }

            // Quantity
            DefaultText {
                id: quantity_value
                anchors.right: parent.right
                anchors.rightMargin: quantity_header.anchors.rightMargin

                font.pixelSize: price_value.font.pixelSize
                font.family: price_value.font.family

                text_value: General.formatDouble(quantity, General.amountPrecision, true)
                color: Style.colorWhite4
                anchors.verticalCenter: parent.verticalCenter
            }

            // Total
            DefaultText {
                id: total_value
                anchors.right: parent.right
                anchors.rightMargin: total_header.anchors.rightMargin

                font.pixelSize: price_value.font.pixelSize
                font.family: price_value.font.family

                text_value: General.formatDouble(total, General.amountPrecision, true)
                color: Style.colorWhite4
                anchors.verticalCenter: parent.verticalCenter
            }

            DefaultText {
                id: cancel_button_text
                property bool requested_cancel: false
                visible: is_mine && !requested_cancel

                font.pixelSize: Style.textSizeSmall4
                text_value: "x"
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -font.pixelSize * 0.125
                anchors.left: parent.left
                anchors.leftMargin: 6

                color: cancel_button.containsMouse ? Style.colorText : Style.colorText2

                DefaultMouseArea {
                    id: cancel_button
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if(!is_mine) return

                        cancel_button_text.requested_cancel = true
                        cancelOrder(uuid)
                    }
                }
            }

            // Line
            HorizontalLine {
                visible: index !== root.model.length - 1
                width: parent.width
                color: Style.colorWhite9
                anchors.bottom: parent.bottom
            }
        }
    }
}
