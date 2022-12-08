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
                anchors.topMargin: 30
                anchors.bottomMargin: 30
                anchors.leftMargin: 10
                anchors.rightMargin: 20
                spacing: 20

                // Searchbar
                SearchField
                {
                    id: searchCoinField

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 38

                    textField.placeholderText: qsTr("Search")
                    //forceFocus: true
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
                        topMargin: 5
                        bottomMargin: 5
                        scrollbar_visible: false

                        reuseItems: true

                        delegate: SidebarItemDelegate { }

                        Dex.Rectangle
                        {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width + 4
                            height: 30
                            radius: 8
                            opacity: .5
                            visible: list.position < (.98 - list.scrollVert.visualSize) ? true : false
                            Qaterial.Icon
                            {
                                anchors.centerIn: parent
                                color: Dex.CurrentTheme.foregroundColor
                                icon: Qaterial.Icons.arrowDownCircleOutline
                            }
                        }

                        Dex.Rectangle
                        {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width + 4
                            height: 30
                            radius: 8
                            opacity: .5
                            visible: list.position > 0 ? true : false
                            Qaterial.Icon
                            {
                                anchors.centerIn: parent
                                color: Dex.CurrentTheme.foregroundColor
                                icon: Qaterial.Icons.arrowUpCircleOutline
                            }
                        }
                    }
                }

                DexAppButton {
                    id: add_coin_button
                    onClicked: enable_coin_modal.open()
                    Layout.alignment:  Qt.AlignHCenter
                    Layout.preferredWidth: 140
                    radius: 18
                    spacing: 2
                    label.font: DexTypo.overLine
                    text: qsTr("ADD CRYPTO")
                    iconSource: Qaterial.Icons.plus
                    leftPadding: 3
                    rightPadding: 3
                    btnPressedColor: Dex.CurrentTheme.buttonSecondaryColorPressed
                    btnHoveredColor: Dex.CurrentTheme.buttonSecondaryColorHovered
                    btnEnabledColor: Dex.CurrentTheme.buttonSecondaryColorEnabled
                    btnDisabledColor: Dex.CurrentTheme.buttonSecondaryColorDisabled

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
