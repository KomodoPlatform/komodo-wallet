import QtQuick 2.12
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import "../Components" as Dex
import "../Constants" as Dex

Dex.Rectangle
{
    id: root

    property var     contactModel

    // Edition mode variables
    property bool    editionMode: false
    property string  addressType
    property string  addressKey
    property string  addressValue

    property var     availableNetworkStandards: ["QRC-20", "ERC-20", "BEP-20", "Smart Chain", "SLP"]

    // Return the asset type that will be used in the backend to validate the address
    function getTypeForAddressChecker(addressType)
    {
        switch (addressType)
        {
            case "QRC-20":      return "QTUM"
            case "BEP-20":      return "BNB"
            case "ERC-20":      return "ETH"
            case "Smart Chain": return "KMD"
            case "SLP":         return "USDT-SLP"
        }

        let coinInfo = Dex.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(addressType);
        if (coinInfo.has_parent_fees_ticker && coinInfo.type !== "SLP")
            return coinInfo.fees_ticker;
        return addressType
    }

    // Tells if the given address type represents a network standard address (e.g. BEP-20)
    function isNetworkStandard(addressType)
    {
        switch (addressType)
        {
            case "QRC-20":      return true
            case "BEP-20":      return true
            case "ERC-20":      return true
            case "Smart Chain": return true
            case "SLP":         return true
        }
        return false
    }

    signal cancel()
    signal addressCreated()

    width: 500
    height: column.height + 26
    radius: 10

    onVisibleChanged:
    {
        if (!visible)
        {
            // Resets data when address is added/edited.
            addressKeyField.text = ""
            addressValueField.text = ""
            invalidAddressValueLabel.text = ""
            editionMode = false
            addressType = ""
            addressKey = ""
            addressValue = ""
        }
        else if (editionMode)
        {
            // Feeds form with the data we are currently editing.

            if (!isNetworkStandard(addressType))
            {
                useStandardsCheckBox.checked = false
                let addressTypeIndex =
                        Dex.API.app.portfolio_pg.global_cfg_mdl.all_proxy.match(
                        Dex.API.app.portfolio_pg.global_cfg_mdl.all_proxy.index(0, 0),
                        Qt.UserRole + 1, addressType, 1, Qt.MatchExactly)[0]
                addressTypeComboBox.currentIndex = addressTypeIndex.row
            }
            else
            {
                useStandardsCheckBox.checked = true
                let addressTypeIndex = availableNetworkStandards.indexOf(addressType)
                addressTypeComboBox.currentIndex = addressTypeIndex
            }
            addressKeyField.text = addressKey
            addressValueField.text = addressValue
        }
    }

    ColumnLayout
    {
        id: column
        anchors.centerIn: parent
        spacing: 17

        RowLayout
        {
            Layout.preferredWidth: 458
            Layout.preferredHeight: 38

            AddressTypeSelector
            {
                id: addressTypeComboBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                showAssetStandards: useStandardsCheckBox.checked
            }

            RowLayout {
                id: rowLayout
                spacing: 4
                Dex.DefaultCheckBox
                {
                    id: useStandardsCheckBox
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true
                    Layout.leftMargin: 4
                }
                Dex.DefaultText {
                    Layout.minimumWidth: 120
                    Layout.maximumWidth: 120
                    text: qsTr("Use standard network address")
                    font: Dex.DexTypo.caption
                }
            }
        }

        Dex.TextField
        {
            id: addressKeyField
            Layout.preferredWidth: 458
            Layout.preferredHeight: 38
            placeholderText: qsTr("Label")

            Dex.ToolTip
            {
                id: addressKeyAlreadyExistsToolTip
                contentItem: Dex.Text { text_value: qsTr("This key already exists.") }
            }
        }

        Dex.TextField
        {
            id: addressValueField
            Layout.preferredWidth: 458
            Layout.preferredHeight: 38
            placeholderText: qsTr("Address")
        }

        Dex.Text
        {
            id: invalidAddressValueLabel
            Layout.preferredWidth: 458
            Layout.preferredHeight: 60
            visible: text !== ""
            color: Dex.CurrentTheme.warningColor
            wrapMode: Dex.Text.WordWrap
            elide: Dex.Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout
        {
            Layout.topMargin: 10
            Layout.fillWidth: true

            Dex.CancelButton
            {
                Layout.preferredWidth: 116
                Layout.preferredHeight: 38
                radius: 18
                text: qsTr("Cancel")
                onClicked: cancel()
            }

            Item { Layout.fillWidth: true }

            Dex.GradientButton
            {
                property bool isConvertMode: Dex.API.app.wallet_pg.validate_address_data.convertible ?? false

                enabled: addressKeyField.length > 0 && addressValueField.length > 0 && !Dex.API.app.wallet_pg.validate_address_busy
                Layout.preferredWidth: 116
                Layout.preferredHeight: 38
                radius: 18
                text: isConvertMode ? qsTr("Convert") : editionMode ? qsTr("Update") : qsTr("Save")
                onClicked:
                {
                    let addressType = getTypeForAddressChecker(addressTypeComboBox.currentText)

                    if (!Dex.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(addressType).is_enabled)
                    {
                        enableAssetModal.assetTicker = addressType
                        enableAssetModal.open()
                    }
                    else if (isConvertMode)
                        Dex.API.app.wallet_pg.convert_address(addressValueField.text, addressType, Dex.API.app.wallet_pg.validate_address_data.to_address_format);
                    else
                        Dex.API.app.wallet_pg.validate_address(addressValueField.text, addressType)
                }
            }
        }
    }

    Connections
    {
        target: Dex.API.app.wallet_pg

        function onConvertAddressBusyChanged()
        {
            if (Dex.API.app.wallet_pg.convert_address_busy) // Currently converting entered address
            {
                return
            }

            addressValueField.text = Dex.API.app.wallet_pg.converted_address
            Dex.API.app.wallet_pg.validate_address_data = {}
            invalidAddressValueLabel.text = ""
        }

        function onValidateAddressBusyChanged()
        {
            if (Dex.API.app.wallet_pg.validate_address_busy) // Currently checking entered address
            {
                return
            }
            
            let validation_data = Dex.API.app.wallet_pg.validate_address_data
            if (!validation_data.is_valid) // Entered address is invalid.
            {
                invalidAddressValueLabel.text = validation_data.reason
                
                return
            }

            if (editionMode) // Removes old address entry before if we are in edition mode.
            {
                contactModel.removeAddressEntry(addressType, addressKey);
            }

            var createAddressResult = contactModel.addAddressEntry(addressTypeComboBox.currentText, addressKeyField.text, addressValueField.text);
            if (createAddressResult === true)
            {
                addressCreated()
                Dex.API.app.addressbookPg.model.proxy.searchExp = "x"
                Dex.API.app.addressbookPg.model.proxy.searchExp = ""
            }
            else
            {
                addressKeyAlreadyExistsToolTip.visible = true
            }
        }
    }

    Dex.ModalLoader
    {
        id: enableAssetModal

        property string assetTicker

        onLoaded: item.assetTicker = assetTicker

        sourceComponent: Dex.MultipageModal
        {
            property string assetTicker
            Dex.MultipageModalContent
            {
                Layout.fillWidth: true
                titleText: qsTr("Enable " + assetTicker)

                Dex.Text
                {
                    Layout.fillWidth: true
                    text: qsTr("You need to enable %1 before adding this kind of address.").arg(assetTicker)
                }

                footer:
                [
                    // Enable button
                    Dex.Button
                    {
                        text: qsTr("Enable")

                        onClicked:
                        {
                            Dex.API.app.enable_coin(assetTicker)
                            close()
                        }
                    },

                    // Cancel button
                    Dex.CancelButton
                    {
                        Layout.rightMargin: 5
                        text: qsTr("Cancel")

                        onClicked: close()
                    }
                ]
            }
        }
    }
}
