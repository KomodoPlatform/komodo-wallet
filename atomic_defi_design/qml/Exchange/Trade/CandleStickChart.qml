import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import QtCharts 2.3
import QtWebEngine 1.8

import "../../Components"
import "../../Constants"

// List
Item {
    id: root

    property bool pair_supported: false
    readonly property bool is_fetching: chart.loadProgress < 100

    RowLayout {
        visible: pair_supported && !chart.visible
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
        visible: !pair_supported
        text_value: qsTr("There is no chart data for this pair yet")
        anchors.centerIn: parent
    }

    Component.onCompleted: loadChart(default_base, default_rel)

    Connections {
        target: exchange_trade
        function onPairChanged(base, rel) {
            root.loadChart(base, rel)
        }
    }

    readonly property string theme: Style.dark_theme ? "dark" : "light"
    onThemeChanged: loadChart(chart_base, chart_rel, true)

    property string chart_base
    property string chart_rel
    property string loaded_symbol
    function loadChart(base, rel, force=false) {
        const pair = base + "/" + rel
        const pair_reversed = rel + "/" + base

        console.log("Will try to load TradingView chart", pair)

        // Normal pair
        let symbol = General.supported_pairs[pair]
        if(!symbol) {
            console.log("Symbol not found for", pair)
            symbol = General.supported_pairs[pair_reversed]
        }

        // Reversed pair
        if(!symbol) {
            console.log("Symbol not found for", pair_reversed)
            pair_supported = false
            return
        }

        pair_supported = true

        // Load HTML
        if(!force && symbol === loaded_symbol) {
            console.log("Chart is already loaded,", symbol)
            return
        }

        loaded_symbol = symbol
        console.log("Loading TradingView chart", symbol, " theme: ", theme)

        chart_base = base
        chart_rel = rel

        chart.loadHtml(`
<style>
body { margin: 0; background: ${ graph_bg.color } }
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
<!-- TradingView Widget END -->`)
    }

    WebEngineView {
        id: chart
        anchors.fill: parent
        anchors.margins: -1
        visible: !is_fetching && pair_supported
    }
}


/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
