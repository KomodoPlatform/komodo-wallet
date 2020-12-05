import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.15
import "../Constants"

Menu {
    Universal.theme: Style.dark_theme ? Universal.Dark : Universal.Light
    Universal.accent: Style.colorQtThemeAccent
    Universal.foreground: Style.colorQtThemeForeground
    Universal.background: Style.colorQtThemeBackground

    // Ugly but required hack for automatic menu width, otherwise long texts are being cut
    width: {
        let result = 0
        let padding = 0

        for (let i = 0; i < count; ++i) {
            let item = itemAt(i)
            result = Math.max(item.contentItem.implicitWidth, result)
            padding = Math.max(item.padding, padding)
        }

        return result + padding * 2
    }

    MenuItem {
        id: disable_action
        text: qsTr("Disable %1", "TICKER").arg(ticker)
        onTriggered: API.app.disable_coins([ticker])
        enabled: General.canDisable(ticker)
    }

    MenuItem {
        text: qsTr("Disable and Delete %1", "TICKER").arg(ticker)
        onTriggered: {
            const cloneTicker = General.clone(ticker)
            API.app.disable_coins([ticker])
            API.app.settings_pg.remove_custom_coin(cloneTicker)
            restart_modal.open()
        }
        enabled: disable_action.enabled && API.app.get_coin_info(ticker).is_custom_coin
    }

    MenuItem {
        readonly property string coin_type: API.app.get_coin_info(ticker).type
        enabled: !General.prevent_coin_disabling.running
        text: qsTr("Disable all %1 assets").arg(coin_type)
        onTriggered: API.app.disable_coins(API.app.enabled_coins.filter(c => c.type === coin_type).map(c => c.ticker))
    }

    MenuItem {
        enabled: !General.prevent_coin_disabling.running
        text: qsTr("Disable all assets")
        onTriggered: API.app.disable_coins(API.app.enabled_coins.map(c => c.ticker))
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

