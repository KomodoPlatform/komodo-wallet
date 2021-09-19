// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0


// Project Imports
import "../Components"
import "../Constants"
import App 1.0

Item {
    id: root
    function disconnect() {
        API.app.disconnect()
        onDisconnect()
    }

    readonly property string mm2_version: API.app.settings_pg.get_mm2_version()
    property var recommended_fiats: API.app.settings_pg.get_recommended_fiats()
    property var fiats: API.app.settings_pg.get_available_fiats()



    InnerBackground {
        id: layout_background
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter

        width: 650
        height: 750

        content: ColumnLayout {
            width: layout_background.width
            height: layout_background.height

            ComboBoxWithTitle {
                id: combo_fiat
                title: qsTr("Fiat")
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: Layout.leftMargin

                model: fiats

                property bool initialized: false
                onCurrentIndexChanged: {
                    if(initialized) {
                        const new_fiat = fiats[currentIndex]
                        API.app.settings_pg.current_fiat = new_fiat
                        API.app.settings_pg.current_currency = new_fiat
                    }
                }
                Component.onCompleted: {
                    currentIndex = model.indexOf(API.app.settings_pg.current_fiat)
                    initialized = true
                }

                RowLayout {
                    Layout.topMargin: 5
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    Layout.rightMargin: Layout.leftMargin

                    DefaultText {
                        text: qsTr("Recommended: ")
                        font.pixelSize: Style.textSizeSmall4
                    }

                    Grid {
                        Layout.leftMargin: 30
                        Layout.alignment: Qt.AlignVCenter

                        clip: true

                        columns: 6
                        spacing: 25

                        layoutDirection: Qt.LeftToRight

                        Repeater {
                            model: recommended_fiats

                            delegate: DefaultText {
                                text: modelData
                                color: fiats_mouse_area.containsMouse ? Style.colorText : Style.colorText2

                                DefaultMouseArea {
                                    id: fiats_mouse_area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        API.app.settings_pg.current_fiat = modelData
                                        API.app.settings_pg.current_currency = modelData
                                        combo_fiat.currentIndex = combo_fiat.model.indexOf(API.app.settings_pg.current_fiat)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            HorizontalLine {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                Layout.topMargin: 10
            }

            Languages {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
            }

            HorizontalLine {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                Layout.topMargin: 10
            }

            DefaultSwitch {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("Enable Desktop Notifications")
                Component.onCompleted: checked = API.app.settings_pg.notification_enabled
                onCheckedChanged: API.app.settings_pg.notification_enabled = checked
            }
            DefaultSwitch {
                property bool firstTime: true
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                checked: parseInt(atomic_settings2.value("FontMode")) === 1
                text: qsTr("Use QtTextRendering Or NativeTextRendering")
                onCheckedChanged: {
                    if(checked){
                        atomic_settings2.setValue("FontMode", 1)
                    }else {
                        atomic_settings2.setValue("FontMode", 0)
                    }
                    if(firstTime) {
                        firstTime = false
                    }else {
                        restart_modal.open()
                    }

                }
            }

            DefaultButton {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("Open Logs Folder")
                onClicked: openLogsFolder()
            }

            DefaultButton {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("View seed and private keys")
                onClicked: view_seed_modal.open()
            }



            HorizontalLine {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
            }

            DefaultButton {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("Disclaimer and ToS")
                onClicked: eula_modal.open()
            }

            ModalLoader {
                id: eula_modal
                sourceComponent: EulaModal {
                    close_only: true
                }
            }

            HorizontalLine {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
            }

            DefaultButton {
                visible: !API.app.is_pin_cfg_enabled()
                text: qsTr("Setup Camouflage Password")
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                onClicked: camouflage_password_modal.open()
            }

            ModalLoader {
                id: camouflage_password_modal
                sourceComponent: CamouflagePasswordModal {}
            }

            DangerButton {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("Reset wallet configuration")
                onClicked: {
                    restart_modal.open()
                    restart_modal.item.onTimerEnded = () => { API.app.settings_pg.reset_coin_cfg() }
                }
            }

            DangerButton {
                text: qsTr("Delete Wallet")
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                onClicked: delete_wallet_modal.open()
            }

            ModalLoader {
                id: delete_wallet_modal
                sourceComponent: DeleteWalletModal {}
            }

            DefaultButton {
                Layout.fillWidth: true
                Layout.leftMargin: combo_fiat.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
                text: qsTr("Log out")
                onClicked: disconnect()
            }
        }
    }

    DefaultText {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.rightMargin: anchors.bottomMargin
        text_value: qsTr("mm2 version") + ":  " + mm2_version
        font.pixelSize: Style.textSizeSmall
    }
}
