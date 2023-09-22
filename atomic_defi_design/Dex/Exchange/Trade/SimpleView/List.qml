//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

import App 1.0

//! Project Imports
import "../../../Components"
import "../../../Constants" as Constants  //> Style
import "../Orders" as Orders
import "Main.js" as Main
import Dex.Themes 1.0 as Dex

DexListView
{
    id: order_list_view
    anchors.fill: parent
    model: API.app.orders_mdl.orders_proxy_mdl
    clip: true
    currentIndex: -1
    spacing: 5

    delegate: ClipRRect
    {
        property var details: model
        readonly property bool is_placed_order: !details ? false :
                               details.order_id !== ''

        property bool expanded: order_list_view.currentIndex === index

        width: order_list_view.width - 40
        x: 20
        height: expanded? colum_order.height + 25 : 70
        radius: 12

        DefaultRectangle
        {
            anchors.fill: parent
            radius: 10
        }

        DefaultMouseArea
        {
            id: order_mouse_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(order_list_view.currentIndex === index) {
                    order_list_view.currentIndex = -1
                }else {
                    order_list_view.currentIndex = index
                }
            }
        }

        Column
        {
            id: colum_order
            width: parent.width
            spacing: 5
            topPadding: 0
            RowLayout
            {
                width: parent.width
                height: 70
                spacing: 5
                Item
                {
                    Layout.preferredWidth: 40 
                    height: 30
                    BusyIndicator
                    {
                        width: 30
                        height: width
                        anchors.centerIn: parent
                        running: !isSwapDone(details.order_status) && Qt.platform.os != "osx"
                        DefaultText
                        {
                            anchors.centerIn: parent
                            font.pixelSize: getStatusFontSize(details.order_status)
                            color: !details ? "white" : getStatusColor(details.order_status)
                            text_value: !details ? "" :
                                        visible ? getStatusStep(details.order_status) : ''
                        }
                    }
                }

                Row
                {
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true
                    Layout.alignment: Label.AlignVCenter
                    spacing: 5
                    DefaultImage
                    {
                        id: base_icon
                        source: General.coinIcon(!details ? atomic_app_primary_coin :
                                                            details.base_coin?? atomic_app_primary_coin)
                        width: Constants.Style.textSize1
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DefaultText
                    {
                        id: base_amount
                        text_value: !details ? "" :
                                    General.formatCrypto("", details.base_amount, details.base_coin).replace(" ","<br>")
                        font: rel_amount.font
                        privacy: is_placed_order
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                Item
                {
                    Layout.preferredWidth: 40
                    Layout.fillWidth: true

                    SwapIcon
                    {
                        width: 30
                        height: 30
                        opacity: .6
                        anchors.centerIn: parent
                        top_arrow_ticker: !details ? atomic_app_primary_coin :
                                                     details.base_coin?? ""
                        bottom_arrow_ticker: !details ? atomic_app_primary_coin :
                                                        details.rel_coin?? ""
                    }
                }

                Row
                {
                    Layout.preferredWidth: 120
                    Layout.fillHeight: true
                    Layout.alignment: Label.AlignVCenter
                    spacing: 5
                    DefaultImage
                    {
                        id: rel_icon
                        source: General.coinIcon(!details ? atomic_app_primary_coin :
                                                            details.rel_coin?? atomic_app_secondary_coin)

                        width: base_icon.width
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    DefaultText
                    {
                        id: rel_amount
                        text_value: !details ? "" :
                                    General.formatCrypto("", details.rel_amount, details.rel_coin).replace(" ","<br>")
                        font: Qt.font({
                            pixelSize: 14,
                            letterSpacing: 0.4,
                            family: DexTypo.fontFamily,
                            weight: Font.Normal
                        })
                        anchors.verticalCenter: parent.verticalCenter
                        privacy: is_placed_order
                    }
                }

                Qaterial.ColorIcon
                {
                    Layout.alignment: Qt.AlignVCenter
                    color: Dex.CurrentTheme.foregroundColor
                    source:  expanded? Qaterial.Icons.chevronUp : Qaterial.Icons.chevronDown
                    iconSize: 14
                }
                Item
                {
                    Layout.preferredWidth: 10
                    Layout.fillHeight: true
                    opacity: .6
                }

            }

            RowLayout
            {
                visible: expanded
                width: parent.width-40
                anchors.horizontalCenter: parent.horizontalCenter
                height: 20
                opacity: .6
                DexLabel
                {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    verticalAlignment: Label.AlignVCenter
                    text: !details ? "" :
                                General.formatCrypto("", details.base_amount, details.base_coin)
                }
                DexLabel
                {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: !details ? "" :
                                General.formatCrypto("", details.rel_amount, details.rel_coin)
                }
            }

            RowLayout
            {
                visible: expanded
                width: parent.width-40
                anchors.horizontalCenter: parent.horizontalCenter
                height: 20
                opacity: .6
                DefaultText
                {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    verticalAlignment: Label.AlignVCenter
                    text: "%1 %2".arg(API.app.settings_pg.current_currency).arg(details.base_amount_current_currency)
                }
                DefaultText
                {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: "%1 %2".arg(API.app.settings_pg.current_currency).arg(details.rel_amount_current_currency)
                }
            }

            RowLayout
            {
                visible: expanded
                width: parent.width-40
                anchors.horizontalCenter: parent.horizontalCenter
                height: 20
                opacity: .6
                DexLabel
                {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    verticalAlignment: Label.AlignVCenter
                    text: !details ? "" : details.date?? ""
                }
                Item
                {
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true 
                    visible: !details || details.recoverable === undefined ? false : details.recoverable && details.order_status !== "refunding"
                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        spacing: 5
                        Qaterial.ColorIcon
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qaterial.Icons.alert
                            iconSize: 15
                            color: Qaterial.Colors.amber
                        }
                        DexLabel
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Refund "
                            color: Qaterial.Colors.amber
                        }
                    }
                    MouseArea
                    {
                        id: refund_hover
                        anchors.fill: parent
                        hoverEnabled: true 
                    }
                    DefaultTooltip
                    {
                        visible: (parent.visible && refund_hover.containsMouse) ?? false

                        contentItem: ColumnLayout
                        {
                            DefaultText {
                                text_value: qsTr("Funds are recoverable")
                                font.pixelSize: Constants.Style.textSizeSmall4
                            }
                        }
                    }
                }
            }
            RowLayout {
                visible: expanded
                width: parent.width-30
                anchors.horizontalCenter: parent.horizontalCenter
                height: 30
                opacity: .6
                Qaterial.OutlineButton {
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true 
                    bottomInset: 0
                    topInset: 0
                    outlinedColor: DexTheme.warningColor
                    visible: !main_order.is_history && details.cancellable
                    onClicked: { if(details) cancelOrder(details.order_id) }
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Qaterial.ColorIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qaterial.Icons.close
                            iconSize: 17
                            color: DexTheme.warningColor
                        }
                        DexLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Cancel "
                            color: DexTheme.warningColor
                        }
                    }
                }
                
                Qaterial.OutlineButton {
                    Layout.preferredWidth: 80
                    Layout.fillHeight: true 
                    bottomInset: 0
                    topInset: 0
                    outlinedColor: Qaterial.Colors.gray
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Qaterial.ColorIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qaterial.Icons.eye
                            iconSize: 15
                            color: Qaterial.Colors.gray
                        }
                        DexLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Show "
                            color: Qaterial.Colors.gray
                        }
                    }
                    onClicked: {
                        order_modal.open()
                        order_modal.item.details = details
                    }
                }
                Item {
                    Layout.fillWidth: true 
                    Layout.fillHeight: true 
                    
                }
            }
        }
        
    }
}
