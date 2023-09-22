import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../../../Components"
import "../../../Constants"
import App 1.0
import bignumberjs 1.0
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import AtomicDEX.MarketMode 1.0
import AtomicDEX.TradingError 1.0


Item
{
    property bool isAsk

    DefaultTooltip
    {
        visible: mouse_area.containsMouse && (tooltip_text.text_value != "")
        width: 300

        contentItem: RowLayout
        {
            width: 290

            Qaterial.ColorIcon
            {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                source: Qaterial.Icons.alert
                color: Qaterial.Colors.amber
            }

            DexLabel
            {
                id: tooltip_text
                Layout.fillWidth: true

                text_value:
                {
                    if (mouse_area.containsMouse)
                    {
                        let relMaxTakerVol = parseFloat(API.app.trading_pg.orderbook.rel_max_taker_vol.decimal);
                        let baseMaxTakerVol = parseFloat(API.app.trading_pg.orderbook.base_max_taker_vol.decimal);

                        if (!enough_funds_to_pay_min_volume)
                        {
                            return qsTr("This order requires a minimum amount of %1 %2 <br>You don't have enough funds.<br> %3")
                                .arg(parseFloat(min_volume).toFixed(8))
                                .arg(isAsk ? right_ticker : left_ticker)
                                .arg(relMaxTakerVol > 0 || baseMaxTakerVol > 0 ?
                                    "Your max balance after fees is: %1".arg(isAsk ?
                                    relMaxTakerVol.toFixed(8) : baseMaxTakerVol.toFixed(8)) : "")
                        }

                        if ([TradingError.LeftParentChainNotEnoughBalance, TradingError.RightParentChainNotEnoughBalance,
                             TradingError.LeftParentChainNotEnabled, TradingError.RightParentChainNotEnabled].includes(last_trading_error))
                        {
                            return General.getTradingError(
                                last_trading_error, curr_fee_info,
                                base_ticker, rel_ticker, left_ticker,
                                right_ticker)
                        }

                        if (!([TradingError.None, TradingError.PriceFieldNotFilled, TradingError.VolumeFieldNotFilled].includes(last_trading_error)))
                        {
                            if (isAsk && API.app.trading_pg.market_mode == MarketMode.Buy)
                            {
                                return General.getTradingError(
                                    last_trading_error, curr_fee_info,
                                    base_ticker, rel_ticker, left_ticker,
                                    right_ticker)
                            }

                            if (!isAsk && API.app.trading_pg.market_mode == MarketMode.Sell)
                            {
                                return General.getTradingError(
                                    last_trading_error, curr_fee_info,
                                    base_ticker, rel_ticker, left_ticker,
                                    right_ticker)
                            }
                            return ""
                        }
                        return ""
                    }
                    return ""
                }
                wrapMode: Text.WordWrap
            }
        }
        delay: 200
    }

    DefaultMouseArea
    {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: true

        onClicked:
        {
            if (is_mine) return

            if (enough_funds_to_pay_min_volume )
            {
                orderbook_list.currentIndex = index

                selectOrder(isAsk, coin, price, price_denom,
                            price_numer, min_volume, base_min_volume, base_max_volume,
                            rel_min_volume, rel_max_volume, base_max_volume_denom,
                            base_max_volume_numer, uuid)

                placeOrderForm.visible = General.flipFalse(placeOrderForm.visible)
                orderSelected()
            }
        }

        AnimatedRectangle
        {
            visible: mouse_area.containsMouse
            width: parent.width
            height: parent.height
            color: Dex.CurrentTheme.foregroundColor
            opacity: 0.1
        }

        Rectangle
        {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: width / 2
            visible: is_mine
            color: isAsk ? Dex.CurrentTheme.warningColor : Dex.CurrentTheme.okColor
        }

        // Progress bar
        Rectangle
        {
            anchors.bottom: parent.bottom
            height: 2
            width: parent.width
            radius: 3
            color: Dex.CurrentTheme.backgroundColor

            Rectangle
            {
                id: depth_bar
                anchors.top: parent.top
                height: 2
                width: 0
                Behavior on width { NumberAnimation { duration: 1000 } }
                radius: 3
                opacity: 0.8
                color: isAsk ? Dex.CurrentTheme.warningColor : Dex.CurrentTheme.okColor
                Component.onCompleted: width = ((depth * 100) * (mouse_area.width + 40)) / 100
            }
        }

        Row
        {
            id: row
            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter
            onWidthChanged: progress.width = ((depth * 100) * (width + 40)) / 100
            spacing: 0

            Dex.ElidableText
            {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.31
                text: { new BigNumber(price).toFixed(8) }
                font.family: DexTypo.fontFamily
                font.pixelSize: 12
                color: isAsk ? Dex.CurrentTheme.warningColor : Dex.CurrentTheme.okColor
                horizontalAlignment: Text.AlignRight
                wrapMode: Text.NoWrap
            }

            Item { width: parent.width * 0.01 }

            // Quantity
            Dex.ElidableText
            {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.37
                text: { new BigNumber(base_max_volume).toFixed(6) }
                font.family: DexTypo.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                onTextChanged: depth_bar.width = ((depth * 100) * (mouse_area.width + 40)) / 100
                wrapMode: Text.NoWrap
            }

            Item { width: parent.width * 0.01 }

            // Total
            Dex.ElidableText
            {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.30
                rightPadding: (is_mine) && (mouse_area.containsMouse || cancel_button.containsMouse) ? 30 : 0
                font.family: DexTypo.fontFamily
                font.pixelSize: 12
                text: { new BigNumber(total).toFixed(6) }
                horizontalAlignment: Text.AlignRight
                wrapMode: Text.NoWrap

                Behavior on rightPadding { NumberAnimation { duration: 150 } }
            }
        }
    }

    Qaterial.ColorIcon
    {
        id: cancel_button_text
        property bool requested_cancel: false

        visible: is_mine && !requested_cancel

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        anchors.right: parent.right
        anchors.rightMargin:  mouse_area.containsMouse || cancel_button.containsMouse ? 12 : 6

        Behavior on iconSize
        {
            NumberAnimation
            {
                duration: 200
            }
        }

        iconSize: mouse_area.containsMouse || cancel_button.containsMouse? 16 : 0

        color: cancel_button.containsMouse ?
            Qaterial.Colors.red : mouse_area.containsMouse ?
            DexTheme.foregroundColor: Qaterial.Colors.red

        DefaultMouseArea
        {
            id: cancel_button
            anchors.fill: parent
            hoverEnabled: true

            onClicked:
            {
                if (!is_mine) return

                cancel_button_text.requested_cancel = true
                cancelOrder(uuid)
            }
        }
    }

    AnimatedRectangle
    {
        visible: !enough_funds_to_pay_min_volume && mouse_area.containsMouse
        color: Dex.CurrentTheme.backgroundColor
        anchors.fill: parent
        opacity: .3
    }
}
