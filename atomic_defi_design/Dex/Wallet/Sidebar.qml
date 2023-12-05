import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0

import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex

// Coins bar at left side
Item
{
    id: root

    function reset() { resetted() }

    signal resetted()

    Layout.alignment: Qt.AlignLeft
    Layout.fillHeight: true
    Layout.preferredWidth: 175

    // Background
    DefaultRectangle
    {
        id: background
        radius: 0
        width: parent.width
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin : - border.width
        anchors.topMargin : - border.width
        anchors.bottomMargin:  - border.width
        anchors.leftMargin: - border.width
        border.width: 0
        color: 'transparent'

        // Panel contents
        Item
        {
            id: coins_bar
            width: 175
            height: parent.height
            anchors.right: parent.right

            ColumnLayout
            {
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 10
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // Searchbar
                SearchField
                {
                    id: searchCoinField

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    textField.placeholderText: qsTr("Search")
                    forceFocus: true
                    searchModel: portfolio_coins
                }

                // Coins list
                InnerBackground
                {
                    id: list_bg
                    Layout.preferredWidth: 145
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    color: 'transparent'
                    content: Dex.ListView
                    {
                        id: list
                        height: list_bg.height
                        model: portfolio_coins
                        scrollbar_visible: false

                        reuseItems: true

                        delegate: SidebarItemDelegate { }

                    }
                }
            }
        }
    }

    // Right separator
    VerticalLine
    {
        anchors.right: parent.right
        height: parent.height
    }
}
