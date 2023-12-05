import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import Qaterial 1.0 as Qaterial

import "../../../Components"
import "../../../Constants"
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import AtomicDEX.MarketMode 1.0
import AtomicDEX.TradingError 1.0

Widget
{
    title: qsTr("Place Order")
    property int loop_count: 0
    property bool show_waiting_for_trade_preimage: false;
    property var fees: API.app.trading_pg.fees
    property var preimage_rpc_busy: API.app.trading_pg.preimage_rpc_busy
    property string protocolIcon: General.platformIcon(General.coinPlatform(left_ticker))
    property var trade_preimage_error: fees.hasOwnProperty('error') ? fees["error"].split("] ").slice(-1) : ""
    readonly property bool trade_preimage_ready: fees.hasOwnProperty('base_transaction_fees_ticker')
    readonly property bool can_submit_trade: last_trading_error === TradingError.None

    margins: 10
    collapsable: false

    Connections {
        target: API.app.trading_pg

        function onFeesChanged() {
            // console.log("onFeesChanged::fees: " + JSON.stringify(fees))
        }

        function onPreImageRpcStatusChanged(){
            // console.log("onPreImageRpcStatusChanged::preimage_rpc_busy: " + API.app.trading_pg.preimage_rpc_busy)
        }
        function onPrefferedOrderChanged(){
            reset_fees_state()
        }
    }

    Connections
    {
        target: app
        function onPairChanged(left, right)
        {
            reset_fees_state()
        }
    }

    Connections
    {
        target: exchange_trade
        function onOrderSelected()
        {
            reset_fees_state()
        }
    }

    function reset_fees_state()
    {
        show_waiting_for_trade_preimage = false;
        check_trade_preimage.stop()
        loop_count = 0
        API.app.trading_pg.reset_fees()
        errors.text_value = ""
    }

    // Market mode selector
    RowLayout
    {
        Layout.topMargin: 5
        Layout.bottomMargin: 2
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: parent.width
        height: 32

        MarketModeSelector
        {
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: (parent.width / 100) * 46
            Layout.preferredHeight: 32
            marketMode: MarketMode.Buy
            ticker: atomic_qt_utilities.retrieve_main_ticker(left_ticker)
        }

        Item { Layout.fillWidth: true }

        MarketModeSelector
        {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: (parent.width / 100) * 46
            Layout.preferredHeight: 32
            ticker: atomic_qt_utilities.retrieve_main_ticker(left_ticker)
        }
    }

    // Protocol text for platform tokens
    Item
    {
        height: 32
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: parent.width
        visible: protocolIcon != ""

        ColumnLayout
        {
            spacing: 2
            anchors.fill: parent
            anchors.centerIn: parent

            Dex.Text
            {
                id: protocolTitle
                Layout.preferredWidth: parent.width
                text_value: "Protocol:"
                font.pixelSize: Style.textSizeSmall1
                horizontalAlignment: Text.AlignHCenter
                color: Style.colorText2
            }

            RowLayout
            {
                id: protocol
                Layout.alignment: Qt.AlignHCenter

                DefaultImage
                {
                    id: protocolImg
                    source: protocolIcon
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: Layout.preferredHeight
                }

                DexLabel
                {
                    id: protocolText
                    text_value: General.getProtocolText(left_ticker)
                    wrapMode: DexLabel.NoWrap
                    font.pixelSize: Style.textSizeSmall1
                    color: Style.colorText2
                }
            }
        }
    }

    // Order selected indicator
    Item
    {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: parent.width
        height: 32

        RowLayout
        {
            id: orderSelection
            visible: API.app.trading_pg.preffered_order.price !== undefined
            anchors.fill: parent
            anchors.verticalCenter: parent.verticalCenter

            DefaultText
            {
                Layout.leftMargin: 15
                color: Dex.CurrentTheme.warningColor
                text: qsTr("Order Selected")
            }

            Item { Layout.fillWidth: true }

            Qaterial.FlatButton
            {
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: 30
                Layout.rightMargin: 5
                foregroundColor: Dex.CurrentTheme.warningColor
                onClicked: {
                    API.app.trading_pg.reset_order()
                    reset_fees_state()
                }

                Qaterial.ColorIcon
                {
                    anchors.centerIn: parent
                    iconSize: 16
                    color: Dex.CurrentTheme.warningColor
                    source: Qaterial.Icons.close
                }
            }
        }

        Rectangle
        {
            visible: API.app.trading_pg.preffered_order.price !== undefined
            anchors.fill: parent
            radius: 8
            color: 'transparent'
            border.color: Dex.CurrentTheme.warningColor
        }
    }

    OrderForm
    {
        id: formBase
        width: parent.width
        height: 330
        Layout.alignment: Qt.AlignHCenter
    }

    Item { Layout.fillHeight: true }

    // Error messages
    Item
    {
        height: 55
        Layout.preferredWidth: parent.width

        // Show errors
        Dex.Text
        {
            id: errors
            visible: errors.text_value !== ""
            anchors.fill: parent
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Style.textSizeSmall4
            color: Dex.CurrentTheme.warningColor
            text_value: General.getTradingError(
                            last_trading_error,
                            curr_fee_info,
                            base_ticker,
                            rel_ticker, left_ticker, right_ticker)
            elide: Text.ElideRight
        }
    }

    TotalView
    {
        height: 70
        Layout.preferredWidth: parent.width
        Layout.alignment: Qt.AlignHCenter
    }

    DexGradientAppButton
    {
        id: swap_btn
        height: 32
        Layout.preferredWidth: parent.width - 30
        Layout.alignment: Qt.AlignHCenter

        radius: 16
        text: qsTr("START SWAP")
        font.weight: Font.Medium
        enabled: can_submit_trade && !show_waiting_for_trade_preimage && errors.text_value == ""
        onClicked: 
        {
            console.log("Getting fees info...")
            API.app.trading_pg.determine_fees()
            show_waiting_for_trade_preimage = true;
        }

        Item
        {
            visible: show_waiting_for_trade_preimage
            height: parent.height - 10
            width: parent.width - 10
            anchors.fill: parent
            anchors.centerIn: parent

            DefaultBusyIndicator
            {
                id: preimage_BusyIndicator
                anchors.fill: parent
                anchors.centerIn: parent
                indicatorSize: 32
                indicatorDotSize: 5
            }
        }

        DexMouseArea
        {
            id: areaAlert
            hoverEnabled: true
            anchors.fill: parent
            onClicked: 
            {
                console.log("Getting fees info...")
                API.app.trading_pg.determine_fees()
                show_waiting_for_trade_preimage = true;
                check_trade_preimage.start()
            }
        }
    }

    Timer {
        id: check_trade_preimage
        interval: 500;
        running: false;
        repeat: true;
        triggeredOnStart: true;
        onTriggered: {
            loop_count++;
            console.log("Getting fees info... " + loop_count + "/50")
            if (trade_preimage_ready)
            {
                show_waiting_for_trade_preimage = false
                loop_count = 0
                stop()
                confirm_trade_modal.open()
            }
            else if (trade_preimage_error != "")
            {
                loop_count = 0
                errors.text_value = trade_preimage_error.toString()
                show_waiting_for_trade_preimage = false
                stop()

            }
            else if (loop_count > 50)
            {
                loop_count = 0
                show_waiting_for_trade_preimage = false
                trade_preimage_error = "Trade preimage timed out, try again."
                stop()
            }
        }
    }
}
