import QtQuick 2.15
import "../Constants"
import App 1.0

AnimatedRectangle {
    property string type
    radius: 20

    height: type_tag.font.pixelSize * 1.5
    width: type_tag.width + 8

    color: Style.getCoinTypeColor(type)

    DexLabel {
        id: type_tag
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        text: type
        color: Style.getCoinTypeTextColor(type)
        font: DexTypo.overLine
    }
}
