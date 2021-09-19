//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

//! Project Imports
import "../../../Components"
import "../../../Constants" as Constants  //> Style
import "../Orders" as Orders
import "Main.js" as Main

import App 1.0

Item
{
    id: _subOrdersRoot

    readonly property date default_min_date: new Date("2019-01-01")
    readonly property date default_max_date: new Date(new Date().setDate(new Date().getDate() + 30))
    property var list_model_proxy: Constants.API.app.orders_mdl.orders_proxy_mdl
    property bool displayFilter: false

    anchors.fill: parent

    Component.onDestruction: reset()

    function update()
    {
        reset()   
    }

    function reset()
    {
        list_model_proxy.is_history = true
        applyFilter()
        applyAllFiltering()
        list_model_proxy.is_history = false
    }
    
    function applyTickerFilter() {  
        applyTickerFilter2(combo_base.currentTicker, combo_rel.currentTicker)
    }

    function applyTickerFilter2(ticker1, ticker2) {
        list_model_proxy.set_coin_filter(ticker1 + "/" + ticker2)
    }

    function applyDateFilter() {
        list_model_proxy.filter_minimum_date = min_date.date

        if(max_date.date < min_date.date)
            max_date.date = min_date.date

        list_model_proxy.filter_maximum_date = max_date.date
    }

    function applyFilter() {
        applyTickerFilter()
        applyDateFilter()
    }

    function applyAllFiltering() {
        list_model_proxy.apply_all_filtering()
    }



    ColumnLayout // Orders Content
    {
        height: parent.height
        width: parent.width
        spacing: 20

        Column // Header
        {
            leftPadding: 20
            topPadding: 20

            DefaultText // Title
            {
                text: qsTr("Orders")
                font: DexTypo.head6
                opacity: .8
            }

            DexLabel // Description
            {
                width: _subOrdersRoot.width - 40
                anchors.topMargin: 12
                font.pixelSize: Constants.Style.textSizeSmall4
                //text: _filterApplied? "" : qsTr("Finished orders")
                DexLabel {
                    opacity: .4
                    text: qsTr("Filter") + " %1 / %2 <br> %3 %4 - %5"
                                                    .arg(combo_base.currentTicker)
                                                    .arg(combo_rel.currentTicker)
                                                    .arg(qsTr("Date"))
                                                    .arg(min_date.date.toLocaleDateString(Locale.ShortFormat, "yyyy.MM.dd"))
                                                    .arg(max_date.date.toLocaleDateString(Locale.ShortFormat, "yyyy.MM.dd"))    
                }
                DexAppButton 
                {
                    anchors.right: parent.right
                    anchors.rightMargin: -5
                    anchors.bottom: parent.bottom
                    iconSource: _subOrdersRoot.displayFilter ? Qaterial.Icons.close : Qaterial.Icons.cogBox
                    iconSize: 14
                    backgroundColor: DexTheme.iconButtonColor
                    foregroundColor: DexTheme.iconButtonForegroundColor
                    opacity: containsMouse ? .7 : 1
                    width: 35
                    height: 25
                    ToolTip.delay: 500
                    ToolTip.timeout: 5000
                    ToolTip.visible: containsMouse
                    ToolTip.text: _subOrdersRoot.displayFilter ? qsTr("Close filtering options.") : qsTr("Open filtering options.")
                    onClicked: _subOrdersRoot.displayFilter = !_subOrdersRoot.displayFilter
                }
            }
        }

        Item
        {
            height: 2
            Layout.fillWidth: true
        }

        Item {
            id: main_order
            Layout.fillHeight: true
            Layout.fillWidth: true
            property bool is_history: false
            property var list_model_proxy: Constants.API.app.orders_mdl.orders_proxy_mdl
            Component.onCompleted: list_model_proxy.is_history = false

            List { id: order_list_view }

            DexRectangle {
                anchors.fill: parent 
                color: DexTheme.portfolioPieGradient ? 'transparent' : DexTheme.dexBoxBackgroundColor
                opacity: .8
                visible: _subOrdersRoot.displayFilter
                border.width: 0
            }

            DexRectangle {
                width: parent.width
                height: _subOrdersRoot.displayFilter ? parent.height : 60
                visible: height > 100
                sizeAnimation: true
                color: DexTheme.portfolioPieGradient ? DexTheme.contentColorTopBold : DexTheme.dexBoxBackgroundColor
                radius: 0
                y: -20
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    leftPadding: 15 
                    rightPadding: 15
                    visible: parent.height > 250
                    DexLabel {
                        text: qsTr("Filter settings")
                        topPadding: 10
                        leftPadding: 10
                        font: DexTypo.head6
                        opacity: .8
                    }
                    RowLayout {
                        width: main_order.width - 30
                        height: 35
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0
                        DefaultSweetComboBox {
                            id: combo_base
                            Layout.fillWidth: true
                            model: Constants.API.app.portfolio_pg.global_cfg_mdl.all_proxy
                            onCurrentTickerChanged: applyTickerFilter()
                            height: 60
                            valueRole: "ticker"
                            textRole: 'ticker'
                        }
                        
                    }
                    RowLayout {
                        width: main_order.width - 30
                        height: 35
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        DefaultSweetComboBox {
                            id: combo_rel
                            Layout.fillWidth: true
                            model: Constants.API.app.portfolio_pg.global_cfg_mdl.all_proxy//combo_base.model
                            onCurrentTickerChanged: applyTickerFilter()
                            height: 60
                            valueRole: "ticker"
                            textRole: 'ticker'

                        }
                        
                    }

                    RowLayout {
                        width: main_order.width - 40
                        height: 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        Qaterial.TextFieldDatePicker {
                            id: min_date
                            title: qsTr("From")
                            from: default_min_date
                            to: default_max_date
                            date: default_min_date
                            onAccepted: applyDateFilter()
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            opacity: .8
                            color: DexTheme.foregroundColor
                            backgroundColor: DexTheme.portfolioPieGradient ? '#FFFFFF' : 'transparent'
                        }

                        Qaterial.TextFieldDatePicker {
                            id: max_date
                            enabled: min_date.enabled
                            title: qsTr("To")
                            from: min_date.date
                            to: default_max_date
                            date: default_max_date
                            onAccepted: applyDateFilter()
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            rightInset: 0
                            opacity: .8
                            color: DexTheme.foregroundColor
                            backgroundColor: DexTheme.portfolioPieGradient ? '#FFFFFF' : 'transparent'
                        }
                        
                    }

                    spacing: 10

                }

                Item {
                    anchors.bottom: parent.bottom
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 60
                    RowLayout {
                        anchors.fill: parent
                        spacing: 15
                        DexAppButton {
                            Layout.fillWidth: true
                            radius: 10
                            Layout.alignment: Qt.AlignVCenter
                            text: qsTr("Cancel")
                            onClicked: {
                                _subOrdersRoot.displayFilter = false
                            }
                        }
                        DexAppOutlineButton {
                            id: applyButton
                            height: 35
                            Layout.fillWidth: true
                            radius: 10
                            Layout.alignment: Qt.AlignVCenter
                            opacity: containsMouse ? .7 : 1
                            text: qsTr("Apply filter")
                            onClicked: {
                                _subOrdersRoot.displayFilter = false
                                _subOrdersRoot.applyFilter()
                                _subOrdersRoot.applyAllFiltering()
                            }
                        }
                    }
                }
            }
        }

        Item
        {
            height: 2
            Layout.fillWidth: true
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 15
            DexLabel // Title
            {
                text: order_list_view.count + " " + qsTr("Orders")
                anchors.horizontalCenter: parent.horizontalCenter
                y: -10
                //anchors.verticalCenterOffset: -4
            }
        }
        
    }

    DexLabel
    {
        visible: !_subOrdersRoot.displayFilter && order_list_view.count === 0
        anchors.centerIn: parent
        text: qsTr("No results found")
    }
}
