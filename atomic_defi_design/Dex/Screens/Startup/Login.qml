import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../../Components"
import "../../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

SetupPage
{
    id: login

    property string text_error
    property string walletName
    property bool   _isPasswordWrong: false

    image_scale: 1
    image_path: Dex.CurrentTheme.bigLogoPath
    backgroundColor: 'transparent'

    signal backClicked()
    signal loginSucceeded()

    function onClickedLogin(password)
    {
        if (API.app.wallet_mgr.login(password, walletName))
        {
            console.info("Success: Login");
            app.currentWalletName = walletName;
            loginSucceeded();
            return true;
        }
        else
        {
            console.info("Failed: Login");
            return false;
        }
    }

    content: ColumnLayout
    {
        id: content
        spacing: 10

        DexLabel
        {
            Layout.alignment: Qt.AlignHCenter
            text: "%1 wallet".arg(walletName)
            color: Dex.CurrentTheme.foregroundColor
            font: DexTypo.body1
            topPadding: 10
        }

        Item
        {
            height: 20
            width: 1
        }

        DexAppPasswordField
        {
            id: _inputPassword
            Layout.alignment: Qt.AlignHCenter
            max_length: General.max_pw_length
            height: 50
            width: 300
            forceFocus: true
            field.onTextChanged: { _isPasswordWrong = false }
            field.onAccepted:
            {
                if (_keyChecker.isValid())
                {
                    if (!onClickedLogin(field.text))
                    {
                        _inputPassword.error = true;
                        _isPasswordWrong = true;
                    }
                    return true
                }
                else
                {
                    _inputPassword.error = true;
                    _isPasswordWrong = true;
                    return false;
                }
            }
        }

        DexLabel
        {
            Layout.alignment: Qt.AlignHCenter
            height: 14
            text: _isPasswordWrong ? qsTr("Incorrect Password") : ""
            color: Dex.CurrentTheme.warningColor
        }

        GradientButton
        {
            Layout.alignment: Qt.AlignHCenter
            radius: width
            width: 200
            text: qsTr("Log In")
            onClicked: _inputPassword.field.accepted()
        }

        DexKeyChecker
        {
            Layout.alignment: Qt.AlignHCenter
            id: _keyChecker
            max_pw_len: General.max_pw_length
            field: _inputPassword.field
            visible: false
        }

        CancelButton
        {
            text: qsTr("Cancel")
            height: 25
            radius: 20
            width: 100
            Layout.alignment: Qt.AlignHCenter
            font: Qt.font(
            {
                pixelSize: 14,
                letterSpacing: 0.15,
                family: DexTypo.fontFamily,
                weight: Font.Normal
            })
            onClicked: backClicked()
        }
    }
}
