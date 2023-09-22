//! Qt Imports
import QtQuick 2.15          //> Item
import QtQuick.Layouts 1.15  //> RowLayout
import QtQuick.Controls 2.15 //> ItemDelegate

// 3rdParty
import Qaterial 1.0 as Qaterial

import App 1.0

//! Project Imports
import "../../../Components" //> MultipageModal
import "../../../Constants" as Constants  //> API
import Dex.Themes 1.0 as Dex

DexListView
{
    id: _listBestOrdersView
    model: Constants.API.app.trading_pg.orderbook.best_orders.proxy_mdl
    enabled: !Constants.API.app.trading_pg.orderbook.best_orders_busy
    onVisibleChanged: currentLeftToken = _tradeCard.selectedTicker

    property var    tradeCard
    property var    selectedOrder
    property bool best: true
    property string currentLeftToken // The token we wanna sell

    property int    _rowWidth: width
    property int    _rowHeight: 40
    property int    _tokenColumnSize: 90
    property int    _quantityColumnSize: 90
    property int    _quantityInBaseColumnSize: 120
    property int    _fiatVolumeColumnSize: 80
    property int    _cexRateColumnSize: 60

    headerPositioning: ListView.OverlayHeader
    reuseItems: true
    cacheBuffer: 40
    clip: true

    header: DexRectangle // Best orders list header
    {
        id: header_row
        width: _rowWidth
        height: _rowHeight
        z: 2
        radius: 0
        border.width: 0
        color: Dex.CurrentTheme.floatingBackgroundColor

        RowLayout                   // Order Columns Name
        {
            anchors.fill: parent
            anchors.margins: 5
            anchors.verticalCenter: parent.verticalCenter

            DexLabel             // "Token" Header
            {
                Layout.preferredWidth: _tokenColumnSize
                horizontalAlignment: Text.AlignLeft

                text_value: qsTr("Token")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            DexLabel             // "Available Quantity" Header
            {
                id: qty_header

                Layout.preferredWidth: _quantityColumnSize
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("Available Quantity")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            DexLabel             // "Available Quantity (in BASE)" header
            {
                id: base_qty_header

                Layout.preferredWidth: _quantityInBaseColumnSize
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("Available Quantity (in %1)").arg(currentLeftToken)
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            DexLabel             // "Fiat Volume" column header
            {
                Layout.preferredWidth: _fiatVolumeColumnSize
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("Fiat Volume")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            DexLabel             // "CEX Rate" column header
            {
                Layout.preferredWidth: _cexRateColumnSize
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("CEX Rate")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }

        MouseArea { anchors.fill: parent }
    }

    delegate: DexRectangle // Order Line
    {
        property bool _isCoinEnabled: Constants.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled

        width: _rowWidth
        height: _rowHeight
        radius: mouse_area.containsMouse ? 3 : 0
        border.width: 0
        colorAnimation: false
        color: mouse_area.containsMouse ? Dex.CurrentTheme.listItemHoveredBackground : 'transparent'

        DexMouseArea
        {
            id: mouse_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked:
            {
                if (!Constants.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled)
                {
                    _tooltip.open()
                }
                else
                {
                    _listBestOrdersView.tradeCard.best = false
                    _listBestOrdersView.selectedOrder = { "coin": coin, "uuid": uuid, "price": price, "base_min_volume": base_min_volume, "base_max_volume": base_max_volume, "from_best_order": true }
                }
            }
        }

        HorizontalLine { width: parent.width; opacity: .5 }

        RowLayout                   // Order Info
        {
            anchors.fill: parent

            RowLayout                           // Order Token
            {
                property int _iconWidth: 24
                Layout.preferredWidth: _tokenColumnSize
                Layout.leftMargin: 3

                DexImage                         // Order Token Icon
                {
                    Layout.preferredWidth: parent._iconWidth
                    Layout.preferredHeight: 24
                    source: General.coinIcon(coin)
                    opacity: !_isCoinEnabled? .3 : 1
                }

                DexLabel                          // Order Token Name
                {
                    Layout.preferredWidth: _tokenColumnSize - parent._iconWidth
                    text_value: coin
                    font.pixelSize: 14
                }
            }

            DexLabel                         // Order Available Quantity
            {
                Layout.preferredWidth: _quantityColumnSize
                horizontalAlignment: Text.AlignRight
                text_value: parseFloat(General.formatDouble(rel_max_volume, General.amountPrecision, true)).toFixed(8)
                font.pixelSize: 14
            }

            DexLabel                         // Order Available Quantity In BASE
            {
                Layout.preferredWidth: _quantityInBaseColumnSize
                horizontalAlignment: Text.AlignRight
                text_value: parseFloat(General.formatDouble(base_max_volume, General.amountPrecision, true)).toFixed(8)
                font.pixelSize: 14
            }

            DexLabel                         // Order Fiat Volume
            {
                Layout.preferredWidth: _fiatVolumeColumnSize
                horizontalAlignment: Text.AlignRight
                text_value: parseFloat(price_fiat).toFixed(2)+Constants.API.app.settings_pg.current_fiat_sign
            }

            DexLabel
            {
                Layout.preferredWidth: _cexRateColumnSize
                horizontalAlignment: Text.AlignRight
                color: cex_rates=== "0" ? Qt.darker(DexTheme.foregroundColor) : parseFloat(cex_rates)>0? DexTheme.warningColor : DexTheme.okColor
                text_value: cex_rates=== "0" ? "N/A" : parseFloat(cex_rates)>0? "+"+parseFloat(cex_rates).toFixed(2)+"%" : parseFloat(cex_rates).toFixed(2)+"%"
            }

            DexTooltip
            {
                id: _tooltip

                width: 250

                dim: true
                modal: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                contentItem: DexLabelUnlinked
                {
                    text_value: !General.isZhtlc(coin) ? 
                        qsTr(" %1 is not enabled - Do you want to enable it to be able to select %2 best orders ?<br><a href='#'>Yes</a> - <a href='#no'>No</a>").arg(coin).arg(coin) :
                        qsTr(" %1 is not enabled - Please enable it through the coin activation menu").arg(coin)
                    wrapMode: DexLabel.Wrap
                    width: 250
                    onLinkActivated:
                    {
                        if (link === "#no") _tooltip.close()
                        else
                        {
                            if (Constants.API.app.enable_coins([coin]) === false)
                                cannot_enable_coin_modal.open()
                            else
                            {
                                color = DexTheme.buttonColorTextDisabled
                                opacity = 0.8
                                _coinIsEnabling.visible = true
                             }
                        }
                    }
                }

                BusyIndicator
                {
                    id: _coinIsEnabling

                    visible: false
                    enabled: visible
                    anchors.fill: parent

                    Connections
                    {
                        target: Constants.API.app.portfolio_pg.global_cfg_mdl.all_disabled_proxy

                        function onLengthChanged()
                        {
                            _tooltip.close()
                            _isCoinEnabled = Constants.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin).is_enabled
                        }
                     }
                }

                ModalLoader
                {
                    property string coin_to_enable_ticker: coin
                    id: cannot_enable_coin_modal
                    sourceComponent: CannotEnableCoinModal { coin_to_enable_ticker: cannot_enable_coin_modal.coin_to_enable_ticker }
                }

                delay: 200
            }
        }
    }

    Connections
    {
        target: _tradeCard
        function onBestChanged()
        {
            Constants.API.app.trading_pg.orderbook.best_orders.proxy_mdl.setFilterFixedString("")
            positionViewAtBeginning()
        }
    }
}
