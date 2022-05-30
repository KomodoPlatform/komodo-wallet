//! Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0
import QtQml 2.12
import QtQuick.Window 2.12
import QtQuick.Controls.Universal 2.12

//! 3rdParty Imports
import Qaterial 1.0 as Qaterial

//! Project Imports
import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex


Qaterial.Dialog
{
    id: support_modal
    readonly property bool update_needed: API.app.self_update_service.update_needed

    width: 950
    height: 650
    padding: 20
    topPadding: 30
    bottomPadding: 30
    anchors.centerIn: parent

    dim: true
    modal: true
    title: "Support"

    header: Item
    {}

    Overlay.modal: Item
    {
        DexRectangle
        {
            anchors.fill: parent
            color: 'black'
            opacity: .7
        }
    }

    background: DexRectangle
    {
        color: DexTheme.backgroundColor
        border.width: 0
        radius: 16
    }

    ColumnLayout
    {
        id: support_layout
        width: support_modal.width - 100
        Layout.alignment: Qt.AlignHCenter

        RowLayout
        {
            id: faq_title
            height: 30
            Layout.preferredWidth: faq_column.width
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            Layout.leftMargin: 42
            DexLabel
            {
                id: faq_label
                Layout.preferredWidth: faq_title.width
                text_value: qsTr("Frequently Asked Questions")
                font.pixelSize: Style.textSize2
                horizontalAlignment: Text.AlignHCenter
            }
        }

        DexFlickable
        {
            id: faq_flickable

            width: support_modal.width - 100
            height: support_modal.height - 220
            contentWidth: width - 20
            contentHeight: faq_column.height
            Layout.leftMargin: 32

            ColumnLayout
            {
                id: faq_column
                width: parent.width - 5
                spacing: 12


                // FAQ Lines
                FAQLine
                {
                    title: qsTr("Do you store my private keys?")
                    text: qsTr("No! %1 is non-custodial. We never store any sensitive data, including your private keys, seed phrases, or PIN. This data is  only stored on the user’s device and never leaves it. You are in full control of your assets.").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("How is trading on %1 different from trading on other DEXs?").arg(API.app_name)
                    text: qsTr("Other DEXs generally only allow you to trade assets that are based on a single blockchain network, use proxy tokens, and only allow placing a single order with the same funds. 

%1 enables you to natively trade across two different blockchain networks without proxy tokens. You can also place multiple orders with the same funds. For example, you can sell 0.1 BTC for KMD, QTUM, or VRSC — the first order that fills automatically cancels all other orders.").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("How long does each atomic swap take?")
                    text: qsTr('Several factors determine the processing time for each swap. The block time of the traded assets depends on each network (Bitcoin typically being the slowest) Additionally, the user can customize security preferences. For example,  (you can ask %1 to consider a KMD transaction as final after just 3 confirmations which makes the swap time shorter compared to waiting for a <a href="https://komodoplatform.com/security-delayed-proof-of-work-dpow/">notarization</a>.').arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("Do I need to be online for the duration of the swap?")
                    text: qsTr("Yes. You must remain connected to the internet and have your app running to successfully complete each atomic swap (very short breaks in connectivity are usually fine). Otherwise, there is risk of trade cancellation if you are a maker, and risk of loss of funds if you are a taker.

The atomic swap protocol requires both participants to stay online and monitor the involved blockchains for the process to stay atomic.

If you go offline, so will your orders, and any that are in progress will fail, leading to potential loss of trade / transaction fees, and a wait for the swap to timeout and issue a refund. It may also negatively affect your wallet's reputation score for future trade matching.

When you come back online, your orders will begin to broadcast again at the price you set before you went offline. If there has been significant price movement in the meantime, you might unintentionally offer someone a bargain!

For this reason, we recommend cancelling orders before closing %1, or reviewing and revising your prices when restarting %1.").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("How are the fees on %1 calculated?").arg(API.app_name)
                    text: qsTr("There are two fee categories to consider when trading on %1.

1. %1 charges approximately 0.13% (1/777 of trading volume but not lower than 0.0001) as the trading fee for taker orders, and maker orders have zero fees.

2. Both makers and takers will need to pay normal network fees to the involved blockchains when making atomic swap transactions.

Network fees can vary greatly depending on your selected trading pair.").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("Do you provide user support?")
                    text: qsTr('Yes! %1 offers support through the <a href="%2">%1 Discord server</a>. The team and the community are always happy to help!').arg(API.app_name).arg(API.app_discord_url)
                }

                FAQLine
                {
                    title: qsTr("Who is behind %1?").arg(API.app_name)
                    text: qsTr("%1 is developed by the Komodo team. Komodo is one of the most established blockchain projects working on innovative solutions like atomic swaps, Delayed Proof of Work, and an interoperable multi-chain architecture.").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("Is it possible to develop my own white-label exchange on %1?").arg(API.app_name)
                    text: qsTr("Absolutely! You can read our developer documentation for more details or contact us with your partnership inquiries. Have a specific technical question? The %1 developer community is always ready to help!").arg(API.app_name)
                }

                FAQLine
                {
                    title: qsTr("Which devices can I use %1 on?").arg(API.app_name)
                    text: qsTr('%1 is available for mobile on both <a href="%2">Android and iPhone, and for desktop on Windows, Mac, and Linux</a> operating systems.').arg(API.app_name).arg(API.app_website_url)
                }

                FAQLine
                {
                    title: qsTr("Compliance Info")
                    text: qsTr("Due to regulatory and legal circumstances the citizens of certain jurisdictions including, but not limited to, the United States of America, Canada, Hong Kong, Israel, Singapore, Sudan, Austria, Iran and any other state, country or other jurisdiction that is embargoed by the United States of America or the European Union are not allowed to use this application.")
                }
            }
        }

        RowLayout
        {
            id: bottom_row
            Layout.topMargin: 20
            Layout.preferredHeight: 70
            Layout.preferredWidth: faq_title.width
            Layout.leftMargin: 32
            property var filler_width: (parent.width - links_row.width - changelog_button.width - logs_btn.width) / 2 - 14

            LinksRow { id: links_row }

            Item { Layout.preferredWidth: bottom_row.filler_width }

            DexMouseArea
            {
                id: changelog_button

                Layout.preferredWidth: column_layout.width
                Layout.preferredHeight: column_layout.height
                hoverEnabled: true

                onClicked: update_modal.open()

                ColumnLayout
                {
                    id: column_layout
                    RowLayout
                    {
                        Layout.alignment: Qt.AlignHCenter

                        Circle
                        {
                            Layout.alignment: Qt.AlignVCenter
                            color: Qt.lighter(update_needed ? Style.colorOrange : Style.colorGreen, changelog_button.containsMouse ? Style.hoverLightMultiplier : 1.0)
                        }

                        DexLabel
                        {
                            Layout.alignment: Qt.AlignVCenter
                            text_value: update_needed ? qsTr("Update available") : qsTr("Up to date")
                            color: changelog_text.color
                        }
                    }

                    DexLabel
                    {
                        Layout.alignment: Qt.AlignHCenter
                        text_value: General.version_string
                        font.pixelSize: Style.textSizeSmall3
                        color: changelog_text.color
                    }

                    DexLabel
                    {
                        id: changelog_text
                        Layout.alignment: Qt.AlignHCenter
                        text_value: General.cex_icon + ' ' + qsTr('Changelog')
                        font.pixelSize: Style.textSizeSmall2
                    }
                }
            }

            Item { Layout.preferredWidth: bottom_row.filler_width }

            DexAppButton
            {
                id: logs_btn
                text: qsTr("Open Logs Folder")
                onClicked: openLogsFolder()
            }
        }
    }
}