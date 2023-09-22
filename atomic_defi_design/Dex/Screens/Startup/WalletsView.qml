import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12

import QtQuick.Window 2.15

import Qaterial 1.0 as Qaterial

import "../../Components"
import "../../Constants"
import "../../Settings"
import App 1.0
import Dex.Themes 1.0 as Dex

SetupPage
{
    // Override
    id: _setup

    property var wallets: API.app.wallet_mgr.get_wallets()
    readonly property int wallet_count: API.app.wallet_mgr.get_wallets().length

    signal newWalletClicked()
    signal importWalletClicked();
    signal walletSelected(string walletName);

    image_path: Dex.CurrentTheme.bigLogoPath
    image_margin: 15

    backgroundColor: Dex.CurrentTheme.backgroundColor

    content: ColumnLayout
    {
        id: content_column
        width: 270
        spacing: Style.rowSpacing
        RowLayout
        {
            Layout.fillWidth: true
            DexLabel
            {
                font: DexTypo.head6
                text_value: qsTr("Welcome")
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
            }
        }

        Item
        {
            Layout.fillWidth: true
        }

        GradientButton
        {
            Layout.fillWidth: true
            Layout.minimumWidth: 269
            text: qsTr("New wallet")
            Layout.preferredHeight: 40
            radius: 18
            onClicked: newWalletClicked()
        }

        OutlineButton
        {
            text: qsTr("Import wallet")
            radius: 18
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            onClicked: importWalletClicked()
        }

        // Wallets
        ColumnLayout
        {
            spacing: Style.rowSpacing
            visible: wallet_count > 0

            // Searchbar
            DefaultTextField
            {
                id: wallet_search
                visible: wallet_count > 5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: qsTr("Search your wallets...")
                forceFocus: true
                onTextChanged:
                {
                    wallets = API.app.wallet_mgr.get_wallets(text)
                }
                Component.onDestruction: wallets = API.app.wallet_mgr.get_wallets()
            }

            DexLabel
            {
                visible: !wallet_search.visible
                topPadding: 10
                text_value: qsTr("My Wallets")
                font.pixelSize: Style.textSizeSmall2
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }


            // Wallets List
            DexRectangle
            {
                id: wallet_list_bg

                readonly property int row_height: 40

                width: content_column.width
                Layout.minimumHeight: row_height
                Layout.preferredHeight: (row_height * Math.min(wallet_count, 5)) + 20
                color: Dex.CurrentTheme.floatingBackgroundColor
                radius: 18

                RowLayout
                {
                    anchors.fill: parent

                    Item { Layout.fillWidth: true }

                    DexLabel
                    {
                        text_value: qsTr("No wallets found!")
                        visible: wallets.length == 0
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }
                }


                DefaultListView
                {
                    id: list
                    Layout.preferredHeight: wallet_list_bg.Layout.preferredHeight
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0

                    model: wallets

                    delegate: ClipRRect
                    {
                        radius: 18
                        width: wallet_list_bg.width - 20
                        height: wallet_list_bg.row_height

                        DefaultRectangle
                        {
                            color: "transparent"
                            border.width: 0
                            anchors.fill: parent
                            radius: 18

                            Rectangle
                            {
                                height: parent.height
                                width: parent.width
                                opacity: 1
                                color: Dex.CurrentTheme.backgroundColor
                                visible: mouse_area.containsMouse
                                radius: 18
                            }

                            DexMouseArea
                            {
                                id: mouse_area
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
                                    walletSelected(model.modelData)
                                }
                            }

                            Rectangle
                            {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 5
                                width: 30
                                height: width
                                radius: 18
                                color: Dex.CurrentTheme.floatingBackgroundColor

                                Qaterial.ColorIcon
                                {
                                    anchors.fill: parent
                                    color: Dex.CurrentTheme.userIconColorStart
                                    source: Qaterial.Icons.account
                                    iconSize: 28
                                }
                            }

                            DefaultText
                            {
                                anchors.left: parent.left
                                anchors.leftMargin: 40

                                text_value: model.modelData
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: Style.textSizeSmall2
                                font.family: 'Ubuntu'
                                font.weight: Font.Medium
                            }
                        }

                        Item
                        {
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            height: parent.height
                            width: 30
                            Qaterial.ColorIcon
                            {
                                visible: mouse_area.containsMouse || _deleteArea.containsMouse
                                source: Qaterial.Icons.close
                                iconSize: 18
                                anchors.centerIn: parent
                                opacity: .8
                                color: _deleteArea.containsMouse ? Dex.CurrentTheme.warningColor : Dex.CurrentTheme.foregroundColor
                            }

                            DexMouseArea
                            {
                                id: _deleteArea
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked:
                                {
                                    let wallet_name = model.modelData;
                                    let dialog = app.getText(
                                    {
                                        "title": qsTr("Delete") + " %1 ".arg(wallet_name) + ("wallet?"),
                                        text: qsTr("Enter password to confirm deletion of") + " %1 ".arg(wallet_name) + qsTr("wallet"),
                                        standardButtons: Dialog.Yes | Dialog.Cancel,
                                        warning: true,
                                        iconColor: Dex.CurrentTheme.warningColor,
                                        isPassword: true,
                                        placeholderText: qsTr("Type password"),
                                        yesButtonText: qsTr("Delete"),
                                        cancelButtonText: qsTr("Cancel"),
                                        onAccepted: function(text)
                                        {
                                            if (API.app.wallet_mgr.confirm_password(wallet_name, text))
                                            {
                                                API.app.wallet_mgr.delete_wallet(wallet_name);
                                                app.showDialog(
                                                {
                                                    title: qsTr("Wallet status"),
                                                    text: "%1 ".arg(wallet_name) + qsTr("wallet deleted successfully"),
                                                    yesButtonText: qsTr("Ok"), titleBold: true,
                                                    showCancelBtn: false,
                                                    standardButtons: Dialog.Ok
                                                })
                                                wallets = API.app.wallet_mgr.get_wallets()
                                            }
                                            else
                                            {
                                                app.showDialog(
                                                {
                                                    title: qsTr("Wallet status"),
                                                    text: "%1 ".arg(wallet_name) + qsTr("wallet password is incorrect"),
                                                    warning: true,
                                                    standardButtons: Dialog.Ok, titleBold: true,
                                                    showCancelBtn: false,
                                                    yesButtonText: qsTr("Ok"),
                                                })
                                            }
                                            dialog.close()
                                            dialog.destroy()
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        HorizontalLine
        {}
    }

    LinksRow
    {
        Layout.alignment: Qt.AlignHCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20

        anchors.horizontalCenter: parent.horizontalCenter

    }

    GaussianBlur
    {
        anchors.fill: _setup
        visible: false
        source: _setup
        radius: 21
        deviation: 2
    }
}
