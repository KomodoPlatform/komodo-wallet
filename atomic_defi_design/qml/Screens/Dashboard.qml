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
import "../Sidebar"
import "../Fiat"
import "../Settings" as SettingsPage


Item {
    id: dashboard

    property alias webEngineView: webEngineView

    readonly property int idx_dashboard_portfolio: 0
    readonly property int idx_dashboard_wallet: 1
    readonly property int idx_dashboard_exchange: 2
    readonly property int idx_dashboard_addressbook: 3
    readonly property int idx_dashboard_news: 4
    readonly property int idx_dashboard_dapps: 5
    readonly property int idx_dashboard_settings: 6
    readonly property int idx_dashboard_support: 7
    readonly property int idx_dashboard_light_ui: 8
    readonly property int idx_dashboard_privacy_mode: 9
    readonly property int idx_dashboard_fiat_ramp: 10

    //readonly property int idx_exchange_trade: 3
    readonly property int idx_exchange_trade: 0
    readonly property int idx_exchange_orders: 1
    readonly property int idx_exchange_history: 2

    property var current_ticker

    Layout.fillWidth: true

    function openLogsFolder() {
        Qt.openUrlExternally(General.os_file_prefix + API.app.settings_pg.get_log_folder())
    }

    readonly property
    var api_wallet_page: API.app.wallet_pg
    readonly property
    var current_ticker_infos: api_wallet_page.ticker_infos
    readonly property bool can_change_ticker: !api_wallet_page.tx_fetching_busy

    readonly property alias loader: loader
    readonly property alias current_component: loader.item
    property int current_page: idx_dashboard_portfolio

    onCurrent_pageChanged: {
        app.deepPage = current_page * 10
    }


    readonly property bool is_dex_banned: !API.app.ip_checker.ip_authorized

    function inCurrentPage() {
        return app.current_page === idx_dashboard
    }

    function switchPage(page)
    {
        if (loader.status === Loader.Ready)
            current_page = page
        else
            console.warn("Tried to switch to page %1 when loader is not ready yet.".arg(page))
    }

    property
    var notifications_list: ([])

    readonly property
    var portfolio_mdl: API.app.portfolio_pg.portfolio_mdl
    property
    var portfolio_coins: portfolio_mdl.portfolio_proxy_mdl

    function resetCoinFilter() {
        portfolio_coins.setFilterFixedString("")
    }


    function openTradeViewWithTicker() {
        dashboard.loader.onLoadComplete = () => {
            dashboard.current_component.openTradeView(api_wallet_page.ticker)
        }
    }
    // Al settings depends this modal
    SettingsPage.SettingModal {
        id: setting_modal
    }

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
    AnimatedRectangle {
        color: DexTheme.backgroundColorDeep
        width: parent.width - sidebar.width
        height: parent.height
        x: sidebar.width
        border.color: 'transparent'

        // Modals
        ModalLoader {
            id: enable_coin_modal
            sourceComponent: EnableCoinModal {
                anchors.centerIn: Overlay.overlay
            }
        }

        Component {
            id: portfolio

            Portfolio {}
        }

        Component {
            id: wallet

            Wallet {}
        }

        Component {
            id: exchange

            Exchange {}
        }

        Component {
            id: addressbook

            AddressBook {}
        }

        Component {
            id: news

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                DefaultText {
                    anchors.centerIn: parent
                    text_value: qsTr("Content for this section will be added later. Stay tuned!")
                }
            }
        }

        Component {
            id: dapps

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                DefaultText {
                    anchors.centerIn: parent
                    text_value: qsTr("Content for this section will be added later. Stay tuned!")
                }
            }
        }

        Component {
            id: settings

            Settings {
                Layout.alignment: Qt.AlignCenter
            }
        }

        Component {
            id: support

            Support {
                Layout.alignment: Qt.AlignCenter
            }
        }

        Component {
            id: fiat_ramp

            FiatRamp {

            }
        }

        WebEngineView
        {
            id: webEngineView
            backgroundColor: "transparent"
        }

        DefaultLoader {
            id: loader

            anchors.fill: parent
            transformOrigin: Item.Center
            asynchronous: true

            sourceComponent: {
                switch (current_page) {
                    case idx_dashboard_portfolio:
                        return portfolio
                    case idx_dashboard_wallet:
                        return wallet
                    case idx_dashboard_exchange:
                        return exchange
                    case idx_dashboard_addressbook:
                        return addressbook
                    case idx_dashboard_news:
                        return news
                    case idx_dashboard_dapps:
                        return dapps
                    case idx_dashboard_settings:
                        return settings
                    case idx_dashboard_support:
                        return support
                    case idx_dashboard_fiat_ramp:
                        return fiat_ramp
                    default:
                        return undefined
                }
            }
        }

        Item {
            visible: !loader.visible

            anchors.fill: parent

            DexBusyIndicator {
                anchors.centerIn: parent
                running: !loader.visible
            }
        }
    }

    // Sidebar, left side
    Sidebar {
        id: sidebar
        y: -30
    }

    DropShadow {
        anchors.fill: sidebar
        source: sidebar
        cached: false
        horizontalOffset: 0
        verticalOffset: 0
        radius: DexTheme.sidebarShadowRadius
        samples: 32
        spread: 0
        color: DexTheme.colorSidebarDropShadow
        smooth: true
    }

    ModalLoader {
        id: add_custom_coin_modal
        sourceComponent: AddCustomCoinModal {}
    }

    // CEX Rates info
    ModalLoader {
        id: cex_rates_modal
        sourceComponent: CexInfoModal {}
    }
    ModalLoader {
        id: min_trade_modal
        sourceComponent: MinTradeModal {}
    }

    ModalLoader {
        id: restart_modal
        sourceComponent: RestartModal {}
    }

    function getStatusColor(status) {
        switch (status) {
            case "matching":
                return Style.colorYellow
            case "matched":
            case "ongoing":
            case "refunding":
                return Style.colorOrange
            case "successful":
                return DexTheme.greenColor
            case "failed":
            default:
                return DexTheme.redColor
        }
    }

    function isSwapDone(status) {
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

    function getStatusStep(status) {
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

    function getStatusText(status, short_text=false) {
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

    function getStatusTextWithPrefix(status, short_text = false) {
        return getStatusStep(status) + " " + getStatusText(status, short_text)
    }

    function getEventText(event_name) {
        switch (event_name) {
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
