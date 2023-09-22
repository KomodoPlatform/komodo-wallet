import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import QtWebEngine 1.8

import QtGraphicalEffects 1.0
import QtCharts 2.3
import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import App 1.0

// Portfolio
Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 600
    InnerBackground {
        id: price_graph_bg
        radius: 20
        anchors.fill: parent
        content: Item {
            property bool ticker_supported: false
            readonly property bool is_fetching: chart.loadProgress < 100
            readonly property string chartTheme: Style.dark_theme ? "dark" : "light"
            property color backgroundColor: DexTheme.chartTradingLineBackgroundColor
            property var ticker: api_wallet_page.ticker

            function loadChart() {
                const pair = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency)
                const pair_reversed = atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency) + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_usd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "USD"
                const pair_usd_reversed = "USD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_busd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "BUSD"
                const pair_busd_reversed = "BUSD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)

                // Normal pair
                let symbol = General.supported_pairs[pair]
                if (!symbol) {
                    console.log("Symbol not found for", pair)
                    symbol = General.supported_pairs[pair_reversed]
                }

                // Reversed pair
                if (!symbol) {
                    console.log("Symbol not found for", pair_reversed)
                    symbol = General.supported_pairs[pair_usd]
                }

                // Pair with USD
                if (!symbol) {
                    console.log("Symbol not found for", pair_usd)
                    symbol = General.supported_pairs[pair_usd_reversed]
                }

                // Reversed pair with USD
                if (!symbol) {
                    console.log("Symbol not found for", pair_usd_reversed)
                    symbol = General.supported_pairs[pair_busd]
                }

                // Pair with BUSD
                if (!symbol) {
                    console.log("Symbol not found for", pair_busd)
                    symbol = General.supported_pairs[pair_busd_reversed]
                }

                // Reversed pair with BUSD
                if (!symbol) {
                    console.log("Symbol not found for", pair_busd_reversed)
                    ticker_supported = false
                    return
                }

                ticker_supported = true

                console.debug("Wallet: Loading chart for %1".arg(symbol))

                chart.loadHtml(`
                                         <style>
                                         body { margin: 0; background: %1 }
                                         </style>
                                         <!-- TradingView Widget BEGIN -->
                                         <div class="tradingview-widget-container">
                                           <div class="tradingview-widget-container__widget"></div>
                                           <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                                           {
                                           "symbol": "${symbol}",
                                           "width": "100%",
                                           "height": "100%",
                                           "locale": "en",
                                           "dateRange": "1m",
                                           "colorTheme": "${chartTheme}",
                                           "trendLineColor": "%2",
                                           "underLineColor": "%3",
                                           "isTransparent": true,
                                           "autosize": false,
                                           "largeChartUrl": ""
                                           }
                                           </script>
                                         </div>
                                         <!-- TradingView Widget END -->`.arg(DexTheme.backgroundColor).arg(DexTheme.chartTradingLineColor).arg(DexTheme.chartTradingLineBackgroundColor))
                                }

                                 width: price_graph_bg.width
                                 height: price_graph_bg.height

                                 onTickerChanged: loadChart()
                                 onChartThemeChanged: loadChart()
                                 onBackgroundColorChanged: loadChart()

                                 RowLayout {
                                     visible: ticker_supported && !chart.visible
                                     anchors.centerIn: parent

                                     DefaultBusyIndicator {
                                         Layout.alignment: Qt.AlignHCenter
                                         Layout.leftMargin: -15
                                         Layout.rightMargin: Layout.leftMargin*0.75
                                         scale: 0.5
                                     }

                                     DefaultText {
                                         text_value: qsTr("Loading market data") + "..."
                                     }
                                 }

                                 DefaultText {
                                     visible: !ticker_supported
                                     text_value: qsTr("There is no chart data for this ticker yet")
                                     anchors.centerIn: parent
                                 }

                                 WebEngineView {
                                     id: chart
                                     anchors.fill: parent
                                     anchors.margins: -1
                                     visible: !is_fetching && ticker_supported
                                 }
                             }
                        }
                    }
