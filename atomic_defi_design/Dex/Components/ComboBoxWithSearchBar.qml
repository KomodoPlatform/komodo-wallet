import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import "../Constants"

ComboBox
{
    id: control

    property int    radius: 10
    property int    popupWidth: width
    property int    popupMaxHeight: 450
    property bool   popupForceMaxHeight: false
    property color  backgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
    property color  popupBackgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
    property color  highlightedBackgroundColor: Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor
    property alias  searchBar: _searchBar
    property string searchBarPlaceholderText: qsTr("Search")

    background: Rectangle
    {
        id: bg
        anchors.fill: parent
        color: control.backgroundColor
        radius: control.radius
    }

    popup: Popup
    {
        id: popup
        width: control.popupWidth
        height: popupForceMaxHeight ? control.popupMaxHeight : Math.min(contentItem.implicitHeight, control.popupMaxHeight)
        leftPadding: 0
        rightPadding: 0
        topPadding: 16
        bottomPadding: 16

        contentItem: ColumnLayout
        {
            width: popup.width
            height: popup.height

            SearchField
            {
                id: _searchBar
                textField.placeholderText: searchBarPlaceholderText
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.preferredHeight: 40
                searchModel: control.delegateModel
                textField.forceFocus: true
            }

            DefaultListView
            {
                id: _list
                Layout.fillHeight: true
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                ScrollBar.vertical: ScrollBar
                {
                    visible: _list.contentHeight > control.dropDownMaxHeight
                    anchors.right: _list.right
                    anchors.rightMargin: 2
                    width: 7
                    background: DefaultRectangle
                    {
                        radius: 12
                        color: Dex.CurrentTheme.scrollBarBackgroundColor
                    }
                    contentItem: DefaultRectangle
                    {
                        radius: 12
                        color: Dex.CurrentTheme.scrollBarIndicatorColor
                    }
                }
            }
        }

        background: Rectangle
        {
            radius: control.radius
            color: control.popupBackgroundColor
        }
    }

    delegate: ItemDelegate
    {
        id: delegate

        width: control.width
        highlighted: control.highlightedIndex === index

        contentItem: DefaultText
        {
            width: control.width
            font: DexTypo.subtitle2
            text_value: control.textRole === "" ? model.modelData : !model.modelData ? model[textRole] : model.modelData[textRole]
            elide: Text.ElideRight
        }

        background: Rectangle
        {
            anchors.fill: delegate
            color: delegate.highlighted ? Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor : Dex.CurrentTheme.comboBoxBackgroundColor
        }
    }

    indicator: Column
    {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        spacing: -12

        Qaterial.Icon
        {
            width: 20
            height: 20
            color: Dex.CurrentTheme.comboBoxArrowsColor
            icon: Qaterial.Icons.chevronUp
        }

        Qaterial.Icon
        {
            width: 20
            height: 20
            color: Dex.CurrentTheme.comboBoxArrowsColor
            icon: Qaterial.Icons.chevronDown
        }
    }
}
