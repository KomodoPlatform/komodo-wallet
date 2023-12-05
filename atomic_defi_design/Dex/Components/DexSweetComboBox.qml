import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.impl 2.15

import Qaterial 1.0 as Qaterial

import "../Constants" as Constants
import App 1.0
import Dex.Themes 1.0 as Dex

ComboBox
{
    id: control

    property alias radius: bg_rect.radius
    property color comboBoxBackgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
    property color popupBackgroundColor: Dex.CurrentTheme.floatingBackgroundColor
    property color highlightedBackgroundColor: Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor
    property color mainBackgroundColor: Dex.CurrentTheme.floatingBackgroundColor
    property string currentTicker: "All"
    property var dropdownLineText: m => textRole === "" ?
                                       m.modelData : !m.modelData ?
                                           m[textRole] : m.modelData[textRole]

    // Combobox Dropdown Button Background
    background: DexRectangle
    {
        id: bg_rect
        implicitHeight: 40
        color: comboBoxBackgroundColor
        radius: 20
    }

    contentItem: DexLabel
    {
        leftPadding: 10
        verticalAlignment: Text.AlignVCenter
        width: bg_rect.width - leftPadding
        height: bg_rect.height
        text: control.currentTicker
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }

    // Each dropdown item
    delegate: ItemDelegate
    {
        id: combo_item
        width: control.width + 50
        highlighted: control.highlightedIndex === index

        contentItem: DexLabel
        {
            text_value: control.currentTicker
            color: Dex.CurrentTheme.foregroundColor
        }

        background: DexRectangle {
            anchors.fill: combo_item
            color: combo_item.highlighted ? highlightedBackgroundColor : mainBackgroundColor
        }
    }

    indicator: Qaterial.Icon
    {
        x: control.mirrored ? control.padding : control.width - width - control.padding - 4
        y: control.topPadding + (control.availableHeight - height) / 2
        color: Dex.CurrentTheme.foregroundColor
        icon: Qaterial.Icons.chevronDown
    }

    // Dropdown itself
    popup: Popup
    {
        id: combo_popup
        readonly property double max_height: 450

        width: control.width
        height: Math.min(contentItem.implicitHeight, max_height) + 20

        padding: 1

        contentItem: ColumnLayout
        {
            anchors.rightMargin: 5

            DefaultTextField
            {
                id: input_coin_filter
                placeholderText: qsTr("Search")

                font.pixelSize: 16
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.preferredHeight: 40
                Layout.rightMargin: 2
                Layout.topMargin: Layout.leftMargin

                background: DexRectangle
                {
                    anchors.fill: parent
                    anchors.topMargin: -5
                    anchors.rightMargin: -1
                    radius: control.radius
                    color: control.mainBackgroundColor
                }

                onTextChanged: control.model.setFilterFixedString(text)

                function reset()
                {
                    text = ""
                }

                Connections
                {
                    target: popup
                    function onOpened()
                    {
                        input_coin_filter.reset()
                        input_coin_filter.forceActiveFocus()
                    }

                    function onClosed()
                    {
                        input_coin_filter.reset()
                    }
                }

                Keys.onDownPressed: control.incrementCurrentIndex()
                Keys.onUpPressed: control.decrementCurrentIndex()
                Keys.onPressed:
                {
                    if (event.key === Qt.Key_Return)
                    {
                        if (control.count > 0)
                        {
                            control.currentIndex = 0;
                            control.currentTicker = control.currentText;
                        }
                        popup.close();
                        event.accepted = true;
                    }
                }
            }

            Item
            {
                Layout.maximumHeight: popup.max_height - 100
                Layout.fillWidth: true
                implicitHeight: popup_list_view.contentHeight + 5

                DexListView
                {
                    id: popup_list_view
                    model: control.popup.visible ? control.model : null
                    currentIndex: control.highlightedIndex
                    anchors.fill: parent
                    anchors.bottomMargin: 10
                    anchors.rightMargin: 2
                    clip: true

                    visibleBackground: true

                    highlight: DefaultRectangle
                    {
                        radius: 0
                    }

                    delegate: ItemDelegate
                    {
                        width: control.width + 50
                        highlighted: control.highlightedIndex === index
                        contentItem: DefaultText
                        {
                            text_value: "<b><font color='" + Style.getCoinColor(ticker) + "'>" + ticker + "</font></b>" + "    %1".arg(General.coinName(ticker)) 
                        }

                        background: DefaultRectangle
                        {
                            colorAnimation: false
                            color: popup_list_view.currentIndex === index ? Dex.CurrentTheme.buttonColorHovered : control.mainBackgroundColor
                        }

                        onClicked:
                        {
                            control.currentTicker = ticker
                            popup.close()
                        }
                    }

                    DexMouseArea
                    {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

        }

        background: DefaultRectangle
        {
            width: parent.width
            height: parent.height
            radius: control.radius
            color: control.popupBackgroundColor
            colorAnimation: false
            border.width: 1
        }
    }

    DefaultMouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }
}
