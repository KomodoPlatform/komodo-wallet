import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../Constants"
import App 1.0


ColumnLayout {

    id: control

    property var field
    property bool hide_hint: false
    property bool new_password: true
    property bool double_validation: false
    property string match_password
    property int max_pw_len: General.max_std_pw_length
    property bool high_security: true

    function isValid() {
        if (double_validation) {
            return control.field.acceptableInput && RegExp(high_security ? General.reg_pass_valid : General.reg_pass_valid_low_security).test(control.field.text) && passwordsDoMatch()
        } else {
            return control.field.acceptableInput && RegExp(high_security ? General.reg_pass_valid : General.reg_pass_valid_low_security).test(control.field.text)
        }
    }

    function hasEnoughUppercaseCharacters() {
        return control.field.acceptableInput && RegExp(General.reg_pass_uppercase).test(control.field.text)
    }

    function hasEnoughLowercaseCharacters() {
        return control.field.acceptableInput && RegExp(General.reg_pass_lowercase).test(control.field.text)
    }

    function hasEnoughNumericCharacters() {
        return control.field.acceptableInput && RegExp(General.reg_pass_numeric).test(control.field.text)
    }

    function hasEnoughSpecialCharacters() {
        return control.field.acceptableInput && RegExp(General.reg_pass_special).test(control.field.text)
    }

    function hasEnoughCharacters() {
        return control.field.acceptableInput && RegExp(high_security ? General.reg_pass_count : General.reg_pass_count_low_security).test(control.field.text)
    }

    function passwordsDoMatch() {
        return match_password !== "" && control.field.acceptableInput && control.field.text === match_password
    }

    function hintColor(valid) {
        return valid ? DexTheme.okColor : DexTheme.warningColor
    }

    function hintPrefix(valid) {
        return " " + (valid ? Style.successCharacter : Style.failureCharacter) + "   "
    }
    ColumnLayout {
        spacing: 5

        visible: !hide_hint
        Layout.fillWidth: true

        DexLabel {
            visible: high_security
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(hasEnoughLowercaseCharacters()) + qsTr("At least 1 lowercase alphabetical character")
            color: hintColor(hasEnoughLowercaseCharacters())
        }
        DexLabel {
            visible: high_security
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(hasEnoughUppercaseCharacters()) + qsTr("At least 1 uppercase alphabetical character")
            color: hintColor(hasEnoughUppercaseCharacters())
        }
        DexLabel {
            visible: high_security
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(hasEnoughNumericCharacters()) + qsTr("At least 1 numeric character")
            color: hintColor(hasEnoughNumericCharacters())
        }
        DexLabel {
            visible: high_security
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(hasEnoughSpecialCharacters()) + qsTr("At least 1 special character (eg. !@#$%)")
            color: hintColor(hasEnoughSpecialCharacters())
        }
        DexLabel {
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(hasEnoughCharacters()) + qsTr("Between %1 and %2 character(s)").arg(high_security ? 16 : 1).arg(max_pw_len)
            color: hintColor(hasEnoughCharacters())
        }
        DexLabel {
            font: DexTypo.body2
            Layout.fillWidth: true
            wrapMode: DexLabel.Wrap
            text_value: hintPrefix(passwordsDoMatch()) + qsTr("Password and Confirm Password have to be same")
            color: hintColor(passwordsDoMatch())
        }
    }
}
