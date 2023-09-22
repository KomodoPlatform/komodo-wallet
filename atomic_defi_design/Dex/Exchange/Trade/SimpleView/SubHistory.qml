//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1

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
    id: _subHistoryRoot

    readonly property date default_min_date: new Date("2019-01-01")
    readonly property date default_max_date: new Date(new Date().setDate(new Date().getDate() + 30))
    property var list_model_proxy: API.app.orders_mdl.orders_proxy_mdl
    property bool displayFilter: false

    function update() {
        reset()
        if(combo_base.currentTicker !== "All" | combo_rel.currentTicker !== "All") {
            buttonDelay.start()
        }
    }

    function reset() {
        list_model_proxy.is_history = false
        applyFilter()
        applyAllFiltering()
        list_model_proxy.is_history = true

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

    anchors.fill: parent

    Component.onDestruction: reset()

    Timer {
        id: buttonDelay
        interval: 200
        running: true
        onTriggered: applyButton.clicked()
    }

    ColumnLayout // History
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
                text: qsTr("History")
                font: DexTypo.head6
                opacity: .8
            }

            DexLabel // Description
            {
                width: _subHistoryRoot.width - 40
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
                    iconSource: _subHistoryRoot.displayFilter ? Qaterial.Icons.close : Qaterial.Icons.cogBox
                    iconSize: 14
                    opacity: containsMouse ? .7 : 1
                    width: 35
                    height: 25

                    DefaultTooltip
                    {
                        delay: 500
                        timeout: 5000
                        visible: parent.containsMouse
                        text: _subHistoryRoot.displayFilter ? qsTr("Close filtering options.") : qsTr("Open filtering options.")
                    }

                    onClicked: _subHistoryRoot.displayFilter = !_subHistoryRoot.displayFilter
                }
            }
        }

        Item { height: 2; Layout.fillWidth: true }

        Item {
            id: main_order
            Layout.fillHeight: true
            Layout.fillWidth: true
            property bool is_history: true

            Component.onCompleted:  _subHistoryRoot.list_model_proxy.is_history = is_history

            List { id: order_list_view }

            DefaultRectangle
            {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                height: _subHistoryRoot.displayFilter ? parent.height : 60
                visible: height > 100
                radius: 18

                Column
                {
                    anchors.horizontalCenter: parent.horizontalCenter
                    leftPadding: 15
                    rightPadding: 15
                    visible: parent.height > 250

                    DefaultText
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

                    spacing: 10

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
                            onClicked: _subHistoryRoot.displayFilter = false
                        }

                        DefaultButton
                        {
                            id: applyButton
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            radius: 10
                            text: qsTr("Apply filter")
                            onClicked:
                            {
                                _subHistoryRoot.displayFilter = false
                                _subHistoryRoot.applyFilter()
                                _subHistoryRoot.applyAllFiltering()
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
            Layout.preferredHeight: 30
            Item
            {
                width: parent.width
                height: 50
                y: -20
                DefaultComboBox
                {
                    readonly property int item_count: API.app.orders_mdl.limit_nb_elements
                    readonly property var options: [5, 10, 25, 50, 100, 200]
                    anchors.verticalCenter: parent.verticalCenter
                    height: 35
                    width: 80
                    x: 15
                    model: options
                    currentIndex: options.indexOf(item_count)
                    onCurrentValueChanged: API.app.orders_mdl.limit_nb_elements = currentValue
                }
                DexAppButton {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: qsTr("Export")
                    height: 35
                    anchors.rightMargin: 15
                    onClicked: {
                         export_csv_dialog.folder = General.os_file_prefix + API.app.settings_pg.get_export_folder()
                         export_csv_dialog.open()
                    }
                }
            }

        }
        FileDialog {
            id: export_csv_dialog

            title: qsTr("Please choose the CSV export name and location")
            fileMode: FileDialog.SaveFile

            defaultSuffix: "csv"
            nameFilters: [ "CSV files (*.csv)", "All files (*)" ]

            onAccepted: {
                const path = currentFile.toString()

                // Export
                console.log("Exporting to CSV: " + path)
                API.app.exporter_service.export_swaps_history_to_csv(path.replace(General.os_file_prefix, ""))

                // Open the save folder
                const folder_path = path.substring(0, path.lastIndexOf("/"))
                Qt.openUrlExternally(folder_path)
            }
            onRejected: {
                console.log("CSV export cancelled")
            }
        }

    }

    DexLabel
    {
        visible: !_subHistoryRoot.displayFilter && order_list_view.count === 0
        anchors.centerIn: parent
        text: qsTr("No results found")
    }
}
