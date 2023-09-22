import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Layouts 1.12
import App 1.0

Popup {
    id: dialog
    width: 350
    dim: true
    modal: true
    anchors.centerIn: Overlay.overlay
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    Overlay.modal: Item {
        DexRectangle {
            anchors.fill: parent
            color: Qt.darker(DexTheme.backgroundDarkColor6)
            opacity: .8
        }
    }

    property bool warning: false

    signal accepted(string text)
    signal applied()
    signal clicked(AbstractButton button)
    signal discarded()
    signal helpRequested()
    signal rejected()
    signal reset()
    signal checkValidator()

    property
    var validator: undefined

    property string title: ""
    property string text: ""
    property string placeholderText: ""
    property alias iconSource: _insideLabel.icon.source
    property alias iconColor: _insideLabel.icon.color
    property alias item: _col.contentItem
    property alias itemSpacing: _insideLabel.spacing
    property int standardButtons: Dialog.NoButton
    property string yesButtonText: ""
    property string cancelButtonText: ""
    property bool getText: false
    property bool isPassword: false
    property bool enableAcceptButton: validator === undefined ? true : validator(_insideField.field.text)

    background: Qaterial.ClipRRect {
        radius: 4
        DexRectangle {
            anchors.fill: parent
            radius: 4
            color: DexTheme.backgroundDarkColor2
        }
    }

    focus: true

    contentItem: Qaterial.ClipRRect {
        height: _insideColumn.height
        radius: 4
        focus: true
        Column {
            id: _insideColumn
            width: parent.width
            padding: 0
            topPadding: 10
            spacing: 0
            bottomPadding: 3
            Item {
                id: _header
                height: _label.height + 10
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter

                DexLabel {
                    id: _label
                    width: parent.width
                    wrapMode: Label.Wrap
                    leftPadding: 5
                    font: DexTypo.body1
                    color: DexTheme.foregroundColor
                    anchors.verticalCenter: parent.verticalCenter
                    text: dialog.title
                }
            }

            Container {
                id: _col
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                bottomPadding: 10
                topPadding: 10
                leftPadding: 5
                contentItem: Column {
                    Qaterial.IconLabel {
                        id: _insideLabel
                        icon.source: dialog.iconSource
                        icon.width: dialog.iconSource === "" ? 0 : 48
                        icon.height: dialog.iconSource === "" ? 0 : 48
                        icon.color: dialog.iconColor
                        width: parent.width

                        color: DexTheme.foregroundColor

                        text: dialog.text
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Label.AlignLeft

                        display: dialog.iconSource === "" ? AbstractButton.TextOnly : AbstractButton.TextBesideIcon
                    }

                    Item {
                        height: 10
                        width: 10
                        visible: _insideField.visible
                    }

                    DexDialogTextField {
                        id: _insideField
                        width: parent.width
                        height: 45
                        error: false
                        visible: dialog.getText
                        defaultBorderColor: DexTheme.backgroundDarkColor6
                        background.border.width: 1
                        field.font: DexTypo.body2
                        placeholderText: dialog.placeholderText
                        field.placeholderText: ""
                        field.rightPadding: dialog.isPassword ? 55 : 20
                        field.leftPadding: dialog.isPassword ? 70 : 20
                        field.echoMode: dialog.isPassword ? TextField.Password : TextField.Normal

                        field.onAccepted: {
                            if(dialog.enableAcceptButton) {
                                dialog.accepted(field.text)
                            }
                        }

                        DexRectangle {
                            x: 3
                            visible: dialog.isPassword
                            height: 40
                            width: 60
                            radius: 20
                            color: DexTheme.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Qaterial.ColorIcon {
                                anchors.centerIn: parent
                                iconSize: 19
                                source: Qaterial.Icons.keyVariant
                                color: DexTheme.backgroundDarkColor2
                            }

                        }
                        Qaterial.AppBarButton {
                            visible: dialog.isPassword
                            opacity: .8
                            icon {
                                source: _insideField.field.echoMode === TextField.Password ? Qaterial.Icons.eyeOffOutline : Qaterial.Icons.eyeOutline
                                color: _insideField.field.focus ? _insideField.background.border.color : DexTheme.accentColor
                            }
                            anchors {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                                rightMargin: 10
                            }
                            onClicked: {
                                if (_insideField.field.echoMode === TextField.Password) {
                                    _insideField.field.echoMode = TextField.Normal
                                } else {
                                    _insideField.field.echoMode = TextField.Password
                                }
                            }
                        }
                    }
                }
            }
            DialogButtonBox {
                id: _dialogButtonBox
                visible: standardButtons !== Dialog.NoButton
                standardButtons: dialog.standardButtons
                width: parent.width - 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 60
                alignment: Qt.AlignRight
                buttonLayout: DialogButtonBox.AndroidLayout
                onAccepted: {
                    if (dialog.getText) {
                        dialog.accepted(_insideField.field.text)
                    } else {
                        dialog.accepted(undefined)
                    }
                    dialog.close()
                }
                onApplied: {
                    dialog.applied()
                    dialog.close()
                }
                onDiscarded: {
                    dialog.discarded()
                    dialog.close()
                }
                onHelpRequested: dialog.helpRequested()
                onRejected: {
                    dialog.rejected()
                    dialog.close()
                }
                onReset: dialog.reset()
                topPadding: 25
                background: Rectangle {
                    color: DexTheme.backgroundDarkColor6
                }
                delegate: Qaterial.Button {
                    id: _dialogManagerButton
                    flat: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole
                    bottomInset: 0
                    topInset: 0
                    opacity: enabled ? 1 : .6
                    enabled: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole ? true : dialog.enableAcceptButton
                    backgroundColor: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole ? 'transparent' : dialog.warning ? DexTheme.warningColor : DexTheme.accentColor
                    property alias cursorShape: mouseArea.cursorShape
                    Component.onCompleted: {
                        if (text === "Yes" && dialog.yesButtonText !== "") {
                            text = dialog.yesButtonText
                        } else if (text === "Cancel" && dialog.cancelButtonText !== "") {
                            text = dialog.cancelButtonText
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onPressed: mouse.accepted = false
                    }
                }
            }
        }
    }
}