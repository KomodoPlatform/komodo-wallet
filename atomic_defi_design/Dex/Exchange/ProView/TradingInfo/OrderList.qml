import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App 1.0
import "../../../Components"
import "../../../"
import Dex.Themes 1.0 as Dex

Item
{
    id: root

    property string title
    property var    items
    property bool   is_history: false

    ColumnLayout
    {
        width: parent.width
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        HorizontalLine
        {
            Layout.fillWidth: true
            Layout.maximumWidth: 450
        }

        DefaultListView
        {
            id: list

            property int            animationTimestamp: 0
            readonly property int   animationTime: 600
            readonly property int   animationDelay: 50
            property bool           resetAnimation: false

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: items.orders_proxy_mdl
            enabled: !is_history || !API.app.orders_mdl.fetching_busy

            // Row
            delegate: OrderLine
            {
                readonly property double anim_time: list.animationTimestamp > index * list.animationDelay ?
                    Math.min((list.animationTimestamp - index * list.animationDelay) / (list.animationTime), 1) : 0

                details: model
                opacity: anim_time
                width: root.width * 0.985
            }

            populate: Transition
            {
                PropertyAction
                {
                    target: list
                    property: "resetAnimation"
                    value: !list.resetAnimation
                }
            }

            onResetAnimationChanged:
            {
                list.animationTimestamp = 0
                spawn_anim_timer.repeat = true
                spawn_anim_timer.restart()
            }

            Timer
            {
                id: spawn_anim_timer
                interval: General.delta_time
                running: true
                repeat: true
                onTriggered: () => {
                    list.animationTimestamp += interval
                    if (list.animationTimestamp > list.animationDelay * list.count + list.animationTime)
                        repeat = false
                }
            }
        }

        Item
        {
            Layout.fillHeight: true
        }

        // Pagination
        DexPaginator
        {
            visible: is_history && list.count > 0
            enabled: list.enabled
            Layout.maximumHeight: 70
            Layout.preferredWidth: parent.width
            Layout.bottomMargin: 10
            itemsPerPageComboBox.mainBackgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
            itemsPerPageComboBox.popupBackgroundColor: Dex.CurrentTheme.comboBoxBackgroundColor
        }
    }

    DefaultText
    {
        visible: list.count === 0
        anchors.centerIn: parent
        text: qsTr("No results found")
    }
}
