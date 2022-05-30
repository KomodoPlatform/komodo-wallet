// Qt imports
import QtQml 2.15            //> Component
import QtQuick.Layouts 1.15  //> Layout.fillWidth
import QtQuick.Controls 2.15 //> ProgressBar

// Project imports
import "../Components" //> MultipageModal
import "../Constants"
import App 1.0  //> API.app.self_update_service

MultipageModal
{
    id: root

    readonly property var    self_update_service:      API.app.self_update_service
    readonly property string last_release_tag_name:    self_update_service.last_release_tag_name
    readonly property bool   update_needed:            self_update_service.update_needed
    readonly property bool   update_downloading:       self_update_service.update_downloading
    readonly property real   update_download_progress: self_update_service.update_download_progress
    readonly property bool   update_ready:             self_update_service.update_ready
    property bool            invalid_update_files:     self_update_service.invalid_update_files
    // Display the good modal section according to current self update service state
    function select_index()
    {
        if (invalid_update_files)
        {
            invalid_update_files = false
            currentIndex = 0
            close()
            update_invalid_checksum.open()
        }
        else if (update_ready)
        {
            currentIndex = 4
            visible = true
        }
        else if (update_downloading)
        {
            currentIndex = 3
            visible = true
        }
        else if (update_needed)
        {
            currentIndex = 2
            visible = true
        }
        else if (currentIndex === 1)
        {
            currentIndex = 0
        }
        else
        {
            currentIndex = 1
        }
    }

    // Fetches latest update info when opening this modal.
    onOpened:
    {
        select_index()
        self_update_service.fetch_last_release_info()
    }

    onUpdate_neededChanged: select_index()
    onUpdate_downloadingChanged: select_index()
    onUpdate_readyChanged: select_index()
    onInvalid_update_filesChanged: select_index()

    // Section when fetching update
    MultipageModalContent
    {
        titleText: qsTr("Searching new updates...")
        titleAlignment: Label.AlignHCenter

        DefaultText
        {
            horizontalAlignment: Label.AlignHCenter
            text: qsTr("Please wait while the application is finding a new update... You can close this modal if you want.")
        }
    }

    // Section when no new update is found.
    MultipageModalContent
    {
        titleText: qsTr("Already updated")
        titleAlignment: Label.AlignHCenter


        DefaultText
        {
            horizontalAlignment: Label.AlignHCenter
            Layout.fillWidth: true
            text: qsTr("%1 is already up-to-date !").arg(API.app_name)
        }
        footer:
        [
            DexAppButton
            {
                text: qsTr("Close")
                Layout.alignment: Qt.AlignHCenter
                onClicked: root.visible = false
            }
        ]
    }

    // Second section. Asks user to update its client.
    MultipageModalContent
    {
        titleText: qsTr("New update detected !")

        DefaultText
        {
            Layout.fillWidth: true

            text: qsTr("Do you want to update %1 from %2 to %3 ?")
                    .arg(API.app_name).arg(API.current_version).arg(last_release_tag_name)
        }

        footer:
        [
            PrimaryButton
            {
                text: qsTr("Download")

                onClicked: self_update_service.download_update()
            },
            DefaultButton
            {
                text: qsTr("Remind me later")

                onClicked: root.visible = false
            }
        ]
    }

    // Download progress bar
    MultipageModalContent
    {
        titleText: qsTr("Download in progress...")

        RowLayout
        {
            Layout.fillWidth: true

            ProgressBar
            {
                Layout.fillWidth: true
                value: update_download_progress
            }

            DefaultText
            {
                Layout.preferredWidth: 40
                text: "%1 %".arg(Math.round(update_download_progress * 100))
            }
        }
    }

    // Update download finished... Asks for restart
    MultipageModalContent
    {
        titleText: qsTr("Update downloaded")

        DefaultText
        {
            text: qsTr("Update has been successfully downloaded. Do you want to restart the application now ?")
        }

        footer:
        [
            PrimaryButton
            {
                text: qsTr("Restart now")

                onClicked:
                {
                    self_update_service.perform_update()
                    root.visible = false
                }
            },
            DefaultButton
            {
                text: qsTr("Restart later")

                onClicked: close()
            }
        ]
    }
}
