import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.impl 2.15
import QtQuick.Controls.Universal 2.15
import "../Constants"

ComboBox {
    id: control

    Universal.theme: Style.dark_theme ? Universal.Dark : Universal.Light
    Universal.accent: Style.colorQtThemeAccent
    Universal.foreground: Style.colorQtThemeForeground
    Universal.background: Style.colorQtThemeBackground

    font.family: Style.font_family

    property color lineHoverColor: Style.colorTheme5
    property color mainBorderColor: control.pressed ? Style.colorTheme8 : Style.colorTheme5
    Behavior on lineHoverColor { ColorAnimation { duration: Style.animationDuration } }
    Behavior on mainBorderColor { ColorAnimation { duration: Style.animationDuration } }

    property string mainLineText: control.displayText
    property var dropdownLineText: m => textRole === "" ? m.modelData : m.modelData[textRole]


    readonly property bool disabled: !enabled

    hoverEnabled: true

    // Main, selected text
    contentItem: RowLayout {
        property alias color: text.color

        DefaultText {
            id: text
            leftPadding: 12
            rightPadding: control.indicator.width + control.spacing

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            text_value: control.mainLineText
            color: !control.enabled ? Style.colorTextDisabled : control.pressed ? Style.colorText2 : Style.colorText
        }
    }


    // Main background
    background: AnimatedRectangle {
        implicitWidth: 120
        implicitHeight: 40
        color: !control.enabled ? Style.colorTheme5 : control.hovered ? Style.colorTheme7 : Style.colorTheme9
        border.color: control.mainBorderColor
        border.width: control.visualFocus ? 2 : 1
        radius: Style.rectangleCornerRadius
    }

    // Dropdown itself
    popup: Popup {
        y: control.height - 1
        width: control.width
        height: Math.min(contentItem.implicitHeight, control.Window.height - bottomMargin - mapToItem(control.Window.contentItem, x, y).y)

        bottomMargin: 20

        padding: 1

        contentItem: DefaultListView {
            implicitHeight: contentHeight + 5 // Scrollbar appears if this extra space is not added
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            DefaultMouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
            }
        }

        background: AnimatedRectangle {
            color: Style.colorTheme9
            border.color: control.mainBorderColor
            radius: Style.rectangleCornerRadius
        }
    }

    // Each dropdown item
    delegate: ItemDelegate {
        Universal.accent: control.lineHoverColor
        width: control.width
        highlighted: control.highlightedIndex === index

        contentItem: DefaultText {
            text_value: control.dropdownLineText(model)
            color: Style.colorText
        }
    }

    // Dropdown arrow icon at right side
    indicator: ColorImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.contentItem.color
        defaultColor: control.contentItem.color
        source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/double-arrow.png"
    }

    DefaultMouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

