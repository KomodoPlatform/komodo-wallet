import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import QtWebEngine 1.10

import "../Components"
import "../Constants"
import App 1.0
import "../Dashboard"
import "../Portfolio"
import "../Wallet"
import "../Exchange"
import "../Settings"
import "../Support"
import "../Sidebar" as Sidebar
import "../Fiat"
import "../Settings" as SettingsPage
import "../Support" as SupportPage
import "../Screens"
import Dex.Themes 1.0 as Dex
//import Dex.Sidebar 1.0 as Dex


Item {
    id: dashboard

    enum PageType
    {
        Portfolio,
        Wallet,
        DEX,            // DEX == Trading page
        Addressbook,
        Support
    }

    property var currentPage: Dashboard.PageType.Portfolio
    property var availablePages: [portfolio, wallet, exchange, addressbook, support]

    property alias webEngineView: webEngineView

    readonly property int idx_exchange_trade: 0
    readonly property int idx_exchange_orders: 1
    readonly property int idx_exchange_history: 2

    property var current_ticker

    property var notifications_list: ([])

    readonly property var portfolio_mdl: API.app.portfolio_pg.portfolio_mdl
    property var portfolio_coins: portfolio_mdl.portfolio_proxy_mdl

    readonly property var   api_wallet_page: API.app.wallet_pg
    readonly property var   current_ticker_infos: api_wallet_page.ticker_infos
    readonly property bool  can_change_ticker: !api_wallet_page.tx_fetching_busy
    readonly property bool  is_dex_banned: !API.app.ip_checker.ip_authorized

    readonly property alias loader: loader
    readonly property alias current_component: loader.item


    function openLogsFolder()
    {
        Qt.openUrlExternally(General.os_file_prefix + API.app.settings_pg.get_log_folder())
    }

    function inCurrentPage() { return app.current_page === idx_dashboard }

    function switchPage(page)
    {
        if (loader.status === Loader.Ready)
            currentPage = page
        else
            console.warn("Tried to switch to page %1 when loader is not ready yet.".arg(page))
    }

    function resetCoinFilter() { portfolio_coins.setFilterFixedString("") }

    function openTradeViewWithTicker()
    {
        dashboard.loader.onLoadComplete = () => {
            dashboard.current_component.openTradeView(api_wallet_page.ticker)
        }
    }

    Layout.fillWidth: true

    onCurrentPageChanged: sidebar.currentLineType = currentPage

    SupportPage.SupportModal { id: support_modal }

    // Al settings depends this modal
    SettingsPage.SettingModal { id: setting_modal }

    // Force restart modal: opened when the user has more coins enabled than specified in its configuration
    ForceRestartModal {
        reasonMsg: qsTr("The current number of enabled coins does not match your configuration specification. Your assets configuration will be reset.")
        Component.onCompleted: {
            if (API.app.portfolio_pg.portfolio_mdl.length > atomic_settings2.value("MaximumNbCoinsEnabled")) {
                open()
                onTimerEnded = () => {
                    API.app.settings_pg.reset_coin_cfg()
                }
            }
        }
    }

    // Right side
    AnimatedRectangle
    {
        width: parent.width - sidebar.width
        height: parent.height
        x: sidebar.width
        border.color: 'transparent'

        // Modals
        ModalLoader
        {
            id: enable_coin_modal
            sourceComponent: EnableCoinModal
            {
                anchors.centerIn: Overlay.overlay
            }
        }

        Component
        {
            id: portfolio

            Portfolio {}
        }

        Component
        {
            id: wallet

            Wallet {}
        }

        Component
        {
            id: exchange

            Exchange {}
        }

        Component
        {
            id: addressbook

            AddressBook {}
        }

        Component
        {
            id: settings

            Settings
            {
                Layout.alignment: Qt.AlignCenter
            }
        }

        Component
        {
            id: support

            Support
            {
                Layout.alignment: Qt.AlignCenter
            }
        }

        WebEngineView
        {
            id: webEngineView
            backgroundColor: "transparent"
        }

        DefaultLoader
        {
            id: loader

            anchors.fill: parent
            transformOrigin: Item.Center
            asynchronous: true

            sourceComponent: availablePages[currentPage]
        }

        Item
        {
            visible: !loader.visible

            anchors.fill: parent

            DefaultBusyIndicator
            {
                anchors.centerIn: parent
                running: !loader.visible
            }
        }
    }

    // Sidebar, left side
    Sidebar.Main
    {
        id: sidebar

        enabled: loader.status === Loader.Ready

        onLineSelected: currentPage = lineType;
        onSettingsClicked: setting_modal.open()
        onSupportClicked: support_modal.open()
    }

    ModalLoader
    {
        id: add_custom_coin_modal
        sourceComponent: AddCustomCoinModal {}
    }

    // CEX Rates info
    ModalLoader
    {
        id: cex_rates_modal
        sourceComponent: CexInfoModal {}
    }
    ModalLoader
    {
        id: min_trade_modal
        sourceComponent: MinTradeModal {}
    }

    ModalLoader
    {
        id: restart_modal
        sourceComponent: RestartModal {}
    }

    function getStatusColor(status)
    {
        switch (status) {
            case "matching":
                return Style.colorYellow
            case "matched":
            case "ongoing":
            case "refunding":
                return Style.colorOrange
            case "successful":
                return Dex.CurrentTheme.sidebarLineTextHovered
            case "failed":
            default:
                return DexTheme.redColor
        }
    }

    function isSwapDone(status)
    {
        switch (status) {
            case "matching":
            case "matched":
            case "ongoing":
                return false
            case "successful":
            case "refunding":
            case "failed":
            default:
                return true
        }
    }

    function getStatusStep(status)
    {
        switch (status) {
            case "matching":
                return "0/3"
            case "matched":
                return "1/3"
            case "ongoing":
                return "2/3"
            case "successful":
                return Style.successCharacter
            case "refunding":
                return Style.warningCharacter
            case "failed":
                return Style.failureCharacter
            default:
                return "?"
        }
    }

    function getStatusFontSize(status)
    {
        switch (status) {
            case "matching":
                return 9
            case "matched":
                return 9
            case "ongoing":
                return 9
            case "successful":
                return 16
            case "refunding":
                return 16
            case "failed":
                return 12
            default:
                return 9
        }
    }

    function getStatusText(status, short_text=false)
    {
        switch(status) {
            case "matching":
                return short_text ? qsTr("Matching") : qsTr("Order Matching")
            case "matched":
                return short_text ? qsTr("Matched") : qsTr("Order Matched")
            case "ongoing":
                return short_text ? qsTr("Ongoing") : qsTr("Swap Ongoing")
            case "successful":
                return short_text ? qsTr("Successful") : qsTr("Swap Successful")
            case "refunding":
                return short_text ? qsTr("Refunding") : qsTr("Refunding")
            case "failed":
                return short_text ? qsTr("Failed") : qsTr("Swap Failed")
            default:
                return short_text ? qsTr("Unknown") : qsTr("Unknown State")
        }
    }

    function getStatusTextWithPrefix(status, short_text = false)
    {
        return getStatusStep(status) + " " + getStatusText(status, short_text)
    }

    function getEventText(event_name)
    {
        switch (event_name)
        {
            case "Started":
                return qsTr("Started")
            case "Negotiated":
                return qsTr("Negotiated")
            case "TakerFeeSent":
                return qsTr("Taker fee sent")
            case "MakerPaymentReceived":
                return qsTr("Maker payment received")
            case "MakerPaymentWaitConfirmStarted":
                return qsTr("Maker payment wait confirm started")
            case "MakerPaymentValidatedAndConfirmed":
                return qsTr("Maker payment validated and confirmed")
            case "TakerPaymentSent":
                return qsTr("Taker payment sent")
            case "TakerPaymentSpent":
                return qsTr("Taker payment spent")
            case "MakerPaymentSpent":
                return qsTr("Maker payment spent")
            case "Finished":
                return qsTr("Finished")
            case "StartFailed":
                return qsTr("Start failed")
            case "NegotiateFailed":
                return qsTr("Negotiate failed")
            case "TakerFeeValidateFailed":
                return qsTr("Taker fee validate failed")
            case "MakerPaymentTransactionFailed":
                return qsTr("Maker payment transaction failed")
            case "MakerPaymentDataSendFailed":
                return qsTr("Maker payment Data send failed")
            case "MakerPaymentWaitConfirmFailed":
                return qsTr("Maker payment wait confirm failed")
            case "TakerPaymentValidateFailed":
                return qsTr("Taker payment validate failed")
            case "TakerPaymentWaitConfirmFailed":
                return qsTr("Taker payment wait confirm failed")
            case "TakerPaymentSpendFailed":
                return qsTr("Taker payment spend failed")
            case "MakerPaymentWaitRefundStarted":
                return qsTr("Maker payment wait refund started")
            case "MakerPaymentRefunded":
                return qsTr("Maker payment refunded")
            case "MakerPaymentRefundFailed":
                return qsTr("Maker payment refund failed")
            default:
                return qsTr(event_name)
        }
    }
}
