import QtQuick 2.12
import QtQuick.Layouts 1.2

import App 1.0
import "../Components"
import "../Constants"
import Dex.Themes 1.0 as Dex

MouseArea
{
    property alias spacing: _columnLayout.spacing

    signal lineSelected(var lineType)

    height: lineHeight * 5
    hoverEnabled: true

    Connections
    {
        target: parent.parent

        function onIsExpandedChanged()
        {
            if (isExpanded) waitForSidebarExpansionAnimation.start();
            else
            {
                _portfolioLine.label.opacity = 0;
                _walletLine.label.opacity = 0;
                _dexLine.label.opacity = 0;
                _addressBookLine.label.opacity = 0;
                _fiatLine.label.opacity = 0;
            }
        }
    }

    NumberAnimation
    {
        id: waitForSidebarExpansionAnimation
        targets: [_portfolioLine.label, _walletLine.label, _dexLine.label, _addressBookLine.label, _fiatLine.label]
        properties: "opacity"
        duration: 200
        from: 0
        to: 0
        onFinished: labelsOpacityAnimation.start()
    }

    NumberAnimation
    {
        id: labelsOpacityAnimation
        targets: [_portfolioLine.label, _walletLine.label, _dexLine.label, _addressBookLine.label, _fiatLine.label]
        properties: "opacity"
        duration: 350
        from: 0.0
        to: 1
    }

    // Selection List
    ColumnLayout
    {
        id: _columnLayout
        anchors.fill: parent
        FigurativeLine
        {
            id: _portfolioLine

            Layout.fillWidth: true
            type: Main.LineType.Portfolio
            label.text: qsTr("Portfolio") // isExpanded ? qsTr("Portfolio") : ""
            icon.source: General.image_path + "menu-assets-portfolio.svg"
            onClicked: lineSelected(type)
        }

        FigurativeLine
        {
            id: _walletLine

            Layout.fillWidth: true
            type: Main.LineType.Wallet
            label.text: qsTr("Wallet") // isExpanded ? qsTr("Wallet") : ""
            icon.source: General.image_path + "menu-assets-white.svg"
            onClicked: lineSelected(type)
        }

        FigurativeLine
        {
            id: _dexLine

            Layout.fillWidth: true
            type: Main.LineType.DEX
            label.text: qsTr("DEX") // isExpanded ? qsTr("DEX") : ""
            icon.source: General.image_path + "menu-exchange-white.svg"
            onClicked: lineSelected(type)
        }

        FigurativeLine
        {
            id: _addressBookLine

            Layout.fillWidth: true
            type: Main.LineType.Addressbook
            label.text: qsTr("Address Book") // isExpanded ? qsTr("Address Book") : ""
            icon.source: General.image_path + "menu-news-white.svg"
            onClicked: lineSelected(type)
        }

        FigurativeLine
        {
            id: _fiatLine

            label.enabled: false
            icon.enabled: false
            Layout.fillWidth: true
            label.text: qsTr("Fiat") // isExpanded ? qsTr("Fiat") : ""
            icon.source: General.image_path + "bill.svg"
        }
    }
}
