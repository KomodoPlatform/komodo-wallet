import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../Constants"

import App 1.0

ColumnLayout {
    property alias title: pw.title
    property alias field: pw.field
    property int max_pw_len: General.max_std_pw_length
    property bool hide_hint: false
    property bool new_password: true
    property string match_password
    property bool high_security: true

    function reset() {
        pw.reset()
    }

    function isValid() {
        return pw.field.acceptableInput && RegExp(high_security ? General.reg_pass_valid : General.reg_pass_valid_low_security).test(pw.field.text)
    }

    function hasEnoughUppercaseCharacters() {
        return pw.field.acceptableInput && RegExp(General.reg_pass_uppercase).test(pw.field.text)
    }

    function hasEnoughLowercaseCharacters() {
        return pw.field.acceptableInput && RegExp(General.reg_pass_lowercase).test(pw.field.text)
    }

    function hasEnoughNumericCharacters() {
        return pw.field.acceptableInput && RegExp(General.reg_pass_numeric).test(pw.field.text)
    }

    function hasEnoughSpecialCharacters() {
        return pw.field.acceptableInput && RegExp(General.reg_pass_special).test(pw.field.text)
    }

    function hasEnoughCharacters() {
        return pw.field.acceptableInput && RegExp(high_security ? General.reg_pass_count : General.reg_pass_count_low_security).test(pw.field.text)
    }

    function passwordsDoMatch() {
        return match_password !== "" && pw.field.acceptableInput && pw.field.text === match_password
    }

    function hintColor(valid) {
        return valid ? DexTheme.okColor : DexTheme.warningColor
    }

    function hintPrefix(valid) {
        return " " + (valid ? Style.successCharacter : Style.failureCharacter) + "   "
    }

    TextFieldWithTitle {
        id: pw
        hidable: true
        title: qsTr("Password")
        field.placeholderText: qsTr("Enter your wallet password")
        field.validator: RegExpValidator { regExp: General.reg_pass_input }
        max_length: max_pw_len
    }

    ColumnLayout {
        spacing: -Style.textSizeSmall3*0.1

        visible: !hide_hint
        Layout.fillWidth: true

        DefaultText {
            visible: high_security
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(hasEnoughLowercaseCharacters()) + qsTr("At least 1 lowercase alphabetical character")
            color: hintColor(hasEnoughLowercaseCharacters())
        }
        DefaultText {
            visible: high_security
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(hasEnoughUppercaseCharacters()) + qsTr("At least 1 uppercase alphabetical character")
            color: hintColor(hasEnoughUppercaseCharacters())
        }
        DefaultText {
            visible: high_security
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(hasEnoughNumericCharacters()) + qsTr("At least 1 numeric character")
            color: hintColor(hasEnoughNumericCharacters())
        }
        DefaultText {
            visible: high_security
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(hasEnoughSpecialCharacters()) + qsTr("At least 1 special character (eg. !@#$%)")
            color: hintColor(hasEnoughSpecialCharacters())
        }
        DefaultText {
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(hasEnoughCharacters()) + qsTr("Between %1 and %2 character(s)").arg(high_security ? 16 : 1).arg(max_pw_len)
            color: hintColor(hasEnoughCharacters())
        }
        DefaultText {
            font.pixelSize: Style.textSizeSmall3
            text_value: hintPrefix(passwordsDoMatch()) + qsTr(high_security ? "Password and Confirm Password have to be same" : "Password suffix and confirm password suffix must be the same")
            color: hintColor(passwordsDoMatch())
        }
    }
}
