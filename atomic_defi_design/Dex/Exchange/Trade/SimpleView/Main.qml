//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

//! Project Imports
import "../../../Components"
import "../../../Constants"  as Constants 
import "../../ProView/TradingInfo" as Orders
import "Main.js" as Main
import App 1.0
import Dex.Themes 1.0 as Dex

Item
{
    id: root
    readonly property var subPages: Main.getSubPages()

    // Variable which holds the current sub-page of the SimpleView.
    property var currentSubPage: subPages.Trade

    onCurrentSubPageChanged: _selectedTabMarker.update()

    Connections
    {
        target: exchange_trade
        function onOrderPlaced()
        {
            currentSubPage = subPages.Orders
        }
    }

    Column
    {
        width: root.currentSubPage === subPages.Trade ? _simpleTrade.best ? 600 : 450 : 450
        y: 80
        spacing: 30
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle // Tabs Border
        {
            anchors.horizontalCenter: parent.horizontalCenter
            width: _selectedTabMarker.width * 3 + 8
            height: 38
            border.color: Dex.CurrentTheme.gradientButtonStartColor
            border.width: 1
            color: Dex.CurrentTheme.floatingBackgroundColor
            radius: 19

            Item // Sub-pages Tabs Selector
            {
                anchors.centerIn: parent
                width: _selectedTabMarker.width * 3
                height: 30

                Rectangle // Selected Tab Rectangle
                {
                    id: _selectedTabMarker

                    function update() // Updates transform according to selected sub-page.
                    {
                        switch (currentSubPage)
                        {
                        case subPages.Trade:
                            x = 0
                            break;
                        case subPages.Orders:
                            x = (parent.width / 3) 
                            orders_view.update()
                            break;
                        case subPages.History:
                            x = (parent.width / 3) * 2
                            history_view.update()
                            break;
                        }
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: 108
                    radius: 15
                    color: Dex.CurrentTheme.tabSelectedColor

                    Behavior on x { NumberAnimation { duration: 150 } }
                }

                RowLayout
                {
                    anchors.fill: parent
                    spacing: 0

                    ClickableText
                    {
                        id: _tradeText
                        Layout.preferredWidth: parent.width / 3
                        Layout.fillHeight: true
                        text: qsTr("Swap")
                        font.pixelSize: Constants.Style.textSize
                        onClicked: if (currentSubPage !== subPages.Trade) currentSubPage = subPages.Trade
                    }

                    ClickableText
                    {
                        id: _ordersText
                        Layout.preferredWidth: parent.width / 3
                        Layout.fillHeight: true
                        text: qsTr("Orders")
                        font.pixelSize: Constants.Style.textSize
                        onClicked: if (currentSubPage !== subPages.Orders) currentSubPage = subPages.Orders
                    }

                    ClickableText
                    {
                        id: _historyText
                        Layout.preferredWidth: parent.width / 3
                        Layout.fillHeight: true
                        text: qsTr("History")
                        font.pixelSize: Constants.Style.textSize
                        onClicked: if (currentSubPage !== subPages.History) currentSubPage = subPages.History
                    }
                }
            }
        }

        SwipeView
        {
            id: _swipeSimplifiedView
            currentIndex: root.currentSubPage
            anchors.horizontalCenter: parent.horizontalCenter
            width: 600
            height: 650
            clip: true
            interactive: false

            Item
            {
                FloatingBackground
                {
                    id: subTradePage
                    height: _simpleTrade.height
                    width: _simpleTrade.best ? 600 : _simpleTrade.coinSelection ? 450 : 380
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 20

                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on height { NumberAnimation { duration: 250 } }

                    Trade
                    {
                        id: _simpleTrade
                        width: parent.width
                    }
                }
            }

            Item
            {
                FloatingBackground
                {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    height: 500
                    radius: 20

                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on height { NumberAnimation { duration: 250 } }

                    SubOrders { id: orders_view }
                }
            }

            Item
            {
                FloatingBackground
                {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    height: 500
                    radius: 20

                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on height { NumberAnimation { duration: 250 } }

                    SubHistory { id: history_view }
                }
            }
        }
    }

    ModalLoader
    {
        id: order_modal
        sourceComponent: Orders.OrderModal {}
    }
}
