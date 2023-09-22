import QtQuick 2.15
import QtQuick.Layouts 1.12

import "../Constants" as Dex
import "../Components" as Dex
import "../String.js" as DexString
import "../Screens"
import App 1.0 as Dex
import Dex.Themes 1.0 as Dex

Dex.DexListView
{
    id: list
    interactive: false
    scrollbar_visible: false
    model: Dex.API.app.portfolio_pg.portfolio_mdl.portfolio_proxy_mdl

    property real _assetRowHeight: 46
    property real _assetNameColumnWidth: 180
    property real _assetBalanceColumnWidth: 190
    property real _fiatBalanceColumnWidth: 180
    property real _assetChange24hColumnWidth: 160
    property real _assetPriceColumWidth: 180
    property real _assetProviderColumnWidth: 90

    width: _assetNameColumnWidth + _assetBalanceColumnWidth + _fiatBalanceColumnWidth + _assetChange24hColumnWidth + _assetPriceColumWidth + _assetProviderColumnWidth
    height: (count * _assetRowHeight) + 46


    // Header
    header: Item
    {
        width: list.width
        height: 40

        RowLayout
        {
            id: columnsHeader
            anchors.fill: parent

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _assetNameColumnWidth
                Layout.fillHeight: true
                Layout.leftMargin: 15
                h_align: Text.AlignLeft
                sort_type: sort_by_name
                text: qsTr("Asset")
            }

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _assetBalanceColumnWidth
                Layout.fillHeight: true
                h_align: Text.AlignRight
                sort_type: sort_by_value
                text: qsTr("Balance")
            }

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _fiatBalanceColumnWidth
                Layout.fillHeight: true
                h_align: Text.AlignRight
                sort_type: sort_by_value
                text: qsTr("Fiat Balance")
            }

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _assetChange24hColumnWidth
                Layout.fillHeight: true
                h_align: Text.AlignRight
                sort_type: sort_by_change
                text: qsTr("Change 24h")
            }

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _assetPriceColumWidth
                Layout.fillHeight: true
                h_align: Text.AlignRight
                sort_type: sort_by_price
                text: qsTr("Price")
            }

            Dex.ColumnHeader
            {
                Layout.preferredWidth: _assetProviderColumnWidth
                Layout.fillHeight: true
                h_align: Text.AlignHCenter
                text: qsTr("Source")
            }
        }
    }

    delegate: Rectangle
    {
        property color _idleColor: index % 2 === 1 ? Dex.CurrentTheme.listItemOddBackground : Dex.CurrentTheme.listItemEvenBackground
        property int   activation_progress: Dex.General.zhtlcActivationProgress(activation_status, ticker)

        width: list.width
        height: _assetRowHeight

        color: mouseArea.containsMouse ? Dex.CurrentTheme.listItemHoveredBackground : _idleColor

        RowLayout
        {
            anchors.fill: parent

            Item // Asset Column.
            {
                Layout.fillHeight: true
                Layout.preferredWidth: _assetNameColumnWidth
                Layout.leftMargin: 15

                Dex.DexImage {
                    id: assetImage
                    anchors.verticalCenter: parent.verticalCenter
                    source: Dex.General.coinIcon(ticker)
                    width: 30
                    height: 30

                    Dex.DexRectangle
                    {
                        anchors.centerIn: parent
                        anchors.fill: parent
                        radius: 15
                        enabled: Dex.General.isZhtlc(ticker) ? activation_progress < 100 : false
                        visible: enabled
                        opacity: .9
                        color: Dex.DexTheme.backgroundColor
                    }

                    Dex.DexLabel
                    {
                        anchors.centerIn: parent
                        anchors.fill: parent
                        enabled: Dex.General.isZhtlc(ticker) ? activation_progress < 100 : false
                        visible: enabled
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: activation_progress + "%"
                        font: Dex.DexTypo.head8
                        color: Dex.DexTheme.okColor
                    }
                }

                Dex.DexLabel
                {
                    id: assetNameLabel
                    anchors.top: assetImage.top
                    anchors.left: assetImage.right
                    anchors.leftMargin: 15
                    text: model.ticker
                }

                Dex.DexLabel
                {
                    id: typeTag
                    anchors.bottom: assetImage.bottom
                    anchors.left: assetImage.right
                    anchors.leftMargin: 15

                    text: model.type
                    font: Dex.DexTypo.overLine
                    opacity: .7
                    color: Dex.Style.getCoinColor(ticker)

                    Dex.DexLabel
                    {
                        enabled: Dex.General.isIDO(ticker)
                        visible: enabled
                        anchors.left: parent.right
                        anchors.leftMargin: 5

                        text: "IDO"
                        font: Dex.DexTypo.overLine
                        opacity: .7
                        color: Dex.DexTheme.warningColor
                    }
                }
            }

            Dex.DexLabel // Balance Column.
            {
                id: assetBalanceLabel
                Layout.fillHeight: true
                Layout.preferredWidth: _assetBalanceColumnWidth
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                font: Dex.DexTypo.body2
                text_value:
                {
                    if (Dex.General.isZhtlc(ticker))
                    {
                        if (activation_progress != 100)
                        {
                            return qsTr("Activating: ") + activation_progress + "%"
                        }
                    }
                    return parseFloat(balance).toFixed(8)
                }

                privacy: true
            }

            Dex.DexLabel // Fiat Balance
            {
                id: fiatBalanceLabel
                Layout.fillHeight: true
                Layout.preferredWidth: _fiatBalanceColumnWidth
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                font: Dex.DexTypo.body2
                text_value: Dex.General.formatFiat("", main_currency_balance, Dex.API.app.settings_pg.current_currency)
                privacy: true
            }

            Dex.DexLabel // Change 24h.
            {
                id: assetChange24hLabel
                Layout.fillHeight: true
                Layout.preferredWidth: _assetChange24hColumnWidth

                font: Dex.DexTypo.body2
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                text_value:
                {
                    const v = parseFloat(change_24h)
                    return v === 0 ? '-' : Dex.General.formatPercent(v)
                }
                color: Dex.DexTheme.getValueColor(change_24h)
            }

            Dex.DexLabel // Price Column.
            {
                id: price24hLabe
                Layout.fillHeight: true
                Layout.preferredWidth: _assetPriceColumWidth

                font: Dex.DexTypo.body2
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                text_value: Dex.General.formatFiat('', main_currency_price_for_one_unit,
                                                   Dex.API.app.settings_pg.current_currency, 6)
            }

            Item // Price Provider
            {
                Layout.fillHeight: true
                Layout.preferredWidth: _assetProviderColumnWidth

                Dex.DexImage {
                    id: priceProviderIcon
                    enabled: priceProvider !== "unknown"
                    visible: enabled
                    anchors.centerIn: parent
                    source: enabled ? Dex.General.providerIcon(priceProvider) : ""
                    width: 16
                    height: 16

                    Dex.DefaultMouseArea
                    {
                        id: priceProviderIconMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Dex.DexTooltip
                    {
                        contentItem: Dex.DefaultText
                        {
                           text: qsTr("Price provider is: %1").arg(DexString.capitalizeFirstLetter(priceProvider))
                           font: Dex.DexTypo.caption
                           padding: 5
                        }
                        visible: priceProviderIconMouseArea.containsMouse
                    }
                }
            }

            Dex.CoinMenu { id: contextMenu }
        }

        Dex.DefaultMouseArea
        {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked:
            {
                if (!can_change_ticker)
                    return
                if (mouse.button === Qt.RightButton)
                {
                    contextMenu.can_disable = Dex.General.canDisable(ticker)
                    contextMenu.popup()
                }
                else
                {
                    api_wallet_page.ticker = ticker
                    dashboard.switchPage(Dashboard.PageType.Wallet)
                }
            }

            onPressAndHold:
            {
                if (!can_change_ticker) return

                if (mouse.source === Qt.MouseEventNotSynthesized)
                    contextMenu.can_disable = Dex.General.canDisable(ticker)
                    contextMenu.popup()
            }
        }
    }
}
