import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"
import ".."

import "Orders/"


MultipageModal {
    id: root

    width: 1100

    onOpened: reset()

    function reset() {

    }

    MultipageModalContent {
        titleText: qsTr("Confirm Multi Order Details")

        DefaultListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: API.app.trading_pg.market_pairs_mdl.multi_order_coins

            // Row
            delegate: OrderLine {
                clickable: false
                readonly property var order_data: model.multi_ticker_data

                details: ({
                    base_coin: order_data.base,
                    rel_coin: order_data.rel,
                    is_maker: true,
                    is_swap: false,
                    base_amount: order_data.volume,
                    rel_amount: order_data.rel_volume,
                    cancellable: false,
                    date: "",
                    order_id: "",
                })

                FeeIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    trade_info: order_data.trade_info
                    base: order_data.base
                }
            }
        }

        FloatingBackground {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10

            color: Style.colorTheme5

            width: warning_texts.width + 20
            height: warning_texts.height + 20

            ColumnLayout {
                id: warning_texts
                anchors.centerIn: parent

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("These swaps requests can not be undone and this is the final event!")
                }

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("These transactions can take up to 60 mins - DO NOT close this application!")
                    font.pixelSize: Style.textSizeSmall4
                }

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("Same funds will be used until an order matches.")
                    font.pixelSize: Style.textSizeSmall4
                }

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("Note that if one order is filled other will not be cancelled.")
                    font.pixelSize: Style.textSizeSmall4
                }
            }
        }

        // Buttons
        footer: [
            CancelButton {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            PrimaryButton {
                text: qsTr("Confirm")
                Layout.fillWidth: true
                onClicked: {
                    console.log("Submitting multiple sell order")
                    API.app.trading_pg.place_multiple_sell_order()

                    root.close()

                    toast.show(qsTr("Placed multiple orders"), General.time_toast_basic_info, "", false)

                    onOrderSuccess()
                }
            }
        ]
    }
}
