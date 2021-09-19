import QtQuick 2.15
import QtQuick.Layouts 1.15

import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import App 1.0

BasicModal {
    readonly property var glbCoinsCfgModel: API.app.portfolio_pg.global_cfg_mdl
    property alias        selected_wallet_type: wallet_list.selected_wallet_type

    function resetModal()
    {
        _searchbar.text = ""
        filterWallets(_searchbar.text)
    }

    function filterWallets(text)
    {
        _qrc20Expandable.model.setFilterFixedString(text)
        _erc20Expandable.model.setFilterFixedString(text)
        _bep20Expandable.model.setFilterFixedString(text)
        _scExpandable.model.setFilterFixedString(text)
        _utxoExpandable.model.setFilterFixedString(text)

        // Expands type lists if searchbar is not empty
        _qrc20Expandable.expanded = text !== ""
        _erc20Expandable.expanded = text !== ""
        _bep20Expandable.expanded = text !== ""
        _scExpandable.expanded = text !== ""
        _utxoExpandable.expanded = text !== ""
    }

    function onTypeSelect(type_or_ticker)
    {
        selected_wallet_type = type_or_ticker
        close()
    }

    width: 400

    onOpened: _searchbar.forceActiveFocus()
    onClosed: resetModal()

    ModalContent
    {
        id: wallet_list

        property string selected_wallet_type: ""

        title: qsTr("Select wallet type")

        // Search input
        DefaultTextField
        {
            Layout.rightMargin: 10
            id: _searchbar

            Layout.fillWidth: true
            placeholderText: qsTr("Search")

            onTextChanged: filterWallets(text)
        }

        AddressBookWalletTypeList
        {
            id: _qrc20Expandable

            Layout.rightMargin: 10
            Layout.fillWidth: true

            title: "QRC-20 coins"
            type_title: "QRC-20"
            type: "QRC-20"

            model: glbCoinsCfgModel.all_qrc20_proxy
        }

        AddressBookWalletTypeList
        {
            id: _erc20Expandable
            Layout.rightMargin: 10
            Layout.fillWidth: true

            title: "ERC-20 coins"
            type_title: "ERC-20"
            type: "ERC-20"

            model: glbCoinsCfgModel.all_erc20_proxy
        }

        AddressBookWalletTypeList
        {
            id: _bep20Expandable
            Layout.rightMargin: 10
            Layout.fillWidth: true

            title: "BEP-20 coins"
            type_title: "BEP-20"
            type: "BEP-20"
            typeIcon: "BNB"

            model: glbCoinsCfgModel.all_bep20_proxy
        }

        AddressBookWalletTypeList
        {
            id: _scExpandable
            Layout.rightMargin: 10
            Layout.fillWidth: true

            title: "Smart Chain coins"
            type_title: "Smart Chain"
            type: "Smart Chain"

            model: glbCoinsCfgModel.all_smartchains_proxy
        }

        AddressBookWalletTypeList
        {
            id: _utxoExpandable

            Layout.rightMargin: 10
            Layout.fillWidth: true

            title: "UTXO coins"
            type_title: "UTXO"

            model: glbCoinsCfgModel.all_utxo_proxy
        }
    }
}
