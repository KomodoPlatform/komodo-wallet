import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial

import QtGraphicalEffects 1.0

import bignumberjs 1.0

import App 1.0

import "../../../Components"
import Dex.Themes 1.0 as Dex

FloatingBackground
{
    Layout.fillWidth: true

    property var            details
    property alias          clickable: mouseArea.enabled
    readonly property bool  is_placed_order: !details ? false : details.order_id !== ''

    height: 50

    color: mouseArea.containsMouse ? Dex.CurrentTheme.accentColor : Dex.CurrentTheme.floatingBackgroundColor
    radius: 0

    DefaultMouseArea
    {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: enabled
        onClicked:
        {
            order_modal.open()
            order_modal.item.details = details
        }
    }

    RowLayout
    {
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Item
        {
            Layout.fillHeight: true
            Layout.preferredWidth: 24
            Layout.alignment: Qt.AlignCenter

            DefaultText
            {
                id: statusText
                anchors.centerIn: parent

                visible: clickable ? !details ? false : (details.is_swap || !details.is_maker) : false
                font.pixelSize: getStatusFontSize(details.order_status)
                color: !details ? Dex.CurrentTheme.foregroundColor : getStatusColor(details.order_status)
                text_value: !details ? "" : visible ? getStatusStep(details.order_status) : ''
            }

            Qaterial.ColorIcon
            {
                anchors.centerIn: parent

                visible: !statusText.visible ? clickable ? true : false : false
                iconSize: 16
                color: Dex.CurrentTheme.foregroundColor
                source: Qaterial.Icons.clipboardTextSearchOutline
            }
        }


        ColumnLayout
        {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: 0

            Item
            {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height

                clip: true

                DefaultText
                {
                    id: baseAmountLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 12
                    text:
                    {
                        if (!details) return

                        BigNumber.config({ DECIMAL_PLACES: 6 })
                        return new BigNumber(details.base_amount).toString(10)
                    }
                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                DefaultText
                {
                    anchors.left: baseAmountLabel.right
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 12
                    text: !details ? "" : "(%1 %2)".arg(details.base_amount_current_currency).arg(API.app.settings_pg.current_fiat_sign)
                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Qaterial.ColorIcon
                {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    source: Qaterial.Icons.swapHorizontal
                    color: Dex.CurrentTheme.foregroundColor
                    iconSize: 18
                }

                DefaultText
                {
                    anchors.right: relAmountInCurrCurrency.left
                    anchors.rightMargin: 3
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 12
                    text:
                    {
                        if (!details) return

                        BigNumber.config({ DECIMAL_PLACES: 6 })
                        return new BigNumber(details.rel_amount).toString(10)
                    }

                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                DefaultText
                {
                    id: relAmountInCurrCurrency

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 12
                    text: !details ? "" : "(%1 %2)".arg(details.rel_amount_current_currency).arg(API.app.settings_pg.current_fiat_sign)
                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Item
            {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height

                DefaultImage
                {
                    id: baseIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: 15
                    height: 15

                    source: General.coinIcon(!details ? atomic_app_primary_coin : details.base_coin ?? atomic_app_primary_coin)
                }

                DefaultText
                {
                    anchors.left: baseIcon.right
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter

                    font.weight: Font.Bold
                    font.pixelSize: 12
                    text: !details ? "" : details.base_coin
                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                DefaultText
                {
                    visible: clickable

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 11
                    text_value: !details ? "" : details.date ?? ""
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: Dex.CurrentTheme.foregroundColor2
                }

                DefaultText
                {
                    anchors.right: relCoin.left
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter

                    font.weight: Font.Bold
                    font.pixelSize: 12
                    text: !details ? "" : details.rel_coin
                    privacy: is_placed_order
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                DefaultImage
                {
                    id: relCoin

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 15
                    height: 15

                    source: General.coinIcon(!details ? atomic_app_primary_coin : details.rel_coin ?? atomic_app_secondary_coin)
                }
            }
        }

        Item
        {
            Layout.fillHeight: true
            Layout.preferredWidth: 24
            Layout.alignment: Qt.AlignCenter

            DefaultText
            {
                anchors.centerIn: parent

                visible: !details || details.recoverable === undefined ? false : details.recoverable && details.order_status !== "refunding"
                font.pixelSize: baseAmountLabel.font.pixelSize
                text_value: Style.warningCharacter
                color: Style.colorYellow

                DefaultTooltip
                {
                    contentItem: DefaultText
                    {
                        text_value: qsTr("Funds are recoverable")
                        font.pixelSize: Style.textSizeSmall4
                    }

                    visible: (parent.visible && mouseArea.containsMouse) ?? false
                }
            }

            Qaterial.FlatButton
            {
                id: cancel_button_text
                anchors.centerIn: parent
                anchors.fill: parent

                visible: (!is_history ? details.cancellable ?? false : false) === true ? (mouseArea.containsMouse || hovered) ? true : false : false

                outlinedColor: Dex.CurrentTheme.warningColor
                hoverEnabled: true

                onClicked: if (details) cancelOrder(details.order_id)

                Behavior on scale
                {
                    NumberAnimation
                    {
                        duration: 200
                    }
                }
                Qaterial.ColorIcon
                {
                    anchors.centerIn: parent
                    iconSize: 16
                    color: Dex.CurrentTheme.warningColor
                    source: Qaterial.Icons.close
                    scale: parent.visible ? 1 : 0
                }
            }
        }
    }
    // Separator
    HorizontalLine
    {
        width: parent.width
        height: 2
        anchors.bottom: parent.bottom
    }
}
