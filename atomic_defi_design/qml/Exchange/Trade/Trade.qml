import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import AtomicDEX.MarketMode 1.0

import "../../Components"
import "../../Constants"
import "../../Wallet"

Item {
    id: exchange_trade

    readonly property bool block_everything: swap_cooldown.running || fetching_multi_ticker_fees_busy

    readonly property bool fetching_multi_ticker_fees_busy: API.app.trading_pg.fetching_multi_ticker_fees_busy
    readonly property alias multi_order_enabled: multi_order_switch.checked

    signal prepareMultiOrder()
    property bool multi_order_values_are_valid: true

    readonly property string non_null_price: backend_price === '' ? '0' : backend_price
    readonly property string non_null_volume: backend_volume === '' ? '0' : backend_volume
    readonly property bool price_is_empty: parseFloat(non_null_price) <= 0

    readonly property string backend_price: API.app.trading_pg.price
    function setPrice(v) {
        API.app.trading_pg.price = v
    }
    readonly property int last_trading_error: API.app.trading_pg.last_trading_error
    readonly property string max_volume: API.app.trading_pg.max_volume
    readonly property string backend_volume: API.app.trading_pg.volume
    function setVolume(v) {
        API.app.trading_pg.volume = v
    }

    readonly property bool sell_mode: API.app.trading_pg.market_mode == MarketMode.Sell
    function setMarketMode(v) {
        API.app.trading_pg.market_mode = v
    }

    readonly property string left_ticker: API.app.trading_pg.market_pairs_mdl.left_selected_coin
    readonly property string right_ticker: API.app.trading_pg.market_pairs_mdl.right_selected_coin
    readonly property string base_ticker: API.app.trading_pg.market_pairs_mdl.base_selected_coin
    readonly property string rel_ticker: API.app.trading_pg.market_pairs_mdl.rel_selected_coin
    readonly property string base_amount: API.app.trading_pg.base_amount
    readonly property string rel_amount: API.app.trading_pg.rel_amount

    Timer {
        id: swap_cooldown
        repeat: false
        interval: 1000
    }

    // Override
    property var onOrderSuccess: () => {}

    onSell_modeChanged: reset()

    // Local
    function inCurrentPage() {
        return  exchange.inCurrentPage() &&
                exchange.current_page === General.idx_exchange_trade
    }

    function fullReset() {
        initialized_orderbook_pair = false
        reset()
    }

    function reset() {
        multi_order_switch.checked = false
    }

    readonly property var preffered_order: API.app.trading_pg.preffered_order

    function selectOrder(is_asks, coin, price, quantity, price_denom, price_numer, quantity_denom, quantity_numer) {
        setMarketMode(!is_asks ? MarketMode.Sell : MarketMode.Buy)

        API.app.trading_pg.preffered_order = { coin, price, quantity, price_denom, price_numer, quantity_denom, quantity_numer }

        form_base.focusVolumeField()
    }

    // Cache Trade Info
    property bool valid_fee_info: API.app.trading_pg.fees.base_transaction_fees !== undefined
    readonly property var curr_fee_info: API.app.trading_pg.fees

    property bool initialized_orderbook_pair: false
    readonly property string default_base: "KMD"
    readonly property string default_rel: "BTC"

    // Trade
    function open(ticker) {
        onOpened(ticker)
    }

    function onOpened(ticker="") {
        if(!initialized_orderbook_pair) {
            initialized_orderbook_pair = true
            API.app.trading_pg.set_current_orderbook(default_base, default_rel)
        }

        reset()
        setPair(true, ticker)
    }


    signal pairChanged(string base, string rel)

    function setPair(is_left_side, changed_ticker) {
        swap_cooldown.restart()

        if(API.app.trading_pg.set_pair(is_left_side, changed_ticker)) {
            pairChanged(base_ticker, rel_ticker)
            exchange.onTradeTickerChanged(base_ticker)
        }
    }

    function trade(options, default_config) {
        // Will move to backend - nota, conf
        let nota = ""
        let confs = ""

        if(options.enable_custom_config) {
            if(options.is_dpow_configurable) {
                nota = options.enable_dpow_confs ? "1" : "0"
            }

            if(nota !== "1") {
                confs = options.required_confirmation_count.toString()
            }
        }
        else {
            if(General.exists(default_config.requires_notarization)) {
                nota = default_config.requires_notarization ? "1" : "0"
            }

            if(nota !== "1" && General.exists(default_config.required_confirmations)) {
                confs = default_config.required_confirmations.toString()
            }
        }

        if(sell_mode)
            API.app.trading_pg.place_sell_order(nota, confs)
        else
            API.app.trading_pg.place_buy_order(nota, confs)
    }

    readonly property bool buy_sell_rpc_busy: API.app.trading_pg.buy_sell_rpc_busy
    readonly property var buy_sell_last_rpc_data: API.app.trading_pg.buy_sell_last_rpc_data

    onBuy_sell_last_rpc_dataChanged: {
        const response = General.clone(buy_sell_last_rpc_data)

        if(response.error_code) {
            confirm_trade_modal.close()

            toast.show(qsTr("Failed to place the order"), General.time_toast_important_error, response.error_message)

            return
        }
        else if(response.result && response.result.uuid) { // Make sure there is information
            confirm_trade_modal.close()

            toast.show(qsTr("Placed the order"), General.time_toast_basic_info, General.prettifyJSON(response.result), false)

            onOrderSuccess()
        }
    }

    // Form
    ColumnLayout {
        id: form

        spacing: layout_margin

        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: left_section
                anchors.left: parent.left
                anchors.right: forms.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: layout_margin

                InnerBackground {
                    id: graph_bg

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: selectors.top
                    anchors.bottomMargin: layout_margin * 2

                    content: CandleStickChart {
                        id: chart
                        width: graph_bg.width
                        height: graph_bg.height
                    }
                }


                // Ticker Selectors
                RowLayout {
                    id: selectors
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: orderbook_area.top
                    anchors.bottomMargin: layout_margin
                    spacing: 20

                    TickerSelector {
                        id: selector_left
                        left_side: true
                        ticker_list: API.app.trading_pg.market_pairs_mdl.left_selection_box
                        ticker: left_ticker
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.fillWidth: true
                    }

                    // Swap button
                    SwapIcon {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.preferredHeight: selector_left.height * 0.9

                        top_arrow_ticker: selector_left.ticker
                        bottom_arrow_ticker: selector_right.ticker
                        hovered: swap_button.containsMouse

                        DefaultMouseArea {
                            id: swap_button
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if(!block_everything)
                                    setPair(true, right_ticker)
                            }
                        }
                    }

                    TickerSelector {
                        id: selector_right
                        left_side: false
                        ticker_list: API.app.trading_pg.market_pairs_mdl.right_selection_box
                        ticker: right_ticker
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                }

                StackLayout {
                    id: orderbook_area
                    height: 250
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: price_line.top
                    anchors.bottomMargin: layout_margin

                    currentIndex: multi_order_enabled ? 1 : 0

                    Orderbook {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    MultiOrder {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }


                // Price
                InnerBackground {
                    id: price_line
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: price_line_obj.height + 30
                    PriceLine {
                        id: price_line_obj
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                }
            }

            Item {
                id: forms
                width: 375
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                // Sell
                OrderForm {
                    id: form_base

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                }

                // Multi-Order
                FloatingBackground {
                    visible: sell_mode

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: form_base.bottom
                    anchors.topMargin: layout_margin

                    height: column_layout.height

                    ColumnLayout {
                        id: column_layout

                        width: parent.width

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: layout_margin
                            Layout.rightMargin: layout_margin
                            Layout.topMargin: layout_margin
                            Layout.bottomMargin: layout_margin
                            spacing: layout_margin

                            DefaultSwitch {
                                id: multi_order_switch
                                Layout.leftMargin: 15
                                Layout.rightMargin: Layout.leftMargin
                                Layout.fillWidth: true

                                text: qsTr("Multi-Order")
                                enabled: !block_everything && (form_base.can_submit_trade || checked)

                                checked: API.app.trading_pg.multi_order_enabled
                                onCheckedChanged: {
                                    if(checked) {
                                        setVolume(max_volume)
                                        API.app.trading_pg.multi_order_enabled = checked
                                    }
                                }
                            }

                            DefaultText {
                                id: first_text

                                Layout.leftMargin: multi_order_switch.Layout.leftMargin
                                Layout.rightMargin: Layout.leftMargin
                                Layout.fillWidth: true

                                text_value: qsTr("Select additional assets for multi-order creation.")
                                font.pixelSize: Style.textSizeSmall2
                            }

                            DefaultText {
                                Layout.leftMargin: multi_order_switch.Layout.leftMargin
                                Layout.rightMargin: Layout.leftMargin
                                Layout.fillWidth: true

                                text_value: qsTr("Same funds will be used until an order matches.")
                                font.pixelSize: first_text.font.pixelSize
                            }

                            DefaultButton {
                                text: qsTr("Submit Trade")
                                Layout.leftMargin: multi_order_switch.Layout.leftMargin
                                Layout.rightMargin: Layout.leftMargin
                                Layout.fillWidth: true
                                enabled: multi_order_enabled && form_base.can_submit_trade
                                onClicked: {
                                    multi_order_values_are_valid = true
                                    prepareMultiOrder()
                                    if(multi_order_values_are_valid)
                                        confirm_multi_order_trade_modal.open()
                                }
                            }
                        }
                    }
                }
            }
        }

        ConfirmTradeModal {
            id: confirm_trade_modal
        }

        ConfirmMultiOrderTradeModal {
            id: confirm_multi_order_trade_modal
        }
    }
}










/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
