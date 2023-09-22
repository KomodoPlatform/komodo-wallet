import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0

import "../../../Constants" as Dex
import "../../../Components"
import App 1.0
import Dex.Themes 1.0 as Dex

// todo: coding style is wrong, use camelCase.
RowLayout
{
    id: control
    property alias  fiat_value: _fiat_label.text_value
    property alias  left_label: _left_label.text
    property alias  middle_label: _middle_label.text
    property alias  right_label: _right_label.text
    property string left_tooltip_text: ""
    property string middle_tooltip_text: ""
    property string right_tooltip_text: ""
    property alias  left_btn: _left_btn
    property alias  middle_btn: _middle_btn
    property alias  right_btn: _right_btn
    property int    pixel_size: 12
    property int    btn_width: 33
    spacing: 2
    height: 20
    width: parent.width

    Item
    {
        width: btn_width
        height: parent.height

        DefaultRectangle
        {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: Dex.CurrentTheme.inputModifierBackgroundColor
        }

        DefaultText
        {
            id: _left_label
            anchors.centerIn: parent
            font.pixelSize: pixel_size
            color: Dex.CurrentTheme.foregroundColor2
            text: "-1%"
        }

        DexTooltip
        {
            id: _left_tooltip
            visible: _left_btn.containsMouse && left_tooltip_text != ""
            
            contentItem: FloatingBackground
            {
                anchors.top: parent.bottom
                anchors.topMargin: 30
                color: Dex.CurrentTheme.accentColor

                DefaultText
                {
                    text: left_tooltip_text
                    font: Dex.DexTypo.caption
                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 6
                    bottomPadding: 6
                }
            }

            background: Rectangle {
                width: 0
                height: 0
                color: "transparent"
            }
        }

        DefaultMouseArea
        {
            id: _left_btn
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    Item
    {

        width: btn_width
        height: parent.height

        DefaultRectangle
        {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: Dex.CurrentTheme.inputModifierBackgroundColor

            DefaultMouseArea
            {
                id: _middle_btn
                anchors.fill: parent
                hoverEnabled: true
            }

            DefaultText
            {
                id: _middle_label
                anchors.centerIn: parent
                font.pixelSize: pixel_size
                color: Dex.CurrentTheme.foregroundColor2
                text: "0%"
            }

            DexTooltip
            {
                id: _middle_tooltip
                visible: _middle_btn.containsMouse && middle_tooltip_text != ""

                contentItem: FloatingBackground
                {
                    anchors.top: parent.bottom
                    anchors.topMargin: 30
                    color: Dex.CurrentTheme.accentColor

                    DefaultText
                    {
                        text: middle_tooltip_text
                        font: Dex.DexTypo.caption
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                    }
                }

                background: Rectangle {
                    width: 0
                    height: 0
                    color: "transparent"
                }
            }
        }
    }

    Item
    {

        width: btn_width
        height: parent.height

        DefaultRectangle
        {
            id: right_rect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: Dex.CurrentTheme.inputModifierBackgroundColor
        }

        DefaultText
        {
            id: _right_label
            anchors.centerIn: parent
            font.pixelSize: pixel_size
            color: Dex.CurrentTheme.foregroundColor2
            text: "+1%"
        }

        DexTooltip
        {
            id: _right_tooltip
            visible: _right_btn.containsMouse && right_tooltip_text != ""


            contentItem: FloatingBackground
            {
                anchors.top: parent.bottom
                anchors.topMargin: 30
                color: Dex.CurrentTheme.accentColor

                DefaultText
                {
                    text: right_tooltip_text
                    font: Dex.DexTypo.caption
                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 6
                    bottomPadding: 6
                }
            }

            background: Rectangle {
                width: 0
                height: 0
                color: "transparent"
            }
        }

        DefaultMouseArea
        {
            id: _right_btn
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    Item { Layout.fillWidth: true }

    DefaultText
    {
        id: _fiat_label
        font.pixelSize: pixel_size
        color: Dex.CurrentTheme.foregroundColor2
        DefaultInfoTrigger { triggerModal: cex_info_modal }
    }
}