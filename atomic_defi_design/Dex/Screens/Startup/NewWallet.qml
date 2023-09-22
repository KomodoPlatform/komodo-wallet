import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Qaterial 1.0 as Qaterial

import "../../Components"
import "../../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex

SetupPage
{
    id: new_user

    // Override
    signal backClicked()
    signal walletCreated(string walletName)

    property string current_mnemonic
    property string text_error
    property string guess_text_error

    property bool form_is_filled: false
    property int currentStep: 0
    property int current_word_idx: 0
    property int guess_count: 1
    verticalCenterOffset: 0

    function onOpened()
    {
        current_mnemonic = API.app.get_mnemonic()
    }

    function getWords()
    {
        return current_mnemonic.split(" ")
    }

    function setRandomGuessWord(words)
    {
        const prev_idx = current_word_idx
        while (current_word_idx === prev_idx)
            current_word_idx = General.getRandomInt(0, words.length - 1)
        return words[current_word_idx]
    }

    function validGuessField(field)
    {
        return field.acceptableInput
    }

    function submitGuess(field)
    {
        if (validGuessField(field))
        {
            // Check if it's correct
            if (field.text === getWords()[current_word_idx])
            {
                if (isFinalGuess())
                {
                    return [true, true];
                }
                else
                {
                    ++guess_count;
                }
                field.text = "";
                guess_text_error = "";
                return [true, false];
            }
            else guess_text_error = qsTr("Wrong word, please check again");
        }
        return [false, false];
    }

    function getNumSuffix(num)
    {
        switch(num) {
          case 1: case 21:
            return num + qsTr("st");
          case 2: case 22:
            return num + qsTr("nd");
          case 3: case 23:
            return num + qsTr("rd");
          default:
            return num + qsTr("th");
        }
    }

    function isFinalGuess()
    {
        return guess_count === 3
    }

    function reset()
    {
        current_mnemonic = ""
        text_error = ""
        form_is_filled = false
        guess_text_error = ""
        guess_count = 1
    }

    function shuffle(array)
    {
        var currentIndex = array.length,
            randomIndex;

        // While there remain elements to shuffle...
        while (0 !== currentIndex)
        {

            // Pick a remaining element...
            randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex--;

            // And swap it with the current element.
            [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
        }

        return array;
    }

    function getRandomWords(num_words)
    {
        if (current_mnemonic) {

            // get word to confirm
            let list = current_mnemonic.split(" ");
            let keep = setRandomGuessWord(list);

            // remove confirm word from list
            list.splice(list.indexOf(keep), 1)

            // randomise and re-add confirm word
            let randomList = shuffle(list).slice(0, num_words - 1)
            randomList.push(keep)

            // return final word list (shuffled)
            return shuffle(randomList)
        }
    }

    function onClickedCreate(password, generated_seed, wallet_name)
    {
        if (API.app.wallet_mgr.create(password, generated_seed, wallet_name))
        {
            walletCreated(wallet_name);
            return true
        }
        else
        {
            text_error = qsTr("Failed to create a wallet")
            return false
        }
    }

    image_scale: 0.7

    content: Dex.Rectangle
    {
        color: Dex.CurrentTheme.floatingBackgroundColor
        width: column_layout.width + 50
        height: column_layout.height + 60
        radius: 18
        function reset()
        {
            new_user.reset()
            input_wallet_name.reset()
            _inputPassword.field.text = ""
            input_seed_word.field.text = ""
            input_generated_seed.text = ""
        }

        function completeForm()
        {

            if (!nextButton.enabled) return
            text_error = General.validateWallet(input_wallet_name.field.text)
            if (text_error !== "")
            {
                input_wallet_name.error = true
                return
            }

            currentStep++
            input_seed_word.field.text = ""
            guess_count = 1

            form_is_filled = true
        }

        function tryGuess()
        {
            // Open EULA if it's the final one
            let sub = submitGuess(input_seed_word.field)
            if (sub[0] == true && sub[1] == true)
            {
                currentStep++
            }
            else if (sub[0] == true && sub[1] == false)
            {
                input_seed_word.field.text = ""
            }
            else
            {
                input_seed_word.field.text = ""
                input_seed_word.error = true
            }
            mmo.model = getRandomWords(4)
        }

        ColumnLayout
        {
            id: column_layout
            spacing: Style.rowSpacing

            anchors.centerIn: parent

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 10
                SquareButton
                {
                    icon.source: Qaterial.Icons.chevronLeft
                    Layout.alignment: Qt.AlignVCenter
                    onClicked:
                    {
                        if (currentStep === 0)
                        {
                            reset()
                            backClicked();
                        }
                        else
                        {
                            if (currentStep == 2)
                            {
                                currentStep = 0
                                _inputPassword.field.text = ""
                                _inputPasswordConfirm.field.text = ""
                            }
                            else
                            {
                                input_seed_word.field.text = ""
                                currentStep--
                            }
                        }
                    }
                }

                Dex.Text
                {
                    font: DexTypo.head6
                    text_value: if (currentStep === 0)
                    {
                        qsTr("New Wallet")
                    }
                    else if (currentStep === 1)
                    {
                        qsTr("Confirm Seed")
                    }
                    else if (currentStep === 2)
                    {
                        qsTr("Choose Password")
                    }
                    Layout.alignment: Qt.AlignVCenter
                }

            }

            Item
            {
                Layout.fillWidth: true
            }

            ModalLoader
            {
                id: eula_modal
                sourceComponent: EulaModal
                {
                    onConfirm: () =>
                    {
                        if (onClickedCreate(_inputPassword.field.text,
                                input_generated_seed.text,
                                input_wallet_name.field.text)) reset()
                    }
                }
            }

            ColumnLayout
            {
                visible: currentStep === 0
                enabled: visible
                Layout.preferredWidth: 450
                spacing: Style.rowSpacing

                DexAppTextField
                {
                    id: input_wallet_name
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    opacity: enabled ? 1 : .5
                    background.radius: 25
                    field.onAccepted: completeForm()
                    field.font: DexTypo.body1
                    field.horizontalAlignment: Qt.AlignLeft
                    field.leftPadding: 75
                    field.placeholderText: "Wallet Name"
                    field.onTextChanged: text_error = General.validateWallet(input_wallet_name.field.text)
                    field.forceFocus: true

                    Dex.Rectangle
                    {
                        x: 5
                        height: 40
                        width: 60
                        radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Dex.CurrentTheme.inputLeftIconBackgroundColor

                        Qaterial.ColorIcon
                        {
                            anchors.centerIn: parent
                            iconSize: 19
                            source: Qaterial.Icons.wallet
                            color: Dex.CurrentTheme.inputLeftIconColor
                        }
                    }
                }

                DefaultRectangle
                {
                    Layout.topMargin: 10
                    Layout.bottomMargin: Layout.topMargin
                    Layout.fillWidth: true
                    color: Dex.CurrentTheme.warningColor
                    height: warning_texts.height + 20
                    radius: 20

                    Column
                    {
                        id: warning_texts

                        anchors.centerIn: parent
                        width: parent.width

                        spacing: 10

                        DefaultText
                        {
                            width: parent.width - 40
                            color: Style.colorWhite0
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            text_value: qsTr("Important: Back up your seed phrase before proceeding!")
                        }

                        DefaultText
                        {
                            width: parent.width - 40
                            color: Style.colorWhite0
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            text_value: qsTr("We recommend storing it offline.")
                            font.pixelSize: Style.textSizeSmall4
                        }
                    }
                }

                TextField
                {
                    id: input_generated_seed
                    visible: false
                    text: current_mnemonic
                }

                Column
                {
                    Layout.fillWidth: true
                    spacing: 5
                    RowLayout
                    {
                        width: parent.width
                        DefaultText
                        {
                            text: qsTr("Generated Seed")
                            font: DexTypo.body1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Qaterial.RawMaterialButton
                        {
                            implicitWidth: 45
                            backgroundColor: "transparent"
                            icon.source: Qaterial.Icons.contentCopy
                            icon.color: Dex.CurrentTheme.foregroundColor
                            Layout.alignment: Qt.AlignVCenter

                            DefaultMouseArea
                            {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
                                    API.qt_utilities.copy_text_to_clipboard(input_generated_seed.text)
                                    app.notifyCopy(qsTr("Seed phrase"), qsTr("copied to clipboard"))
                                }
                            }
                        }
                    }
                    Item
                    {
                        width: parent.width
                        height: _insideFlow.height
                        Grid
                        {
                            id: _insideFlow
                            width: parent.width
                            spacing: 10
                            Repeater
                            {
                                model: current_mnemonic.split(" ")
                                delegate: DexAppButton
                                {
                                    width: (_insideFlow.width - 30) / 4
                                    height: _insideLabel.implicitHeight + 10
                                    radius: 10
                                    opacity: .8
                                    color: Dex.CurrentTheme.backgroundColor
                                    DefaultText
                                    {
                                        id: _insideLabel
                                        text: (index + 1) + ". " + modelData
                                        font: DexTypo.body2
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }
                    }
                }

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                }

                RowLayout
                {
                    Layout.preferredWidth: 400
                    spacing: Style.buttonSpacing

                    DefaultText
                    {
                        text_value: text_error
                        color: Dex.CurrentTheme.warningColor
                        visible: text !== ''
                    }

                    Item
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                    }

                    DexGradientAppButton
                    {
                        id: nextButton
                        text: qsTr("Next")
                        radius: 20
                        leftPadding: 5
                        rightPadding: 5
                        padding: 16
                        enabled: input_wallet_name.field.text !== "" && text_error == ""
                        opacity: enabled ? 1 : .7
                        Layout.preferredHeight: 45
                        iconSourceRight: Qaterial.Icons.arrowRight

                        onClicked:
                        {
                            text_error = General.validateWallet(input_wallet_name.field.text)
                            if (text_error !== "")
                            {
                                input_wallet_name.error = true
                                return
                            }

                            currentStep++
                            input_seed_word.field.text = ""
                            guess_text_error = ""
                            guess_count = 1
                            mmo.model = getRandomWords(4)
                        }
                    }
                }
            }

            // Second page, write the seed word
            ColumnLayout
            {
                visible: currentStep === 1
                enabled: visible

                DefaultRectangle
                {
                    Layout.topMargin: 10
                    Layout.bottomMargin: Layout.topMargin
                    Layout.fillWidth: true
                    height: 140
                    radius: 20

                    Column
                    {
                        id: warning_texts_2

                        anchors.centerIn: parent
                        width: parent.width

                        spacing: 5

                        DefaultText
                        {
                            width: parent.width - 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            font
                            {
                                bold: true
                            }
                            text_value: qsTr("Let's double check your seed phrase")
                        }

                        DefaultText
                        {
                            width: parent.width - 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            text_value: qsTr("Your seed phrase is important - that's why we like to make sure it's correct. We'll ask you three different questions about your seed phrase to make sure you'll be able to easily restore your wallet whenever you want.")
                            font.pixelSize: Style.textSizeSmall4
                            color: Dex.CurrentTheme.foregroundColor
                        }
                    }
                }

                Column
                {
                    Layout.fillWidth: true
                    spacing: 5
                    Item
                    {
                        width: parent.width - 10
                        height: _insideFlow2.height
                        Grid
                        {
                            id: _insideFlow2
                            width: parent.width
                            spacing: 10
                            horizontalItemAlignment: Grid.AlignHCenter
                            Repeater
                            {
                                id: mmo
                                model: ""

                                delegate: DexAppButton
                                {
                                    width: (_insideFlow2.width - 30) / 4
                                    text: modelData ?? ""
                                    radius: 20
                                    btnEnabledColor: Dex.CurrentTheme.buttonColorEnabled
                                    btnHoveredColor: Dex.CurrentTheme.accentColor
                                    font: DexTypo.body2

                                    onClicked:
                                    {
                                        input_seed_word.field.text = modelData
                                        tryGuess()
                                    }
                                }
                            }
                        }
                    }
                }

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                }

                DexAppTextField
                {
                    id: input_seed_word
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    opacity: enabled ? 1 : .5
                    background.radius: 25
                    field.font: DexTypo.body2
                    field.horizontalAlignment: Qt.AlignLeft
                    field.leftPadding: 75
                    field.placeholderText: qsTr("Enter the ") + " %1 ".arg(getNumSuffix(current_word_idx + 1)) + qsTr("word")
                    field.validator: RegExpValidator
                    {
                        regExp: /[a-z]+/
                    }
                    field.onAccepted: tryGuess()

                    DefaultRectangle
                    {
                        x: 5
                        height: 40
                        width: 50
                        radius: 20
                        color: Dex.CurrentTheme.inputLeftIconBackgroundColor
                        anchors.verticalCenter: parent.verticalCenter

                        DefaultText
                        {
                            anchors.centerIn: parent
                            font: DexTypo.body1
                            text: current_word_idx + 1
                        }

                    }
                }

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                }

                RowLayout
                {
                    Layout.preferredWidth: 400
                    spacing: Style.buttonSpacing

                    Item
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                    }

                    DexGradientAppButton
                    {
                        id: checkForNext
                        text: qsTr("Check")
                        radius: 20
                        leftPadding: 5
                        rightPadding: 5
                        padding: 16
                        opacity: enabled ? 1 : .7
                        Layout.preferredHeight: 45
                        iconSourceRight: Qaterial.Icons.check
                        enabled: validGuessField(input_seed_word.field)
                        onClicked: tryGuess()
                    }
                }

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    DefaultText
                    {
                        text_value: guess_text_error
                        color: Dex.CurrentTheme.warningColor
                        visible: input_seed_word.error
                        DexVisibleBehavior on visible
                        {}
                    }
                }
            }

            ColumnLayout
            {
                visible: currentStep === 2
                enabled: visible

                Layout.preferredWidth: 450
                spacing: Style.rowSpacing

                DexAppPasswordField
                {
                    id: _inputPassword
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    field.placeholderText: qsTr("Enter password")
                    field.onAccepted: _keyChecker.isValid() ? eula_modal.open() : undefined
                }

                DexKeyChecker
                {
                    id: _keyChecker
                    field: _inputPassword.field
                    double_validation: true
                    Layout.leftMargin: 20
                    match_password: _inputPasswordConfirm.field.text
                }

                DexAppPasswordField
                {
                    id: _inputPasswordConfirm
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    field.placeholderText: qsTr("Enter the same password to confirm")
                    field.onAccepted: _keyChecker.isValid() ? eula_modal.open() : undefined
                }

                Item
                {
                    Layout.fillWidth: true
                }

                RowLayout
                {
                    Layout.preferredWidth: 400

                    Item
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                    }



                    DexGradientAppButton
                    {
                        id: finalRegisterButton
                        text: qsTr("Continue")
                        radius: 20
                        leftPadding: 5
                        rightPadding: 5
                        padding: 16
                        opacity: enabled ? 1 : .7
                        Layout.preferredHeight: 45
                        iconSourceRight: Qaterial.Icons.arrowRight
                        enabled: _keyChecker.isValid()
                        onClicked: eula_modal.open()
                    }
                }

                DefaultText
                {
                    text_value: text_error
                    color: Dex.CurrentTheme.warningColor
                    visible: text !== ''
                }
            }
        }
    }

    Component.onCompleted: onOpened()
}
