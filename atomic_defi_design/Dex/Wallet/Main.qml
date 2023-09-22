// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCharts 2.3
import QtWebEngine 1.8
import QtGraphicalEffects 1.0

import Qaterial 1.0 as Qaterial

// Project Imports
import "../Components"
import "../Constants"
import App 1.0
import "../Exchange/Trade"
import Dex.Themes 1.0 as Dex

// Right side, main
Item
{
    id: root
    property alias send_modal: send_modal

    readonly property int       layout_margin: 20
    readonly property string    headerTitleColor: Style.colorText2
    readonly property string    headerTitleFont: Style.textSizeMid1
    readonly property string    headerTextColor: Dex.CurrentTheme.foregroundColor
    readonly property string    headerTextFont: Style.textSize
    readonly property string    headerSmallTitleFont: Style.textSizeSmall4
    readonly property string    headerSmallFont: Style.textSizeSmall2
    readonly property string    addressURL: General.getAddressExplorerURL(api_wallet_page.ticker, current_ticker_infos.address)

    function loadingPercentage(remaining)
    {
        return General.formatPercent((100 * (1 - parseFloat(remaining)/parseFloat(current_ticker_infos.current_block))).toFixed(3), false)
    }

    readonly property var transactions_mdl: api_wallet_page.transactions_mdl
    readonly property var activation_status: current_ticker_infos.activation_status
    readonly property var activation_progress: General.isZhtlc(api_wallet_page.ticker) ? General.zhtlcActivationProgress(current_ticker_infos.activation_status, api_wallet_page.ticker) : 100

    Layout.fillHeight: true
    Layout.fillWidth: true

    // TODO: Move this section for the coin summary bar at the top to its own component
    ColumnLayout
    {
        id: wallet_layout

        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: layout_margin
        anchors.bottom: parent.bottom

        spacing: 20

        // Balance box
        InnerBackground
        {
            id: balance_box

            Layout.fillWidth: true
            Layout.preferredHeight: 100
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin

            RowLayout
            {
                anchors.fill: parent

                RowLayout
                {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: Layout.topMargin
                    Layout.leftMargin: 20
                    Layout.rightMargin: Layout.leftMargin
                    spacing: 5

                    // Icon & Full name
                    ColumnLayout
                    {
                        DefaultImage
                        {
                            id: icon_img
                            Layout.bottomMargin: 0
                            source: General.coinIcon(api_wallet_page.ticker)
                            Layout.preferredHeight: 60
                            Layout.preferredWidth: Layout.preferredHeight
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            DexRectangle
                            {
                                anchors.centerIn: parent
                                anchors.fill: parent
                                radius: 30
                                enabled: activation_progress != 100
                                visible: enabled
                                opacity: .9
                                color: DexTheme.backgroundColor
                            }

                            DexLabel
                            {
                                anchors.centerIn: parent
                                anchors.fill: parent
                                enabled: activation_progress != 100
                                visible: enabled
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: activation_progress + "%"
                                font: DexTypo.head8
                                color: DexTheme.okColor
                            }
                        }

                        DefaultText
                        {
                            id: ticker_name
                            Layout.topMargin: 0
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            text_value: api_wallet_page.ticker // current_ticker_infos.name
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Ticker and crypto / fiat amount
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: 2

                        DefaultText
                        {
                            id: balance_title
                            Layout.alignment: Qt.AlignHCenter
                            text_value: current_ticker_infos.name + " Balance" // "Wallet Balance"
                            font.pixelSize: headerTitleFont
                            color: headerTitleColor
                        }

                        DefaultText
                        {
                            id: name_value
                            Layout.alignment: Qt.AlignHCenter
                            text_value: General.formatCrypto("", current_ticker_infos.balance, "", current_ticker_infos.fiat_amount, API.app.settings_pg.current_currency)
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                            privacy: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    VerticalLine
                    {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.rightMargin: 0
                        Layout.preferredHeight: parent.height * 0.6
                    }

                    Item { Layout.fillWidth: true }

                    // Price
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DefaultText
                        {
                            id: price
                            text_value: qsTr("Price")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DefaultText
                        {
                            text_value:
                            {
                                const v = General.formatFiat('', current_ticker_infos.current_currency_ticker_price, API.app.settings_pg.current_currency)
                                return current_ticker_infos.current_currency_ticker_price == 0 ? 'N/A' : v
                            }
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    // 24hr change
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DefaultText
                        {
                            id: change_24hr
                            text_value: qsTr("Change 24hr")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DefaultText
                        {
                            id: change_24hr_value
                            Layout.alignment: Qt.AlignHCenter
                            text_value:
                            {
                                const v = parseFloat(current_ticker_infos.change_24h)
                                return v === 0 ? 'N/A' : General.formatPercent(v)
                            }
                            font.pixelSize: headerTextFont
                            color: change_24hr_value.text_value == "N/A" ? headerTextColor : DexTheme.getValueColor(current_ticker_infos.change_24h)
                        }
                    }

                    // Porfolio %
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DefaultText
                        {
                            id: portfolio_title
                            text_value: qsTr("Portfolio")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DefaultText
                        {
                            Layout.alignment: Qt.AlignHCenter
                            text_value:
                            {
                                const fiat_amount = parseFloat(current_ticker_infos.fiat_amount)
                                const portfolio_balance = parseFloat(API.app.portfolio_pg.balance_fiat_all)
                                if(fiat_amount <= 0 || portfolio_balance <= 0) return "N/A"
                                return General.formatPercent((100 * fiat_amount/portfolio_balance).toFixed(2), false)
                            }
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    VerticalLine
                    {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.rightMargin: 0
                        Layout.preferredHeight: parent.height * 0.6
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""
                    }

                    // Contract address
                    ColumnLayout
                    {
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""

                        RowLayout
                        {
                            Layout.alignment: Qt.AlignLeft
                            id: contract_title_row_layout

                            DefaultImage
                            {
                                id: protocol_img
                                source: General.platformIcon(General.coinPlatform(api_wallet_page.ticker))
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: Layout.preferredHeight
                            }

                            DefaultText
                            {
                                id: contract_address_title
                                text_value: General.coinPlatform(api_wallet_page.ticker) + qsTr(" Contract Address")
                                font.pixelSize: headerSmallTitleFont
                                color: headerTitleColor
                            }
                        }

                        RowLayout
                        {
                            Layout.topMargin: 0
                            Layout.bottomMargin: 0
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredHeight: General.coinContractAddress(api_wallet_page.ticker) ? headerSmallFont : 0
                            visible: General.coinContractAddress(api_wallet_page.ticker) !== ""

                            DefaultText
                            {
                                id: contract_address
                                text_value: General.coinContractAddress(api_wallet_page.ticker)
                                Layout.preferredWidth: contract_title_row_layout.width - headerTextFont
                                font: DexTypo.monoSpace
                                color: headerTextColor
                                elide: Text.ElideMiddle
                                wrapMode: Text.NoWrap
                            }

                            Qaterial.Icon {
                                size: headerTextFont
                                icon: Qaterial.Icons.linkVariant
                                color: contract_linkArea.containsMouse ? headerTextColor : headerTitleColor
                                visible: General.contractURL(api_wallet_page.ticker) != ""

                                DefaultMouseArea {
                                    id: contract_linkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Qt.openUrlExternally(General.contractURL(api_wallet_page.ticker))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Buttons
        RowLayout
        {
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 25

            Item
            {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48

                // Send Button
                DefaultButton
                {
                    enabled: General.canSend(api_wallet_page.ticker, activation_progress)
                    anchors.fill: parent
                    radius: 18
                    label.text: qsTr("Send")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    content.anchors.rightMargin: 23

                    onClicked:
                    {
                        if (API.app.wallet_pg.current_ticker_fees_coin_enabled) send_modal.open()
                        else enable_fees_coin_modal.open()
                    }

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.arrowTopRight
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.warningColor
                        }
                    }
                }

                // Send button error icon
                DefaultAlertIcon
                {
                    visible: activation_progress != 100 || api_wallet_page.send_availability_state !== ""
                    tooltipText: General.isZhtlc(api_wallet_page.ticker) && activation_progress != 100
                                            ? api_wallet_page.ticker + qsTr(" Activation: " + activation_progress + "%")
                                            : api_wallet_page.send_availability_state
                }
            }

            ModalLoader
            {
                id: send_modal
                sourceComponent: SendModal {}
            }

            Component
            {
                id: enable_fees_coin_comp

                MultipageModal
                {
                    id: root
                    width: 300

                    MultipageModalContent
                    {
                        titleText: qsTr("Enable %1 ?").arg(coin_to_enable_ticker)
                        RowLayout
                        {
                            Layout.fillWidth: true
                            DefaultButton
                            {
                                Layout.fillWidth: true
                                text: qsTr("Yes")
                                
                                onClicked:
                                {
                                    if (API.app.enable_coin(coin_to_enable_ticker) === false)
                                    {
                                        enable_fees_coin_failed_modal.open()
                                    }
                                    close()
                                }
                            }

                            DefaultButton
                            {
                                Layout.fillWidth: true
                                text: qsTr("No")
                                onClicked: close()
                            }
                        }
                    }
                }
            }

            ModalLoader
            {
                property string coin_to_enable_ticker: API.app.wallet_pg.ticker_infos.fee_ticker
                id: enable_fees_coin_modal
                sourceComponent: enable_fees_coin_comp
            }

            ModalLoader
            {
                id: enable_fees_coin_failed_modal
                sourceComponent: CannotEnableCoinModal { coin_to_enable_ticker: API.app.wallet_pg.ticker_infos.fee_ticker }
            }

            Item
            {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48

                // Receive Button
                DefaultButton
                {
                    // Address wont display until activated
                    enabled: General.isZhtlcReady(api_wallet_page.ticker)
                    anchors.fill: parent
                    radius: 18

                    label.text: qsTr("Receive")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48

                    onClicked: receive_modal.open()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.arrowBottomRight
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.okColor
                        }
                    }
                }

                // Receive button error icon
                DefaultAlertIcon
                {
                    visible: !General.isZhtlcReady(api_wallet_page.ticker)
                    tooltipText: api_wallet_page.ticker + qsTr(" Activation: " + activation_progress + "%")
                }
            }

            ModalLoader
            {
                id: receive_modal
                sourceComponent: ReceiveModal {}
            }

            // Swap Button
            Item
            {
                visible: !is_dex_banned
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48

                DefaultButton
                {
                    enabled: !General.isWalletOnly(api_wallet_page.ticker) && activation_progress == 100
                    anchors.fill: parent
                    radius: 18

                    // Inner text.
                    label.text: qsTr("Swap")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48

                    onClicked: onClickedSwap()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.swapHorizontal
                            size: 28
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.swapIconColor
                        }
                    }

                }

                // Swap button error icon
                DefaultAlertIcon
                {
                    visible: General.isWalletOnly(api_wallet_page.ticker) || activation_progress != 100
                    tooltipText: General.isWalletOnly(api_wallet_page.ticker)
                                    ? api_wallet_page.ticker + qsTr(" is wallet only")
                                    : api_wallet_page.ticker + qsTr(" Activation: " + activation_progress + "%")
                }
            }

            Item { Layout.fillWidth: true }

            // Rewards Button
            Item
            {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48
                visible: current_ticker_infos.is_claimable && !API.app.is_pin_cfg_enabled()

                Item { Layout.fillWidth: true }

                DefaultButton
                {
                    text: qsTr("Rewards")
                    radius: 18
                    font.pixelSize: 16
                    anchors.fill: parent
                    enabled: parseFloat(current_ticker_infos.balance) > 0
                    onClicked:
                    {
                        claimRewardsModal.open()
                        claimRewardsModal.item.prepareClaimRewards()
                    }
                }

                ModalLoader
                {
                    id: claimRewardsModal
                    sourceComponent: ClaimRewardsModal {}
                }
            }

            // Faucet Button
            Item
            {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48
                visible:  current_ticker_infos.is_faucet_coin

                DefaultButton
                {
                    enabled: activation_progress == 100
                    anchors.fill: parent
                    radius: 18
                    label.text: qsTr("Faucet")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    content.anchors.rightMargin: 23

                    onClicked: api_wallet_page.claim_faucet()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.water
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "cyan"
                        }
                    }
                }

                // Faucet button error icon
                DefaultAlertIcon
                {
                    visible: activation_progress != 100
                    tooltipText: api_wallet_page.ticker + qsTr(" Activation: " + activation_progress + "%")
                }
            }

            Component.onCompleted: api_wallet_page.claimingFaucetRpcDataChanged.connect(onClaimFaucetRpcResultChanged)
            Component.onDestruction: api_wallet_page.claimingFaucetRpcDataChanged.disconnect(onClaimFaucetRpcResultChanged)
            function onClaimFaucetRpcResultChanged() { claimFaucetResultModal.open() }

            ModalLoader
            {
                id: claimFaucetResultModal
                sourceComponent: ClaimFaucetResultModal {}
            }

            // Public Key button
            Item
            {
                Layout.minimumWidth: 160
                Layout.maximumWidth: 180
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                visible: current_ticker_infos.name === "Tokel" || current_ticker_infos.name === "Marmara Credit Loops"

                DefaultButton
                {
                    text: qsTr("Public Key")
                    radius: 18
                    font.pixelSize: 16
                    anchors.fill: parent
                    onClicked:
                    {
                        API.app.settings_pg.fetchPublicKey()
                        publicKeyModal.open()
                    }
                }

                ModalLoader
                {
                    id: publicKeyModal
                    sourceComponent: MultipageModal
                    {
                        MultipageModalContent
                        {
                            titleText: qsTr("Public Key")

                            DefaultBusyIndicator
                            {
                                Layout.alignment: Qt.AlignCenter

                                visible: API.app.settings_pg.fetchingPublicKey
                                enabled: visible
                            }

                            RowLayout
                            {
                                Layout.fillWidth: true

                                DefaultText
                                {
                                    Layout.fillWidth: true
                                    visible: !API.app.settings_pg.fetchingPublicKey
                                    text: API.app.settings_pg.publicKey
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }

                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.contentCopy
                                    icon.color: Dex.CurrentTheme.foregroundColor
                                    onClicked:
                                    {
                                        API.qt_utilities.copy_text_to_clipboard(API.app.settings_pg.publicKey)
                                        app.notifyCopy(qsTr("Public Key"), qsTr("Copied to Clipboard"))
                                    }
                                }
                            }

                            Image
                            {
                                visible: !API.app.settings_pg.fetchingPublicKey

                                Layout.topMargin: 20
                                Layout.alignment: Qt.AlignHCenter

                                sourceSize.width: 300
                                sourceSize.height: 300
                                source: API.qt_utilities.get_qrcode_svg_from_string(API.app.settings_pg.publicKey)
                            }
                        }
                    }
                }
            }
        }

        // Price Graph
        InnerBackground
        {
            visible: false
            id: price_graph_bg

            property bool ticker_supported: false
            readonly property bool is_fetching: webEngineView.loadProgress < 100
            property var ticker: api_wallet_page.ticker

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin
            Layout.bottomMargin: -parent.spacing * 0.5
            Layout.preferredHeight: wallet.height * 0.6

            radius: 18

            // Chart disabled
            // onTickerChanged: loadChart()

            function loadChart()
            {
                const pair = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency)
                const pair_reversed = atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency) + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_usd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "USD"
                const pair_usd_reversed = "USD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_busd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "BUSD"
                const pair_busd_reversed = "BUSD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)

                // Normal pair
                let symbol = General.supported_pairs[pair]
                if (!symbol) {
                    console.warn("Symbol not found for", pair)
                    symbol = General.supported_pairs[pair_reversed]
                }

                // Reversed pair
                if (!symbol) {
                    console.warn("Symbol not found for", pair_reversed)
                    symbol = General.supported_pairs[pair_usd]
                }

                // Pair with USD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_usd)
                    symbol = General.supported_pairs[pair_usd_reversed]
                }

                // Reversed pair with USD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_usd_reversed)
                    symbol = General.supported_pairs[pair_busd]
                }

                // Pair with BUSD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_busd)
                    symbol = General.supported_pairs[pair_busd_reversed]
                }

                // Reversed pair with BUSD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_busd_reversed)
                    console.warn("No chart for", ticker)
                    ticker_supported = false
                    return
                }

                ticker_supported = true

                console.debug("Wallet: Loading chart for %1".arg(symbol))

                webEngineView.loadHtml(`<style>
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
                                              "dateRange": "1D",
                                              "colorTheme": "dark",
                                              "trendLineColor": "%2",
                                              "isTransparent": true,
                                              "autosize": false,
                                              "largeChartUrl": ""
                                          }
                                          </script>
                                        </div>
                                        <!-- TradingView Widget END -->`.arg(Dex.CurrentTheme.floatingBackgroundColor).arg(Dex.CurrentTheme.textSelectionColor))
            }

            WebEngineView
            {
                id: webEngineView
                anchors.fill: parent
                visible: parent.ticker_supported && !loading
            }

            Connections
            {
                target: Dex.CurrentTheme
                function onThemeChanged()
                {
                    // Chart disabled
                    // loadChart();
                }
            }

            RowLayout
            {
                visible: !webEngineView.visible && parent.ticker_supported
                anchors.centerIn: parent

                DefaultBusyIndicator
                {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.leftMargin: -15
                    Layout.rightMargin: Layout.leftMargin*0.75
                    scale: 0.5
                }

                DefaultText
                {
                    text_value: qsTr("Loading market data") + "..."
                }
            }

            DefaultText
            {
                visible: !parent.ticker_supported
                text_value: qsTr("There is no chart data for this ticker yet")
                anchors.centerIn: parent
            }
        }

        Rectangle {
            id: transactions_bg
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin
            Layout.bottomMargin: !fetching_text_row.visible ? layout_margin : undefined

            implicitHeight: wallet.height*0.54

            color: Dex.CurrentTheme.floatingBackgroundColor
            radius: 22

            ClipRRect
            {
                id: clip_rect
                radius: parent.radius
                width: transactions_bg.width
                height: transactions_bg.height

                DefaultRectangle
                {
                    anchors.fill: parent
                    gradient: Gradient
                    {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.001; color: Dex.CurrentTheme.innerBackgroundColor }
                        GradientStop { position: 1; color: Dex.CurrentTheme.backgroundColor }
                    }
                }
                
                // Transactions history table
                Transactions
                {
                    width: parent.width
                    height: parent.height
                }

                // Placeholder if no tx history available, or being fetched.
                ColumnLayout
                {
                    visible: current_ticker_infos.tx_state !== "InProgress" && transactions_mdl.length === 0
                    anchors.fill: parent
                    anchors.centerIn: parent
                    spacing: 24

                    DefaultText
                    {
                        id: fetching_text_row
                        Layout.topMargin: 24
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textSize
                        text_value:
                        {
                            if (api_wallet_page.tx_fetching_busy) return qsTr("Fetching transactions...")
                            if (General.isZhtlc(api_wallet_page.ticker))
                            {
                                if (activation_progress != 100) return qsTr("Please wait, %1 is %2").arg(api_wallet_page.ticker).arg(activation_progress) + qsTr("% activated...")
                            }
                            return qsTr('No transactions available')
                        }
                    }

                    DefaultBusyIndicator
                    {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.preferredWidth: Style.textSizeSmall3
                        Layout.preferredHeight: Layout.preferredWidth
                        indicatorSize: 32
                        indicatorDotSize: 5
                        visible: api_wallet_page.tx_fetching_busy
                    }

                    // When no tx history available, or being fetched, show a button to open the explorer.
                    DefaultText
                    {
                        id: explorerLink
                        Layout.topMargin: 24
                        Layout.alignment: Qt.AlignHCenter
                        visible:
                        {
                            if (activation_progress != 100) return false
                            return api_wallet_page.tx_fetching_busy ? false : addressURL == "" ? false : api_wallet_page.tx_fetching_failed 
                        }
                        text_value:  qsTr("Click to view your address on %1 (%2) block explorer").arg(current_ticker_infos.name).arg(api_wallet_page.ticker)
                        font.pixelSize: Style.textSize
                        color: explorer_mouseArea.containsMouse ? Dex.CurrentTheme.textSelectionColor : Dex.CurrentTheme.foregroundColor

                        DefaultMouseArea
                        {
                            id: explorer_mouseArea
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(addressURL)
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
