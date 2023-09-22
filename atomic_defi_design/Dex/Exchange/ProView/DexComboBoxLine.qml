import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import QtQuick.Controls.Universal 2.15

import "../../Constants" as Dex
import "../../Components"
import App 1.0
import Dex.Themes 1.0 as Dex
import Dex.Components 1.0 as Dex


RowLayout
{
    id: root

    property int padding: 0
    property var details
    property color color: !details ? "white" : Style.getCoinColor(details.ticker)
    property alias middle_text: middle_line.text_value
    property alias bottom_text: bottom_line.text_value
    property int activation_progress: Dex.General.zhtlcActivationProgress(details.activation_status, details.ticker)

    Behavior on color { ColorAnimation { duration: Style.animationDuration } }

    Dex.Image
    {
        id: icon
        source: General.coinIcon(details.ticker)
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        Layout.leftMargin: padding
        Layout.topMargin: Layout.leftMargin
        Layout.bottomMargin: Layout.leftMargin

        DexRectangle
        {
            anchors.centerIn: parent
            anchors.fill: parent
            radius: 10
            enabled: Dex.General.isZhtlc(details.ticker) ? activation_progress < 100 : false
            visible: enabled
            opacity: .9
            color: Dex.DexTheme.backgroundColor
        }

        DexLabel
        {
            anchors.centerIn: parent
            anchors.fill: parent
            enabled: Dex.General.isZhtlc(details.ticker) ? activation_progress < 100 : false
            visible: enabled
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: activation_progress + "%"
            font: Dex.DexTypo.body2
            color: Dex.DexTheme.okColor
        }

        ColumnLayout
        {
            anchors.left: parent.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 48
            spacing: 3

            Dex.Text
            {
                Layout.preferredWidth: parent.width - 15

                text_value: !details ? "" :
                            `<font color="${root.color}"><b>${details.ticker}</b></font>&nbsp;&nbsp;&nbsp;<font color="${Dex.CurrentTheme.foregroundColor}">${details.name}</font>`
                font.pixelSize: Style.textSizeSmall3
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Dex.Text
            {
                id: middle_line

                property string coin_value: !details ? "" : details.balance
                text: coin_value
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Dex.CurrentTheme.foregroundColor
                font: DexTypo.body2
                wrapMode: Label.NoWrap
                ToolTip.text: coin_value
                Component.onCompleted: font.pixelSize = 11.5
            }

            Dex.Text
            {
                id: bottom_line

                property string fiat_value: !details ? "" :
                            General.formatFiat("", details.main_currency_balance, API.app.settings_pg.current_fiat_sign)
                text: fiat_value
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Dex.CurrentTheme.foregroundColor
                font: DexTypo.body2
                wrapMode: Label.NoWrap
                ToolTip.text: fiat_value
                Component.onCompleted: font.pixelSize = 11.5
            }
        }
    }
}
