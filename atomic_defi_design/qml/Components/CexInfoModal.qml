// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15

// Project Imports
import "../Constants"
import App 1.0

BasicModal {
    id: root

    // Inside modal
    ModalContent {
        title: General.cex_icon + " " + qsTr("Market Data")

        DefaultText {
            Layout.preferredHeight: 50
            Layout.fillWidth: true

            text: qsTr('Market data (prices, charts, etc.) marked with the ⓘ icon originates from third-party sources.<br><br>Data is sourced via <a href="https://smartportal.smartfi.com">SmartFi</a> and <a href="https://coingecko.com">CoinGecko</a>.<br><br>')
        }
    }
}
