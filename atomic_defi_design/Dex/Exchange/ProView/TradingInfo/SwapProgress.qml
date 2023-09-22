import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Dex.Themes 1.0 as Dex
import App 1.0

import "../../../Components"
import "../../../Constants"

// Content
ColumnLayout
{
    id: root

    property var details
    property var lastEvent

    readonly property var all_events: !details
                            ? [] : has_error_event
                            ? details.events.map(e => e.state) : details.success_events

    // Is there error in swap json?
    readonly property bool has_error_event:
    {
        if (!details) return false

        const events = details.events

        for (let i = events.length - 1; i >= 0; --i)
            if (details.error_events.indexOf(events[i].state) !== -1)
                return true

        return false
    }

    // Total swaptime from sum of events duration
    readonly property double totalTimePassed:
    {
        if (!details) return 0

        const events = details.events

        let sum = 0
        for (let i = 0; i < events.length; ++i)
            sum += events[i].time_diff

        return sum
    }


    // Total swap duration estimate
    readonly property double totalTimePassedEstimated:
    {
        const events = all_events

        let sum = 0
        for (let i = 0; i < events.length; ++i)
            sum += API.app.orders_mdl.average_events_time_registry[events[i]]

        return sum
    }

    // Current Event index
    readonly property int current_event_idx:
    {
        if (!details) return -1
        const events = details.events
        if (events.length === 0) return -1
        if (all_events.length === 0) return -1

        const last_state = events[events.length - 1].state
        if (last_state === "Finished") return -1

        const idx = all_events.indexOf(last_state)
        if (idx === -1) return -1

        return idx + 1
    }

    // Simulated time of the running event
    property double simulatedTime: 0
    function updateSimulatedTime()
    {
        if (!details)
        {
            simulatedTime = 0
            return
        }

        const events = details.events
        if (!events || events.length === 0)
        {
            simulatedTime = 0
            return
        }

        lastEvent = events[events.length - 1]
        if (!lastEvent.timestamp)
        {
            simulatedTime = 0
            return
        }

        if (current_event_idx !== -1)
        {
            const diff = Date.now() - lastEvent.timestamp
            simulatedTime = diff - (diff % 1000)

        } else simulatedTime = 0
    }

    Timer
    {
        running: current_event_idx !== -1
        interval: 1000
        repeat: true
        onTriggered: updateSimulatedTime()
    }

    // Simulated countdown time until refund unlocked
    property double paymentLockCountdownTime: -1    // First we wait for locktime expiry
    property double waitUntilCountdownTime: -1      // Then we count down to 'wait_until' time
    function updateCountdownTime()
    {
        if (current_event_idx == -1 || !details)
        {
            paymentLockCountdownTime = -1
            return
        }

        const events = details.events

        if (events[current_event_idx - 1].hasOwnProperty('data'))
        {
            if (events[current_event_idx - 1]['data'].hasOwnProperty('wait_until'))
            {
                const diff = events[current_event_idx - 1]['data']['wait_until'] * 1000 - Date.now()
                waitUntilCountdownTime = diff - (diff % 1000)

                if (waitUntilCountdownTime <= 0)
                {
                    waitUntilCountdownTime = 0
                }
            }
        }

        else
        {
            waitUntilCountdownTime = -1
        }

        if (details.hasOwnProperty('paymentLock'))
        {
            const lock_diff = details.paymentLock - Date.now()
            paymentLockCountdownTime = lock_diff - (lock_diff % 1000)

            if (paymentLockCountdownTime <= 0)
            {
                paymentLockCountdownTime = 0
            }
        }

        else
        {
            paymentLockCountdownTime = -1
        }
    }

    Timer
    {
        running: !has_error_event ? false : details.events[details.events.length - 1].state == "Finished" ? false : true
        interval: 1000
        repeat: true
        onTriggered: updateCountdownTime()
    }

    function getTimeText(duration, estimated)
    {
        return `<font color="${Dex.CurrentTheme.okColor}">` + qsTr("act", "SHORT FOR ACTUAL TIME") + ": " + `</font>` +
            `<font color="${Dex.CurrentTheme.foregroundColor}">` + General.durationTextShort(duration) + `</font>` +
            `<font color="${Dex.CurrentTheme.foregroundColor3}"> | ` + qsTr("est", "SHORT FOR ESTIMATED") + ": " +
            General.durationTextShort(estimated) + `</font>`
    }

    function getRefundText()
    {
        if ((paymentLockCountdownTime > 0) && (waitUntilCountdownTime == -1))
        {
            return `<font color="${Dex.CurrentTheme.foregroundColor}">` + qsTr(General.durationTextShort(paymentLockCountdownTime) + " until refund lock is released.") + `</font>`
        }
        else if (waitUntilCountdownTime > 0) {
            if (lastEvent.state !== "Finished") {
                return `<font color="${Dex.CurrentTheme.foregroundColor}">` + qsTr(General.durationTextShort(waitUntilCountdownTime) + " until refund completed.") + `</font>`
            }
        }
        return ""
    }

    // Title
    DefaultText
    {
        Layout.fillWidth: true
        text_value: `<font color="${Dex.CurrentTheme.foregroundColor}">` + qsTr("Progress details") + `</font>` +
            `<font color="${Dex.CurrentTheme.foregroundColor}"> | </font>` +
            getTimeText(totalTimePassed + simulatedTime, totalTimePassedEstimated)
        font.pixelSize: Style.textSize1
        Layout.bottomMargin: 10
    }

    Repeater
    {
        Layout.fillHeight: true
        model: all_events

        delegate: Item
        {
            readonly property
            var event:
            {
                if (!details) return undefined
                const idx = details.events.map(e => e.state).indexOf(modelData)
                if (idx === -1) return undefined

                return details.events[idx]
            }

            readonly property bool is_current_event: index === current_event_idx

            readonly property bool is_active: General.exists(event) || is_current_event

            readonly property double time_passed: event ? event.time_diff : is_current_event ? simulatedTime : 0

            width: root.width
            height: 50

            DefaultText {
                id: icon

                text_value: is_active ? "●" : "○"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: col_layout.verticalCenter

                color:
                {
                    // Already exists, completed event
                    if (event)
                    {
                        // Red for the Finished if swap failed
                        if (event.state === "Finished" && details.order_status === "failed") return Dex.CurrentTheme.warningColor

                        // Red for error event, green for the others
                        return details.error_events.indexOf(event.state) === -1 ? Dex.CurrentTheme.okColor : Dex.CurrentTheme.warningColor
                    }

                    // In progress one is orange
                    if (is_current_event)
                        return Style.colorOrange

                    // Passive color for the rest
                    return Dex.CurrentTheme.foregroundColor3
                }
            }

            ColumnLayout
            {
                id: col_layout

                anchors.left: icon.right
                anchors.leftMargin: icon.anchors.leftMargin
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right

                DefaultText
                {
                    id: name

                    font.pixelSize: Style.textSizeSmall4

                    text_value: getEventText(modelData)
                    color: event ? Dex.CurrentTheme.foregroundColor : is_current_event ? Dex.CurrentTheme.foregroundColor : Dex.CurrentTheme.foregroundColor3
                }

                AnimatedRectangle
                {
                    id: bar
                    visible: is_active
                    width: parent.width
                    height: 2

                    color: Dex.CurrentTheme.foregroundColor2

                    AnimatedRectangle
                    {
                        width: parent.width * (totalTimePassed > 0 ? (time_passed / (totalTimePassed + simulatedTime)) : 0)
                        height: parent.height
                        color: Dex.CurrentTheme.okColor
                    }
                }

                DefaultText
                {
                    visible: bar.visible
                    font.pixelSize: Style.textSizeSmall2

                    text_value: !is_active ? '' : getTimeText(time_passed, API.app.orders_mdl.average_events_time_registry[modelData])
                }
            }
        }
    }
}