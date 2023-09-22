import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0


import QtQuick.Window 2.12

import Qaterial 1.0 as Qaterial

// Project Imports
import "../Components"
import "../Constants"
import App 1.0
Item
{
    anchors.margins: 10

    Column
    {
        anchors.fill: parent
        topPadding: 10
        spacing: 15

        RowLayout
        {
            width: parent.width - 30
            anchors.horizontalCenter: parent.horizontalCenter
            height: 50
            spacing: 10

            DexLabel
            {
                Layout.alignment: Qt.AlignVCenter
                font: DexTypo.subtitle1
                text: qsTr("Language") + ":"
            }

            Item { Layout.fillWidth: true }

            Languages
            {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout
        {
            Layout.topMargin: 10
            width: parent.width - 30
            anchors.horizontalCenter: parent.horizontalCenter
            height: 50

            DexLabel
            {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font: DexTypo.subtitle1
                text: qsTr("Fiat")
            }

            Item { Layout.fillWidth: true }

            DexComboBox
            {
                id: combo_fiat
                width: 100
                height: 30
                model: fiats
                property bool initialized: false

                onCurrentIndexChanged:
                {
                    if(initialized)
                    {
                        const new_fiat = fiats[currentIndex]
                        API.app.settings_pg.current_fiat = new_fiat
                        API.app.settings_pg.current_currency = new_fiat
                        setting_modal.recommended_fiats = API.app.settings_pg.get_recommended_fiats()
                    }
                }

                Component.onCompleted:
                {
                    currentIndex = model.indexOf(API.app.settings_pg.current_fiat)
                    initialized = true
                }
            }
        }

        RowLayout
        {
            Layout.topMargin: 10
            width: parent.width - 30
            anchors.horizontalCenter: parent.horizontalCenter
            height: 50

            DexText
            {
                text: qsTr("Recommended: ")
                font.pixelSize: Style.textSizeSmall4
            }

            Item { Layout.fillWidth: true }

            Grid
            {
                Layout.leftMargin: 30
                Layout.alignment: Qt.AlignVCenter

                clip: true

                columns: 6
                spacing: 25

                layoutDirection: Qt.LeftToRight

                Repeater
                {
                    model: recommended_fiats

                    delegate: DexText
                    {
                        text: modelData
                        color: DexTheme.foregroundColor
                        opacity: text == API.app.settings_pg.current_fiat ? 1 : fiats_mouse_area.containsMouse ? .8 : .6

                        DexMouseArea
                        {
                            id: fiats_mouse_area
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked:
                            {
                                API.app.settings_pg.current_fiat = modelData
                                API.app.settings_pg.current_currency = modelData
                                combo_fiat.currentIndex = combo_fiat.model.indexOf(API.app.settings_pg.current_fiat)
                            }
                        }
                    }
                }
            }
        }
    }
}

