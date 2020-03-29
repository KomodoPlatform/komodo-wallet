import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.0
import "../Components"
import "../Constants"

RowLayout {
    id: wallet

    // Local
    function onClickedSwap() {
        dashboard.current_page = General.idx_dashboard_exchange
        exchange.current_page = General.idx_exchange_trade
        exchange.openTradeView(API.get().current_coin_info.ticker)
    }

    function reset() {
        send_modal.reset(true)
        receive_modal.reset()
        claim_rewards_modal.reset()
        enable_coin_modal.reset()

        transactions.reset()
        input_coin_filter.reset()
    }

    readonly property double button_margin: 0.05
    spacing: 0
    Layout.fillWidth: true

    // Left side, main
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
        ColumnLayout {
            id: wallet_layout
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50
            anchors.bottom: parent.bottom

            spacing: 30

            // Balance texts
            RowLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                ColumnLayout {
                    id: balance_layout
                    DefaultText {
                        text: API.get().empty_string + (General.formatCrypto("", API.get().current_coin_info.balance, API.get().current_coin_info.ticker))
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: Style.textSize5
                    }

                    DefaultText {
                        text: API.get().empty_string + (General.formatFiat("", API.get().current_coin_info.fiat_amount, API.get().fiat))
                        Layout.topMargin: -15
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: Style.textSize2
                        color: Style.colorWhite4
                    }
                }
                Image {
                    source: General.coinIcon(API.get().current_coin_info.ticker)
                    Layout.leftMargin: 10
                    Layout.preferredHeight: balance_layout.childrenRect.height
                    Layout.preferredWidth: Layout.preferredHeight
                }
            }

            // Send, Receive buttons at top
            RowLayout {
                width: parent.width * 0.6

                Layout.topMargin: -10
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                spacing: 50

                DefaultButton {
                    enabled: API.get().current_coin_info.tx_state !== "InProgress"
                    text: API.get().empty_string + (qsTr("Send"))
                    leftPadding: parent.width * button_margin
                    rightPadding: leftPadding
                    onClicked: send_modal.open()
                }

                SendModal {
                    id: send_modal
                }

                DefaultButton {
                    text: API.get().empty_string + (qsTr("Receive"))
                    leftPadding: parent.width * button_margin
                    rightPadding: leftPadding
                    onClicked: receive_modal.open()
                }

                ReceiveModal {
                    id: receive_modal
                }

                DefaultButton {
                    text: API.get().empty_string + (qsTr("Swap"))
                    leftPadding: parent.width * button_margin
                    rightPadding: leftPadding
                    onClicked: onClickedSwap()
                }

                PrimaryButton {
                    id: button_claim_rewards
                    text: API.get().empty_string + (qsTr("Claim Rewards"))
                    leftPadding: parent.width * button_margin
                    rightPadding: leftPadding

                    visible: API.get().current_coin_info.is_claimable === true
                    enabled: API.get().current_coin_info.tx_state !== "InProgress" && claim_rewards_modal.canClaim()
                    onClicked: {
                        claim_rewards_modal.prepareClaimRewards()
                        claim_rewards_modal.open()
                    }
                }

                ClaimRewardsModal {
                    id: claim_rewards_modal

                    postClaim: () => { button_claim_rewards.enabled = claim_rewards_modal.canClaim() }
                }
            }

            // Separator line
            HorizontalLine {
                width: 720
                Layout.alignment: Qt.AlignHCenter
            }

            DefaultText {
                visible: API.get().current_coin_info.tx_state !== "InProgress" && API.get().current_coin_info.transactions.length === 0
                text: API.get().empty_string + (qsTr("No transactions"))
                font.pixelSize: Style.textSize
                color: Style.colorWhite4
                Layout.alignment: Qt.AlignHCenter
            }


            // Transactions or loading
            Rectangle {
                id: loading_tx
                color: "transparent"
                visible: API.get().current_coin_info.tx_state === "InProgress"
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                implicitHeight: 100

                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    DefaultText {
                        text: API.get().empty_string + (qsTr("Loading"))
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textSize2
                    }

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                    }

                    DefaultText {
                        text: API.get().empty_string + (qsTr("Syncing %n TX(s)...", "", parseInt(API.get().current_coin_info.tx_current_block)))
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Separator line
            HorizontalLine {
                visible: loading_tx.visible && transactions.model.length > 0
                width: 720
                Layout.alignment: Qt.AlignHCenter
            }

            Transactions {
                id: transactions
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Math.min(contentItem.childrenRect.height, wallet.height*0.5)
            }

            implicitHeight: Math.min(contentItem.childrenRect.height, wallet.height*0.5)
        }
    }

    // Coins bar at right side
    Rectangle {
        id: coins_bar
        Layout.alignment: Qt.AlignRight
        width: 150
        Layout.fillHeight: true
        color: Style.colorTheme7

        // Balance
        DefaultText {
            anchors.top: parent.top
            anchors.topMargin: search_button.anchors.topMargin * 0.5 - font.pixelSize * 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            text: API.get().empty_string + (General.formatFiat("", API.get().balance_fiat_all, API.get().fiat))
        }

        // Search button
        Image {
            id: search_button

            source: General.image_path + "exchange-search.svg"

            width: 32; height: width

            anchors.top: parent.top
            anchors.topMargin: parent.width * 0.5 - height * 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            visible: false
        }
        ColorOverlay {
            id: search_button_overlay
            property bool hovered: false

            anchors.fill: search_button
            source: search_button
            color: search_button_overlay.hovered || input_coin_filter.visible ? Style.colorWhite1 : Style.colorWhite4

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onHoveredChanged: search_button_overlay.hovered = containsMouse
                onClicked: {
                    input_coin_filter.text = ""
                    input_coin_filter.visible = !input_coin_filter.visible
                    if(input_coin_filter.visible)
                        input_coin_filter.focus = true
                }
            }
        }

        // Search input
        TextField {
            id: input_coin_filter

            function reset() {
                visible = false
                text = ""
            }

            anchors.top: search_button.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            placeholderText: API.get().empty_string + (qsTr("Search"))
            selectByMouse: true

            visible: false

            width: parent.width * 0.8
        }

        // Add button
        PlusButton {
            id: add_coin_button

            width: 32

            mouse_area.onClicked: enable_coin_modal.prepareAndOpen()

            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.width * 0.5 - height * 0.5
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Coins list
        ListView {
            ScrollBar.vertical: ScrollBar {}
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: contentItem.childrenRect.width
            implicitHeight: Math.min(contentItem.childrenRect.height, parent.height - coins_bar.width * 2)
            clip: true

            model: General.filterCoins(API.get().enabled_coins, input_coin_filter.text)

            delegate: Rectangle {
                property bool hovered: false

                color: API.get().current_coin_info.ticker === model.modelData.ticker ? Style.colorTheme2 : hovered ? Style.colorTheme4 : "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                width: coins_bar.width
                height: 50

                // Click area
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onHoveredChanged: hovered = containsMouse

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (mouse.button === Qt.RightButton) context_menu.popup()
                        else API.get().current_coin_info.ticker = model.modelData.ticker

                        send_modal.reset()
                    }
                    onPressAndHold: {
                        if (mouse.source === Qt.MouseEventNotSynthesized) context_menu.popup()
                    }
                }

                // Right click menu
                Menu {
                    id: context_menu
                    Action {
                        text: API.get().empty_string + (qsTr("Disable %1", "TICKER").arg(model.modelData.ticker))
                        onTriggered: API.get().disable_coins([model.modelData.ticker])
                        enabled: General.canDisable(model.modelData.ticker)
                    }
                }

                // Icon
                Image {
                    id: icon
                    anchors.left: parent.left
                    anchors.leftMargin: 20

                    source: General.image_path + "coins/" + model.modelData.ticker.toLowerCase() + ".png"
                    fillMode: Image.PreserveAspectFit
                    width: Style.textSize2
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Name
                DefaultText {
                    anchors.left: icon.right
                    anchors.leftMargin: 5

                    text: API.get().empty_string + (model.modelData.ticker)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}









/*##^##
Designer {
    D{i:0;autoSize:true;height:600;width:1200}
}
##^##*/
