import QtQuick 2.12
import QtQuick.Layouts 1.15

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex
import "../Constants" as Dex

Dex.MultipageModal
{
    id: root

    property var contactModel: { "name": "", "categories": [] }

    Dex.MultipageModalContent
    {
        titleText: qsTr("Edit contact")
        titleTopMargin: 0
        titleAlignment: Qt.AlignHCenter
        contentSpacing: 24

        Dex.TextFieldWithTitle
        {
            id: contactNameInput
            title: qsTr("Contact name")
            field.placeholderText: qsTr("Enter a contact name")
            field.text: contactModel.name
            field.onTextChanged: if (field.text.length > 30) field.text = field.text.substring(0, 30)
        }

        Column
        {
            id: addressList
            property bool contactAddAddressMode: false

            Layout.fillWidth: true
            spacing: 18

            Dex.Text
            {
                text: qsTr("Address list")
            }

            Dex.ListView
            {
                visible: !addressList.contactAddAddressMode
                model: contactModel.proxyFilter
                spacing: 10
                height: contentHeight > 190 ? 190 : contentHeight
                width: parent.width

                delegate: Dex.MouseArea
                {
                    id: addressRowMouseArea
                    height: 82
                    width: addressList.width - 10
                    hoverEnabled: true

                    Dex.Rectangle
                    {
                        visible: parent.containsMouse
                        anchors.fill: parent
                        radius: 17
                        color: Dex.CurrentTheme.accentColor
                    }

                    Item
                    {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 10

                        ColumnLayout
                        {
                            property var coinInfo: Dex.API.app.portfolio_pg.global_cfg_mdl.get_coin_info(address_type)

                            Row
                            {
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

                                Dex.Button
                                {
                                    visible: addressRowMouseArea.containsMouse
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 9
                                    height: 9
                                    color: "transparent"
                                    iconSource: Qaterial.Icons.close
                                    onClicked: contactModel.removeAddressEntry(address_type, address_key)
                                }
                            }

                            Dex.Text
                            {
                                Layout.leftMargin: 36
                                Layout.maximumWidth: 330
                                text: address_key
                                font: Dex.DexTypo.caption
                                elide: Text.ElideRight
                            }

                            Dex.Text
                            {
                                Layout.leftMargin: 36
                                Layout.maximumWidth: 330
                                text: address_value
                                font: Dex.DexTypo.caption
                                elide: Text.ElideRight

                                Dex.Button
                                {
                                    width: 18
                                    height: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.right
                                    anchors.leftMargin: 3
                                    color: "transparent"
                                    iconSource: Qaterial.Icons.contentCopy

                                    onClicked:
                                    {
                                        Dex.API.qt_utilities.copy_text_to_clipboard(address_value)
                                        app.notifyCopy(qsTr("Address Book"), qsTr("address copied to clipboard"))
                                    }
                                }
                            }
                        }

                        Row
                        {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 20

                            Dex.ClickableText
                            {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: addressRowMouseArea.containsMouse
                                text: qsTr("Edit")
                                font.underline: true
                                onClicked:
                                {
                                    addAddressForm.editionMode = true
                                    addAddressForm.addressType = address_type
                                    addAddressForm.addressKey = address_key
                                    addAddressForm.addressValue = address_value
                                    addressList.contactAddAddressMode = true
                                }
                            }

                            Dex.Button
                            {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 37
                                height: 37
                                radius: 18.5
                                visible: addressRowMouseArea.containsMouse
                                iconSource: Qaterial.Icons.sendOutline
                                onClicked:
                                {
                                    trySend(address_value, address_type)
                                }
                            }
                        }
                    }
                }
            }

            Dex.Button
            {
                visible: !addressList.contactAddAddressMode
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("+ Add Address")
                width: 211
                height: 38
                radius: 18
                onClicked: addressList.contactAddAddressMode = true
            }

            AddAddressForm
            {
                id: addAddressForm
                visible: addressList.contactAddAddressMode
                contactModel: root.contactModel
                onCancel: addressList.contactAddAddressMode = false
                onAddressCreated: addressList.contactAddAddressMode = false
            }
        }

        Column
        {
            Layout.fillWidth: true
            spacing: 12

            Dex.Text
            {
                text: qsTr("Tags")
            }

            Dex.ListView
            {
                width: parent.width
                model: contactModel.categories
                orientation: Qt.Horizontal
                spacing: 4
                delegate: Dex.MouseArea
                {
                    width: tagBg.width + tagRemoveBut.width + 2
                    height: tagBg.height
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

                    Dex.Button
                    {
                        id: tagRemoveBut
                        visible: parent.containsMouse
                        anchors.left: tagBg.right
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        color: "transparent"
                        iconSource: Qaterial.Icons.close
                        onClicked: contactModel.removeCategory(modelData)
                    }
                }
            }

            Dex.Button
            {
                iconSource: Qaterial.Icons.plus
                text: qsTr("Add tag")
                font: Dex.DexTypo.body2
                color: "transparent"
                onClicked: addTagPopup.open()

                AddTagPopup
                {
                    y: -10
                    x: parent.width + 10
                    id: addTagPopup
                }
            }
        }

        footer:
        [
            Dex.CancelButton
            {
                Layout.preferredWidth: 199
                Layout.preferredHeight: 48
                radius: 18
                text: qsTr("Cancel Updates")
                onClicked: root.close()
            },

            Item { Layout.fillWidth: true },

            Dex.GradientButton
            {
                Layout.preferredWidth: 199
                Layout.preferredHeight: 48
                radius: 18
                text: qsTr("Save Updates")
                onClicked:
                {
                    contactModel.name = contactNameInput.field.text
                    contactModel.save()
                    root.close()
                }
            }
        ]
    }
}
