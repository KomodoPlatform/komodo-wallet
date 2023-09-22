import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.0
import Qaterial 1.0 as Qaterial
import ModelHelper 0.1

import Dex.Themes 1.0 as Dex

import "../Constants"
import App 1.0
import "../Components"
import "../Screens"

DexPopup
{
    id: root

    width: 406
    height: 526
    backgroundColor: Dex.CurrentTheme.floatingBackgroundColor

    property var orders: API.app.orders_mdl.orders_proxy_mdl.ModelHelper

    // Notification types.
    readonly property string updateSwapStatusNotification: "onUpdateSwapStatus"
    readonly property string balanceUpdateStatusNotification: "onBalanceUpdateStatus"
    readonly property string enablingZCoinStatusNotification: "onEnablingZCoinStatus"
    readonly property string enablingCoinFailedStatusNotification: "onEnablingCoinFailedStatus"
    readonly property string disablingCoinFailedStatus: "onDisablingCoinFailedStatus"
    readonly property string endpointNonReacheableStatus: "onEndpointNonReacheableStatus"

    readonly property string check_internet_connection_text: qsTr("Please check your internet connection (e.g. VPN service or firewall might block it).")

    function reset(close_after_reset = false)
    {
        notifications_list = []
        if (close_after_reset)
            root.close()
    }

    enum NotificationKind
    {
        Send,
        Receive,
        Others
    }

    function showApp()
    {
        switch (window.real_visibility)
        {
            case 4:
                window.showMaximized()
                break
            case 5:
                window.showFullScreen()
                break
            default:
                window.show()
                break
        }
        window.raise()
        window.requestActivate()
    }

    function performNotificationAction(notification)
    {
        root.close()

        switch (notification.click_action)
        {
            case "open_notifications":
                root.open()
                break
            case "open_wallet_page":
                API.app.wallet_pg.ticker = notification.params.ticker
                app.pageLoader.item.switchPage(Dashboard.PageType.Wallet)
                break
            case "open_swaps_page":
                app.pageLoader.item.switchPage(Dashboard.PageType.DEX)
                break
            case "open_log_modal":
                showError(getNotificationTitle(notification), notification.long_message)
                break
            default:
                console.warn("Unknown notification click action", notification.click_action)
                break
        }
    }

    function newNotification(event_name, params, id, human_date, click_action = "open_notifications", long_message = "")
    {
        let obj =
        {
            event_name,
            params,
            id,
            human_date,
            click_action,
            long_message,
        }
        {
            let notifTitle = getNotificationTitle(obj)
            if (notifTitle.indexOf("You received") !== -1)
            {
                obj.kind = NotificationsModal.NotificationKind.Receive
            }
            else if (notifTitle.indexOf("You sent") !== -1)
            {
                obj.kind = NotificationsModal.NotificationKind.Send
            }
            else
            {
                obj.kind = NotificationsModal.NotificationKind.Others
            }
        }

        // Update if it already exists
        let updated_existing_one = false
        for (let i = 0; i < notifications_list.length; ++i)
        {
            if (notifications_list[i].id === obj.id)
            {
                notifications_list[i] = General.clone(obj)
                updated_existing_one = true
                break
            }
        }

        // Add new line
        if (!updated_existing_one)
        {
            notifications_list = [obj].concat(notifications_list)
        }

        // Display OS notification
        if (API.app.settings_pg.notification_enabled)
            tray.showMessage(getNotificationTitle(obj), getNotificationMsg(obj))

        // Refresh the list if updated an existing one
        if (updated_existing_one)
            notifications_list = notifications_list
    }

    function getOrderStatusText(status, short_text = false)
    {
        switch (status)
        {
            case "matching":
                return short_text ? qsTr("Matching") : qsTr("Order Matching")
            case "matched":
                return short_text ? qsTr("Matched") : qsTr("Order Matched")
            case "ongoing":
                return short_text ? qsTr("Ongoing") : qsTr("Swap Ongoing")
            case "successful":
                return short_text ? qsTr("Successful") : qsTr("Swap Successful")
            case "refunding":
                return short_text ? qsTr("Refunding") : qsTr("Refunding")
            case "failed":
                return short_text ? qsTr("Failed") : qsTr("Swap Failed")
            default:
                return short_text ? qsTr("Unknown") : qsTr("Unknown State")
        }
    }

    function getNotificationTitle(notification)
    {
        switch (notification.event_name)
        {
        case updateSwapStatusNotification:
            return notification.params.base_coin + "/" + notification.params.rel_coin + " - " + qsTr("Swap status updated")
        case balanceUpdateStatusNotification:
            const change = General.formatFullCrypto("", notification.params.amount, notification.params.ticker, "", "", true)
            return notification.params.am_i_sender ? qsTr("You sent %1").arg(change) : qsTr("You received %1").arg(change)
        case enablingZCoinStatusNotification:
            return qsTr(" %1 Enable status", "TICKER").arg(notification.params.coin)
        case enablingCoinFailedStatusNotification:
            return qsTr("Failed to enable %1", "TICKER").arg(notification.params.coin)
        case disablingCoinFailedStatus:
            return qsTr("Failed to disable %1", "TICKER").arg(notification.params.coin)
        case endpointNonReacheableStatus:
            return qsTr("Endpoint not reachable")
        }
    }

    function getNotificationMsg(notification)
    {
        switch (notification.event_name)
        {
        case updateSwapStatusNotification:
            return getOrderStatusText(notification.params.old_swap_status) + " " + General.right_arrow_icon + " " + getOrderStatusText(notification.params.new_swap_status)
        case balanceUpdateStatusNotification:
            return qsTr("Your wallet balance changed")
        case enablingZCoinStatusNotification:
            return notification.params.msg
        case enablingCoinFailedStatusNotification:
            return check_internet_connection_text
        case disablingCoinFailedStatus:
            return ""
        case endpointNonReacheableStatus:
            return notification.params.base_uri
        }
    }

    function getNotificationIcon(notification)
    {
        switch (notification.kind)
        {
        case NotificationsModal.NotificationKind.Send:
            return Qaterial.Icons.arrowTopRight
        case NotificationsModal.NotificationKind.Receive:
            return Qaterial.Icons.arrowBottomRight
        case NotificationsModal.NotificationKind.Others:
            return Qaterial.Icons.messageOutline
        }
    }

    function onUpdateSwapStatus(old_swap_status, new_swap_status, swap_uuid, base_coin, rel_coin, human_date)
    {
        newNotification(
            updateSwapStatusNotification,
            {
                old_swap_status,
                new_swap_status,
                swap_uuid,
                base_coin,
                rel_coin,
                human_date
            },
            swap_uuid,
            human_date,
            "open_swaps_page")
    }

    function onBalanceUpdateStatus(am_i_sender, amount, ticker, human_date, timestamp)
    {
        if (amount != 0)
        {
            newNotification(
                balanceUpdateStatusNotification,
                {
                    am_i_sender,
                    amount,
                    ticker,
                    human_date,
                    timestamp
                },
                timestamp,
                human_date,
                "open_wallet_page")
        }
    }

    function onEnablingZCoinStatus(coin, msg, human_date, timestamp)
    {
        // Ignore if coin already enabled (e.g. parent chain in batch)
        if (msg.search("already initialized") > -1)
        {
            console.trace()
            return
        }

        newNotification(
            enablingZCoinStatusNotification,
            {
                coin,
                msg,
                human_date,
                timestamp
            },
            timestamp,
            human_date,
            "open_log_modal",
            msg)
    }

    function onEnablingCoinFailedStatus(coin, error, human_date, timestamp)
    {
        // Ignore if coin already enabled (e.g. parent chain in batch)
        if (error.search("already initialized") > -1)
        {
            console.trace()
            return
        }

        error = check_internet_connection_text + "\n\n" + error

        newNotification(
            enablingCoinFailedStatusNotification,
            {
                coin,
                error,
                human_date,
                timestamp
            },
            timestamp,
            human_date,
            "open_log_modal",
            error)
    }

    function onDisablingCoinFailedStatus(coin, error, human_date, timestamp)
    {
        newNotification(
            disablingCoinFailedStatus,
            {
                coin,
                error,
                human_date,
                timestamp
            },
            timestamp,
            human_date,
            "open_log_modal",
            error)
        toast.show(qsTr("Failed to disable %1", "TICKER").arg(coin), General.time_toast_important_error, error)
    }

    function onEndpointNonReacheableStatus(base_uri, human_date, timestamp)
    {
        newNotification(
            endpointNonReacheableStatus,
            {
                base_uri,
                human_date,
                timestamp
            },
            timestamp,
            human_date,
            "open_log_modal",
            qsTr("Could not reach to endpoint") + ". " + check_internet_connection_text + "\n\n" + base_uri)

        toast.show(qsTr("Endpoint not reachable"), General.time_toast_important_error, error)
    }

    Component.onCompleted:
    {
        API.app.notification_mgr.updateSwapStatus.connect(onUpdateSwapStatus)
        API.app.notification_mgr.balanceUpdateStatus.connect(onBalanceUpdateStatus)
        API.app.notification_mgr.enablingZCoinStatus.connect(onEnablingZCoinStatus)
        API.app.notification_mgr.enablingCoinFailedStatus.connect(onEnablingCoinFailedStatus)
        API.app.notification_mgr.disablingCoinFailedStatus.connect(onDisablingCoinFailedStatus)
        API.app.notification_mgr.endpointNonReacheableStatus.connect(onEndpointNonReacheableStatus)
    }
    
    Component.onDestruction:
    {
        API.app.notification_mgr.updateSwapStatus.disconnect(onUpdateSwapStatus)
        API.app.notification_mgr.balanceUpdateStatus.disconnect(onBalanceUpdateStatus)
        API.app.notification_mgr.enablingZCoinStatus.disconnect(onEnablingZCoinStatus)
        API.app.notification_mgr.enablingCoinFailedStatus.disconnect(onEnablingCoinFailedStatus)
        API.app.notification_mgr.disablingCoinFailedStatus.disconnect(onDisablingCoinFailedStatus)
        API.app.notification_mgr.endpointNonReacheableStatus.disconnect(onEndpointNonReacheableStatus)
    }

    SystemTrayIcon
    {
        id: tray
        visible: true
        iconSource: General.image_path + "dex-tray-icon.png"

        tooltip: API.app_name

        onMessageClicked:
        {
            if (notifications_list.length > 0)
                performNotificationAction(notifications_list[0])
            showApp()
        }

        menu: Menu
        {
            MenuItem
            {
                text: qsTr("Show")
                onTriggered: showApp()
            }

            MenuItem
            {
                text: qsTr("Restart")
                onTriggered: API.app.restart()
            }

            MenuItem
            {
                text: qsTr("Quit")
                onTriggered:
                {
                    if (orders.count != 0) logout_modal.open()
                    else return_to_login()
                }
            }
        }
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 30
        anchors.topMargin: 20
        spacing: 24

        DefaultText
        {
            Layout.fillWidth: true
            font
            {
                pixelSize: 20
                weight: Font.Normal
            }
            text: qsTr("Notifications")
        }

        Item
        {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Qaterial.Icon
            {

                anchors.centerIn: parent
                icon: Qaterial.Icons.bellOutline
                size: 166
                opacity: 0.03

            }

            DefaultText
            {
                anchors.centerIn: parent
                visible: !list.visible
                text_value: qsTr("There aren't any notifications")
                font.pixelSize: 14
            }

            DefaultListView
            {
                id: list
                visible: notifications_list.length !== 0
                width: parent.width + 58
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                model: notifications_list

                delegate: Item
                {
                    height: _column.height + 10
                    width: list.width

                    Rectangle
                    {
                        anchors.fill: parent
                        opacity: 0.7

                        gradient: Gradient
                        {
                            orientation: Qt.Horizontal
                            GradientStop
                            {
                                position: 0.1255
                                color: mouseArea.containsMouse ? Dex.CurrentTheme.buttonColorEnabled : 'transparent'
                            }
                            GradientStop
                            {
                                position: 0.933
                                color: 'transparent'
                            }
                        }
                    }

                    function removeNotification()
                    {
                        notifications_list.splice(index, 1)
                        notifications_list = notifications_list
                    }

                    RowLayout
                    {
                        anchors.fill: parent
                        Item
                        {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 60

                            Rectangle
                            {
                                width: 23
                                height: 23
                                radius: 12
                                anchors.right: parent.right
                                anchors.rightMargin: -5
                                y: 13
                                
                                Qaterial.Icon
                                {
                                    anchors.centerIn: parent
                                    size: 16
                                    icon: getNotificationIcon(modelData)
                                }
                            }
                        }

                        Item
                        {
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Column
                            {
                                id: _column
                                width: parent.width
                                leftPadding: 15
                                topPadding: 10
                                bottomPadding: 5
                                spacing: 5

                                DefaultText
                                {
                                    text: getNotificationTitle(modelData)
                                    font: DexTypo.subtitle1
                                    width: parent.width
                                    wrapMode: Label.Wrap
                                }

                                DefaultText
                                {
                                    text: getNotificationMsg(modelData)
                                    font: DexTypo.subtitle2
                                    width: parent.width - 20
                                    wrapMode: Label.Wrap
                                }

                                DefaultText
                                {
                                    text: modelData.human_date
                                    font: DexTypo.caption
                                    opacity: 0.7
                                }
                            }

                            Qaterial.AppBarButton
                            {
                                id: action_button
                                scale: .6
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                anchors.bottomMargin: -4
                                foregroundColor: Dex.CurrentTheme.foregroundColor
                                visible: modelData.event_name !== "check"

                                icon.source:
                                {
                                    let name
                                    switch (modelData.event_name)
                                    {
                                        case enablingCoinFailedStatusNotification:
                                            name = "repeat"
                                            break
                                        default:
                                            name = "check"
                                            break
                                    }

                                    return General.qaterialIcon(name)
                                }

                                function removeNotification()
                                {
                                    notifications_list.splice(index, 1)
                                    notifications_list = notifications_list
                                }

                                onClicked:
                                {
                                    // Action might create another event so we save it and then remove the current one, then take the action
                                    const event_before_removal = General.clone(modelData)

                                    // Action
                                    switch (event_before_removal.event_name)
                                    {
                                        case enablingCoinFailedStatusNotification:
                                            removeNotification()
                                            console.log("Retrying to enable", event_before_removal.params.coin, "asset...")
                                            API.app.enable_coins([event_before_removal.params.coin])
                                            break

                                        default:
                                            removeNotification()
                                            break
                                    }
                                }
                            }
                        }
                    }

                    DefaultMouseArea
                    {
                        id: mouseArea
                        hoverEnabled: true
                        cursorShape: "PointingHandCursor"
                        anchors.fill: parent

                        onClicked:
                        {
                            performNotificationAction(notifications_list[index])
                            removeNotification()
                        }
                    }
                }
            }
        }

        OutlineButton
        {            
            text: notifications_list.length !== 0 ? qsTr('Mark all as read') : qsTr('Close')
            height: 40
            width: 260
            Layout.alignment: Qt.AlignHCenter
            onClicked: notifications_list.length !== 0 ? root.reset(false) : root.reset(true)
        }
    }
}
