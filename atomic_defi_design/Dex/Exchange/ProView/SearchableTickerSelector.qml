import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import "../../Components" as Dex
import "../../Constants" as Dex

Dex.ComboBoxWithSearchBar
{
    id: control

    property var    currentItem: model.index(currentIndex, 0)
    property bool   left_side: false
    property string ticker
    property bool   index_changed: false
    
    height: 70
    enabled: !block_everything

    textRole: "ticker"
    valueRole: "ticker"

    popupMaxHeight: Math.min(model.rowCount() * 70 + 70, 600)
    popupForceMaxHeight: true

    searchBar.visible: true
    searchBar.searchModel: model

    delegate: ItemDelegate
    {
        id: _delegate
        width: control.width
        height: visible ? 70 : 0
        highlighted: control.highlightedIndex === index

        contentItem: DexComboBoxLine { details: model }
        background: Dex.DexRectangle
        {
            anchors.fill: _delegate
            color: _delegate.highlighted ? Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor : Dex.CurrentTheme.comboBoxBackgroundColor
        }
    }

    contentItem: DexComboBoxLine
    {
        id: _contentRow

        property int update_count: 0
        property var prev_details

        padding: 10

        function forceUpdateDetails()
        {
            console.log("Portfolio item data changed, force-updating the selected ticker details!")
            ++update_count
        }

        details:
        {
            const idx = currentIndex
            if (idx === -1) return prev_details

            const new_details = {
                update_count:           _contentRow.update_count,
                ticker:                 model.data(model.index(idx, 0), 257),
                name:                   model.data(model.index(idx, 0), 259),
                balance:                model.data(model.index(idx, 0), 260),
                main_currency_balance:  model.data(model.index(idx, 0), 261),
                activation_status:      model.data(model.index(idx, 0), 266)
            }

            prev_details = new_details
            return new_details
        }
        Component.onCompleted: portfolio_mdl.portfolioItemDataChanged.connect(forceUpdateDetails)
        Component.onDestruction: portfolio_mdl.portfolioItemDataChanged.disconnect(forceUpdateDetails)
    }

    onCurrentIndexChanged: control.index_changed = true
    onCurrentValueChanged:
    {
        if (control.index_changed)
        {
            control.index_changed = false
            if (currentValue !== undefined)
                setPair(left_side, currentValue)
        }
        else
        {
            if (currentText.indexOf(ticker) === -1)
            {
                const target_index = indexOfValue(ticker)
                if (currentIndex !== target_index)
                    currentIndex = target_index
            }
        }
    }
    searchBar.onVisibleChanged: if (!visible) { searchBar.textField.text = "" }
    searchBar.textField.onTextChanged: control.model.setFilterFixedString(searchBar.textField.text)
}
