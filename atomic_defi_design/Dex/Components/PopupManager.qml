import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Layouts 1.12
import App 1.0
import Dex.Themes 1.0 as Dex
import "../Constants"

Popup
{


    id: dialog
    width: 420
    // There is a binding loop issue if this line is active
    // height: _insideColumn.height > dialog.height ? _insideColumn.height + 82 : dialog.height
    dim: true
    modal: true
    anchors.centerIn: Overlay.overlay
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    Overlay.modal: Item
    {
        DexRectangle
        {
            anchors.fill: parent
            color: 'black'
            opacity: .7
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
    property bool showCancelBtn: true
    property bool getText: false
    property bool isPassword: false
    property bool centerAlign: false
    property color backgroundColor: Dex.CurrentTheme.backgroundColor
    property bool titleBold: false
    property bool forceFocus: false
    property bool enableAcceptButton: validator === undefined ? true : validator(_insideField.field.text)

    background: Qaterial.ClipRRect
    {
        radius: 4
        DexRectangle
        {
            anchors.fill: parent
            radius: 18
            color: dialog.backgroundColor
        }
    }

    focus: true

    contentItem: Qaterial.ClipRRect
    {
        width: dialog.width
        // There is a binding loop issue if this line is active
        // height: _insideColumn.height >  dialog.height ? _insideColumn.height + 92 : dialog.height
        radius: 18
        focus: true
        Column
        {
            id: _insideColumn
            width: parent.width - 92
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 0
            topPadding: 10
            spacing: 0
            bottomPadding: 3
            anchors.verticalCenter: parent.verticalCenter
            Item
            {
                id: _header
                height: _label.height + 10
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                DexLabel
                {
                    id: _label
                    width: parent.width
                    wrapMode: Label.Wrap
                    font: DexTypo.body1
                    color: DexTheme.foregroundColor
                    horizontalAlignment: dialog.centerAlign ? Text.AlignHCenter : Text.AlignLeft
                    text: dialog.title
                    Component.onCompleted: {
                        font.bold = dialog.titleBold
                    }
                }
            }

            Container
            {
                id: _col
                width: parent.width
                bottomPadding: 10
                topPadding: 10
                contentItem: Column
                {
                    Qaterial.IconLabel
                    {
                        id: _insideLabel
                        icon.source: dialog.iconSource
                        icon.width: dialog.iconSource === "" ? 0 : 48
                        icon.height: dialog.iconSource === "" ? 0 : 48
                        icon.color: dialog.iconColor
                        width: parent.width

                        color: DexTheme.foregroundColor

                        text: dialog.text
                        wrapMode: Text.WordWrap
                        horizontalAlignment: dialog.centerAlign ? Text.AlignHCenter : Text.AlignLeft

                        display: dialog.iconSource === "" ? AbstractButton.TextOnly : AbstractButton.TextBesideIcon
                    }

                    Item
                    {
                        height: 10
                        width: 10
                        visible: _insideField.visible
                    }

                    DexDialogTextField
                    {
                        id: _insideField
                        width: parent.width
                        height: 45
                        error: false
                        visible: dialog.getText
                        defaultBorderColor: background.color
                        background.border.width: 1
                        background.color: Dex.CurrentTheme.floatingBackgroundColor
                        field.font: DexTypo.body2
                        placeholderText: dialog.placeholderText
                        field.placeholderText: ""
                        field.forceFocus: forceFocus
                        max_length: dialog.isPassword ? General.max_std_pw_length : 40
                        field.rightPadding: dialog.isPassword ? 55 : 20
                        field.leftPadding: dialog.isPassword ? 70 : 20
                        field.echoMode: dialog.isPassword ? TextField.Password : TextField.Normal

                        field.onTextChanged:
                        {
                            if (validator)
                            {
                                if (validator(field.text))
                                {
                                    dialog.enableAcceptButton = true
                                }
                                else {
                                    dialog.enableAcceptButton = false
                                }
                            }
                        }
                        field.onAccepted:
                        {
                            if (dialog.enableAcceptButton)
                            {
                                dialog.accepted(field.text)
                            }
                        }

                        DexRectangle
                        {
                            x: 3
                            visible: dialog.isPassword
                            height: 40
                            width: 60
                            radius: _insideField.background.radius
                            color: DexTheme.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Qaterial.ColorIcon
                            {
                                anchors.centerIn: parent
                                iconSize: 19
                                source: Qaterial.Icons.keyVariant
                                color: Dex.CurrentTheme.foregroundColor
                            }

                        }
                        Qaterial.AppBarButton
                        {
                            visible: dialog.isPassword
                            opacity: .8
                            icon
                            {
                                source: _insideField.field.echoMode === TextField.Password ? Qaterial.Icons.eyeOffOutline : Qaterial.Icons.eyeOutline
                                color: Dex.CurrentTheme.foregroundColor
                            }
                            anchors
                            {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                                rightMargin: 10
                            }

                            HoverHandler {
                                cursorShape: "PointingHandCursor"
                            }
                            onClicked:
                            {
                                if (_insideField.field.echoMode === TextField.Password)
                                {
                                    _insideField.field.echoMode = TextField.Normal
                                } else
                                {
                                    _insideField.field.echoMode = TextField.Password
                                }
                            }
                        }
                    }
                }
            }

            Container
            {
                width: parent.width - 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 60
                background:  Rectangle
                {
                    color: dialog.backgroundColor
                }
                contentItem:  RowLayout
                {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 80
                    CancelButton
                    {
                        id: cancelBtn
                        visible: showCancelBtn
                        text: dialog.cancelButtonText !== "" ? dialog.cancelButtonText : "Cancel"
                        height: 40
                        leftPadding: 20
                        rightPadding: 20
                        radius: 18
                        onClicked:
                        {
                            dialog.rejected()
                            dialog.close()
                        }
                    }
                    Item
                    {
                        Layout.fillWidth: true
                    }
                    DexGradientAppButton
                    {
                        text: dialog.yesButtonText !== "" ? dialog.yesButtonText : "Yes"
                        height: 40
                        width: showCancelBtn ? cancelBtn.width : 90
                        leftPadding: 20
                        rightPadding: 20
                        radius: 18
                        enabled: dialog.enableAcceptButton
                        onClicked:
                        {
                            if (dialog.getText)
                            {
                                dialog.accepted(_insideField.field.text)
                            } else
                            {
                                dialog.accepted(undefined)
                            }
                            dialog.close()
                        }
                    }
                }
            }

            DialogButtonBox
            {
                id: _dialogButtonBox
                visible: false
                standardButtons: dialog.standardButtons
                width: parent.width - 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 60
                alignment: Qt.AlignRight
                buttonLayout: DialogButtonBox.AndroidLayout
                onAccepted:
                {
                    if (dialog.getText)
                    {
                        dialog.accepted(_insideField.field.text)
                    } else
                    {
                        dialog.accepted(undefined)
                    }
                    dialog.close()
                }
                onApplied:
                {
                    dialog.applied()
                    dialog.close()
                }
                onDiscarded:
                {
                    dialog.discarded()
                    dialog.close()
                }
                onHelpRequested: dialog.helpRequested()
                onRejected:
                {
                    dialog.rejected()
                    dialog.close()
                }
                onReset: dialog.reset()
                topPadding: 25
                background: Rectangle
                {
                    color: DexTheme.backgroundDarkColor6
                }
                delegate: Qaterial.Button
                {
                    id: _dialogManagerButton
                    flat: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole
                    bottomInset: 0
                    topInset: 0
                    opacity: enabled ? 1 : .6
                    enabled: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole ? true : dialog.enableAcceptButton
                    backgroundColor: DialogButtonBox.buttonRole === DialogButtonBox.RejectRole ? 'transparent' : dialog.warning ? DexTheme.warningColor : DexTheme.accentColor
                    property alias cursorShape: mouseArea.cursorShape
                    Component.onCompleted:
                    {
                        if (text === "Yes" && dialog.yesButtonText !== "")
                        {
                            text = dialog.yesButtonText
                        } else if (text === "Cancel" && dialog.cancelButtonText !== "")
                        {
                            text = dialog.cancelButtonText
                        }
                    }

                    MouseArea
                    {
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
