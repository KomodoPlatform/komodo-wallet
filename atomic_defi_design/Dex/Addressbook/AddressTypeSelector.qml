import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import "../Components" as Dex
import "../Constants" as Dex

Dex.ComboBoxWithSearchBar
{
    id: control

    property bool   showAssetStandards: false
    property var    assetStandards: availableNetworkStandards

    function resetList()
    {
        if (showAssetStandards) currentIndex = 0; else { resetSearch(); currentIndex = 1 }
        setContentItem(currentIndex)
    }

    function resetSearch()
    {
        Dex.API.app.portfolio_pg.global_cfg_mdl.all_proxy.setFilterFixedString("");
        searchBar.textField.text = "";
    }

    function setContentItem(index)
    {
        if (showAssetStandards)
        {
            _contentRow.ticker = assetStandards[index]
            _contentRow.name = assetStandards[index]
            _contentRow.type = assetStandards[index]
        }
        else
        {
            _contentRow.ticker = model.data ? model.data(model.index(index, 0), Qt.UserRole + 1) : ""
            _contentRow.name = model.data ? model.data(model.index(index, 0), Qt.UserRole + 3) : ""
            _contentRow.type = model.data ? model.data(model.index(index, 0), Qt.UserRole + 9) : ""
        }
    }

    popupForceMaxHeight: true
    popupMaxHeight: 220

    model: showAssetStandards ? assetStandards : Dex.API.app.portfolio_pg.global_cfg_mdl.all_proxy
    textRole: showAssetStandards ? "" : "ticker"

    searchBar.visible: !showAssetStandards
    searchBar.searchModel: model

    delegate: ItemDelegate
    {
        id: _delegate

        visible: model.ticker !== "All"

        width: control.width
        height: visible ? 40 : 0
        highlighted: control.highlightedIndex === index

        contentItem: AssetRow
        {
            ticker: showAssetStandards ? modelData : model.ticker
            name: showAssetStandards ? modelData : model.name
            type: showAssetStandards ? modelData : model.type
        }

        background: Dex.Rectangle
        {
            anchors.fill: _delegate
            color: _delegate.highlighted ? Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor : Dex.CurrentTheme.comboBoxBackgroundColor
        }
    }

    contentItem: AssetRow
    {
        id: _contentRow

        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter
    }

    onCurrentIndexChanged:
    {
        if (!showAssetStandards && currentIndex === 0 && searchBar.textField.text == "") currentIndex = 1
        setContentItem(currentIndex)
    }
    onActivated: setContentItem(index)
    onShowAssetStandardsChanged: resetList()
    onVisibleChanged: if (!visible) resetList()
    Component.onDestruction: resetList()
    Component.onCompleted: resetList()
}
