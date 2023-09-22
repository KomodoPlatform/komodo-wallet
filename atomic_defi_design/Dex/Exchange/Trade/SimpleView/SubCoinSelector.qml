//! Qt Imports
import QtQuick 2.15          //> Item
import QtQuick.Layouts 1.15  //> RowLayout
import QtQuick.Controls 2.15 //> ItemDelegate

// 3rdParty
import Qaterial 1.0 as Qaterial

import App 1.0

//! Project Imports
import "../../../Components" //> MultipageModal
import "../../../Constants" as Constants //> API
import Dex.Themes 1.0 as Dex

DexListView
{
    id: _listCoinView
    model: Constants.API.app.trading_pg.market_pairs_mdl.left_selection_box
    signal tickerSelected(var ticker)

    property real _rowWidth: width
    property real _rowHeight: 40
    property real _tokenColumnWidth: 150
    property real _balanceColumnWidth: 120
    property real _fiatColumnWidth: 120

    headerPositioning: ListView.OverlayHeader
    reuseItems: true
    cacheBuffer: 40
    clip: true

    header: DexRectangle
    {
        id: header_row
        width: _rowWidth
        height: _rowHeight
        z: 2
        radius: 0
        border.width: 0
        color: Dex.CurrentTheme.floatingBackgroundColor

        RowLayout
        {
            anchors.margins: 5
            anchors.fill: parent
            anchors.verticalCenter: parent.verticalCenter

            DexLabel             // "Token" Header
            {
                property bool asc: true

                Layout.preferredWidth: _tokenColumnWidth
                horizontalAlignment: Text.AlignLeft

                text_value: qsTr("Token")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold

                DexMouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked:
                    {
                        parent.asc = !parent.asc 
                        _listCoinView.model.sort_by_name(parent.asc)
                    }
                }
            }

            DexLabel             // "Balance" Header
            {
                property bool asc: true

                Layout.preferredWidth: _balanceColumnWidth
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("Balance")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold

                DexMouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked:
                    {
                        parent.asc = !parent.asc 
                        _listCoinView.model.sort_by_currency_balance(parent.asc)
                    }
                }
            }

            DexLabel             // Fiat Balance Header
            {
                property bool asc: true

                Layout.preferredWidth: _fiatColumnWidth
                horizontalAlignment: Text.AlignRight

                text_value: qsTr("Balance Fiat")
                font.family: Constants.Style.font_family
                font.bold: true
                font.pixelSize: 12
                font.weight: Font.Bold

                DexMouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked:
                    {
                        parent.asc = !parent.asc 
                        _listCoinView.model.sort_by_currency_balance(parent.asc)
                    }
                }
            }
        }
    }

    delegate: DexRectangle
    {
        width: _rowWidth
        height: _rowHeight
        radius: 0
        border.width: 0
        colorAnimation: false
        color: mouse_area.containsMouse ? Dex.CurrentTheme.listItemHoveredBackground : 'transparent'

        DexMouseArea
        {
            id: mouse_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tickerSelected(model.ticker)
        }

        HorizontalLine { width: parent.width; opacity: .5 }

        RowLayout
        {
            anchors.fill: parent

            RowLayout {
                property int _iconWidth: 24
                Layout.preferredWidth: _tokenColumnWidth

                DexImage
                {
                    id: _coinIcon
                    Layout.preferredWidth: parent._iconWidth
                    Layout.preferredHeight: 24
                    source: General.coinIcon(model.ticker)
                }

                DexLabel
                {
                    Layout.preferredWidth: _tokenColumnWidth - parent._iconWidth
                    text_value: model.ticker
                    font.pixelSize: 14
                    wrapMode: Text.NoWrap
                }
            }

            DexLabel
            {
                Layout.preferredWidth: _balanceColumnWidth
                horizontalAlignment: Text.AlignRight
                text_value: model.balance.replace(" ","")
                font.pixelSize: 14
                wrapMode: Text.NoWrap
            }

            DexLabel
            {
                Layout.preferredWidth: _fiatColumnWidth
                Layout.rightMargin: 8
                horizontalAlignment: Text.AlignRight
                text_value: "%1".arg(General.getFiatText(model.balance, model.ticker, false))
                font.pixelSize: 14
                wrapMode: Text.NoWrap
            }
        }
    }

    DexLabel
    {
        anchors.centerIn: parent
        text: qsTr('No Selectable coin.')
        visible: parent.count === 0
    }
}
