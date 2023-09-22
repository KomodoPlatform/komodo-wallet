import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qaterial 1.0 as Qaterial
import "../Constants" as Constants
import App 1.0


DefaultImage
{
    property int iconSize: 24
    property string tooltipText: ""

    source: General.image_path + "warning.svg"
    height: iconSize
    width: iconSize
    opacity: alertArea.containsMouse ? 0.9 : 1
    anchors.left: parent.left
    anchors.leftMargin: iconSize / 2
    anchors.rightMargin: iconSize / 2
    anchors.verticalCenter: parent.verticalCenter

    DexMouseArea
    {
        id: alertArea
        anchors.fill: parent
        hoverEnabled: true
    }

    DefaultTooltip
    {
        visible: alertArea.containsMouse && tooltipText != ""
        text: tooltipText
    }
}