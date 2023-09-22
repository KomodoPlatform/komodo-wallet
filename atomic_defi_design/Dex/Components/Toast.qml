// This is a modified version of QML Toast Implementation of jonmcclung
// https://gist.github.com/jonmcclung/bae669101d17b103e94790341301c129

import QtQuick 2.15
import "../Constants"
import App 1.0

AnimatedRectangle {
    function show(text, duration, info, is_error) {
        title = text
        details = info
        isError = is_error

        if (duration === -1) time = defaultTime
        else time = Math.max(duration, 2 * fadeTime)

        animation.start();
    }

    id: root

    readonly property real defaultTime: 2000
    property real time: defaultTime
    readonly property real fadeTime: 300

    property real margin: 10

    anchors {
        horizontalCenter: !parent ? undefined : parent.horizontalCenter
        margins: margin
    }

    width: message.width + margin
    height: message.height + margin

    radius: margin / 3

    opacity: 0
    color: isError ? DexTheme.warningColor : Style.colorTheme1
    z: 1000

    DexLabel {
        id: message
        color: "white"
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        anchors {
            top: parent.top
            left: parent.left
            margins: margin / 2
        }
        font.pixelSize: Style.textSizeSmall2
        text_value: title + (General.isFilled(details) ? (" - " + qsTr("Click here to see the details")) : "")
    }

    SequentialAnimation on opacity {
        id: animation
        running: false

        NumberAnimation {
            to: .9
            duration: fadeTime
        }

        PauseAnimation {
            duration: time - 2 * fadeTime
        }

        NumberAnimation {
            to: 0
            duration: fadeTime
        }

        onRunningChanged: {
            if (!running) toast.model.remove(index)
        }
    }

    property string title: ""
    property string details: ""
    property bool isError: false

    DefaultMouseArea {
        anchors.fill: parent
        onClicked: {
            if(open_notifications_modal) {
                dashboard.notifications_modal.open()
                animation.running = false
            }
            else if(details !== "") {
                showError(title, details)
                animation.running = false
            }
        }
    }
}
