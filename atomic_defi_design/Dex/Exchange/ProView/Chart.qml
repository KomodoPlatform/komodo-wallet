import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtWebEngine 1.8

import "../../Components"
import "../../Constants"
import Dex.Themes 1.0 as Dex
import AtomicDEX.MarketMode 1.0

Item
{
    id: root

    readonly property string theme: Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Dark ? "dark" : "light"
    property string loaded_symbol
    property bool pair_supported: false
    property string selected_testcoin
    onPair_supportedChanged: if (!pair_supported) webEngineViewPlaceHolder.visible = false

    function loadChart(right_ticker, left_ticker, force = false, source="livecoinwatch")
    {

        // <script defer src="https://www.livecoinwatch.com/static/lcw-widget.js"></script> <div class="livecoinwatch-widget-1" lcw-coin="BTC" lcw-base="USD" lcw-secondary="BTC" lcw-period="w" lcw-color-tx="#ffffff" lcw-color-pr="#58c7c5" lcw-color-bg="#1f2434" lcw-border-w="1" lcw-digits="8" ></div>

        let chart_html = ""
        let symbol = ""
        let widget_x = 385
        let widget_y = 150
        let scale_x = root.width / widget_x
        let scale_y = root.height / widget_y

        if (source == "livecoinwatch")
        {
            selected_testcoin = ""
            if (General.is_testcoin(left_ticker))
            {
                pair_supported = false
                selected_testcoin = left_ticker
                return
            }
            if (General.is_testcoin(right_ticker))
            {
                pair_supported = false
                selected_testcoin = right_ticker
                return
            }

            let rel_ticker = General.getChartTicker(right_ticker)
            let base_ticker = General.getChartTicker(left_ticker)
            if (rel_ticker != "" && base_ticker != "")
            {
                pair_supported = true
                symbol = rel_ticker+"-"+base_ticker
                if (symbol === loaded_symbol && !force)
                {
                    webEngineViewPlaceHolder.visible = true
                    return
                }
                chart_html = `
                <style>
                    body { margin: auto; }
                    .livecoinwatch-widget-1 {
                        transform: scale(${Math.min(scale_x, scale_y)});
                        transform-origin: top left;
                    }
                </style>
                <script defer src="https://www.livecoinwatch.com/static/lcw-widget.js"></script>
                <div class="livecoinwatch-widget-1" lcw-coin="${rel_ticker}" lcw-base="${base_ticker}" lcw-secondary="USDC" lcw-period="w" lcw-color-tx="${Dex.CurrentTheme.foregroundColor}" lcw-color-pr="#58c7c5" lcw-color-bg="${Dex.CurrentTheme.comboBoxBackgroundColor}" lcw-border-w="0" lcw-digits="8" ></div>
                `
            }
        }
        // console.log(chart_html)

        if (chart_html == "")
        {
            const pair = atomic_qt_utilities.retrieve_main_ticker(left_ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(right_ticker)
            const pair_reversed = atomic_qt_utilities.retrieve_main_ticker(right_ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(left_ticker)

            // Try checking if pair/reversed-pair exists
            symbol = General.supported_pairs[pair]
            if (!symbol) symbol = General.supported_pairs[pair_reversed]

            if (!symbol)
            {
                pair_supported = false
                return
            }

            pair_supported = true

            if (symbol === loaded_symbol && !force)
            {
                webEngineViewPlaceHolder.visible = true
                return
            }

            loaded_symbol = symbol

            chart_html = `
            <style>
            body { margin: 0; }
            </style>

            <!-- TradingView Widget BEGIN -->
            <div class="tradingview-widget-container">
            <div id="tradingview_af406"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
            new TradingView.widget(
            {
            "timezone": "Etc/UTC",
            "locale": "en",
            "autosize": true,
            "symbol": "${symbol}",
            "interval": "D",
            "theme": "${theme}",
            "style": "1",
            "enable_publishing": false,
            "save_image": false
            }
            );
            </script>
            </div>
            <!-- TradingView Widget END -->`
        }
        dashboard.webEngineView.loadHtml(chart_html)
    }

    Component.onCompleted:
    {
        try
        {
            loadChart(left_ticker?? atomic_app_primary_coin,
                      right_ticker?? atomic_app_secondary_coin)
        }
        catch (e) { console.error(e) }
    }

// Currently chart should not resize, but in future it might be needed

//    onWidthChanged: {
//        try
//        {
//            loadChart(left_ticker?? atomic_app_primary_coin,
//                      right_ticker?? atomic_app_secondary_coin)
//        }
//        catch (e) { console.error(e) }
//    }

    RowLayout
    {
        anchors.fill: parent
        visible: !webEngineViewPlaceHolder.visible

        DefaultBusyIndicator
        {
            visible: pair_supported
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: -15
            Layout.rightMargin: Layout.leftMargin*0.75
            scale: 0.5
        }

        DefaultText
        {
            visible: pair_supported
            text_value: qsTr("Loading market data") + "..."
        }

        DefaultText
        {
            visible: !pair_supported && selected_testcoin == ""
            text_value: qsTr("There is no chart data for this pair")
            Layout.topMargin: 30
            Layout.alignment: Qt.AlignCenter
        }

        DefaultText
        {
            visible: !pair_supported && selected_testcoin != ""
            text_value: qsTr("There is no chart data for %1 (testcoin) pairs").arg(selected_testcoin)
            Layout.topMargin: 30
            Layout.alignment: Qt.AlignCenter
        }
    }

    Item
    {
        id: webEngineViewPlaceHolder
        anchors.fill: parent
        anchors.centerIn: parent
        visible: false

        Component.onCompleted:
        {
            dashboard.webEngineView.parent = webEngineViewPlaceHolder
            dashboard.webEngineView.anchors.fill = webEngineViewPlaceHolder
        }
        Component.onDestruction:
        {
            dashboard.webEngineView.visible = false
            dashboard.webEngineView.stop()
        }
        onVisibleChanged: dashboard.webEngineView.visible = visible

        Connections
        {
            target: dashboard.webEngineView

            function onLoadingChanged(webEngineLoadReq)
            {
                if (webEngineLoadReq.status === WebEngineView.LoadSucceededStatus)
                {
                    webEngineViewPlaceHolder.visible = true
                }
                else webEngineViewPlaceHolder.visible = false
            }
        }
    }

    Connections
    {
        target: app
        function onPairChanged(left, right)
        {
            if (API.app.trading_pg.market_mode == MarketMode.Sell)
            {
                root.loadChart(left, right)
            }
            else
            {
                root.loadChart(right, left)
            }
        }
    }

    Connections
    {
        target: Dex.CurrentTheme
        function onThemeChanged()
        {
            loadChart(left_ticker?? atomic_app_primary_coin,
                      right_ticker?? atomic_app_secondary_coin,
                      true)
        }
    }
}
