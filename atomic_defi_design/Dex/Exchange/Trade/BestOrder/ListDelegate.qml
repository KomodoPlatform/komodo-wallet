import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import AtomicDEX.MarketMode 1.0

import "../../../Components"
import "../../../Constants" as Constants

import App 1.0 as App

Item {
    id: _control
    property bool coinEnable: Constants.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled
    property var isAsk: {
        if(parseInt(cex_rates)>0){
            false
        }else if(parseInt(cex_rates)<0) {
            true
        }else {
            undefined
        }
    }
    width: visible? list.width : 0
    height: 36


    AnimatedRectangle {
        visible: mouse_are.containsMouse
        width: parent.width
        height: parent.height
        color: App.DexTheme.foregroundColor
        opacity: 0.1
    }

    RowLayout {
        id: row
        width:  parent.width - 30
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        Row {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 130
            leftPadding: -10
            spacing: 5
            DefaultImage {
                source: Constants.General.coinIcon(coin)
                width: 20
                height: 20
                smooth: true
                antialiasing: true
                opacity: !_control.coinEnable? .1 : 1
                anchors.verticalCenter: parent.verticalCenter
            }
            DefaultText {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 2
                text: send + " " + atomic_qt_utilities.retrieve_main_ticker(coin)
                font.family: App.DexTypo.fontFamily
                font.pixelSize: 12

            }
        }
        DefaultTooltip {
            id: _tooltip
            dim: true
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            width: 250
            contentItem: DexLabelUnlinked {
                text_value: qsTr(" %1 is not enabled - Do you want to enable it to be able to select %2 best orders ?<br><a href='#'>Yes</a> - <a href='#no'>No</a>").arg(coin).arg(coin)
                wrapMode: DefaultText.Wrap
                width: 250
                onLinkActivated: {
                    if(link==="#no") {
                        _tooltip.close()
                    }else {
                        if (Constants.API.app.enable_coins([coin]) === true) {
                            _control.coinEnable = true
                            _tooltip.close()
                        }
                        else {
                            cannot_enable_coin_modal.open()
                        }
                    }
                }

                ModalLoader {
                    property string coin_to_enable_ticker: coin
                    id: cannot_enable_coin_modal
                    sourceComponent: CannotEnableCoinModal { coin_to_enable_ticker: cannot_enable_coin_modal.coin_to_enable_ticker }
                }
            }
            delay: 200
        }

        DexLabel {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 70
            text: price_fiat + Constants.API.app.settings_pg.current_fiat_sign
            font.family: App.DexTypo.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Label.AlignRight
            opacity: 1

        }
        DexLabel {
            Layout.alignment: Qt.AlignVCenter
            
            text: cex_rates==="0"? "N/A" : parseFloat(cex_rates)>0? "+"+parseFloat(cex_rates).toFixed(2)+"%" : parseFloat(cex_rates).toFixed(2)+"%"
            font.family: App.DexTypo.fontFamily
            font.pixelSize: 12

            Behavior on rightPadding {
                NumberAnimation {
                    duration: 150
                }
            }

            color:cex_rates==="0"? Qt.darker(App.DexTheme.foregroundColor) : parseFloat(cex_rates)<0? App.DexTheme.greenColor : App.DexTheme.redColor
            horizontalAlignment: Label.AlignRight
            opacity: 1

        }
    }


    DefaultMouseArea {
        id: mouse_are
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if(!Constants.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled){
                _tooltip.open()
            }else {
                if(order_form.visible === false) {
                    order_form.visible = true
                }
                if(order_form.hidden === true) {
                    order_form.hidden = false
                    if(order_form.contentVisible === false) {
                        order_form.contentVisible = true
                    }
                }
                if (Constants.API.app.trading_pg.market_mode == MarketMode.Buy) {
                    console.log("Loading "+coin+"/"+Constants.API.app.trading_pg.market_pairs_mdl.rel_selected_coin+" chart")
                    app.pairChanged(Constants.API.app.trading_pg.market_pairs_mdl.rel_selected_coin, coin)
                } else {
                    console.log("Loading "+coin+"/"+Constants.API.app.trading_pg.market_pairs_mdl.base_selected_coin+" chart")
                    app.pairChanged(Constants.API.app.trading_pg.market_pairs_mdl.base_selected_coin, coin)
                }
                Constants.API.app.trading_pg.orderbook.select_best_order(uuid)
            }
            
            //if(is_mine) return
            //isAsk? selectOrder(true, coin, price, quantity, price_denom, price_numer, quantity_denom, quantity_numer, min_volume) : selectOrder(false, coin, price, quantity, price_denom, price_numer, quantity_denom, quantity_numer, min_volume)
        }
    }
    HorizontalLine {
        width: parent.width
        opacity: .4
    }

}
