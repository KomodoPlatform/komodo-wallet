import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import QtGraphicalEffects 1.0
import "../Components"
import "../Constants"

AnimatedRectangle {
    property var details
    property alias clickable: mouse_area.enabled
    readonly property bool is_placed_order: !details ? false :
                                                       details.order_id !== ''

    width: list.width
    height: 40

    color: Style.colorOnlyIf(mouse_area.containsMouse, Style.colorTheme8)


    // Swap icon
    SwapIcon {
        visible: !status_text.visible
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        top_arrow_ticker: !details ? "KMD" :
                                     details.base_coin
        bottom_arrow_ticker: !details ? "KMD" :
                                        details.rel_coin
    }

    // Matching icon
    RowLayout {
        id: status_text
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        spacing: 5
        visible: !details ? false :
                 (details.is_swap || !details.is_maker)

        DefaultText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: base_amount.font.pixelSize
            color: !details ? "white" : getStatusColor(details.order_status)
            text_value: !details ? "" :
                        visible ? getStatusStep(details.order_status) : ''
        }

        DefaultBusyIndicator {
            Layout.alignment: Qt.AlignVCenter
            visible: !isSwapDone(details.order_status)
            Layout.preferredWidth: 20
            Layout.preferredHeight: Layout.preferredWidth
        }
    }



    DefaultMouseArea {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: enabled
        onClicked: {
            order_modal.details = details
            order_modal.open()
        }
    }

    // Base Icon
    DefaultImage {
        id: base_icon
        source: General.coinIcon(!details ? "KMD" :
                                            details.base_coin)
        width: Style.textSize2

        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.225
        anchors.verticalCenter: parent.verticalCenter
    }

    // Base Amount
    DefaultText {
        id: base_amount
        text_value: !details ? "" :
                    General.formatCrypto("", details.base_amount, details.base_coin, details.base_amount_current_currency, API.app.settings_pg.current_currency)
        font.pixelSize: Style.textSizeSmall4

        anchors.left: base_icon.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        privacy: is_placed_order
    }

    // Rel Amount
    DefaultText {
        id: rel_amount
        text_value: !details ? "" :
                    General.formatCrypto("", details.rel_amount, details.rel_coin, details.rel_amount_current_currency, API.app.settings_pg.current_currency)
        font.pixelSize: base_amount.font.pixelSize

        anchors.right: rel_icon.left
        anchors.rightMargin: base_amount.anchors.leftMargin
        anchors.verticalCenter: base_amount.verticalCenter
        privacy: is_placed_order
    }

    // Rel Icon
    DefaultImage {
        id: rel_icon
        source: General.coinIcon(!details ? "KMD" :
                                            details.rel_coin)

        width: base_icon.width
        anchors.right: parent.right
        anchors.rightMargin: base_icon.anchors.leftMargin
        anchors.verticalCenter: parent.verticalCenter
    }


    DefaultText {
        id: cancel_button_text
        visible: !details ? false :
                 details.cancellable

        font.pixelSize: Style.textSizeSmall4
        text_value: "x"
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -font.pixelSize * 0.125
        anchors.left: parent.left
        anchors.leftMargin: 20

        color: cancel_button.containsMouse ? Style.colorText : Style.colorText2

        DefaultMouseArea {
            id: cancel_button
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { if(details) cancelOrder(details.order_id) }
        }
    }

    // Date
    DefaultText {
        font.pixelSize: base_amount.font.pixelSize
        text_value: !details ? "" :
                    details.date
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: cancel_button_text.left
        anchors.leftMargin: 20
    }

    // Recoverable
    DefaultText {
        font.pixelSize: base_amount.font.pixelSize
        visible: !details || details.recoverable === undefined ? false :
                 details.recoverable && details.order_status !== "refunding"
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 150
        text_value: Style.warningCharacter
        color: Style.colorYellow

        DefaultTooltip {
            visible: parent.visible && mouse_area.containsMouse

            contentItem: ColumnLayout {
                DefaultText {
                    text_value: qsTr("Funds are recoverable")
                    font.pixelSize: Style.textSizeSmall4
                }
            }
        }
    }

    // Order ID
    DefaultText {
        id: order_id
        font.pixelSize: base_amount.font.pixelSize
        text_value: !details || details.order_id === "" ? "" :
                    details.order_id.substring(0, 5) + "..." + details.order_id.substring(details.order_id.length-5)
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 20
        privacy: true
    }

    HorizontalLine {
        width: parent.width
        color: Style.colorWhite9
        anchors.bottom: parent.bottom
    }
}




/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
