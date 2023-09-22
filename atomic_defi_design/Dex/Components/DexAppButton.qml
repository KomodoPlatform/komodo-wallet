//! Qt Imports
import QtQuick 2.15

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

//! Project Imports
import Dex.Themes 1.0 as Dex
import "../Constants"
import App 1.0

DexRectangle
{
    id: control

    property string text: ""
    property string iconSource: ""
    property int    padding: 12
    property int    spacing: 4
    property int    verticalAlignment: Qt.AlignVCenter
    property int    horizontalAlignment: Qt.AlignHCenter
    property int    verticalPadding: 2
    property int    horizontalPadding: 2
    property int    iconSize: _label.font.pixelSize + 2
    property color  iconColor: _label.color

    property color btnPressedColor:  Dex.CurrentTheme.buttonColorPressed
    property color btnHoveredColor:  Dex.CurrentTheme.buttonColorHovered
    property color btnEnabledColor:  Dex.CurrentTheme.buttonColorEnabled
    property color btnDisabledColor: Dex.CurrentTheme.buttonColorDisabled

    property alias label: _label
    property alias font: _label.font
    property alias content: _contentRow
    property alias leftPadding: _contentRow.leftPadding
    property alias rightPadding: _contentRow.rightPadding
    property alias topPadding: _contentRow.topPadding
    property alias bottomPadding: _contentRow.bottomPadding
    property alias text_obj: _label
    property alias containsMouse: _controlMouseArea.containsMouse

    signal clicked()

    radius: 5
    height: _label.implicitHeight + (padding * verticalPadding)
    width: _contentRow.implicitWidth + (padding * horizontalPadding)

    colorAnimation: false
    color: enabled ? _controlMouseArea.containsMouse ? _controlMouseArea.containsPress ?
               btnPressedColor : btnHoveredColor : btnEnabledColor : btnDisabledColor
    opacity: _controlMouseArea.containsMouse ? 1 : .8

    Row
    {
        id: _contentRow

        anchors
        {
            horizontalCenter: parent.horizontalAlignment == Qt.AlignHCenter ? parent.horizontalCenter : undefined
            verticalCenter: parent.verticalAlignment == Qt.AlignVCenter ? parent.verticalCenter : undefined
        }

        spacing: _icon.visible ? parent.spacing : 0

        Qaterial.ColorIcon
        {
            id: _icon
            iconSize: control.iconSize
            visible: control.iconSource === "" ? false : true
            source: control.iconSource
            color: _label.color
            anchors.verticalCenter: parent.verticalCenter
        }

        DexLabel
        {
            id: _label
            anchors.verticalCenter: parent.verticalCenter
            font: DexTypo.body2
            text: control.text
            color: enabled ? _controlMouseArea.containsMouse ? _controlMouseArea.containsPress ?
                    Dex.CurrentTheme.buttonTextPressedColor :
                    Dex.CurrentTheme.buttonTextHoveredColor :
                    Dex.CurrentTheme.buttonTextEnabledColor :
                    Dex.CurrentTheme.buttonTextDisabledColor
        }
    }

    DexMouseArea
    {
        id: _controlMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: control.clicked()
    }
}
