import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Layouts 1.5

import App 1.0
import Dex.Themes 1.0 as Dex
import "../Constants"

Item
{
    id: control
    width: 200
    height: 35

    property int leftWidth: -1
    property int max_length: 180

    property alias field: input_field
    property alias value: input_field.text
    property alias background: _background

    property string leftText: ""
    property string rightText: ""
    property string placeholderText: ""

    property bool error: false

    onErrorChanged:
    {
        if (error)
        {
            _animationTimer.start()
            _animate.start()
        }
    }

    Timer
    {
        id: _animationTimer
        interval: 350
        onTriggered:
        {
            _animate.stop()
            _background.x = 0
        }
    }

    Timer
    {
        id: _animate
        interval: 30
        repeat: true

        onTriggered:
        {
            if (_background.x == -3)
            {
                _background.x = 3
            }
            else
            {
                _background.x = -3
            }
        }
    }

    function reset()
    {
        input_field.text = ""
    }

    Rectangle
    {
        id: _background
        width: parent.width
        height: parent.height
        radius: 4
        color: Dex.CurrentTheme.inputFieldBackgroundColor
        border.color: control.error ? Dex.CurrentTheme.warningColor : input_field.focus ? Dex.CurrentTheme.inputFieldBorderColor : color
        border.width: input_field.focus ? 1 : 0

        Behavior on x
        {
            NumberAnimation
            {
                duration: 40
            }
        }
    }

    RowLayout
    {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 2

        Item
        {
            visible: leftText !== ""
            Layout.preferredWidth: leftWidth !== -1 ? leftWidth : _title_label.implicitWidth + 2
            Layout.fillHeight: true

            DexLabel
            {
                id: _title_label
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 5
                horizontalAlignment: DexLabel.AlignHCenter
                text: leftText
                color: Dex.CurrentTheme.foregroundColor
                opacity: .4
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        Item
        {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle
            {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                radius: _background.radius
                color: Dex.CurrentTheme.inputFieldBackgroundColor

                DexTextField
                {
                    id: input_field
                    anchors.fill: parent
                    horizontalAlignment: Qt.AlignLeft

                    font.weight: Font.Medium
                    font.family: 'Lato'
                    font.pixelSize: 13
                    echoMode: TextInput.Normal
                    background: Item
                    {}

                    onTextChanged:
                    {
                        if (text.length > control.max_length)
                        {
                            text = text.substring(0, control.max_length)
                        }
                        control.error = false
                    }

                }

                DexLabel
                {
                    text: control.placeholderText
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: input_field.leftPadding
                    color: Dex.CurrentTheme.inputPlaceholderTextColor
                    font: DexTypo.inputFieldFont
                    elide: DexLabel.ElideRight
                    width: parent.width - 10
                    wrapMode: DexLabel.NoWrap
                    visible: input_field.text === ""
                }
            }
        }

        Item
        {
            visible: rightText !== ""
            Layout.preferredWidth: _suffix_label.implicitWidth + 2
            Layout.fillHeight: true

            DexLabel
            {
                id: _suffix_label
                anchors.centerIn: parent
                horizontalAlignment: DexLabel.AlignHCenter
                text: rightText
                color: Dex.CurrentTheme.foregroundColor
                opacity: .4
                font: DexTypo.inputFieldSuffixFont
            }
        }
    }
}