// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15

// Project Imports
import "../Components"
import "../Constants"
import Dex.Components 1.0 as Dex
import Dex.Themes 1.0 as Dex

Dex.Popup
{
    id: root
    width: parent.width < 180 ? 180 : parent.width
    height: 88
    onOpened: nameField.forceActiveFocus()
    onClosed: nameField.text = ""
    bgColor: Dex.CurrentTheme.innerBackgroundColor 

    contentItem: Column
    {
        id: new_contact_input
        anchors.centerIn: parent
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Dex.TextField
        {
            id: nameField
            height: 30
            width: parent.width - 20
            anchors.horizontalCenter: parent.horizontalCenter
            placeholderText: qsTr("Contact name")

            Dex.ToolTip
            {
                id: nameAlreadyTakenToolTip
                visible: false
                timeout: 3000
                contentItem: Dex.Text
                {
                    text_value: qsTr("This contact name already exists.")
                }
            }
        }

        DefaultButton
        {
            id: add_contact_btn
            font: DexTypo.body2
            text: qsTr("Save")
            height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked:
            {
                if (nameField.text.length === 0)
                {
                    return
                }

                var createContactResult = API.app.addressbookPg.model.addContact(nameField.text)

                if (createContactResult === false) nameAlreadyTakenToolTip.visible = true
                else
                {
                    root.close()

                    let contactModelIndex = API.app.addressbookPg.model.index(API.app.addressbookPg.model.rowCount() - 1, 0)
                    editContactLoader.contactModel = API.app.addressbookPg.model.data(contactModelIndex, Qt.UserRole + 1)
                    editContactLoader.open()
                }
            }
        }
    }
}
