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
import Dex.Themes 1.0 as Dex
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
        list_model_proxy.filter_minimum_date = min_date.selectedDate

        if(max_date.selectedDate < min_date.selectedDate)
            max_date.selectedDate = min_date.selectedDate

        list_model_proxy.filter_maximum_date = max_date.selectedDate
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
                DexLabel {
                    opacity: .4
                    text: qsTr("Filter") + " %1 / %2 <br> %3 %4 - %5"
                                                    .arg(combo_base.currentTicker)
                                                    .arg(combo_rel.currentTicker)
                                                    .arg(qsTr("Date"))
                                                    .arg(min_date.selectedDate.toLocaleDateString(Locale.ShortFormat, "yyyy.MM.dd"))
                                                    .arg(max_date.selectedDate.toLocaleDateString(Locale.ShortFormat, "yyyy.MM.dd"))
                }
                DexAppButton 
                {
                    anchors.right: parent.right
                    anchors.rightMargin: -5
                    anchors.bottom: parent.bottom
                    iconSource: _subOrdersRoot.displayFilter ? Qaterial.Icons.close : Qaterial.Icons.cogBox
                    iconSize: 14
                    opacity: containsMouse ? .7 : 1
                    width: 35
                    height: 25

                    DefaultTooltip
                    {
                        delay: 500
                        timeout: 5000
                        visible: parent.containsMouse
                        text: _subOrdersRoot.displayFilter ? qsTr("Close filtering options.") : qsTr("Open filtering options.")
                    }

                    onClicked: _subOrdersRoot.displayFilter = !_subOrdersRoot.displayFilter
                }
            }
        }

        Item
        {
            height: 2
            Layout.fillWidth: true
        }

        Item
        {
            id: main_order
            Layout.fillHeight: true
            Layout.fillWidth: true
            property bool is_history: false
            property var list_model_proxy: Constants.API.app.orders_mdl.orders_proxy_mdl
            Component.onCompleted: list_model_proxy.is_history = false

            List { id: order_list_view }

            DefaultRectangle
            {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                height: _subOrdersRoot.displayFilter ? parent.height : 60
                visible: height > 100
                radius: 18

                Column
                {
                    anchors.horizontalCenter: parent.horizontalCenter
                    leftPadding: 15 
                    rightPadding: 15
                    visible: parent.height > 250

                    DexLabel
                    {
                        text: qsTr("Filter settings")
                        topPadding: 10
                        leftPadding: 10
                        font: DexTypo.head6
                        opacity: .8
                    }

                    RowLayout
                    {
                        width: main_order.width - 30
                        height: 35
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        DefaultSweetComboBox
                        {
                            id: combo_base
                            Layout.fillWidth: true
                            model: Constants.API.app.portfolio_pg.global_cfg_mdl.all_proxy
                            onCurrentTickerChanged: applyTickerFilter()
                            height: 60
                            valueRole: "ticker"
                            textRole: 'ticker'
                        }
                        
                    }
                    RowLayout
                    {
                        width: main_order.width - 30
                        height: 35
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5

                        DefaultSweetComboBox
                        {
                            id: combo_rel
                            Layout.fillWidth: true
                            model: Constants.API.app.portfolio_pg.global_cfg_mdl.all_proxy//combo_base.model
                            onCurrentTickerChanged: applyTickerFilter()
                            height: 60
                            valueRole: "ticker"
                            textRole: 'ticker'
                        }
                    }

                    Row
                    {
                        width: main_order.width - 40
                        height: 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        DatePicker
                        {
                            id: min_date
                            width: parent.width * 0.45
                            titleText: qsTr("From")
                            minimumDate: default_min_date
                            maximumDate:  default_max_date
                            selectedDate: default_min_date
                            onAccepted: applyDateFilter()
                        }

                        Item { width: parent.width * 0.1; height: 1 }

                        DatePicker
                        {
                            id: max_date
                            width: parent.width * 0.45
                            titleText: qsTr("To")
                            minimumDate: default_min_date
                            maximumDate: default_max_date
                            selectedDate: default_max_date
                            onAccepted: applyDateFilter()
                        }
                    }
                    spacing: 10
                }

                Item
                {
                    anchors.bottom: parent.bottom
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 60
                    RowLayout
                    {
                        anchors.fill: parent
                        spacing: 15
                        CancelButton
                        {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            radius: 10
                            text: qsTr("Cancel")
                            onClicked: _subOrdersRoot.displayFilter = false
                        }

                        DefaultButton
                        {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            radius: 10
                            text: qsTr("Apply filter")
                            onClicked:
                            {
                                _subOrdersRoot.displayFilter = false;
                                _subOrdersRoot.applyFilter();
                                _subOrdersRoot.applyAllFiltering();
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
        Item
        {
            Layout.fillWidth: true
            Layout.preferredHeight: 15
            DexLabel // Title
            {
                text: order_list_view.count + " " + qsTr("Orders")
                anchors.horizontalCenter: parent.horizontalCenter
                y: -10
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
