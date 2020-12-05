import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"

InnerBackground {
    DefaultFlickable {
        id: list
        anchors.fill: parent

        contentWidth: width
        contentHeight: column.height

        Column {
            id: column

            Repeater {
                model: API.app.trading_pg.market_pairs_mdl.multiple_selection_box

                delegate: Item {
                    id: multi_order_line
                    width: list.width
                    height: 60

                    readonly property bool is_parent_coin: model.ticker === rel_ticker

                    readonly property string base: sell_mode ? left_ticker : model.ticker
                    readonly property string rel: sell_mode ? model.ticker : left_ticker

                    readonly property string price: model.multi_ticker_price

                    readonly property double volume: model.multi_ticker_receive_amount

                    function resetData() {
                        model.multi_ticker_data = {}
                    }

                    function getData() {
                        return model.multi_ticker_data || {}
                    }

                    function setData(d) {
                        model.multi_ticker_data = d
                    }

                    function reset(multi_order_enabled) {
                        // Clear first
                        enable_ticker.checked = false
                        if(is_parent_coin && multi_order_enabled) {
                            // Retrigger the data changes
                            enable_ticker.checked = true
                        }
                    }

                    function setMultiTickerData() {
                        if(!model.is_multi_ticker_currently_enabled) return

                        if(parseFloat(multi_order_line.price) <= 0) {
                            toast.show(qsTr("%1 price is zero!", "TICKER").arg(model.ticker), General.time_toast_important_error)

                            console.log(model.ticker + " price is not higher than zero, not creating an order for this one")
                            multi_order_values_are_valid = false
                            return
                        }

                        if(multi_order_line.volume < General.getMinTradeAmount()) {
                            toast.show(qsTr("%1 receive volume is lower than minimum trade amount", "TICKER").arg(model.ticker) + " : " + General.getMinTradeAmount(), General.time_toast_important_error)

                            console.log(model.ticker + " receive volume is lower than minimum trade amount, not creating an order for this one")
                            multi_order_values_are_valid = false
                            return
                        }

                        if(model.multi_ticker_error > 0) {
                            toast.show(qsTr("Error:", model.multi_ticker_error))

                            console.log("Multi order error for", model.ticker, ":", model.multi_ticker_error)
                            multi_order_values_are_valid = false
                            return
                        }


                        let params = getData()
                        params.base = left_ticker
                        params.rel = model.ticker
                        params.price = price
                        params.volume = non_null_volume
                        params.is_created_order = true
                        params.base_nota = ""
                        params.base_confs = ""
                        params.rel_nota = ""
                        params.rel_confs = ""
                        params.trade_info = model.multi_ticker_fees_info

                        params.rel_volume = "" + multi_order_line.volume

                        setData(params)
                    }

                    Connections {
                        target: exchange_trade

                        function onMulti_order_enabledChanged() {
                            multi_order_line.reset(multi_order_enabled)
                        }

                        function onPrepareMultiOrder() {
                            multi_order_line.setMultiTickerData()
                        }
                    }

                    DexComboBoxLine {
                        anchors.fill: parent
                        details: model
                        padding: 10
                        bottom_text: qsTr("You'll receive %1", "AMOUNT TICKER").arg(General.formatCrypto("", multi_order_line.volume, multi_order_line.rel))
                    }

                    DefaultMouseArea {
                        id: mouse_area
                        anchors.fill: parent
                        hoverEnabled: enabled
                    }

                    // Error
                    DefaultText {
                        font.pixelSize: Style.textSizeSmall4
                        visible: model.multi_ticker_error > 0
                        anchors.verticalCenter: input_price.verticalCenter
                        anchors.right: input_price.left
                        anchors.rightMargin: 40
                        text_value: Style.warningCharacter
                        color: Style.colorYellow

                        DefaultTooltip {
                            visible: parent.visible && mouse_area.containsMouse

                            contentItem: ColumnLayout {
                                DefaultText {
                                    text_value: General.getTradingError(model.multi_ticker_error, model.multi_ticker_fees_info, base_ticker, model.ticker)
                                    font.pixelSize: Style.textSizeSmall2
                                }
                            }
                        }
                    }

                    AmountFieldWithInfo {
                        id: input_price
                        width: 220
                        anchors.right: fee_info_button.left
                        anchors.rightMargin: 30
                        anchors.verticalCenter: parent.verticalCenter

                        field.left_text: qsTr("Price")
                        field.right_text: model.ticker + "/" + multi_order_line.base
                        field.onTextChanged: {
                            if(model.multi_ticker_price !== field.text)
                                model.multi_ticker_price = field.text
                        }

                        field.text: price
                        field.enabled: !is_parent_coin
                    }

                    DefaultSwitch {
                        id: enable_ticker
                        anchors.rightMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !block_everything && !is_parent_coin
                        Component.onCompleted: checked = model.is_multi_ticker_currently_enabled || is_parent_coin
                        checked: is_parent_coin
                        onCheckedChanged: {
                            model.is_multi_ticker_currently_enabled = checked

                            if(!checked) resetData()
                        }
                    }

                    FeeIcon {
                        id: fee_info_button
                        visible: model.multi_ticker_fees_info.trading_fee !== undefined
                        anchors.verticalCenter: enable_ticker.verticalCenter
                        anchors.right: enable_ticker.left
                        anchors.rightMargin: 10
                        trade_info: model.multi_ticker_fees_info
                        base: multi_order_line.base
                    }

                    HorizontalLine {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }
    }

    DefaultBusyIndicator {
        anchors.centerIn: parent
        visible: fetching_multi_ticker_fees_busy
    }
}
