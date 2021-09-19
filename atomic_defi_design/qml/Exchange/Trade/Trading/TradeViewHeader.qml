import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

import Qaterial 1.0 as Qaterial
import Qt.labs.settings 1.0

import AtomicDEX.MarketMode 1.0
import AtomicDEX.TradingError 1.0

import AtomicDEX.TradingMode 1.0

import "../" as OtherPage

import "../../../Components"

import App 1.0


Item {
    height: 40
    visible: true
    width: parent.width-5
    anchors.horizontalCenterOffset: 5
    anchors.horizontalCenter: parent.horizontalCenter
    y: -20

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Rectangle {
            width: _learnRow.implicitWidth+15
            height: 25
            radius: height/2
            visible: false
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            color: tuto_area.containsMouse? 'transparent' : DexTheme.accentColor
            Row {
                id: _learnRow 
                anchors.centerIn: parent
                spacing: 10
                Qaterial.ColorIcon {
                    source: Qaterial.Icons.televisionPlay
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 15
                    color: tuto_area.containsMouse? DexTheme.accentColor : DexTheme.surfaceColor
                }
                DexLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    font.weight: Font.Medium
                    color: tuto_area.containsMouse? DexTheme.accentColor : DexTheme.surfaceColor
                    text: qsTr("How to trade")
                }
            }
            DexMouseArea {
                id: tuto_area
                hoverEnabled: true
                anchors.fill: parent
            }
        }
        Rectangle {
            width: _faqRow.implicitWidth+15
            height: 25
            radius: height/2
            visible: false
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            color: faq_area.containsMouse? 'transparent' : DexTheme.accentColor
            Row {
                id: _faqRow
                anchors.centerIn: parent
                spacing: 10
                DexLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    font.weight: Font.Medium
                    color: faq_area.containsMouse? DexTheme.accentColor : DexTheme.surfaceColor
                    text: qsTr("FAQ")
                }
            }
            DexMouseArea {
                id: faq_area
                hoverEnabled: true
                anchors.fill: parent
            }
        }  
        Rectangle {
            width: 40
            height: 25
            visible: API.app.trading_pg.current_trading_mode == TradingMode.Pro
            radius: height/2
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            color: cog_area.containsMouse? 'transparent' :  API.app.trading_pg.current_trading_mode == TradingMode.Pro ? _viewLoader.item.dexConfig.visible? 'transparent' : DexTheme.accentColor : DexTheme.accentColor
            Row {
                anchors.centerIn: parent
                spacing: 10
                Qaterial.ColorIcon {
                    source: Qaterial.Icons.cog
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 15
                    color: cog_area.containsMouse? DexTheme.accentColor : API.app.trading_pg.current_trading_mode == TradingMode.Pro ? _viewLoader.item.dexConfig.visible? DexTheme.accentColor : DexTheme.surfaceColor  : DexTheme.surfaceColor
                }
            }
            DexMouseArea {
                id: cog_area
                hoverEnabled: true
                anchors.fill: parent
                onClicked: {
                    if(API.app.trading_pg.current_trading_mode == TradingMode.Pro) {
                        if(_viewLoader.item.dexConfig.visible){
                            _viewLoader.item.dexConfig.close()
                        }else {
                            _viewLoader.item.dexConfig.openAt(mapToItem(Overlay.overlay, width / 2, height), Item.Top)
                        }    
                    } 
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 5
        Item {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            Rectangle {
                id: background_rect
                width: 70
                height: 30
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: DexTheme.tabBarBackgroudColor
                Behavior on x {
                    NumberAnimation {
                        duration: 200
                    }
                }
                x: API.app.trading_pg.current_trading_mode != TradingMode.Pro ? 0 : 70
            }
            RowLayout {
                anchors.fill: parent
                spacing: 0
                DexLabel {
                    text: "Simple"
                    Layout.preferredWidth: 70
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    color: DexTheme.foregroundColor
                    DexMouseArea {
                        id: simple_area
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: {
                            background_rect.x = 0
                            API.app.trading_pg.current_trading_mode = TradingMode.Simple
                        }
                    }
                }
                DexLabel {
                    text: "Pro"
                    Layout.preferredWidth: 70
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    color: DexTheme.foregroundColor
                    DexMouseArea {
                        id: pro_area
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: {
                            background_rect.x = 70
                            API.app.trading_pg.current_trading_mode = TradingMode.Pro
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        } 
    }
}
