// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15

// Project Imports
import "../Constants"
import App 1.0

MultipageModal {
    id: root

    // Inside modal
    MultipageModalContent {
        titleText: General.cex_icon + " " + qsTr("Market Data")

        DefaultText {
            Layout.preferredHeight: 200
            Layout.fillWidth: true

            text: qsTr('Market data (prices, charts, etc.) marked with the ⓘ icon originates from third-party sources.<br><br>Data is sourced via <a href="https://coingecko.com">CoinGecko</a>.')
        }
    }
}
