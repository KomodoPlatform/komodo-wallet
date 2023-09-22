import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.15
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import ModelHelper 0.1

import Qaterial 1.0 as Qaterial

import App 1.0
import "Components"
import Dex.Themes 1.0 as Dex

DexWindow
{
    id: window

    property int  previousX: 0
    property int  previousY: 0
    property int  real_visibility
    property bool isOsx: Qt.platform.os == "osx"
    property bool logged: false
    property var  orders: API.app.orders_mdl.orders_proxy_mdl.ModelHelper

    title: API.app_name
    visible: true

    minimumWidth: General.minimumWidth
    minimumHeight: General.minimumHeight

    background: DefaultRectangle
    {
        anchors.fill: parent
    }

    Universal.background: Dex.CurrentTheme.backgroundColor
    Universal.foreground: Dex.CurrentTheme.foregroundColor

    onVisibilityChanged:
    {
        // 3 is minimized, ignore that
        if (visibility !== 3)
            real_visibility = visibility

        API.app.change_state(visibility)
    }

    DexWindowControl
    {
        visible: !isOsx
    }

    DexRectangle
    {
        radius: 0
        width: parent.width
        height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        color: Dex.CurrentTheme.backgroundColorDeep
        visible: isOsx
    }

    DexPopup
    {
        id: userMenu

        spacing: 8
        padding: 2
        backgroundColor: Dex.CurrentTheme.backgroundColor

        contentItem: Item
        {
            implicitWidth: 130
            implicitHeight: 30
            Rectangle
            {
                width: parent.width - 10
                height: parent.height - 5
                anchors.centerIn: parent
                radius: 18
                color: logout_area.containsMouse ? Dex.CurrentTheme.buttonColorHovered : Dex.CurrentTheme.backgroundColor
                Row
                {
                    anchors.centerIn: parent
                    spacing: 5

                    Qaterial.Icon
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Qaterial.Icons.logout
                        color: Dex.CurrentTheme.foregroundColor
                        size: 11
                    }

                    DexLabel
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Dex.CurrentTheme.foregroundColor
                        text: qsTr('Logout')
                    }
                }

                DexMouseArea
                {
                    id: logout_area
                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked:
                    {
                        if (orders.count != 0) app.logout_confirm_modal.open()
                        else app.return_to_login()
                    }
                }
            }
        }
    }

    DexMacControl
    {
        visible: isOsx
    }

    Row
    {
        height: 30
        leftPadding: 8
        anchors.right: isOsx ? parent.right : undefined
        anchors.rightMargin: isOsx ? 8 : 0
        layoutDirection: isOsx ? Qt.RightToLeft : Qt.LeftToRight
        spacing: 5

        DefaultImage
        {
            source: "qrc:/assets/images/dex-tray-icon.png"
            width: 15
            height: 15
            smooth: true
            antialiasing: true
            visible: !_label.visible
            anchors.verticalCenter: parent.verticalCenter
        }

        DexLabel
        {
            text: atomic_app_name
            font.family: 'Montserrat'
            font.weight: Font.Medium
            opacity: .5
            leftPadding: 5
            color: Dex.CurrentTheme.foregroundColor
            visible: !_label.visible
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    Item
    {
        width: _row.width
        height: 30
        clip: true
        Behavior on x
        {
            NumberAnimation
            {
                duration: 200
            }
        }
        anchors.right: parent.right
        anchors.rightMargin: isOsx ? 10 : 120

        Row
        {
            id: _row
            anchors.verticalCenter: parent.verticalCenter
            layoutDirection: Qt.RightToLeft
            spacing: 6

            Item
            {
                width: 15
                height: 1
            }

            // User / logout
            Rectangle
            {
                width: __row.width + 10
                height: __row.height + 5
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: _area.containsMouse ? Dex.CurrentTheme.floatingBackgroundColor : "transparent"

                Row
                {
                    id: __row
                    anchors.centerIn: parent
                    layoutDirection: isOsx ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: 6

                    Qaterial.ColorIcon
                    {
                        source: Qaterial.Icons.menuDown
                        iconSize: 14
                        visible: _label.visible
                        color: Dex.CurrentTheme.foregroundColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DefaultText
                    {
                        id: _label
                        text: API.app.wallet_mgr.wallet_default_name ?? ""
                        font.family: 'Montserrat'
                        font.weight: Font.Medium
                        visible: window.logged
                        color: Dex.CurrentTheme.foregroundColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Qaterial.ColorIcon
                    {
                        source: Qaterial.Icons.account
                        iconSize: 18
                        visible: _label.visible
                        color: _area.containsMouse ? Dex.CurrentTheme.gradientButtonPressedStartColor : Dex.CurrentTheme.foregroundColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DexMouseArea
                {
                    id: _area
                    anchors.fill: parent
                    onClicked:
                    {
                        if (userMenu.visible)
                        {
                            userMenu.close()
                        }
                        else
                        {
                            userMenu.openAt(mapToItem(Overlay.overlay, width / 2, height), Item.Top)
                        }
                    }
                }
            }

            Item
            {
                width: 10
                height: 1
            }

            // Wallet Balance
            Row
            {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                DexLabel
                {
                    leftPadding: 2
                    text: qsTr("Balance")
                    font.family: 'Montserrat'
                    font.weight: Font.Medium
                    visible: _label.visible
                    anchors.verticalCenter: parent.verticalCenter
                }

                DexLabel
                {
                    text_value: General.formatFiat("", API.app.portfolio_pg.balance_fiat_all, API.app.settings_pg.current_currency)
                    font.family: 'lato'
                    font.weight: Font.Bold
                    visible: _label.visible
                    privacy: true
                    anchors.verticalCenter: parent.verticalCenter
                    DexMouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            const current_fiat = API.app.settings_pg.current_currency
                            const available_fiats = API.app.settings_pg.get_available_currencies()
                            const current_index = available_fiats.indexOf(
                                current_fiat)
                            const next_index = (current_index + 1) %
                                available_fiats.length
                            const next_fiat = available_fiats[next_index]
                            API.app.settings_pg.current_currency = next_fiat
                        }
                    }
                }
            }

            Item
            {
                width: 15
                height: 1
            }

            // Notifications
            DexIconButton
            {
                color: containsMouse ? Dex.CurrentTheme.gradientButtonPressedStartColor : Dex.CurrentTheme.foregroundColor
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 24
                icon: Qaterial.Icons.bellOutline
                visible: _label.visible
                active: app.notification_modal.opened
                AnimatedRectangle
                {
                    anchors.rightMargin: -3
                    anchors.right: parent.right
                    y: 8
                    width: 13
                    height: width
                    color: Dex.CurrentTheme.gradientButtonPressedStartColor
                    opacity: 0.8
                    radius: width / 2
                    visible: app.notifications_list !== undefined ? app.notifications_list.length > 0 : false
                    z: 1
                }
                onClicked:
                {
                    if (app.notification_modal.visible)
                        app.notification_modal.close()
                    else
                        app.notification_modal.openAt(mapToItem(Overlay.overlay, -90, 18), Item.Top)
                }
            }

            Item
            {
                width: 15
                height: 1
            }

            Settings
            {
                id: atomic_settings0
                fileName: atomic_cfg_file
            }

            // Theme toggle
            DexIconButton
            {
                id: themeSwitchBut
                visible: _label.visible && Dex.CurrentTheme.hasDarkAndLightMode() && Dex.CurrentTheme.getColorMode() !== Dex.CurrentTheme.ColorMode.None
                active: app.notification_modal.opened
                rotation: -45
                anchors.verticalCenter: parent.verticalCenter
                color: containsMouse ? Dex.CurrentTheme.gradientButtonPressedStartColor : Dex.CurrentTheme.foregroundColor
                iconSize: 24
                icon:
                {
                    if (Dex.CurrentTheme.getColorMode() !== Dex.CurrentTheme.ColorMode.None)
                    {
                        if (Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Light)
                            return Qaterial.Icons.moonWaningCrescent;
                        else if (Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Dark)
                            return Qaterial.Icons.whiteBalanceSunny;
                    }
                    return Qaterial.Icons.moonWaningCrescent;
                }

                onClicked: {
                    let new_theme = Dex.CurrentTheme.switchColorMode()
                    atomic_settings0.setValue("CurrentTheme", new_theme);
                    atomic_settings0.sync();
                }
            }
        }
    }

    App
    {
        id: app
        color: Dex.CurrentTheme.backgroundColor
        anchors.fill: parent
        anchors.topMargin: 30
    }
}
