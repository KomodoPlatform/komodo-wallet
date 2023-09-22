import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../../../Components"
import "../../../Constants"
import App 1.0 as App
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import AtomicDEX.MarketMode 1.0

Item
{
    id: _control

    property bool coinEnable: API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled
    property bool isAsk

    AnimatedRectangle
    {
        visible: mouse_are.containsMouse
        width: parent.width
        height: parent.height
        color: Dex.CurrentTheme.foregroundColor
        opacity: 0.1
    }

    RowLayout
    {
        id: row
        width: parent.width
        height: parent.height
        spacing: 0

        Item
        {
            Layout.fillHeight: true
            Layout.preferredWidth: 140

            DexImage
            {
                id: asset_image
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                source: General.coinIcon(coin)
                opacity: !_control.coinEnable? .1 : 1
            }

            Dex.Text
            {
                anchors.top: parent.top
                anchors.left: asset_image.right
                horizontalAlignment: Text.AlignLeft
                anchors.leftMargin: 5
                text: send
                font.family: App.DexTypo.fontFamily
                font.pixelSize: 12
            }

            Dex.Text
            {
                anchors.bottom: parent.bottom
                anchors.left: asset_image.right
                horizontalAlignment: Text.AlignLeft
                anchors.leftMargin: 5
                text: coin
                font.family: App.DexTypo.fontFamily
                font.pixelSize: 12
            }
        }

        Item { Layout.preferredWidth: (parent.width - 300) / 2 }

        Dex.Text
        {
            Layout.preferredWidth: 80
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: price_fiat + API.app.settings_pg.current_fiat_sign
            font.family: App.DexTypo.fontFamily
            font.pixelSize: 12
        }

        Item { Layout.preferredWidth: (parent.width - 300) / 2 }

        Dex.Text
        {
            Layout.preferredWidth: 80
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            font.family: App.DexTypo.fontFamily
            font.pixelSize: 12

            text: cex_rates === "0" ? "N/A" :
                                      parseFloat(cex_rates) > 0 ? "+" + parseFloat(cex_rates).toFixed(2) + "%" :
                                                                  parseFloat(cex_rates).toFixed(2) + "%"
            color: cex_rates === "0" ? Qt.darker(Dex.CurrentTheme.foregroundColor) :
                                       parseFloat(cex_rates) < 0 ? Dex.CurrentTheme.okColor :
                                                                   Dex.CurrentTheme.warningColor

            Behavior on rightPadding
            {
                NumberAnimation
                {
                    duration: 150
                }
            }
        }
    }

    DefaultTooltip
    {
        id: _tooltip
        dim: true
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 250

        contentItem: DexLabelUnlinked
        {
            text_value: !General.isZhtlc(coin) ? 
                qsTr(" %1 is not enabled - Do you want to enable it to be able to select %2 best orders ?<br><a href='#'>Yes</a> - <a href='#no'>No</a>").arg(coin).arg(coin) :
                qsTr(" %1 is not enabled - Please enable it through the coin activation menu").arg(coin)
            wrapMode: DefaultText.Wrap
            width: 250
            onLinkActivated:
            {
                if (link === "#no")
                {
                    _tooltip.close();
                }
                else
                {
                    if (API.app.enable_coins([coin]) === true)
                    {
                        _control.coinEnable = true;
                        _tooltip.close();
                    }
                    else {
                        cannot_enable_coin_modal.open();
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

    DefaultMouseArea
    {
        id: mouse_are
        anchors.fill: parent
        hoverEnabled: true

        onClicked:
        {
            if (!API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled)
            {
                _tooltip.open()
            }
            else
            {
                placeOrderForm.visible = General.flipFalse(placeOrderForm.visible)
                if (API.app.trading_pg.market_mode == MarketMode.Buy)
                {
                    app.pairChanged(coin, rel_ticker)
                }
                else
                {
                    app.pairChanged(base_ticker, coin)
                }
                API.app.trading_pg.orderbook.select_best_order(uuid)
            }
        }
    }
}
