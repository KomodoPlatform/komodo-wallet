import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3

import AtomicDEX.CoinType 1.0
import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

MultipageModal
{
    id: root

    width: 700

    onClosed:
    {
        currentIndex = 0
        reset()
    }

    property var config_fields: ({})
    property var typeList: ["ERC-20", "QRC-20","BEP-20"]
    readonly property var custom_token_data: API.app.settings_pg.custom_token_data
    readonly property string general_message: qsTr('Get the contract address from')
    readonly property bool fetching_custom_token_data_busy: API.app.settings_pg.fetching_custom_token_data_busy

    function fetchAssetData() {
        const fields = General.clone(config_fields)
        switch(fields.type){
            case "QRC-20":
                API.app.settings_pg.process_qrc_20_token_add(fields.contract_address, fields.coingecko_id, fields.image_path)
                break
            default:
                API.app.settings_pg.process_token_add(fields.contract_address, fields.coingecko_id, fields.image_path, fields.coinType)
                break 
        }
    }

    onCustom_token_dataChanged: {
        const data = custom_token_data
        if(!data.mm2_cfg) return

        var fields = General.clone(config_fields)

        fields.ticker = data.ticker
        fields.name = data.name
        fields.error_code = data.error_code

        config_fields = General.clone(fields)

        root.nextPage()
    }

    function prepareConfigs() {
        var fields = {}

        const addToConfig = (input_component, key, value) => {
            if(input_component.enabled) fields[key] = value
        }

        addToConfig(input_type,             "type",             input_type.currentText)
        addToConfig(input_ticker,           "ticker",           input_ticker.field.text.toUpperCase())
        addToConfig(input_logo,             "image_path",       input_logo.path.replace(General.os_file_prefix, ""))
        addToConfig(input_name,             "name",             input_name.field.text)
        addToConfig(input_contract_address, "contract_address", input_contract_address.text)
        addToConfig(input_active,           "active",           input_active.checked)
        addToConfig(input_coingecko_id,   "coingecko_id",   input_coingecko_id.field.text)
        fields['coinType'] = currentType.coinType

        root.config_fields = General.clone(fields)
    }

    function reset() {
        input_ticker.field.text = ""
        input_logo.path = ""
        input_name.field.text = ""
        input_contract_address.text = ""
        input_active.checked = false
        input_coingecko_id.field.text = "test-coin"
    }

    ListModel
    {
        id: type_model

        ListElement
        {
            text: "ERC-20"
            prefix: ""
            image: "erc"
            url: "https://etherscan.io/tokens"
            name: 'Etherscan'
            coinType: CoinType.ERC20
        }

        ListElement
        {
            text: "QRC-20"
            prefix: "0x"
            image: "qrc"
            url: "https://explorer.qtum.org/tokens/search"
            name: 'QTUM Insight'
            coinType: CoinType.QRC20
        }

        ListElement
        {
            text: "BEP-20"
            prefix: ""
            url: "https://bscscan.com/tokens"
            name: 'BscScan'
            image: "bep"
            coinType: CoinType.BEP20
        }
    }

    readonly property bool has_contract_address: typeList.indexOf(input_type.currentText)!==-1
    property var currentType: type_model.get(input_type.currentIndex)

    // Type page
    MultipageModalContent
    {
        titleText: qsTr("Choose the asset type")
        height: 450

        DefaultComboBox
        {
            id: input_type
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            textRole: "text"
            valueRole: "text"
            model: type_model
            currentIndex: 0
            comboBoxBackgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
            mainBackgroundColor: Dex.CurrentTheme.innerBackgroundColor
            popupBackgroundColor: Dex.CurrentTheme.innerBackgroundColor
            highlightedBackgroundColor: Dex.CurrentTheme.comboBoxDropdownItemHighlightedColor
        }

        Item { Layout.preferredHeight: 50 }

        // Buttons
        footer:
        [
            CancelButton
            {
                text: qsTr("Cancel")
                Layout.preferredWidth: 220
                Layout.preferredHeight: 50
                radius: 18
                onClicked: root.previousPage()
            },

            Item { Layout.fillWidth: true },

            DefaultButton
            {
                text: qsTr("Next")
                Layout.preferredWidth: 220
                Layout.preferredHeight: 50
                radius: 18
                onClicked:
                {
                    root.reset()
                    root.nextPage()
                }
            }
        ]
    }

    // Ticker page
    MultipageModalContent
    {
        titleText: has_contract_address ? qsTr("Contract address") : qsTr("Choose the asset ticker")

        TextFieldWithTitle
        {
            id: input_ticker
            enabled: !has_contract_address
            visible: enabled
            Layout.fillWidth: true
            title: qsTr("Ticker")
            field.placeholderText: qsTr("Enter the ticker")
        }

        AddressField
        {
            id: input_contract_address
            enabled: has_contract_address
            visible: enabled
            Layout.fillWidth: true
            placeholderText: qsTr("Enter the contract address")
            left_text: currentType.prefix
        }

        DefaultText
        {
            visible: input_contract_address.visible
            Layout.fillWidth: true
            text_value: General.cex_icon + (' <a href="'+currentType.url+'">' + qsTr('Get the contract address from ') +currentType.name+ '</a>')
        }

        InnerBackground
        {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            color: 'transparent'

            content: DefaultAnimatedImage
            {
                visible: input_contract_address.visible
                playing: root.visible && visible
                source: General.image_path + "guide_contract_address_" + currentType.image + ".gif"
            }
        }

        // Buttons
        footer:
        [
            DefaultButton
            {
                text: qsTr("Previous")
                Layout.preferredWidth: 220
                radius: 18
                onClicked: root.previousPage()
            },

            Item { Layout.fillWidth: true },

            DefaultButton
            {
                text: qsTr("Next")
                Layout.preferredWidth: 220
                radius: 18
                enabled: (!input_ticker.enabled || input_ticker.field.text !== "") &&
                         (!input_contract_address.enabled || input_contract_address.text !== "")
                onClicked: root.nextPage()
            }
        ]
    }

    // Logo page
    MultipageModalContent
    {
        titleText: qsTr("Choose the asset logo")

        DefaultButton
        {
            Layout.fillWidth: true
            text: qsTr("Browse") + "..."
            onClicked: input_logo.open()
        }

        FileDialog
        {
            id: input_logo

            property string path
            readonly property bool enabled: true // Config preparation function searches for this

            title: qsTr("Please choose the asset logo")
            folder: shortcuts.pictures
            selectMultiple: false
            nameFilters: ["Image files (*.png)"]
            onFileUrlChanged: path = input_logo.fileUrl.toString()
        }


        InnerBackground
        {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            color: 'transparent'

            content: DefaultImage
            {
                width: 300
                height: width
                source: input_logo.path
            }
        }

        // Buttons
        footer:
        [
            DefaultButton
            {
                text: qsTr("Previous")
                Layout.preferredWidth: 220
                onClicked: root.previousPage()
            },

            Item { Layout.fillWidth: true },

            PrimaryButton
            {
                text: qsTr("Next")
                Layout.preferredWidth: 220
                enabled: input_logo.path !== ""
                onClicked: root.nextPage()
            }
        ]
    }

    // Configuration
    MultipageModalContent
    {
        titleText: qsTr("Configuration")

        DefaultText
        {
            visible: has_contract_address
            Layout.fillWidth: true
            text_value: qsTr("All configuration fields will be fetched using the contract address you provided.")
        }

        TextFieldWithTitle
        {
            id: input_name
            enabled: !has_contract_address
            visible: enabled
            Layout.fillWidth: true
            title: qsTr("Name")
            field.placeholderText: qsTr("Enter the name")
        }

        TextFieldWithTitle
        {
            id: input_coingecko_id
            Layout.fillWidth: true
            title: qsTr("Coingecko ID")
            field.placeholderText: qsTr("Enter the Coingecko ID")
        }

        DefaultText
        {
            visible: input_coingecko_id.visible
            Layout.fillWidth: true
            text_value: General.cex_icon + ' <a href="https://coingecko.com/">' + qsTr('Get the Coingecko ID') + '</a>'
        }

        InnerBackground
        {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            color: 'transparent'

            content: DefaultAnimatedImage
            {
                id: guide_coingecko_id
                visible: input_coingecko_id.visible
                playing: root.visible && visible
                source: General.image_path + "guide_coingecko_id.gif"
            }
        }

        DefaultCheckBox
        {
            id: input_active
            enabled: !has_contract_address
            visible: enabled
            text: qsTr("Active")
        }

        DefaultBusyIndicator
        {
            visible: root.fetching_custom_token_data_busy
            Layout.alignment: Qt.AlignCenter
        }

        footer:
        [
            DefaultButton
            {
                text: qsTr("Previous")
                Layout.preferredWidth: 220
                onClicked: root.previousPage()
            },

            Item { Layout.fillWidth: true },

            DefaultButton
            {
                text: qsTr("Preview")
                Layout.fillWidth: true
                enabled: !root.fetching_custom_token_data_busy &&
                         (!input_name.enabled || input_name.field.text !== "") &&
                         (!input_coingecko_id.enabled || input_coingecko_id.field.text !== "")
                onClicked: {
                    root.prepareConfigs()
                    root.fetchAssetData()
                    // Fetch result will open the next page
                }
            }
        ]
    }

    // Preview
    MultipageModalContent {
        titleText: qsTr("Preview")

        DefaultText {
            id: warning_message
            visible: coin_name.visible
            Layout.fillWidth: true
            text_value: qsTr("WARNING: Application will restart immidiately to apply the changes!")
            color: Style.colorRed
            horizontalAlignment: Text.AlignHCenter
        }

        HorizontalLine {
            visible: warning_message.visible
            Layout.fillWidth: true
        }

        DefaultImage {
            Layout.alignment: Qt.AlignHCenter

            Layout.preferredWidth: 64
            Layout.preferredHeight: Layout.preferredWidth
            source: input_logo.path
        }

        DefaultText {
            id: error_text
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: config_fields.error_code !== undefined
            text_value: qsTr("Asset not found, please go back and make sure Contract Address is correct")
            font.pixelSize: Style.textSize2
            color: Style.colorRed
        }

        DefaultText {
            id: coin_name
            Layout.alignment: Qt.AlignHCenter
            visible: has_contract_address && !error_text.visible
            text_value: config_fields.name + " (" + config_fields.ticker + ")"
            font.pixelSize: Style.textSize2
        }

        HorizontalLine {
            Layout.fillWidth: true
        }

        TextAreaWithTitle {
            Layout.fillWidth: true
            title: qsTr("Config Fields")
            field.readOnly: true
            remove_newline: false
            copyable: true
            field.text: General.prettifyJSON(config_fields)
        }

        HorizontalLine {
            Layout.fillWidth: true
        }

        TextAreaWithTitle {
            Layout.fillWidth: true
            title: qsTr("Fetched Data")
            field.readOnly: true
            remove_newline: false
            copyable: true
            field.text: General.prettifyJSON(custom_token_data)
        }


        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Previous")
                Layout.preferredWidth: 220
                onClicked: root.previousPage()
            },

            Item { Layout.fillWidth: true },

            PrimaryButton {
                text: qsTr("Submit & Restart")
                Layout.preferredWidth: 220
                enabled: !error_text.visible
                onClicked: {
                    API.app.settings_pg.submit()
                    root.close()
                    restart_modal.open()
                }
            }
        ]
    }
}
