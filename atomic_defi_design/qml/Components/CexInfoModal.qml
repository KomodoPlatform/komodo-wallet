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
            Layout.preferredHeight: 200
            Layout.fillWidth: true

            text: qsTr('Market data (prices, charts, etc.) marked with the ⓘ icon originates from third-party sources.<br><br>Data is sourced via <a href="https://bandprotocol.com/">Band Decentralized Oracle</a> and <a href="https://coingecko.com">CoinGecko</a>.<br><br><b>Oracle Supported Pairs:</b><br>%1<br><br><b>Last reference (Band Oracle):</b><br><a href="%2">%2</a>')
                            .arg(API.app.portfolio_pg.oracle_price_supported_pairs.join(', '))
                            .arg(API.app.portfolio_pg.oracle_last_price_reference)
        }
    }
}
