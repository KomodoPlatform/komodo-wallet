import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"
import ".."

BasicModal {
    id: root

    width: 1100

    onOpened: reset()

    function reset() {

    }

    ModalContent {
        title: qsTr("Confirm Exchange Details")

        OrderContent {
            Layout.topMargin: 25
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: Layout.leftMargin
            height: 120
            Layout.alignment: Qt.AlignHCenter

            details: ({
                    base_coin: base_ticker,
                    rel_coin: rel_ticker,
                    base_amount: base_amount,
                    rel_amount: rel_amount,

                    order_id: '',
                    date: '',
                   })
            in_modal: true
        }

        PriceLine {
            Layout.alignment: Qt.AlignHCenter
        }

        HorizontalLine {
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            Layout.fillWidth: true
        }

        FloatingBackground {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10

            color: Style.colorTheme5

            width: warning_texts.width + 20
            height: warning_texts.height + 20

            ColumnLayout {
                id: warning_texts
                anchors.centerIn: parent

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("This swap request can not be undone and is a final event!")
                }

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter

                    text_value: qsTr("This transaction can take up to 60 mins - DO NOT close this application!")
                    font.pixelSize: Style.textSizeSmall4
                }
            }
        }

        HorizontalLine {
            Layout.bottomMargin: 10
            Layout.fillWidth: true
        }

        ColumnLayout {
            id: config_section

            readonly property var default_config: API.app.trading_pg.get_raw_mm2_coin_cfg(rel_ticker)

            readonly property bool is_dpow_configurable: config_section.default_config.requires_notarization || false
            Layout.bottomMargin: 10
            Layout.alignment: Qt.AlignHCenter

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: !enable_custom_config.checked

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter
                    text_value: qsTr("Security configuration")
                    font.weight: Font.Medium
                }

                DefaultText {
                    Layout.alignment: Qt.AlignHCenter
                    text_value: "✅ " + (config_section.is_dpow_configurable ? qsTr("dPoW protected") :
                                qsTr("%1 confirmations for incoming %2 transactions").arg(config_section.default_config.required_confirmations || 1).arg(rel_ticker))
                }

                DefaultText {
                    visible: config_section.is_dpow_configurable
                    Layout.alignment: Qt.AlignHCenter
                    text_value: General.cex_icon + ' <a href="https://komodoplatform.com/security-delayed-proof-of-work-dpow/">' + qsTr('Read more about dPoW') + '</a>'
                    font.pixelSize: Style.textSizeSmall2
                }
            }

            // Enable custom config
            DefaultCheckBox {
                Layout.alignment: Qt.AlignHCenter
                id: enable_custom_config

                text: qsTr("Use custom protection settings for incoming %1 transactions", "TICKER").arg(rel_ticker)
            }

            // Configuration settings
            ColumnLayout {
                id: custom_config
                visible: enable_custom_config.checked

                Layout.alignment: Qt.AlignHCenter

                // dPoW configuration switch
                DefaultSwitch {
                    id: enable_dpow_confs
                    Layout.alignment: Qt.AlignHCenter

                    visible: config_section.is_dpow_configurable
                    checked: true
                    text: qsTr("Enable Komodo dPoW security")
                }

                DefaultText {
                    visible: enable_dpow_confs.visible && enable_dpow_confs.enabled
                    Layout.alignment: Qt.AlignHCenter
                    text_value: General.cex_icon + ' <a href="https://komodoplatform.com/security-delayed-proof-of-work-dpow/">' + qsTr('Read more about dPoW') + '</a>'
                    font.pixelSize: Style.textSizeSmall2
                }

                // Normal configuration settings
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !config_section.is_dpow_configurable || !enable_dpow_confs.checked
                    enabled: !config_section.is_dpow_configurable || !enable_dpow_confs.checked

                    HorizontalLine {
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                        Layout.fillWidth: true
                    }

                    DefaultText {
                        Layout.alignment: Qt.AlignHCenter
                        text_value: qsTr("Required Confirmations") + ": " + required_confirmation_count.value
                        color: parent.enabled ? Style.colorText : Style.colorTextDisabled
                    }

                    DefaultSlider {
                        id: required_confirmation_count
                        readonly property int default_confirmation_count: 3
                        Layout.alignment: Qt.AlignHCenter
                        stepSize: 1
                        from: 1
                        to: 5
                        live: true
                        snapMode: Slider.SnapAlways
                        value: default_confirmation_count
                    }
                }
            }

            FloatingBackground {
                visible: enable_custom_config.visible && enable_custom_config.enabled && enable_custom_config.checked &&
                          (config_section.is_dpow_configurable && !enable_dpow_confs.checked)
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10

                color: Style.colorRed3

                width: dpow_off_warning.width + 20
                height: dpow_off_warning.height + 20

                ColumnLayout {
                    id: dpow_off_warning
                    anchors.centerIn: parent

                    DefaultText {
                        Layout.alignment: Qt.AlignHCenter

                        text_value: Style.warningCharacter + " " + qsTr("Warning, this atomic swap is not dPoW protected!")
                    }
                }
            }
            DefaultBusyIndicator {
                visible: buy_sell_rpc_busy
                Layout.alignment: Qt.AlignCenter
            }
        }

        // Buttons
        footer: [
            DefaultButton {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                onClicked: root.close()
            },

            PrimaryButton {
                text: qsTr("Confirm")
                Layout.fillWidth: true
                enabled: !buy_sell_rpc_busy
                onClicked: {
                    trade({
                            enable_custom_config: enable_custom_config.checked,
                            is_dpow_configurable: config_section.is_dpow_configurable,
                            enable_dpow_confs: enable_dpow_confs.checked,
                            required_confirmation_count: required_confirmation_count.value,
                          }, config_section.default_config)
                }
            }
        ]
    }
}
