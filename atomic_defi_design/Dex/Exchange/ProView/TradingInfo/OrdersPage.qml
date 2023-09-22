import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1

import Qaterial 1.0 as Qaterial

import App 1.0
import "../../../Components"
import "../../../Constants"
import "../../.."
import Dex.Themes 1.0 as Dex

Item {
    id: root

    readonly property date default_min_date: new Date("2019-01-01")
    readonly property date default_max_date: new Date(new Date().setDate(new Date().getDate() + 30))

    property var list_model: API.app.orders_mdl
    property var list_model_proxy: API.app.orders_mdl.orders_proxy_mdl
    property int page_index

    property alias title: order_list.title
    property alias items: order_list.items

    property bool is_history: false

    function update()
    {
        reset()
        if (combo_base.currentTicker !== "All" | combo_rel.currentTicker !== "All") {
            buttonDelay.start()
        }
    }

    function reset() {
        list_model_proxy.is_history = !is_history
        applyFilter()
        list_model_proxy.apply_all_filtering()
        list_model_proxy.is_history = is_history
    }

    Component.onDestruction: reset()

    Timer {
        id: buttonDelay
        interval: 200
        onTriggered: {
            applyFilter()
            list_model_proxy.apply_all_filtering()
        }
    }

    function applyDateFilter() {
        list_model_proxy.filter_minimum_date = min_date.selectedDate

        if (max_date.selectedDate < min_date.selectedDate)
            max_date.selectedDate = min_date.selectedDate

        list_model_proxy.filter_maximum_date = max_date.selectedDate
    }

    function applyTickerFilter() {
        list_model_proxy.set_coin_filter(combo_base.currentValue + "/" + combo_rel.currentValue)
    }

    function applyTickerFilter2(ticker1, ticker2) {
        list_model_proxy.set_coin_filter(ticker1 + "/" + ticker2)
    }

    function applyFilter() {
        applyDateFilter()
        applyTickerFilter2(combo_base.currentTicker, combo_rel.currentTicker)
    }

    Component.onCompleted: {
        list_model_proxy.is_history = root.is_history
        applyFilter()
        list_model_proxy.apply_all_filtering()
    }

    ColumnLayout
    {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent
        anchors.margins: 20
        anchors.bottomMargin: is_history ? 0 : 10
        spacing: 8

        RowLayout
        {
            spacing: 8
            DefaultButton
            {
                Layout.preferredHeight: 29
                radius: 7
                label.font: DexTypo.body2
                text: qsTr("Filter")
                iconSource: Qaterial.Icons.filter
                onClicked: settings.visible = !settings.visible
            }

            DefaultButton
            {
                visible: settings.visible && root.is_history
                Layout.preferredHeight: 29
                enabled: list_model_proxy.can_i_apply_filtering
                radius: 7
                label.font: DexTypo.body2
                text: qsTr("Apply Filter")
                onClicked: list_model_proxy.apply_all_filtering()
            }

            DefaultText
            {
                color: Dex.CurrentTheme.foregroundColor2
                font: DexTypo.caption
                visible: !settings.visible
                text: qsTr("Filter") + ": %1 / %2 <br> %3: %4 - %5".arg(combo_base.currentTicker).arg(combo_rel.currentTicker).arg(qsTr("Date")).arg(min_date.selectedDate.toLocaleDateString(Locale.ShortFormat, "yyyy-MM-dd")).arg(max_date.selectedDate.toLocaleDateString(Locale.ShortFormat, "yyyy-MM-dd"))
            }

            Item
            {
                Layout.fillWidth: true
            }

            DefaultButton
            {
                visible: root.is_history
                Layout.preferredHeight: 29
                radius: 7
                label.font: DexTypo.body2
                text: qsTr("Export CSV")
                onClicked:
                {
                    export_csv_dialog.folder = General.os_file_prefix + API.app.settings_pg.get_export_folder()
                    export_csv_dialog.open()
                }
            }

            DefaultButton
            {
                visible: !root.is_history && list_model.length > 0
                enabled: list_model.length > 0
                Layout.preferredHeight: 29
                radius: 7
                label.font: DexTypo.body2
                text: qsTr("Cancel All")
                iconSource: Qaterial.Icons.close
                onClicked: API.app.trading_pg.orders.cancel_order(list_model_proxy.get_filtered_ids())
            }
        }

        ColumnLayout
        {
            id: settings
            visible: false
            spacing: 8

            // Coin Selection comboboxes
            RowLayout
            {
                Layout.alignment: Qt.AlignHCenter

                DefaultSweetComboBox
                {
                    id: combo_base
                    Layout.preferredWidth: parent.width / 2 - swapCoinFilterIcon.width
                    model: API.app.portfolio_pg.global_cfg_mdl.all_proxy
                    valueRole: "ticker"
                    textRole: 'ticker'
                    mainBackgroundColor: Dex.CurrentTheme.backgroundColor
                    popupBackgroundColor: Dex.CurrentTheme.backgroundColor
                    onCurrentTickerChanged: applyFilter()
                }

                Qaterial.ColorIcon
                {
                    id: swapCoinFilterIcon
                    source: Qaterial.Icons.swapHorizontal
                    color: Dex.CurrentTheme.foregroundColor

                    DefaultMouseArea
                    {
                        id: swap_button
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked:
                        {
                            const base_idx = combo_base.currentTicker
                            combo_base.currentTicker = combo_rel.currentTicker
                            combo_rel.currentTicker = base_idx
                        }
                    }
                }

                DefaultSweetComboBox
                {
                    id: combo_rel
                    Layout.fillWidth: true
                    model: API.app.portfolio_pg.global_cfg_mdl.all_proxy
                    valueRole: "ticker"
                    textRole: 'ticker'
                    mainBackgroundColor: Dex.CurrentTheme.backgroundColor
                    popupBackgroundColor: Dex.CurrentTheme.backgroundColor
                    onCurrentTickerChanged: applyFilter()
                }
            }

            Row
            {
                Layout.fillWidth: true
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

        OrderList
        {
            id: order_list
            items: list_model
            is_history: root.is_history
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    ModalLoader
    {
        id: order_modal
        sourceComponent: OrderModal {}
    }

    FileDialog
    {
        id: export_csv_dialog

        title: qsTr("Please choose the CSV export name and location")
        fileMode: FileDialog.SaveFile

        defaultSuffix: "csv"
        nameFilters: ["CSV files (*.csv)", "All files (*)"]

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
