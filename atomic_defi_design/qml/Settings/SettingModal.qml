//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0
import QtQml 2.12
import QtQuick.Window 2.12
import QtQuick.Controls.Universal 2.12

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

//! Project Imports
import "../Components"
import "../Constants" as Constants
import App 1.0


Qaterial.Dialog
{
    property alias selectedMenuIndex: menu_list.currentIndex

    function disconnect() {
        let dialog = app.showText({
            "title": qsTr("Confirm Logout"),
            text: qsTr("Are you sure you want to log out?") ,
            standardButtons: Dialog.Yes | Dialog.Cancel,
            warning: true,
            width: 300,
            iconSource: Qaterial.Icons.logout,
            iconColor: DexTheme.accentColor,
            yesButtonText: qsTr("Yes"),
            cancelButtonText: qsTr("Cancel"),
            onAccepted: function(text) {
                app.notifications_list = []
                app.currentWalletName = ""
                API.app.disconnect()
                onDisconnect()
                dialog.close()
                dialog.destroy()
            }
        })
        
    }

    readonly property string mm2_version: API.app.settings_pg.get_mm2_version()
    property var recommended_fiats: API.app.settings_pg.get_recommended_fiats()
    property var fiats: API.app.settings_pg.get_available_fiats()
    property var enableable_coins_count: enableable_coins_count_combo_box.currentValue


    id: setting_modal
    width: 950
    height: 650
    anchors.centerIn: parent
    dim: true
    modal: true
    title: "Settings"
    header: Item{}
    Overlay.modal: Item {
        Rectangle {
            anchors.fill: parent
            color: 'black'
            opacity: .7
        }
    }
    background: DexRectangle {
        color: DexTheme.backgroundColor
        border.width: 0
        radius: 16
    }
    padding: 20
    topPadding: 30
    bottomPadding: 30
    Item {
        width: parent.width
        height: 60
        DexIconButton {
            anchors.right: parent.right
            anchors.rightMargin: 30
            iconSize: 30
            icon: Qaterial.Icons.close
            anchors.verticalCenter: parent.verticalCenter
            onClicked: setting_modal.close()
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 60
            DexLabel {
                id: settingLabel
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Settings")
                font: Qt.font({
                    pixelSize: 20 ,
                    letterSpacing: 0.15,
                    family: DexTypo.fontFamily,
                    weight: Font.Normal
                })
            }
        }

        Qaterial.DebugRectangle {
            anchors.fill: parent
            visible: false
        }
    }
    Item {
        width: parent.width
        height: parent.height-110
        y:60
        RowLayout {
            anchors.fill: parent
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 280
                ListView {
                    id: menu_list
                    height: parent.height
                    width: 200
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 10
                    spacing: 5
                    currentIndex: 0
                    model: [qsTr("General"),qsTr("Language"),qsTr("User Interface"),qsTr("Security"),qsTr("About & Version")]
                    delegate: DexRectangle {
                        width: parent.width
                        height: 60
                        radius: 22
                        border.width: 0
                        gradient: Gradient {
                            orientation: Qt.Horizontal
                            GradientStop {
                                position: 0.0
                                color: delegateMouseArea.containsMouse ? DexTheme.buttonColorEnabled : menu_list.currentIndex === index ? DexTheme.buttonColorHovered : 'transparent'
                            }
                            GradientStop {
                                position: 1
                                color: 'transparent'
                            }
                        }

                        DexLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            width: parent.width
                            leftPadding: 20
                            font: Qt.font({
                                pixelSize: 17 ,
                                letterSpacing: 0.15,
                                family: DexTypo.fontFamily,
                                weight: Font.Normal
                            })
                        }

                        DexMouseArea {
                            id: delegateMouseArea
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: menu_list.currentIndex = index
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: DexTheme.foregroundColor
                opacity: .10
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                StackLayout {
                    anchors.fill: parent
                    currentIndex: menu_list.currentIndex
                    Item {
                        anchors.margins: 10
                        Column {
                            anchors.fill: parent
                            topPadding: 10
                            spacing: 15
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 30
                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    font: DexTypo.subtitle1
                                    text: qsTr("Enable Desktop Notifications")
                                }
                                DefaultSwitch {
                                    Layout.alignment: Qt.AlignVCenter
                                    Component.onCompleted: checked = API.app.settings_pg.notification_enabled
                                    onCheckedChanged: API.app.settings_pg.notification_enabled = checked
                                }
                            }
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 50
                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    font: DexTypo.subtitle1
                                    text: qsTr("Maximum number of enabled coins")
                                }
                                DexComboBox {
                                    id: enableable_coins_count_combo_box
                                    Layout.preferredWidth: 100
                                    radius: 20
                                    model: [10, 20, 50, 75, 100, 150, 200]
                                    currentIndex: model.indexOf(parseInt(atomic_settings2.value("MaximumNbCoinsEnabled")))
                                    onCurrentIndexChanged: atomic_settings2.setValue("MaximumNbCoinsEnabled", model[currentIndex])
                                }
                            }

                            SettingsButton {
                                noBackground: true
                                width: parent.width-30
                                height: 50
                                title: qsTr("Logs")
                                buttonText: qsTr("Open Folder")
                                onClicked: openLogsFolder()
                            }

                            SettingsButton {
                                width: parent.width-30
                                height: 50
                                title: qsTr("Reset wallet configuration")
                                buttonText: qsTr("Reset")
                                onClicked: {
                                    dialog = app.showText({
                                            title: qsTr("Reset wallet configuration"),
                                            text: qsTr("This will restart your wallet with default settings"),
                                            standardButtons: Dialog.Yes | Dialog.Cancel,
                                            yesButtonText: qsTr("Confirm"),
                                            cancelButtonText: qsTr("Cancel"),
                                            onAccepted: function() {
                                                restart_modal.open()
                                                restart_modal.item.onTimerEnded = () => { API.app.settings_pg.reset_coin_cfg() }
                                            }
                                        })
                                    dialog.close()
                                }
                            }
                        }
                    }
                    Item {
                        Column {
                            anchors.fill: parent
                            topPadding: 10
                            spacing: 15
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 30
                                spacing: 10
                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    font: DexTypo.subtitle1
                                    text: qsTr("Language") + ":"
                                }
                                Languages {
                                    Layout.alignment: Qt.AlignVCenter
                                }

                            }
                            Combo_fiat {
                                id: combo_fiat
                            }
                        }
                    }


                    Item {
                        Column {
                            anchors.fill: parent
                            topPadding: 10
                            spacing: 15
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 30
                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    font: DexTypo.subtitle1
                                    text: qsTr("Current Font")
                                }
                            }
                            DexComboBox {
                                id: dexFont
                                editable: true
                                width: parent.width - 200
                                model: ["Ubuntu", "Montserrat", "Roboto"]
                                Component.onCompleted: {
                                    let current = DexTypo.fontFamily
                                    currentIndex = dexFont.model.indexOf(current)
                                }
                            }
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 30
                                visible: false

                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    font: DexTypo.subtitle1
                                    text: qsTr("Theme")
                                }
                            }
                            DexComboBox {
                                id: dexTheme
                                visible: false
                                width: parent.width - 200
                                displayText: currentText.replace(".json","")
                                model: API.qt_utilities.get_themes_list()
                                Component.onCompleted: {
                                    let current = atomic_settings2.value("CurrentTheme")
                                    currentIndex = model.indexOf(current)
                                }
                            }

                            SettingsButton {
                                width: parent.width-30
                                height: 50
                                buttonText: qsTr("Apply Changes")
                                onClicked: {
                                    atomic_settings2.setValue("CurrentTheme", dexTheme.currentText)
                                    atomic_settings2.sync()
                                    theme_manager.apply(dexTheme.currentText.replace(".json",""))
                                    DexTypo.fontFamily = dexFont.currentText
                                    
                                }
                            }
                        }
                    }
                    Item {
                        Column {
                            anchors.fill: parent
                            topPadding: 10
                            spacing: 15

                            ModalLoader {
                                id: view_seed_modal
                                sourceComponent: RecoverSeedModal {}
                            }

                            ModalLoader {
                                id: eula_modal
                                sourceComponent: EulaModal {
                                    close_only: true
                                }
                            }

                            ModalLoader {
                                id: camouflage_password_modal
                                sourceComponent: CamouflagePasswordModal {}
                            }

                            // Enabled 2FA option. (Disabled on Linux since the feature is not available on this platform yet)
                            RowLayout {
                                enabled: Qt.platform.os !== "linux" // Disable for Linux.
                                visible: enabled
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 60
                                DexLabel {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    font: DexTypo.subtitle1
                                    text: qsTr("Ask system's password before sending coins ? (2FA)")
                                }
                                DexSwitch {
                                    checked: parseInt(atomic_settings2.value("2FA")) === 1
                                    onCheckedChanged: {
                                        if (checked)
                                            atomic_settings2.setValue("2FA", 1)
                                        else
                                            atomic_settings2.setValue("2FA", 0)
                                        atomic_settings2.sync()
                                    }
                                }
                            }

                            SettingsButton {
                                width: parent.width-30
                                height: 50
                                title: qsTr("View seed and private keys")
                                buttonText: qsTr("Show")
                                onClicked: view_seed_modal.open()
                            }

                            SettingsButton {
                                width: parent.width-30
                                height: 50
                                title: qsTr("Setup Camouflage Password")
                                buttonText: qsTr("Open")
                                onClicked: camouflage_password_modal.open()
                            }

                        }
                    }

                    Item {
                        Column {
                            anchors.fill: parent
                            topPadding: 10
                            spacing: 15
                            ModalLoader {
                                id: delete_wallet_modal
                                sourceComponent: DeleteWalletModal {}
                            }

                            SettingsButton {
                                width: parent.width-30
                                height: 50
                                title: qsTr("Disclaimer and ToS")
                                buttonText: qsTr("Show")
                                onClicked: eula_modal.open()
                            }

                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 60
                                DexLabel
                                {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: qsTr("Application version")
                                }
                                DexCopyableLabel
                                {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: API.app.settings_pg.get_version()
                                    onCopyNotificationTitle: qsTr("DEX Version")
                                    onCopyNotificationMsg: qsTr("DEX Version copied to clipboard.")
                                }
                            }
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 60
                                DexLabel {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: qsTr("MM2 version")
                                }
                                DexCopyableLabel
                                {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: API.app.settings_pg.get_mm2_version()
                                    onCopyNotificationTitle: qsTr("MM2 Version")
                                    onCopyNotificationMsg: qsTr("MM2 Version copied to clipboard.")
                                }
                            }
                            RowLayout {
                                width: parent.width-30
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 60
                                DexLabel
                                {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: qsTr("Qt version")
                                }
                                DexCopyableLabel
                                {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: qtversion
                                    onCopyNotificationTitle: qsTr("Qt Version")
                                    onCopyNotificationMsg: qsTr("Qt Version copied to clipboard.")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item {
        width: parent.width
        height: 50
        anchors.bottom: parent.bottom

        Row {
            spacing: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            DexAppButton {
                text: qsTr("Search Update")
                height: 48
                radius: 20
                leftPadding: 20
                rightPadding: 20
                font: Qt.font({
                    pixelSize: 19,
                    letterSpacing: 0.15,
                    family: DexTypo.fontFamily,
                    weight: Font.Normal
                })
                onClicked: new_update_modal.open()
            }
            
            DexAppButton {
                text: qsTr("Logout")
                color: containsMouse ? DexTheme.buttonColorHovered : 'transparent'
                height: 48
                radius: 20
                font: Qt.font({
                    pixelSize: 19 ,
                    letterSpacing: 0.15,
                    family: DexTypo.fontFamily,
                    weight: Font.Normal
                })
                iconSource: Qaterial.Icons.logout
                onClicked: {
                    disconnect()
                    setting_modal.close()
                }
            }
        }

    }
}
