import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

TextField
{
    id: text_field

    property alias left_text: left_text.text_value
    property alias right_text: right_text.text_value
    property alias radius: background.radius
    property color backgroundColor: Dex.CurrentTheme.textFieldBackgroundColor
    property color backgroundColorActive: Dex.CurrentTheme.textFieldActiveBackgroundColor
    property bool forceFocus: false

    font: DexTypo.body2
    placeholderTextColor: Dex.CurrentTheme.textPlaceholderColor
    selectedTextColor: Dex.CurrentTheme.textSelectedColor
    selectionColor: Dex.CurrentTheme.textSelectionColor
    color: enabled ? Dex.CurrentTheme.foregroundColor : Dex.CurrentTheme.textDisabledColor

    // Right click Context Menu
    selectByMouse: true
    persistentSelection: true

    leftPadding: Math.max(0, left_text.width + 20)
    rightPadding: Math.max(0, right_text.width + 20)

    background: DefaultRectangle
    {
        id: background
        color: text_field.focus ? backgroundColorActive : backgroundColor
        radius: 18
        anchors.fill: parent
    }

    Behavior on color
    {
        ColorAnimation
        {
            duration: Style.animationDuration
        }
    }

    Behavior on placeholderTextColor
    {
        ColorAnimation
        {
            duration: Style.animationDuration
        }
    }

    RightClickMenu {}

    DexLabel
    {
        id: left_text
        visible: text_value !== ""
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: Dex.CurrentTheme.textFieldPrefixColor
        font.pixelSize: text_field.font.pixelSize
    }

    DexLabel
    {
        id: right_text
        visible: text_value !== ""
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: Dex.CurrentTheme.textFieldSuffixColor
        font.pixelSize: text_field.font.pixelSize
    }

    Component.onCompleted:
    {
        if (forceFocus) text_field.forceActiveFocus()
    }

    onVisibleChanged: {
        if (forceFocus && visible) text_field.forceActiveFocus()
    }
}
