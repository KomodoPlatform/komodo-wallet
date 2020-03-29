import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.0
import QtCharts 2.3

import "../Components"
import "../Constants"

// Portfolio
ColumnLayout {
    id: portfolio
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property int sort_by_name: 0
    readonly property int sort_by_ticker: 1
    readonly property int sort_by_value: 2
    readonly property int sort_by_balance: 3
    readonly property int sort_by_price: 4
    readonly property int sort_by_change: 5
    readonly property int sort_by_trend: 6

    property int current_sort: sort_by_value
    property bool highest_first: true

    function reset() {
        updatePortfolio()
    }

    function onOpened() {
        updatePortfolio()
    }

    function inCurrentPage() {
        return  dashboard.inCurrentPage() &&
                dashboard.current_page === General.idx_dashboard_portfolio
    }

    property var portfolio_coins: ([])

    function updatePortfolio() {
        portfolio_coins = API.get().get_portfolio_informations()

        update_timer.running = true
    }

    Timer {
        id: update_timer
        running: false
        repeat: true
        interval: 5000
        onTriggered: {
            if(inCurrentPage()) updatePortfolio()
        }
    }

    function getColor(data) {
        return data.rates === null || data.rates[API.get().fiat].percent_change_24h === 0 ? Style.colorWhite4 :
                data.rates[API.get().fiat].percent_change_24h > 0 ? Style.colorGreen : Style.colorRed
    }

    function updateChart(chart, historical) {
        chart.removeAllSeries()

        let i
        if(historical.length > 0) {
            // Fill chart
            let series = chart.createSeries(ChartView.SeriesTypeSpline, "Price", chart.axes[0], chart.axes[1]);

            series.style = Qt.DashDotLine
            series.color = Style.colorTheme1

            let min = 999999999
            let max = -999999999
            for(i = 0; i < historical.length; ++i) {
                let price = historical[i].price
                series.append(i / historical.length, historical[i].price)
                min = Math.min(min, price)
                max = Math.max(max, price)
            }

            chart.axes[1].min = min * 0.99
            chart.axes[1].max = max * 1.01
        }

        // Hide background grid
        for(i = 0; i < chart.axes.length; ++i)
            chart.axes[i].visible = false
    }

    // Top part
    Rectangle {
        color: "transparent"
        Layout.fillWidth: true
        height: 200

        ColumnLayout {
            anchors.centerIn: parent

            // Total Title
            DefaultText {
                Layout.topMargin: 50
                Layout.bottomMargin: 0
                Layout.alignment: Qt.AlignHCenter
                text: API.get().empty_string + (qsTr("TOTAL"))
                font.pixelSize: Style.textSize
                color: Style.colorWhite5
            }

            // Total Balance
            DefaultText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 30
                text: API.get().empty_string + (General.formatFiat("", API.get().balance_fiat_all, API.get().fiat))
                font.pixelSize: Style.textSize4
            }
        }


        // Add button
        PlusButton {
            id: add_coin_button

            width: 50

            mouse_area.onClicked: enable_coin_modal.prepareAndOpen()

            anchors.right: parent.right
            anchors.rightMargin: parent.height * 0.5 - width * 0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        // Search input
        TextField {
            id: input_coin_filter

            function reset() {
                visible = false
                text = ""
            }

            anchors.horizontalCenter: add_coin_button.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10

            placeholderText: API.get().empty_string + (qsTr("Search"))
            selectByMouse: true

            width: 120
        }
    }


    // List header
    Rectangle {
        color: "transparent"

        Layout.alignment: Qt.AlignTop

        Layout.fillWidth: true

        height: 50

        // Line
        HorizontalLine {
            width: parent.width
            color: Style.colorWhite5
            anchors.top: parent.top
        }

        // Coin
        ColumnHeader {
            id: coin_header
            icon_at_left: true
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter

            text: API.get().empty_string + (qsTr("Coin"))
            sort_type: sort_by_name
        }

        // Balance
        ColumnHeader {
            id: balance_header
            icon_at_left: true
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.3
            anchors.verticalCenter: parent.verticalCenter

            text: API.get().empty_string + (qsTr("Balance"))
            sort_type: sort_by_value
        }

        // Change 24h
        ColumnHeader {
            id: change_24h_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.27
            anchors.verticalCenter: parent.verticalCenter

            text: API.get().empty_string + (qsTr("Change 24h"))
            sort_type: sort_by_change
        }

        // 7-day Trend
        ColumnHeader {
            id: trend_7d_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.15
            anchors.verticalCenter: parent.verticalCenter

            text: API.get().empty_string + (qsTr("Trend 7d"))
            sort_type: sort_by_trend
        }

        // Price
        ColumnHeader {
            id: price_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: coin_header.anchors.leftMargin
            anchors.verticalCenter: parent.verticalCenter

            text: API.get().empty_string + (qsTr("Price"))
            sort_type: sort_by_price
        }

        // Line
        HorizontalLine {
            id: bottom_separator
            width: parent.width
            color: Style.colorWhite5
            anchors.bottom: parent.bottom
        }
    }

    // Transactions or loading
    Rectangle {
        id: loading
        color: "transparent"
        visible: portfolio_coins.length === 0
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            DefaultText {
                text: API.get().empty_string + (qsTr("Loading"))
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.textSize2
            }

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // List
    ListView {
        id: list
        visible: portfolio_coins.length > 0
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.fillHeight: true
        ScrollBar.vertical: ScrollBar {}

        model: General.filterCoins(portfolio_coins, input_coin_filter.text)
                .sort((a, b) => {
            const order = highest_first ? 1 : -1
            let val_a
            let val_b
            let result
            switch(current_sort) {
                case sort_by_name:      return (b.name.toUpperCase() > a.name.toUpperCase() ? -1 : 1) * order
                case sort_by_ticker:    return (b.ticker > a.ticker ? -1 : 1) * order
                case sort_by_value:
                    val_a = parseFloat(a.balance_fiat)
                    val_b = parseFloat(b.balance_fiat)
                    result = val_b - val_a

                    if(result === 0) {
                        let val_a = parseFloat(a.balance)
                        let val_b = parseFloat(b.balance)
                        result = val_b - val_a
                    }

                    return result * order
                case sort_by_price:       return (parseFloat(b.price) - parseFloat(a.price)) * order
                case sort_by_balance:     return (parseFloat(b.balance) - parseFloat(a.balance)) * order
                case sort_by_trend:       return (parseFloat(b.price) - parseFloat(a.price)) * order
                case sort_by_change:
                    val_a = a.rates === null ? -9999999 : a.rates[API.get().fiat].percent_change_24h
                    val_b = b.rates === null ? -9999999 : b.rates[API.get().fiat].percent_change_24h

                    return (val_b - val_a) * order
            }
        })

        clip: true

        delegate: Rectangle {
            property bool hovered: false

            color: hovered ? Style.colorTheme5 : index % 2 == 0 ? Style.colorTheme6 : Style.colorTheme7
            width: portfolio.width
            height: 50

            // Click area
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onHoveredChanged: hovered = containsMouse
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    if (mouse.button === Qt.RightButton) context_menu.popup()
                    else {
                        API.get().current_coin_info.ticker = model.modelData.ticker
                        dashboard.current_page = General.idx_dashboard_wallet
                    }
                }
                onPressAndHold: {
                    if (mouse.source === Qt.MouseEventNotSynthesized) context_menu.popup()
                }
            }

            // Right click menu
            Menu {
                id: context_menu
                Action {
                    text: API.get().empty_string + (qsTr("Disable %1", "TICKER").arg(model.modelData.ticker))
                    onTriggered: API.get().disable_coins([model.modelData.ticker])
                    enabled: General.canDisable(model.modelData.ticker)
                }
            }

            // Icon
            Image {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: coin_header.anchors.leftMargin

                source: General.image_path + "coins/" + model.modelData.ticker.toLowerCase() + ".png"
                fillMode: Image.PreserveAspectFit
                width: Style.textSize2
                anchors.verticalCenter: parent.verticalCenter
            }

            // Name
            DefaultText {
                anchors.left: icon.right
                anchors.leftMargin: 10

                text: API.get().empty_string + (model.modelData.name)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Balance
            DefaultText {
                id: balance_value
                anchors.left: parent.left
                anchors.leftMargin: balance_header.anchors.leftMargin

                text: API.get().empty_string + (model.modelData.balance)
                color: Style.colorWhite4
                anchors.verticalCenter: parent.verticalCenter
            }

            // Ticker
            DefaultText {
                id: balance_ticker
                anchors.left: balance_value.right
                anchors.leftMargin: 5
                anchors.baseline: balance_value.baseline

                text: API.get().empty_string + (model.modelData.ticker)
                color: Style.colorWhite6
                font.pixelSize: Style.textSize * 0.9
            }

            // Value
            DefaultText {
                anchors.left: balance_ticker.right
                anchors.leftMargin: 10

                text: API.get().empty_string + ("(" + General.formatFiat('', model.modelData.balance_fiat, API.get().fiat) + ")")
                color: Style.colorWhite5
                anchors.verticalCenter: parent.verticalCenter
            }

            // Change 24h
            DefaultText {
                anchors.right: parent.right
                anchors.rightMargin: change_24h_header.anchors.rightMargin

                text: API.get().empty_string + (model.modelData.rates === null ? '-' :
                        ((model.modelData.rates[API.get().fiat].percent_change_24h > 0 ? '+' : '') +
                         (model.modelData.rates[API.get().fiat].percent_change_24h + '%')))
                color: getColor(model.modelData)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Price
            DefaultText {
                anchors.right: parent.right
                anchors.rightMargin: price_header.anchors.rightMargin

                text: API.get().empty_string + (General.formatFiat('', model.modelData.price, API.get().fiat))
                color: Style.colorWhite6
                anchors.verticalCenter: parent.verticalCenter
            }

            // 7d Trend
            ChartView {
                id: chart
                width: 200
                height: 100
                antialiasing: true
                anchors.right: parent.right
                anchors.rightMargin: trend_7d_header.anchors.rightMargin - width * 0.4
                anchors.verticalCenter: parent.verticalCenter
                legend.visible: false

                Component.onCompleted: updateChart(chart, model.modelData.historical)

                backgroundColor: "transparent"
            }
        }
    }
}








/*##^##
Designer {
    D{i:0;autoSize:true;height:600;width:1200}
}
##^##*/
