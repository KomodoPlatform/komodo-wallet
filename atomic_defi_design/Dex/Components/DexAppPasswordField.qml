import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

import Qaterial 1.0 as Qaterial

import App 1.0
import Dex.Themes 1.0 as Dex
import "../Constants"

DexAppTextField
{
    id: _inputPassword

    property bool forceFocus: false
    property string leftIcon: Qaterial.Icons.keyVariant
    property color leftIconColor: Dex.CurrentTheme.inputLeftIconColor
    property color rightIconColor: Dex.CurrentTheme.inputRightIconColor
    property alias hideFieldButton: _hideFieldButton

    height: 50
    width: 300
    background.radius: 25
    max_length: General.max_std_pw_length

    field.echoMode: TextField.Password
    field.font: DexTypo.inputFieldFont
    field.horizontalAlignment: Qt.AlignLeft
    field.leftPadding: 75
    field.rightPadding: 60
    field.placeholderText: qsTr("Type password")

    Component.onCompleted:
    {
        if (forceFocus) field.forceActiveFocus()
    }

    DefaultRectangle
    {
        x: 5
        height: 40
        width: 60
        radius: 20
        color: Dex.CurrentTheme.inputLeftIconBackgroundColor
        border.width: _inputPassword.focus ? 2 : 0

        anchors.verticalCenter: parent.verticalCenter
        Qaterial.ColorIcon
        {
            anchors.centerIn: parent
            iconSize: 19
            color: leftIconColor
            source: _inputPassword.leftIcon
        }
    }

    Qaterial.AppBarButton
    {
        id: _hideFieldButton

        opacity: .8
        icon
        {
            source: _inputPassword.field.echoMode === TextField.Password ? Qaterial.Icons.eyeOffOutline : Qaterial.Icons.eyeOutline
            color: rightIconColor
        }
        anchors
        {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 10
        }
        onClicked:
        {
            if (_inputPassword.field.echoMode === TextField.Password) _inputPassword.field.echoMode = TextField.Normal;
            else _inputPassword.field.echoMode = TextField.Password;
        }
    }
}