import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Constants"

ComponentWithTitle {
    property alias text: text.text_value
    property alias value_color: text.color
    property alias privacy: text.privacy

    DefaultText {
        id: text

        clip: true
        Layout.fillWidth: true
        color: Style.modalValueColor

        Layout.preferredHeight: show_content ? contentHeight : 0
        Behavior on Layout.preferredHeight { SmoothedAnimation { id: expand_animation; duration: Style.animationDuration * 2; velocity: -1 } }

        opacity: show_content ? 1 : 0
        Behavior on opacity { SmoothedAnimation { duration: expand_animation.duration; velocity: -1 } }
    }
}
