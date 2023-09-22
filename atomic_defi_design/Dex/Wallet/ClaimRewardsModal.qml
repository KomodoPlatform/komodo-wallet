import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0
import Dex.Components 1.0 as Dex

MultipageModal
{
    id: root

    readonly property bool empty_data: !prepare_claim_rewards_result || !prepare_claim_rewards_result.withdraw_answer
    readonly property bool positive_claim_amount: empty_data ? false :
                                                parseFloat(prepare_claim_rewards_result.withdraw_answer.my_balance_change) > 0
    readonly property bool has_eligible_utxo: {
        if(empty_data) return false
        const utxos = prepare_claim_rewards_result.kmd_rewards_info.result
        if(!utxos) return false

        for(let i = 0; i < utxos.length; ++i)
            if(!utxos[i].accrued_rewards.NotAccruedReason)
                return true

        return false
    }

    readonly property var default_prepare_claim_rewards_result: ({
         "kmd_rewards_info": {
             "result": [
                 {
                     "accrue_start_at": 1596785618,
                     "accrue_stop_at": 1599460418,
                     "accrue_start_at_human_date": "7 Aug 2020, 08:33",
                     "accrue_stop_at_human_date": "7 Sep 2020, 08:33",
                     "accrued_rewards": {
                         "Accrued": "0"
                     },
                     "amount": "0",
                     "output_index": 0
                 }
             ]
         },
         "withdraw_answer": {
             "fee_details": {
                 "amount": "0.00001",
                 "amount_fiat": "0.00001"
             },
             "date": "7 Aug 2020, 08:33",
             "my_balance_change": "0",
             "tx_hash": "",
             "tx_hex": ""
         }
     })
    property var prepare_claim_rewards_result: General.clone(default_prepare_claim_rewards_result)

    // Override
    property var postClaim: () => {}

    // Local
    readonly property bool can_confirm: positive_claim_amount && has_eligible_utxo && !is_broadcast_busy

    readonly property bool can_claim: current_ticker_infos.is_claimable && !api_wallet_page.is_claiming_busy
    readonly property var claim_rpc_result: api_wallet_page.claiming_rpc_data

    readonly property bool is_broadcast_busy: api_wallet_page.is_broadcast_busy
    readonly property string broadcast_result: api_wallet_page.broadcast_rpc_data

    onClaim_rpc_resultChanged: {
        prepare_claim_rewards_result = General.clone(claim_rpc_result)
        if(!prepare_claim_rewards_result.withdraw_answer) {
            reset()
            return
        }

        console.log("Claim rewards result changed:", JSON.stringify(prepare_claim_rewards_result))

        if(prepare_claim_rewards_result.error_code) {
            toast.show(qsTr("Failed to prepare to claim rewards"), General.time_toast_important_error, prepare_claim_rewards_result.error_message)
            root.close()
        }
    }

    onBroadcast_resultChanged: {
        if(root.visible && broadcast_result !== "") {
            root.currentIndex = 1
            postClaim()
            root.width = 750
        }
    }

    Behavior on width { NumberAnimation { duration: 300 } }

    function prepareClaimRewards() {
        if(!can_claim) return

        root.currentIndex = 0
        reset()

        api_wallet_page.claim_rewards()
    }

    function claimRewards() {
        api_wallet_page.broadcast(prepare_claim_rewards_result.withdraw_answer.tx_hex, true, false, "0")
    }

    function reset() {
        prepare_claim_rewards_result = General.clone(default_prepare_claim_rewards_result)
    }

    // Inside modal
    width: 1200

    MultipageModalContent
    {
        titleText: qsTr("Claim your %1 reward?", "TICKER").arg(api_wallet_page.ticker)

        DefaultBusyIndicator
        {
            visible: !can_claim || is_broadcast_busy
            Layout.alignment: Qt.AlignCenter
        }

        RowLayout
        {
            visible: can_claim
            Layout.fillWidth: true

            Dex.Text
            {
                Layout.fillWidth: true
                text_value:
                {
                    let amount = prepare_claim_rewards_result.withdraw_answer.my_balance_change
                    !amount ? "" :
                    !has_eligible_utxo ? ("❌ " + qsTr("No UTXOs eligible for claiming")) :
                    !positive_claim_amount ? ("❌ " + qsTr("Transaction fee is higher than the reward!")) :
                    qsTr("You will receive ") + General.formatCrypto(
                        '',
                        amount,
                        api_wallet_page.ticker,
                        API.app.get_fiat_from_amount(api_wallet_page.ticker, amount),
                        API.app.settings_pg.current_fiat
                    )
                }
            }

            Dex.Button
            {
                text: qsTr("Refresh")
                enabled: can_claim
                onClicked: prepareClaimRewards()
            }
        }

        Dex.Text
        {
            text_value: General.cex_icon + ' <a href="https://support.komodoplatform.com/support/solutions/articles/29000024428-komodo-5-active-user-reward-all-you-need-to-know">' + qsTr('Read more about KMD active users rewards') + '</a>'
            font.pixelSize: Style.textSizeSmall2
        }

        // List header
        Row
        {
            visible: can_claim

            Layout.topMargin: 25
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            // Price
            Dex.Text
            {
                id: utxo_header
                font.pixelSize: Style.textSizeSmall4
                text_value: qsTr("UTXO")
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.060
                anchors.verticalCenter: parent.verticalCenter
            }

            // Amount
            Dex.Text
            {
                id: amount_header
                text_value: qsTr("Amount")
                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: utxo_header.horizontalAlignment
                width: parent.width * 0.165
                anchors.verticalCenter: parent.verticalCenter
            }

            // Reward
            Dex.Text
            {
                id: reward_header

                text_value: qsTr("Reward")

                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.235
                anchors.verticalCenter: parent.verticalCenter
            }

            // Accruing start
            Dex.Text
            {
                id: accruing_start_header

                text_value: qsTr("Accruing Start")

                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.150
                anchors.verticalCenter: parent.verticalCenter
            }

            // Accruing Stop
            Dex.Text
            {
                id: accruing_stop_header

                text_value: qsTr("Accruing Stop")

                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.150
                anchors.verticalCenter: parent.verticalCenter
            }

            // Time Left
            Dex.Text
            {
                id: time_left_header

                text_value: qsTr("Time Left")

                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.120
                anchors.verticalCenter: parent.verticalCenter
            }

            // Error
            Dex.Text
            {
                id: error_header

                text_value: qsTr("Error")

                font.pixelSize: utxo_header.font.pixelSize
                font.weight: utxo_header.font.weight
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Separator
        HorizontalLine
        {
            Layout.fillWidth: true
        }

        Dex.ListView
        {
            id: list
            visible: can_claim
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: 500
            clip: true

            model: empty_data ? [] : prepare_claim_rewards_result.kmd_rewards_info.result

            delegate: Column
            {
                width: list.width

                Row
                {
                    width: list.width

                    // UTXO
                    Dex.Text
                    {
                        id: utxo_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.06

                        text: "#" + (index + 1)
                        font.pixelSize: utxo_header.font.pixelSize
                    }

                    // Amount
                    Dex.Text
                    {
                        id: amount_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.165

                        font.pixelSize: utxo_value.font.pixelSize
                        text: modelData.amount
                    }

                    // Reward
                    Dex.Text
                    {
                        id: reward_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.235

                        font.pixelSize: utxo_value.font.pixelSize
                        text: modelData.accrued_rewards.Accrued || "-"
                    }

                    // Accruing Start
                    Dex.Text
                    {
                        id: accruing_start_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.150

                        font.pixelSize: utxo_value.font.pixelSize
                        text: modelData.accrue_start_at_human_date || "-"
                    }

                    // Accruing Stop
                    Dex.Text
                    {
                        id: accruing_stop_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.150

                        font.pixelSize: utxo_value.font.pixelSize
                        text: modelData.accrue_stop_at_human_date || "-"
                    }

                    // Time Left
                    Dex.Text
                    {
                        id: time_left_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.120

                        font.pixelSize: utxo_value.font.pixelSize
                        text: modelData.accrue_stop_at ? General.secondsToTimeLeft(Date.now()/1000, modelData.accrue_stop_at) : '-'
                    }

                    // Error
                    Dex.Text
                    {
                        id: error_value

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.12

                        font.pixelSize: utxo_value.font.pixelSize
                        text:
                        {
                            let val = modelData.accrued_rewards.NotAccruedReason
                            if (val === null || val === undefined) return "-"

                            switch (val)
                            {
                            case "LocktimeNotSet":
                                val = qsTr("Locktime is not set")
                                break
                            case "LocktimeLessThanThreshold":
                                val = qsTr("Locktime is less than the threshold")
                                break
                            case "UtxoHeightGreaterThanEndOfEra":
                                val = qsTr("UTXO height is greater than end of the era")
                                break
                            case "UtxoAmountLessThanTen":
                                val = qsTr("UTXO amount is less than 10")
                                break
                            case "OneHourNotPassedYet":
                                val = qsTr("One hour did not pass yet")
                                break
                            case "TransactionInMempool":
                                val = qsTr("Transaction is in mempool")
                                break
                            default:
                                val = qsTr("Unknown problem")
                                break
                            }

                            return "❌ " + val
                        }
                    }
                }

                HorizontalLine
                {
                    width: parent.width
                }
            }
        }

        // Buttons
        footer:
        [
            CancelButton
            {
                text: qsTr("Cancel")
                leftPadding: 40
                rightPadding: 40
                radius: 18
                onClicked: root.close()
            },

            Item
            {
                Layout.fillWidth: true
            },

            DexAppOutlineButton
            {
                text: qsTr("Confirm")
                leftPadding: 40
                rightPadding: 40
                radius: 18
                opacity: enabled ? containsMouse ? .7 : 1 : .5
                onClicked: claimRewards()
                enabled: can_confirm
            }
        ]
    }

    // Result Page
    SendResult
    {
        address: current_ticker_infos.address
        result: prepare_claim_rewards_result
        tx_hash: broadcast_result
        function onClose() { root.close() }
    }
}
