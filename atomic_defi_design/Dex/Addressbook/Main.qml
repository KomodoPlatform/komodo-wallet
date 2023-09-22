// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15

import Qaterial 1.0 as Qaterial

// Project Imports
import Dex.Components 1.0 as Dex
import "../Components" as Dex
import Dex.Themes 1.0 as Dex
import "../Constants" as Dex
import "../Wallet" as Wallet

Item
{
    function trySend(address, type)
    {
        // Checks if the selected address type represents an asset standard instead of an asset.
        if (Dex.API.app.portfolio_pg.global_cfg_mdl.is_coin_type(type))
        {
            assetFromStandardSelectorLoader.address = address
            assetFromStandardSelectorLoader.standard = type
            assetFromStandardSelectorLoader.open()
        }

        // Checks if the asset is currently enabled.
        else if (!Dex.API.app.portfolio_pg.is_coin_enabled(type))
        {
            enabledAssetModalLoader.assetTicker = type;
            enabledAssetModalLoader.open()
        }

        // If the coin is enabled, opens the send modal.
        else
        {
            if (assetFromStandardSelectorLoader.visible)
                assetFromStandardSelectorLoader.close()
            Dex.API.app.wallet_pg.ticker = type
            sendModalLoader.address = address
            sendModalLoader.open()
        }
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 30

        spacing: 32

        Row
        {
            Layout.fillWidth: true

            Column
            {
                width: parent.width * 0.5
                spacing: 34

                Dex.Text
                {
                    text: qsTr("Address Book")
                    font: Dex.DexTypo.head5
                }

                Dex.SearchField
                {
                    id: searchbar

                    width: 206
                    height: 42
                    textField.forceFocus: true
                    textField.placeholderText: qsTr("Search contact")

                    textField.onTextChanged: Dex.API.app.addressbookPg.model.proxy.searchExp = textField.text
                    Component.onDestruction: Dex.API.app.addressbookPg.model.proxy.searchExp = ""
                }
            }

            Row
            {
                width: parent.width * 0.5
                layoutDirection: Qt.RightToLeft

                Dex.GradientButton
                {
                    height: 40
                    radius: 15
                    text: qsTr("+ NEW CONTACT")

                    onClicked: newContactPopup.open()

                    NewContactPopup
                    {
                        id: newContactPopup
                    }
                }
            }
        }

        // Contact table header
        Row
        {
            Layout.fillWidth: true
            Layout.topMargin: 30

            Dex.Text
            {
                width: parent.width * 0.3
                text: qsTr("Name")
                font: Dex.DexTypo.head8
                leftPadding: 18
            }

            Dex.Text
            {
                text: qsTr("Tags")
                font: Dex.DexTypo.head8
                leftPadding: 18
            }
        }

        // Contact table content
        Dex.DefaultListView
        {
            id: contactTable

            function _getCurrentTagColorId()
            {
                if (typeof _getCurrentTagColorId.counter == 'undefined')
                    _getCurrentTagColorId.counter = 0
                if (_getCurrentTagColorId.counter >= Dex.CurrentTheme.addressBookTagColors.length)
                    _getCurrentTagColorId.counter = 0

                return _getCurrentTagColorId.counter++
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: Dex.API.app.addressbookPg.model.proxy

            delegate: Dex.Expandable
            {
                id: expandable

                padding: 10
                color: index % 2 === 0 ? Dex.CurrentTheme.innerBackgroundColor : Dex.CurrentTheme.backgroundColor
                width: contactTable.width

                header: Item
                {
                    height: 56
                    width: expandable.width

                    Dex.DefaultMouseArea
                    {
                        anchors.fill: parent
                        onClicked: expandable.isExpanded = !expandable.isExpanded
                    }

                    Row
                    {
                        width: parent.width * 0.3
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Dex.UserIcon
                        {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Dex.Text
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                        }

                        Dex.Arrow
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            up: expandable.isExpanded
                        }
                    }

                    Flow
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * 0.3
                        width: parent.width * 0.57
                        spacing: 17

                        Repeater
                        {
                            model: modelData.categories.slice(0, 6)

                            delegate: Dex.MouseArea
                            {
                                width: tagBg.width + 2
                                height: tagBg.height
                                onClicked: searchbar.textField.text = modelData
                                hoverEnabled: true

                                Dex.Rectangle
                                {
                                    id: tagBg
                                    property int _currentColorIndex: contactTable._getCurrentTagColorId()
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: tagLabel.width + 12
                                    height: 21
                                    radius: 20
                                    color: Dex.CurrentTheme.addressBookTagColors[_currentColorIndex]

                                    Dex.Text
                                    {
                                        id: tagLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }

                    Row
                    {
                        spacing: 45
                        width: edit_contact.implicitWidth + delete_contact.implicitWidth + 65
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 20

                        Dex.ClickableText
                        {
                            id: edit_contact
                            anchors.verticalCenter: parent.verticalCenter
                            font: Dex.DexTypo.underline14
                            text: qsTr("Edit")
                            onClicked:
                            {
                                editContactLoader.contactModel = modelData
                                editContactLoader.open()
                            }
                        }

                        Dex.ClickableText
                        {
                            id: delete_contact
                            anchors.verticalCenter: parent.verticalCenter
                            font: Dex.DexTypo.underline14
                            text: qsTr("Delete")
                            onClicked: removeContactPopup.open()

                            RemoveContactPopup
                            {
                                id: removeContactPopup

                                contactName: modelData.name
                            }
                        }
                    }
                }

                content: Item
                {
                    height: noAddressLabel.visible ? 50 : addressList.height
                    width: contactTable.width

                    Dex.ListView
                    {
                        id: addressList

                        visible: addressList.model.rowCount() > 0
                        x: 30
                        model: modelData.proxyFilter
                        width: parent.width - 40
                        implicitHeight: contentHeight > 240 ? 240 : contentHeight
                        spacing: 18

                        delegate: Item
                        {
                            property var coinInfo: Dex.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(address_type)

                            width: addressList.width
                            height: 30

                            Row
                            {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Dex.Image
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 25
                                    height: 25
                                    source: Dex.General.coinIcon(address_type.toLowerCase())
                                }

                                Dex.Text
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: address_type
                                }

                                Dex.Text
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.parent.coinInfo.type
                                    color: Dex.Style.getCoinTypeColor(parent.parent.coinInfo.type)
                                    font: Dex.DexTypo.overLine
                                }
                            }

                            Row
                            {
                                x: parent.width * 0.25
                                spacing: 3

                                Dex.Text
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "%1 : %2".arg(address_key).arg(address_value)
                                }


                                Dex.Button
                                {
                                    width: 25
                                    height: 25
                                    iconSource: Qaterial.Icons.contentCopy
                                    color: "transparent"
                                    onClicked:
                                    {
                                        Dex.API.qt_utilities.copy_text_to_clipboard(address_value)
                                        app.notifyCopy(qsTr("Address Book"), qsTr("address copied to clipboard"))
                                    }
                                }

                                Dex.Button
                                {
                                    width: 25
                                    height: 25
                                    iconSource: Qaterial.Icons.sendOutline
                                    color: "transparent"
                                    onClicked: trySend(address_value, address_type)
                                }
                            }
                        }
                    }

                    Dex.Text
                    {
                        id: noAddressLabel
                        height: 20
                        x: 30
                        y: 15
                        visible: addressList.model.rowCount() === 0
                        text: qsTr("This contact does not have any registered address.")
                    }
                }
            }
        }
    }

    Dex.ModalLoader
    {
        id: editContactLoader

        property var contactModel

        onLoaded: item.contactModel = contactModel

        sourceComponent: EditContactModal { }
    }

    Dex.ModalLoader
    {
        id: sendModalLoader

        property string address

        onLoaded: item.address_field.text = address

        sourceComponent: Wallet.SendModal
        {
            address_field.enabled: false
        }
    }

    Dex.ModalLoader
    {
        id: assetFromStandardSelectorLoader

        property string standard
        property string address

        onLoaded: item.standard = standard

        sourceComponent: AssetFromStandardSelector
        {
            onSelected:
            {
                trySend(assetFromStandardSelectorLoader.address, assetTicker)
            }
        }
    }

    Dex.ModalLoader
    {
        id: enabledAssetModalLoader

        property string assetTicker

        onLoaded: item.assetTicker = assetTicker

        sourceComponent: EnableAssetModal { }
    }
}
