import QtQuick 2.12

import "../Components"
import "../Constants"
import Dex.Themes 1.0 as Dex

Item
{
    id: root

    enum LineType
    {
        Portfolio,
        Wallet,
        DEX,         // DEX == Trading page
        Addressbook,
        Support
    }

    property bool   isExpanded: true
    property real   lineHeight: 36
    property var    currentLineType: Main.LineType.Portfolio
    property alias  _selectionCursor: _selectionCursor
    property bool   containsMouse: mouseArea.containsMouse

    signal lineSelected(var lineType)
    signal settingsClicked()
    signal supportClicked()
    signal addCryptoClicked()
    signal privacySwitched(var checked)
    signal expanded(var isExpanded)
    signal expandStarted(var isExpanding)

    width: 150
    height: parent.height

    // Background Rectangle
    DefaultRectangle
    {
        radius: 0
        anchors.fill: parent
        anchors.rightMargin : - border.width
        anchors.bottomMargin:  - border.width
        anchors.leftMargin: - border.width
        border.width: 1
        border.color: Dex.CurrentTheme.lineSeparatorColor
        color: Dex.CurrentTheme.sidebarBgColor
    }

    // Animation when changing width.
    // Behavior on width
    // {
    //    NumberAnimation { duration: 300; targets: [width, _selectionCursor.width]; properties: "width"; onRunningChanged: { if (!running) expanded(isExpanded); else expandStarted(isExpanded); } }
    // }

    // Selection Cursor
    AnimatedRectangle
    {
        id: _selectionCursor

        y:
        {
            if (currentLineType === Main.LineType.Support) return bottom.y + lineHeight + bottom.spacing;
            else return center.y + currentLineType * (lineHeight + center.spacing);
        }

        anchors.left: parent.left
        anchors.leftMargin: 12
        radius: 12
        width: parent.width - 20
        height: lineHeight

        opacity: .7

        gradient: Gradient
        {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.125; color: Dex.CurrentTheme.sidebarCursorStartColor }
            GradientStop { position: 0.933; color: Dex.CurrentTheme.sidebarCursorEndColor }
        }

        Behavior on y
        {
            NumberAnimation { duration: 180 }
        }
    }

    MouseArea
    {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        Top
        {
            id: top
            width: parent.width
            height: 180
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
        }

        Center
        {
            id: center
            width: parent.width
            anchors.top: top.bottom
            anchors.topMargin: 70
            onLineSelected:
            {
                if (currentLineType === lineType)
                    return;
                currentLineType = lineType;
                root.lineSelected(lineType);
            }
        }

        Bottom
        {
            id: bottom
            width: parent.width
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60

            onAddCryptoClicked: root.addCryptoClicked()
            onSettingsClicked: root.settingsClicked()
            onSupportClicked: root.supportClicked()
        }
    }
}
