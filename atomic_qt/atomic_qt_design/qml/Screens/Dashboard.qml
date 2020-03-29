import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import "../Components"
import "../Constants"

import "../Portfolio"
import "../Wallet"
import "../Exchange"
import "../Settings"
import "../Sidebar"

Item {
    id: dashboard

    Layout.fillWidth: true

    property int prev_page: -1
    property int current_page: API.design_editor ? General.idx_dashboard_exchange : General.idx_dashboard_portfolio

    function reset() {
        current_page = General.idx_dashboard_portfolio
        prev_page = -1

        // Reset all sections
        portfolio.reset()
        wallet.reset()
        exchange.reset()
        news.reset()
        dapps.reset()
        settings.reset()
    }

    function inCurrentPage() {
        return app.current_page === idx_dashboard
    }

    onCurrent_pageChanged: {
        if(prev_page !== current_page) {
            if(current_page === General.idx_dashboard_exchange) {
                API.get().on_gui_enter_dex()
                exchange.onOpened()
            }
            else if(prev_page === General.idx_dashboard_exchange) {
                API.get().on_gui_leave_dex()
            }

            if(current_page === General.idx_dashboard_portfolio) {
                portfolio.onOpened()
            }
        }

        prev_page = current_page
    }

    Timer {
        running: inCurrentPage()
        interval: 1000
        repeat: true
        onTriggered: General.enableEthIfNeeded()
    }

    // Left side
    Rectangle {
        color: Style.colorTheme6
        width: parent.width - sidebar.width
        height: parent.height

        // Modals
        EnableCoinModal {
            id: enable_coin_modal
            anchors.centerIn: Overlay.overlay
        }

        StackLayout {
            currentIndex: current_page

            anchors.fill: parent

            transformOrigin: Item.Center

            Portfolio {
                id: portfolio
            }

            Wallet {
                id: wallet
            }

            Exchange {
                id: exchange
            }

            DefaultText {
                id: news
                text: API.get().empty_string + (qsTr("News"))
                function reset() { }
            }

            DefaultText {
                id: dapps
                text: API.get().empty_string + (qsTr("DApps"))
                function reset() { }
            }

            Settings {
                id: settings
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    // Sidebar, right side
    Rectangle {
        id: sidebar
        color: Style.colorTheme8
        width: 150
        height: parent.height
        x: parent.width - width

        Image {
            source: General.image_path + "komodo-icon.png"
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.width * 0.25
            transformOrigin: Item.Center
            width: 64
            fillMode: Image.PreserveAspectFit
        }

        Sidebar {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}



/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:1200}
}
##^##*/
