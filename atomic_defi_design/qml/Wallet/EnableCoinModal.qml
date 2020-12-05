import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"

BasicModal {
    id: root

    width: 400

    property var selected_to_enable: ({})

    function resetList() {
        // selected_to_enable = {}

        // Modifying selected_to_enable creates a binding loop
        // Have to check and then uncheck to affect all child checkboxes
        coins_utxo.parent_box.checkState = Qt.Checked
        coins_utxo.parent_box.checkState = Qt.Unchecked
        coins_smartchains.parent_box.checkState = Qt.Checked
        coins_smartchains.parent_box.checkState = Qt.Unchecked
        coins_erc.parent_box.checkState = Qt.Checked
        coins_erc.parent_box.checkState = Qt.Unchecked
        coins_qrc.parent_box.checkState = Qt.Checked
        coins_qrc.parent_box.checkState = Qt.Unchecked
    }

    function reset() {
        resetList()
        input_coin_filter.text = ""
    }

    onOpened: {
        input_coin_filter.forceActiveFocus()
    }

    onClosed: {
        reset()
    }

    function prepareAndOpen() {
        reset()
        root.open()
    }

    function markToEnable(ticker, enabled) {
        if(enabled) selected_to_enable[ticker] = true
        else delete selected_to_enable[ticker]

        selected_to_enable = selected_to_enable
    }

    function enableCoins() {
        const coins_to_enable = Object.keys(selected_to_enable)
        console.log("QML enable_coins:", JSON.stringify(coins_to_enable))
        if(coins_to_enable.length > 0)
            API.app.enable_coins(coins_to_enable)
        reset()
        root.close()
    }

    readonly property bool all_coins_are_selected:  coins_utxo.parent_box.checkState === Qt.Checked &&
                                                    coins_smartchains.parent_box.checkState === Qt.Checked &&
                                                    coins_erc.parent_box.checkState === Qt.Checked &&
                                                    coins_qrc.parent_box.checkState === Qt.Checked
    function toggleAllCoins() {
        if(all_coins_are_selected) {
            coins_utxo.parent_box.checkState = Qt.Unchecked
            coins_smartchains.parent_box.checkState = Qt.Unchecked
            coins_erc.parent_box.checkState = Qt.Unchecked
            coins_qrc.parent_box.checkState = Qt.Unchecked
        }
        else {
            coins_utxo.parent_box.checkState = Qt.Checked
            coins_smartchains.parent_box.checkState = Qt.Checked
            coins_erc.parent_box.checkState = Qt.Checked
            coins_qrc.parent_box.checkState = Qt.Checked
        }
    }

    ModalContent {
        title: qsTr("Enable assets")

        DefaultButton {
            Layout.fillWidth: true
            text: all_coins_are_selected ? qsTr("Clear All Selection") : qsTr("Enable All Assets")
            visible: API.app.enableable_coins.length > 0
            onClicked: toggleAllCoins()
        }

        DefaultButton {
            Layout.fillWidth: true
            text: qsTr("Add a custom asset to the list")
            onClicked: {
                root.close()
                add_custom_coin_modal.open()
            }
        }

        HorizontalLine {
            Layout.fillWidth: true
        }

        // Search input
        DefaultTextField {
            id: input_coin_filter

            Layout.fillWidth: true
            placeholderText: qsTr("Search")
        }

        DefaultFlickable {
            id: flickable
            visible: API.app.enableable_coins.length > 0

            height: 375
            Layout.fillWidth: true

            contentWidth: col.width
            contentHeight: col.height

            Column {
                id: col

                CoinList {
                    id: coins_utxo
                    group_title: qsTr("Select all UTXO assets")
                    model: General.filterCoins(API.app.enableable_coins, input_coin_filter.text, "UTXO")
                }

                CoinList {
                    id: coins_smartchains
                    group_title: qsTr("Select all SmartChains")
                    model: General.filterCoins(API.app.enableable_coins, input_coin_filter.text, "Smart Chain")
                }

                CoinList {
                    id: coins_erc
                    group_title: qsTr("Select all Ethereum assets")
                    model: General.filterCoins(API.app.enableable_coins, input_coin_filter.text, "ERC-20")
                }

                CoinList {
                    id: coins_qrc
                    group_title: qsTr("Select all QRC assets")
                    model: General.filterCoins(API.app.enableable_coins, input_coin_filter.text, "QRC-20")
                }
            }
        }


        // Info text
        DefaultText {
            visible: API.app.enableable_coins.length === 0

            text_value: qsTr("All assets are already enabled!")
        }

        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Close")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            PrimaryButton {
                visible: API.app.enableable_coins.length > 0
                enabled: Object.keys(selected_to_enable).length > 0
                text: qsTr("Enable")
                Layout.fillWidth: true
                onClicked: enableCoins()
            }
        ]
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:600;width:1200}
}
##^##*/
