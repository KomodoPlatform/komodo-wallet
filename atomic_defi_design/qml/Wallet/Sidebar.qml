import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import QtGraphicalEffects 1.0
import "../Components"
import "../Constants" as Constants
import App 1.0

// Coins bar at left side
Item {
    id: root

    function reset() {
        resetted()
    }

    signal resetted()

    Layout.alignment: Qt.AlignLeft
    width: 175
    Layout.fillHeight: true
    Layout.topMargin: - 40 

    // Background
    SidebarPanel {
        id: background
        anchors.right: parent.right
        width: sidebar.width + parent.width

        height: parent.height 

        // Panel contents
        Item {
            id: coins_bar
            width: 175
            height: parent.height
            anchors.right: parent.right

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 30
                anchors.bottomMargin: 30
                anchors.leftMargin: 10
                anchors.rightMargin: 20
                spacing: 40
                InnerBackground {
                    id: search_row_bg
                    Layout.preferredWidth: 145
                    radius: 14
                    Layout.alignment: Qt.AlignHCenter
                    color: DexTheme.contentColorTop
                    shadowOff: true

                    content: RowLayout {
                        id: search_row

                        width: search_row_bg.width

                        // Search button
                        Item {
                            Layout.alignment: Qt.AlignLeft
                            Layout.leftMargin: search_button.width
                            Layout.rightMargin: -Layout.leftMargin
                            width: search_button.width
                            height: search_button.height
                            DefaultImage {
                                id: search_button

                                source: Constants.General.image_path + "exchange-search.svg"

                                width: input_coin_filter.font.pixelSize; height: width

                                visible: false
                            }
                            DefaultColorOverlay {
                                id: search_button_overlay

                                anchors.fill: search_button
                                source: search_button
                                color: DexTheme.foregroundColor
                            }
                        }

                        // Search input
                        DefaultTextField {
                            id: input_coin_filter

                            Connections {
                                target: root

                                function onResetted() {
                                    if(input_coin_filter.text === "") resetCoinFilter()
                                    else input_coin_filter.text = ""

                                    //portfolio_coins.sort_by_name(true)
                                }
                            }
                            placeholderText: qsTr("Search coin")

                            onTextChanged: portfolio_coins.setFilterFixedString(text)
                            font.pixelSize: Constants.Style.textSizeSmall3

                            background: null

                            Layout.fillWidth: true

                            Component.onDestruction: portfolio_coins.setFilterFixedString("")
                        }
                    }
                }

                // Add button
                

                // Coins list
                InnerBackground {
                    id: list_bg
                    Layout.preferredWidth: 145
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    color: 'transparent'
                    shadowOff: true
                    content: DexListView {
                        id: list
                        height: list_bg.height
                        model: portfolio_coins
                        topMargin: 5
                        bottomMargin: 5
                        scrollbar_visible: false
                        DexRectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width + 4
                            height: 30
                            radius: 8
                            opacity: .5
                            visible: list.position < (.98 - list.scrollVert.visualSize) ? true : false
                            Qaterial.Icon {
                                anchors.centerIn: parent
                                color: DexTheme.foregroundColor
                                icon: Qaterial.Icons.arrowDownCircleOutline
                            }
                        }

                        DexRectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width + 4
                            height: 30
                            radius: 8
                            opacity: .5
                            visible: list.position > 0 ? true : false
                            Qaterial.Icon {
                                anchors.centerIn: parent
                                color: DexTheme.foregroundColor
                                icon: Qaterial.Icons.arrowUpCircleOutline
                            }
                        }

                        reuseItems: true

                        delegate: SidebarItemDelegate { }
                    }
                }

                DexAppButton {
                    id: add_coin_button
                    onClicked: enable_coin_modal.open()
                    Layout.alignment:  Qt.AlignHCenter
                    Layout.preferredWidth: 140
                    radius: 18
                    spacing: 2
                    font: Qt.font({
                        pixelSize: 9 * DexTypo.fontDensity,
                        letterSpacing: 1.25,
                        capitalization: Font.AllUppercase,
                        family: DexTypo.fontFamily,
                        weight: Font.Normal
                    })
                    text: qsTr("Add asset")
                    iconSource: Qaterial.Icons.plus
                    leftPadding: 3
                    rightPadding: 3

                }
            }

            VerticalLine {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                opacity: .3
                anchors.topMargin: anchors.bottomMargin
                color: DexTheme.walletSidebarLeftBorderColor
            }

            
        }
    }

     DexRectangle {
        anchors.right: parent.right
        height: parent.height
        width: 1
        color: DexTheme.sideBarRightBorderColor
        border.width: 0
    }

    DropShadow {
        anchors.fill: background
        source: background
        cached: false
        horizontalOffset: 0
        verticalOffset: 0
        radius: 32
        samples: 32
        spread: 0
        visible: DexTheme.walletSidebarShadowVisibility
        color: Constants.Style.colorWalletsSidebarDropShadow
        smooth: true
    }
}
