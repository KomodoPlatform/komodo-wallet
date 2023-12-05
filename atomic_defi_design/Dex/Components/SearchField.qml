import QtQuick 2.12
import QtQuick.Controls 2.2

import Qaterial 1.0 as Qaterial

import "../Constants"
import Dex.Themes 1.0 as Dex

Rectangle
{
    property int   searchIconLeftMargin: 13
    property var   searchModel: API.app.portfolio_pg.global_cfg_mdl.all_proxy
    property alias searchIcon: _searchIcon
    property alias textField: _textField
    property alias forceFocus: _textField.forceFocus

    color: Dex.CurrentTheme.accentColor
    radius: 18

    DefaultImage
    {
        id: _searchIcon
        anchors.left: parent.left
        anchors.leftMargin: searchIconLeftMargin
        anchors.verticalCenter: parent.verticalCenter

        width: 12
        height: 12

        source: General.image_path + "exchange-search.svg"

        DexColorOverlay
        {
            anchors.fill: parent
            source: parent
            color: Dex.CurrentTheme.textPlaceholderColor
        }
    }

    DefaultTextField
    {
        id: _textField

        anchors.left: _searchIcon.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - 5
        height: parent.height
        background: null
        font.pixelSize: 14

        placeholderText: qsTr("Search")
        placeholderTextColor: Dex.CurrentTheme.textPlaceholderColor

        onTextChanged: Array.isArray(searchModel) ? "" : searchModel.setFilterFixedString(_textField.text)


        Component.onDestruction: Array.isArray(searchModel) ? "" : searchModel.setFilterFixedString("")
    }

    DefaultRectangle
    {
        id: _clearIcon
        visible: _textField.text != ""
        anchors.right: parent.right
        anchors.rightMargin: searchIconLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        color: mouseArea.containsMouse ? Dex.CurrentTheme.buttonColorHovered : "transparent"

        width: 20
        height: 20

        Qaterial.ColorIcon
        {
            anchors.centerIn: parent
            iconSize: 12
            color: Dex.CurrentTheme.textPlaceholderColor
            source: Qaterial.Icons.close
        }

        DefaultMouseArea
        {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: _textField.text = ""
        }
    }
}
