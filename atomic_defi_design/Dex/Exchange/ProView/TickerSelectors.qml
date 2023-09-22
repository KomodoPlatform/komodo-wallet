import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"

// Ticker selectors.
Row
{
    id: selectors

    function renewIndex()
    {
        selectorLeft.currentIndex = selectorLeft.indexOfValue(selectorLeft.ticker)
        selectorRight.currentIndex = selectorRight.indexOfValue(selectorRight.ticker)
        selectorLeft.searchBar.textField.text = ""
        selectorRight.searchBar.textField.text = ""
    }

    SearchableTickerSelector
    {
        id: selectorLeft

        width: 210
        height: parent.height

        left_side: true
        model: API.app.trading_pg.market_pairs_mdl.left_selection_box
        ticker: left_ticker
        onTickerChanged: renewIndex()
        Component.onCompleted: renewIndex()
        Component.onDestruction: searchBar.textField.text = ""
        onVisibleChanged:
        {
            renewIndex()
            model.with_balance = false
        }
    }

    SwapIcon
    {
        width: 25
        anchors.verticalCenter: parent.verticalCenter
        top_arrow_ticker: selectorLeft.ticker
        bottom_arrow_ticker: selectorRight.ticker
        hovered: swap_button.containsMouse

        DefaultMouseArea
        {
            id: swap_button
            anchors.fill: parent
            hoverEnabled: true
            onClicked:
            {
                if (!block_everything)
                    setPair(true, right_ticker)
            }
        }
    }

    SearchableTickerSelector
    {
        id: selectorRight

        width: 210
        height: parent.height

        left_side: false
        model: API.app.trading_pg.market_pairs_mdl.right_selection_box
        ticker: right_ticker
        onTickerChanged: renewIndex()
        Component.onCompleted: renewIndex()
        Component.onDestruction: searchBar.textField.text = ""
        onVisibleChanged:
        {
            renewIndex()
            model.with_balance = false
        }
    }
}
