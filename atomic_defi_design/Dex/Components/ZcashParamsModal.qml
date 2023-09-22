// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

// Project Imports
import "../Constants" as Dex
import "../Components" as Dex
import App 1.0

Dex.MultipageModal
{
    id: root
    readonly property var coins: API.app.zcash_params.get_enable_after_download()
    width: 750
    closePolicy: Popup.NoAutoClose

    // Inside modal
    Dex.MultipageModalContent
    {
        titleText: qsTr("%1 Activation Failed!").arg(coins.join(' / '))

        Dex.DefaultText
        {
            Layout.fillWidth: true
            text: qsTr("To activate ZHTLC coins, you need to download the Zcash Params.\nThis might take a few minutes...")
        }

        HorizontalLine
        {
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.fillWidth: true
        }

        ColumnLayout
        {
            Dex.DefaultProgressBar
            {
                id: sapling_output_params
                label.text: "sapling-output.params"
                bar_width_pct: 0
                pct_value.text: "0.00 %"
            }
            Dex.DefaultProgressBar
            {
                id: sapling_spend_params
                label.text: "sapling-spend.params"
                bar_width_pct: 0
                pct_value.text: "0.00 %"
            }
        }

        HorizontalLine
        {
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.fillWidth: true
        }

        footer:
        [
            Item { Layout.fillWidth: true },
            Dex.DefaultButton
            {
                id: download_button
                text: qsTr("Download params & enable coins")
                enabled: !sapling_output_params.bar_width_pct > 0 || !sapling_spend_params.bar_width_pct > 0
                onClicked: {
                    download_button.enabled = false
                    Dex.API.app.zcash_params.download_zcash_params()
                }
            },
            Item { Layout.fillWidth: true },
            Dex.DefaultButton
            {
                text: qsTr("More Info")
                onClicked: Qt.openUrlExternally("https://www.coinbureau.com/education/zcash-ceremony/")
            },
            Item { Layout.fillWidth: true },
            Dex.CancelButton
            {
                text: qsTr("Close")
                onClicked: close()
            },
            Item { Layout.fillWidth: true }
        ]

        Connections
        {
            target: Dex.API.app.zcash_params

            // todo: can be improved.
            //       put it maybe in the backend ?
            function onCombinedDownloadStatusChanged()
            {
                let combined_progress = 0
                let data = JSON.parse(Dex.API.app.zcash_params.get_combined_download_progress())
                for (let k in data)
                {
                    let v = data[k];
                    let pct = Dex.General.formatDouble(v * 100, 2)
                    combined_progress += parseFloat(v)/Object.keys(data).length
                    switch(k)
                    {
                        case "sapling-output.params":
                            sapling_output_params.bar_width_pct = pct
                            sapling_output_params.pct_value.text = pct + "%"
                            break
                        case "sapling-spend.params":
                            sapling_spend_params.bar_width_pct = pct
                            sapling_spend_params.pct_value.text = pct + "%"
                            break
                    }
                    console.log(combined_progress)
                    if (combined_progress == 1)
                    {
                        console.log("closing")
                        root.close()
                    }
                }
            }
        }
    }
}
