//! Qt Imports.
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.15

//! Project Imports.
import App 1.0
import Dex.Themes 1.0 as Dex

CheckBox
{
    id: control

    property alias label: _label
    property alias boxWidth: _indicator.implicitWidth
    property alias boxHeight: _indicator.implicitHeight
    property alias boxRadius: _indicator.radius
    property alias mouseArea: mouseArea
    property color textColor: Dex.CurrentTheme.foregroundColor
    property int labelWidth: 0

    font.family: Style.font_family

    indicator: DefaultRectangle
    {
        id: _indicator
        anchors.verticalCenter: control.verticalCenter

        implicitWidth: 20
        implicitHeight: 20
        radius: 4

        gradient: Gradient
        {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.1; color: Dex.CurrentTheme.checkBoxGradientStartColor }
            GradientStop { position: 0.6; color: Dex.CurrentTheme.checkBoxGradientEndColor }
        }

        DefaultImage {
            id: check_icon
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: parent.width - 6
            height: parent.height - 6
            source: General.image_path + "white_check.svg"
            visible: control.checkState === Qt.Checked
        }

        DefaultColorOverlay
        {
            anchors.fill: check_icon
            source: check_icon
            color: Dex.CurrentTheme.checkBoxTickColor
        }

        DefaultRectangle
        {
            visible: !control.checked
            anchors.centerIn: parent
            width: parent.width - 6
            height: parent.height - 6
            radius: parent.radius
        }

        opacity: enabled ? 1 : 0.5
    }

    contentItem: RowLayout
    {
        id: _content
        Layout.alignment: Qt.AlignVCenter
        height: _label.height
        spacing: 0

        DefaultText
        {
            id: _label
            text: control.text
            font: control.font
            color: control.textColor
            verticalAlignment: Text.AlignVCenter
            leftPadding: control.indicator.width + control.spacing
            wrapMode: Label.Wrap
        }
    }

    DefaultMouseArea
    {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }
}
