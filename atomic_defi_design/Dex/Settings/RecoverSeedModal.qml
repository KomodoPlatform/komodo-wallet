import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

MultipageModal
{
    id: root

    property var portfolio_model: API.app.portfolio_pg.portfolio_mdl
    property var settings_page: API.app.settings_pg

    property bool _isPasswordWrong: false

    function tryViewKeysAndSeed()
    {
        if (!submitButton.enabled) return

        const result = API.app.settings_pg.retrieve_seed(API.app.wallet_mgr.wallet_default_name, _inputPassword.field.text)

        if (result.length === 2)
        {
            seedLabel.text = result[0]
            rpcPwLabel.text = result[1]
            _isPasswordWrong = false
            root.nextPage()
            loading.running = true
        }
        else
        {
            _inputPassword.error = true;
            _isPasswordWrong = true;
            return false;
        }
    }

    width: 900

    onClosed:
    {
        _isPasswordWrong = false
        _inputPassword.reset()
        seedLabel.text = ""
        rpcPwLabel.text = ""
        portfolio_model.clean_priv_keys()
        currentIndex = 0
    }

    MultipageModalContent
    {
        titleText: qsTr("View seed and private keys")

        DefaultText
        {
            text_value: qsTr("Please enter your password to view the seed.")
        }

        DexAppPasswordField
        {
            id: _inputPassword
            forceFocus: true
            Layout.fillWidth: true
            Layout.margins: 20
            Layout.alignment: Qt.AlignHCenter
            field.onAccepted: tryViewKeysAndSeed()
            field.onTextChanged: { _isPasswordWrong = false }
        }

        DexLabel
        {
            Layout.alignment: Qt.AlignHCenter
            height: 14
            text: _isPasswordWrong ? qsTr("Incorrect Password") : ""
            color: Dex.CurrentTheme.warningColor
        }

        // Footer
        RowLayout
        {
            Layout.preferredWidth: parent.width
            Layout.topMargin: 30
            CancelButton
            {
                text: qsTr("Cancel")
                Layout.preferredWidth: parent.width / 100 * 48
                onClicked: root.close()
            }

            PrimaryButton
            {
                id: submitButton
                Layout.preferredWidth: parent.width / 100 * 48
                enabled: _inputPassword.field.length > 0
                text: qsTr("View")
                onClicked: tryViewKeysAndSeed()
            }
        }
    }

    MultipageModalContent
    {
        titleText: qsTr("View seed and private keys")
        titleTopMargin: 15
        topMarginAfterTitle: 15

        Timer
        {
            id: loading
            repeat: true
            running: false
            onTriggered:
            {
                if (!settings_page.fetching_priv_keys_busy)
                {
                    repeat = false
                    busyView.visible = false
                    busyView.enabled = false
                    seedContainer.visible = true
                    seedContainer.enabled = true
                    coinsList.visible = true
                    coinsList.enabled = true
                }
            }
        }

        DefaultBusyIndicator { id: busyView; Layout.alignment: Qt.AlignHCenter }

        RowLayout
        {
            id: seedContainer
            visible: false
            enabled: false
            spacing: 5
            width: parent.width
            height: 150

            // Logo
            DefaultImage
            {
                source: Dex.CurrentTheme.bigLogoPath
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 144
                Layout.preferredHeight: 144
            }

            ColumnLayout
            {
                spacing: 5

                // Seed
                RowLayout
                {
                    spacing: 5

                    Qaterial.RawMaterialButton
                    {
                        backgroundImplicitWidth: 30
                        backgroundImplicitHeight: 30
                        backgroundColor: "transparent"
                        icon.source: Qaterial.Icons.qrcodeScan
                        icon.color: Dex.CurrentTheme.foregroundColor2
                        onClicked:
                        {
                            qrcodeModal.qrcodeSvg = API.qt_utilities.get_qrcode_svg_from_string(seedLabel.text)
                            qrcodeModal.open()
                        }
                    }

                    Qaterial.RawMaterialButton
                    {
                        backgroundImplicitWidth: 30
                        backgroundImplicitHeight: 30
                        backgroundColor: "transparent"
                        icon.source: Qaterial.Icons.contentCopy
                        icon.color: Dex.CurrentTheme.foregroundColor2
                        onClicked:
                        {
                            API.qt_utilities.copy_text_to_clipboard(seedLabel.text)
                            app.notifyCopy(qsTr("Seed"), qsTr("copied to clipboard"))
                        }
                    }

                    ColumnLayout
                    {
                        DefaultText
                        {
                            text: qsTr("Backup Seed")
                            font.pixelSize: Style.textSizeSmall2
                            color: Dex.CurrentTheme.foregroundColor2
                        }

                        DefaultText
                        {
                            id: seedLabel
                            Layout.fillWidth: true
                            font.pixelSize: Style.textSizeSmall2
                            maximumLineCount: 4
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // RPC Password
                RowLayout
                {
                    spacing: 5

                    Qaterial.RawMaterialButton
                    {
                        backgroundImplicitWidth: 30
                        backgroundImplicitHeight: 30
                        backgroundColor: "transparent"
                        icon.source: Qaterial.Icons.qrcodeScan
                        icon.color: Dex.CurrentTheme.foregroundColor2
                        onClicked:
                        {
                            qrcodeModal.qrcodeSvg = API.qt_utilities.get_qrcode_svg_from_string(rpcPwLabel.text)
                            qrcodeModal.open()
                        }
                    }

                    Qaterial.RawMaterialButton
                    {
                        backgroundImplicitWidth: 30
                        backgroundImplicitHeight: 30
                        backgroundColor: "transparent"
                        icon.source: Qaterial.Icons.contentCopy
                        icon.color: Dex.CurrentTheme.foregroundColor2
                        onClicked:
                        {
                            API.qt_utilities.copy_text_to_clipboard(rpcPwLabel.text)
                            app.notifyCopy(qsTr("RPC Password"), qsTr("copied to clipboard"))
                        }
                    }

                    ColumnLayout
                    {
                        DefaultText
                        {
                            text: qsTr("RPC Password")
                            font.pixelSize: Style.textSizeSmall2
                            color: Dex.CurrentTheme.foregroundColor2
                        }
                        DefaultText
                        {
                            id: rpcPwLabel
                            Layout.fillWidth: true
                            font.pixelSize: Style.textSizeSmall2
                            maximumLineCount: 4
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }

        HorizontalLine { Layout.fillWidth: true }

        DefaultTextField
        {
            visible: coinsList.visible
            enabled: coinsList.enabled
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width / 3
            placeholderText: qsTr("Search a coin.")
            onTextChanged: portfolio_model.portfolio_proxy_mdl.setFilterFixedString(text)
            Component.onDestruction: portfolio_model.portfolio_proxy_mdl.setFilterFixedString("")
        }

        DefaultRectangle
        {
            id: coinsList
            visible: false
            enabled: false
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 300
            Layout.alignment: Qt.AlignHCenter
            radius: 10
            border.color: Dex.CurrentTheme.lineSeparatorColor
            border.width: 2

            DefaultListView
            {
                anchors.fill: parent
                model: portfolio_mdl.portfolio_proxy_mdl

                delegate: ColumnLayout
                {
                    width: coinsList.width

                    RowLayout
                    {
                        spacing: 5
                        Layout.fillWidth: true
                        Layout.leftMargin: 5

                        ColumnLayout
                        {
                            spacing: 5
                            Layout.fillWidth: true

                            DefaultImage
                            {
                                source: General.coinIcon(model.ticker)
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignCenter
                            }

                            DefaultText
                            {
                                text: model.name
                                font.pixelSize: Style.textSizeSmall4
                                color: Dex.CurrentTheme.foregroundColor2
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 90
                            }
                        }

                        ColumnLayout
                        {
                            spacing: 5
                            // Public Address
                            RowLayout
                            {
                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.qrcodeScan
                                    icon.color: Dex.CurrentTheme.foregroundColor2
                                    onClicked:
                                    {
                                        qrcodeModal.qrcodeSvg = API.qt_utilities.get_qrcode_svg_from_string(publicAddress.text)
                                        qrcodeModal.open()
                                    }
                                }

                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.contentCopy
                                    icon.color: Dex.CurrentTheme.foregroundColor2
                                    onClicked:
                                    {
                                        API.qt_utilities.copy_text_to_clipboard(publicAddress.text)
                                        app.notifyCopy(model.name, qsTr("Public Address copied to clipboard"))
                                    }
                                }

                                ColumnLayout
                                {
                                    spacing: 5
                                    Layout.fillWidth: true
                                    DefaultText
                                    {
                                        text: qsTr("Public Address")
                                        font.pixelSize: Style.textSizeSmall2
                                        color: Dex.CurrentTheme.foregroundColor2
                                    }

                                    DefaultText
                                    {
                                        id: publicAddress
                                        text: model.public_address != 'Invalid Ticker' ? model.public_address : "Please wait for " + model.name + " to fully activate..."
                                        font: model.public_address.length > 70 ? DexTypo.body4 : DexTypo.body3
                                    }
                                }
                            }

                            // Private Key
                            RowLayout
                            {
                                spacing: 5
                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.qrcodeScan
                                    icon.color: Dex.CurrentTheme.foregroundColor2
                                    onClicked:
                                    {
                                        qrcodeModal.qrcodeSvg = API.qt_utilities.get_qrcode_svg_from_string(privateKey.text)
                                        qrcodeModal.open()
                                    }
                                }

                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.contentCopy
                                    icon.color: Dex.CurrentTheme.foregroundColor2
                                    onClicked:
                                    {
                                        API.qt_utilities.copy_text_to_clipboard(model.priv_key)
                                        app.notifyCopy(model.name, qsTr("Private Key copied to clipboard"))
                                    }
                                }

                                ColumnLayout
                                {
                                    spacing: 5
                                    Layout.fillWidth: true

                                    DefaultText
                                    {
                                        text: qsTr("Private Key")
                                        font.pixelSize: Style.textSizeSmall2
                                        color: Dex.CurrentTheme.foregroundColor2
                                    }

                                    DefaultText
                                    {
                                        id: privateKey
                                        font: DexTypo.body3
                                        text: textMetrics.elidedText
                                    }
                                    TextMetrics {
                                        id: textMetrics
                                        elide: Text.ElideMiddle
                                        font.family: DexTypo.fontFamily
                                        elideWidth: 560
                                        text: model.priv_key
                                    }
                                }
                            }
                        }
                    }
                    HorizontalLine { Layout.fillWidth: true }
                }
            }
        }

        ModalLoader
        {
            id: qrcodeModal

            property string qrcodeSvg

            sourceComponent: Popup
            {
                id: popup

                x: (root.width - width) / 2
                y: ((root.height - height) / 2) - 250

                onClosed: qrcodeSvg = ""

                background: Image
                {
                    source: qrcodeSvg
                    sourceSize.width: 200
                    sourceSize.height: 200
                }
            }
        }
    }
}
