import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Layouts 1.5
import App 1.0

Item {
    id: control
    width: 200
    height: 35
    signal accepted()
    property alias value: input_field.text
    property alias field: input_field
    property alias background: _background
    readonly property int max_length: 1000
    property color textColor: DexTheme.foregroundColor
    property bool error: false
    onErrorChanged: {
        if (error) {
            _animationTimer.start()
            _animate.start()
        }
    }
    Timer {
        id: _animationTimer
        interval: 350
        onTriggered: {
            _animate.stop()
            _background.x = 0
        }
    }
    Timer {
        id: _animate
        interval: 30
        repeat: true
        onTriggered: {
            if (_background.x == -3) {
                _background.x = 3
            } else {
                _background.x = -3
            }
        }
    }

    function reset() {
        input_field.text = ""
    }
    Rectangle {
        id: _background
        width: parent.width
        height: parent.height
        radius: 4
        color: DexTheme.backgroundDarkColor2
        border.color: control.error ? DexTheme.warningColor : input_field.focus ? DexTheme.accentColor : DexTheme.rectangleBorderColor
        border.width: input_field.focus ? 1 : 0
        Behavior on x {
            NumberAnimation {
                duration: 40
            }
        }
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 2
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                radius: _background.radius
                color: DexTheme.backgroundDarkColor2
                DexFlickable {
                    anchors.fill: parent
                    contentHeight: input_field.height
                    contentWidth: width
                    interactive: false

                    TextArea.flickable: TextArea {

                        id: input_field
                        horizontalAlignment: Qt.AlignLeft
                        color: control.textColor
                        background: Item {}
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        font.weight: Font.Medium
                        font.family: DexTypo.body2
                        Keys.onReturnPressed: control.accepted()
                        onTextChanged: {
                            control.error = false
                            if (text.length > control.max_length) {
                                text = text.substring(0, control.max_length)
                            }
                            if (text.indexOf('\r') !== -1 || text.indexOf('\n') !== -1) {
                                text = text.replace(/[\r\n]/, '')
                            }
                        }
                    }
                }
            }
        }
    }
}