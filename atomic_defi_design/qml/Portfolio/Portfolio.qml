import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

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
    readonly property int sort_by_value: 1
    readonly property int sort_by_change: 3
    readonly property int sort_by_trend: 4
    readonly property int sort_by_price: 5

    property int current_sort: sort_by_value
    property bool ascending: false

    function applyCurrentSort() {
        // Apply the sort
        switch(current_sort) {
            case sort_by_name: portfolio_coins.sort_by_name(ascending); break
            case sort_by_value: portfolio_coins.sort_by_currency_balance(ascending); break
            case sort_by_price: portfolio_coins.sort_by_currency_unit(ascending); break
            case sort_by_trend:
            case sort_by_change: portfolio_coins.sort_by_change_last24h(ascending); break
        }
    }

    function reset() {
        input_coin_filter.reset()
    }

    function onOpened() {
        // Reset the coin name filter
        input_coin_filter.reset()
    }

    function updateChart(chart, historical, color) {
        chart.removeAllSeries()

        let i
        if(historical.length > 0) {
            // Fill chart
            let series = chart.createSeries(ChartView.SeriesTypeSpline, "Price", chart.axes[0], chart.axes[1]);

            series.style = Qt.SolidLine
            series.color = color

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
    Item {
        Layout.fillWidth: true
        height: 200

        ColumnLayout {
            id: top_layout
            anchors.centerIn: parent

            // Total Title
            DefaultText {
                Layout.topMargin: 50
                Layout.bottomMargin: 0
                Layout.alignment: Qt.AlignHCenter
                text_value: qsTr("TOTAL")
                font.pixelSize: Style.textSize
                color: Qt.lighter(Style.colorWhite5, currency_change_button.containsMouse ? Style.hoverLightMultiplier : 1.0)
            }

            // Total Balance
            DefaultText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 30
                text_value: General.formatFiat("", API.app.portfolio_pg.balance_fiat_all, API.app.settings_pg.current_currency)
                font.pixelSize: Style.textSize4
                color: Qt.lighter(Style.colorWhite4, currency_change_button.containsMouse ? Style.hoverLightMultiplier : 1.0)
                privacy: true
            }
        }

        DefaultMouseArea {
            id: currency_change_button

            anchors.fill: top_layout

            hoverEnabled: true
            onClicked: {
                const current_fiat = API.app.settings_pg.current_currency
                const available_fiats = API.app.settings_pg.get_available_currencies()
                const current_index = available_fiats.indexOf(current_fiat)
                const next_index = (current_index + 1) % available_fiats.length
                const next_fiat = available_fiats[next_index]
                API.app.settings_pg.current_currency = next_fiat
            }
        }

        // Add button
        PlusButton {
            id: add_coin_button
            onClicked: enable_coin_modal.prepareAndOpen()

            anchors.right: parent.right
            anchors.rightMargin: parent.height * 0.5 - width * 0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        // Search input
        DefaultTextField {
            id: input_coin_filter

            function reset() {
                if(text === "") resetCoinFilter()
                else text = ""

                //applyCurrentSort()
            }

            anchors.horizontalCenter: add_coin_button.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10

            placeholderText: qsTr("Search")

            onTextChanged: {
                portfolio_coins.setFilterFixedString(text)
            }

            width: 120
        }
    }


    // List header
    Item {
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

            text: qsTr("Asset")
            sort_type: sort_by_name
        }

        // Balance
        ColumnHeader {
            id: balance_header
            icon_at_left: true
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.265
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Balance")
            sort_type: sort_by_value
        }

        // Change 24h
        ColumnHeader {
            id: change_24h_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.37
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Change 24h")
            sort_type: sort_by_change
        }

        // 7-day Trend
        ColumnHeader {
            id: trend_7d_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Trend 7d")
            sort_type: sort_by_trend
        }

        // Price
        ColumnHeader {
            id: price_header
            icon_at_left: false
            anchors.right: parent.right
            anchors.rightMargin: coin_header.anchors.leftMargin
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Price")
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

    // List
    DefaultListView {
        id: list
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.fillHeight: true

        model: portfolio_coins

        delegate: AnimatedRectangle {
            color: Qt.lighter(mouse_area.containsMouse ? Style.colorTheme5 : index % 2 == 0 ? Style.colorTheme6 : Style.colorTheme7, mouse_area.containsMouse ? Style.hoverLightMultiplier : 1.0)
            width: portfolio.width
            height: 50

            AnimatedRectangle {
                id: main_color
                color: Style.getCoinColor(ticker)
                width: 10
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
            }

            // Click area
            DefaultMouseArea {
                id: mouse_area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    if(!can_change_ticker) return

                    if (mouse.button === Qt.RightButton) context_menu.popup()
                    else {
                        api_wallet_page.ticker = ticker
                        dashboard.current_page = General.idx_dashboard_wallet
                    }
                }
                onPressAndHold: {
                    if(!can_change_ticker) return

                    if (mouse.source === Qt.MouseEventNotSynthesized) context_menu.popup()
                }
            }

            // Right click menu
            CoinMenu {
                id: context_menu
            }

            // Icon
            DefaultImage {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: coin_header.anchors.leftMargin

                source: General.coinIcon(ticker)
                width: Style.textSize2
                anchors.verticalCenter: parent.verticalCenter
            }

            // Name
            DefaultText {
                anchors.left: icon.right
                anchors.leftMargin: 10
                text_value: name
                anchors.verticalCenter: parent.verticalCenter
            }

            // Balance
            DefaultText {
                id: balance_value
                anchors.left: parent.left
                anchors.leftMargin: balance_header.anchors.leftMargin

                text_value: General.formatCrypto("", balance, ticker,  main_currency_balance, API.app.settings_pg.current_currency)
                color: Style.colorWhite4
                anchors.verticalCenter: parent.verticalCenter
                privacy: true
            }

            // Change 24h
            DefaultText {
                id: change_24h_value
                anchors.right: parent.right
                anchors.rightMargin: change_24h_header.anchors.rightMargin

                text_value: {
                    const v = parseFloat(change_24h)
                    return v === 0 ? '-' : General.formatPercent(v)
                }
                color: Style.getValueColor(change_24h)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Price
            DefaultText {
                id: price_value
                anchors.right: parent.right
                anchors.rightMargin: price_header.anchors.rightMargin

                text_value: General.formatFiat('', main_currency_price_for_one_unit, API.app.settings_pg.current_currency)
                color: Style.colorThemeDarkLight
                anchors.verticalCenter: parent.verticalCenter

            }

            DefaultImage {
                visible: API.app.portfolio_pg.oracle_price_supported_pairs.join(",").indexOf(ticker) !== -1
                source: General.coinIcon('BAND')
                width: 12
                height: width
                anchors.top: price_value.top
                anchors.left: price_value.right
                anchors.leftMargin: 5

                CexInfoTrigger {}
            }

            // 7d Trend
            ChartView {
                property var historical: trend_7d
                id: chart
                width: 200
                height: 100
                antialiasing: true
                anchors.right: parent.right
                anchors.rightMargin: trend_7d_header.anchors.rightMargin - width * 0.4
                anchors.verticalCenter: parent.verticalCenter
                legend.visible: false

                function refresh() { updateChart(chart, historical, Style.getValueColor(change_24h)) }

                property bool dark_theme: Style.dark_theme
                onDark_themeChanged: refresh()
                onHistoricalChanged: refresh()
                backgroundColor: "transparent"
            }

            AnimatedRectangle {
                anchors.left: chart.right
                anchors.leftMargin: -25
                anchors.verticalCenter: parent.verticalCenter

                visible: {
                    const type = API.app.get_coin_info(ticker).type
                    return (type === "ERC-20" && ticker !== "ETH") ||
                           (type === "QRC-20" && ticker !== "QTUM")
                }
                radius: 20

                height: type_tag.font.pixelSize * 1.5
                width: type_tag.width + 8

                color: Style.getCoinColor(API.app.get_coin_info(ticker).type === "ERC-20" ? "ETH" : "QTUM")
                DefaultText {
                    id: type_tag
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: API.app.get_coin_info(ticker).type === "ERC-20" ? "ERC-20" : "QRC-20"
                    font.pixelSize: Style.textSizeSmall1
                }
            }
        }
    }
}
