// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 //> ToolTip

// Project Imports
import "../Constants"
import App 1.0
import "../Components"

// Contact address entry creation/edition modal
BasicModal
{
    id: root

    property var contactModel

    // Address Creation (false) or Edition (true) mode.
    property bool isEdition: false

    property alias walletType: wallet_type_list_modal.selected_wallet_type // The selected wallet type that will be associated this new address entry.
    property alias key: contact_new_address_key.text                       // The entered key that will be associated to this new address entry.
    property alias value: contact_new_address_value.text                   // The entered address value that will be associated to this new address entry.

    // These properties are required in edition mode since we need to wipe out old address entry.
    property string oldWalletType
    property string oldKey
    property string oldValue

    function retrieveWalletTypeTicker()
    {
        switch (walletType)
        {
            case "QRC-20":      return "QTUM";
            case "BEP-20":      return "BNB";
            case "ERC-20":      return "ETH";
            case "Smart Chain": return "KMD";
            case "SLP":         return "BCH";
        }

        let coinInfo = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(walletType);
        if (coinInfo.has_parent_fees_ticker)
            return coinInfo.fees_ticker;
        return walletType
    }

    width: 600

    Component.onCompleted:   API.app.wallet_pg.validate_address_data = {}
    Component.onDestruction: API.app.wallet_pg.validate_address_data = {}

    ModalContent
    {
        Layout.topMargin: 5
        Layout.fillWidth: true

        title: isEdition ? qsTr("Edit address entry") : qsTr("Create a new address")

        // Wallet Type Selector
        DexButton
        {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            text: qsTr("Selected wallet: %1").arg(walletType !== "" ? walletType : qsTr("NONE"))

            onClicked: wallet_type_list_modal.open()
        }

        // Address Key Field
        DefaultTextField
        {
            id: contact_new_address_key

            Layout.topMargin: 5
            implicitWidth: parent.width

            placeholderText: qsTr("Enter a name")

            onTextChanged:
            {
                const max_length = 30
                if (text.length > max_length)
                    text = text.substring(0, max_length)
            }

            // Error tooltip when key already exists.
            DefaultTooltip
            {
                id: key_already_exists_tooltip
                visible: false
                contentItem: DefaultText { text_value: qsTr("This key already exists.") }
            }
        }

        // Address Value Field
        DefaultTextField
        {
            id: contact_new_address_value

            Layout.topMargin: 5
            implicitWidth: parent.width

            placeholderText: qsTr("Enter the address")

            onTextChanged:
            {
                const max_length = 50
                if (text.length > max_length)
                    text = text.substring(0, max_length)
            }

            DexLabel
            {
                id: invalidAddressMsgLabel
                anchors.top: parent.bottom
                anchors.topMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter
                color: DexTheme.redColor
                wrapMode: DexLabel.Wrap
                width: 550
            }
        }

        HorizontalLine { Layout.fillWidth: true; Layout.topMargin: 32 }

        Item
        {
            width: root.width - 50
            height: 40

            DexButton
            {
                id: validateButton
                anchors.left: parent.left
                enabled: key.length > 0 && value.length > 0 && walletType !== "" && !API.app.wallet_pg.validate_address_busy
                text: qsTr("Validate")
                onClicked: API.app.wallet_pg.validate_address(contact_new_address_value.text, retrieveWalletTypeTicker())
            }

            DexButton
            {
                anchors.right: parent.right
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            DexButton
            {
                anchors.left: validateButton.right
                anchors.leftMargin: 10
                visible: !API.app.wallet_pg.convert_address_busy && API.app.wallet_pg.validate_address_data.convertible ? API.app.wallet_pg.validate_address_data.convertible : false
                text: qsTr("Convert")
                onClicked: API.app.wallet_pg.convert_address(contact_new_address_value.text, retrieveWalletTypeTicker(), API.app.wallet_pg.validate_address_data.to_address_format);
            }
        }

        Connections
        {
            target: API.app.wallet_pg

            function onConvertAddressBusyChanged()
            {
                if (API.app.wallet_pg.convert_address_busy) // Currently converting entered address
                {
                    return;
                }

                contact_new_address_value.text = API.app.wallet_pg.converted_address
                API.app.wallet_pg.validate_address_data = {}
                invalidAddressMsgLabel.text = ""
            }

            function onValidateAddressBusyChanged()
            {
                if (API.app.wallet_pg.validate_address_busy) // Currently checking entered address
                {
                    return;
                }

                if (!API.app.wallet_pg.validate_address_data.is_valid) // Entered address is invalid.
                {
                    invalidAddressMsgLabel.text = API.app.wallet_pg.validate_address_data.reason
                    return;
                }

                if (isEdition) // Removes old address entry before if we are in edition mode.
                {
                    console.debug("AddressBook: Replacing address %1:%2:%3 of contact %4"
                                    .arg(oldWalletType).arg(oldKey).arg(oldValue).arg(contactModel.name))
                    contactModel.remove_address_entry(oldWalletType, oldKey);
                }

                var create_address_result = contactModel.add_address_entry(walletType, key, value);
                if (create_address_result === true)
                {
                    console.debug("AddressBook: Address %1:%2:%3 created for contact %4"
                                    .arg(walletType).arg(key).arg(value).arg(contactModel.name))
                    root.close()
                }
                else
                {
                    console.debug("AddressBook: Failed to create address for contact %1: %2 key already exists"
                                    .arg(contactModel.name).arg(key))
                    key_already_exists_tooltip.visible = true
                }
            }
        }

        ModalLoader
        {
            id: wallet_type_list_modal

            property string selected_wallet_type: ""

            sourceComponent: AddressBookWalletTypeListModal
            {
                onSelected_wallet_typeChanged: wallet_type_list_modal.selected_wallet_type = selected_wallet_type
            }
        }
    }
}
