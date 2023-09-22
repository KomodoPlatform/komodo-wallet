import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../../../Components"
import "../../../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

Widget
{
    title: qsTr("Order Book")

    margins: 10
    spacing: 10

    Header
    {
        Layout.preferredHeight: 30
        Layout.fillWidth: true
    }

    List
    {
        isAsk: true
        isVertical: true
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    Item
    {
        Layout.preferredHeight: 4
        Layout.fillWidth: true
        Rectangle
        {
            width: parent.width
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            color: Dex.CurrentTheme.floatingBackgroundColor
        }
    }

    List
    {
        isAsk: false
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
