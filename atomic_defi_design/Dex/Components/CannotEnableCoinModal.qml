//! Qt Imports
import QtQuick 2.12
import QtQuick.Layouts 1.15

MultipageModal
{
    property string coin_to_enable_ticker           // The coin you tried to enable.
    property var    settings_modal: setting_modal   // A reference to a SettingModal object. Open when "Increase limit in settings" button is clicked.

    id: root
    width: 600

    MultipageModalContent
    {
        titleText: qsTr("Failed to enable %1").arg(coin_to_enable_ticker)
        DefaultText
        {
            Layout.fillWidth: true
            text: qsTr("Enabling %1 did not succeed. Limit of enabled coins might have been reached.")
                    .arg(coin_to_enable_ticker)
        }
        RowLayout
        {
            Layout.fillWidth: true
            DefaultButton
            {
                Layout.fillWidth: true
                text: qsTr("Change limit in settings")
                onClicked:
                {
                    settings_modal.open()
                    close()
                }
            }
            CancelButton
            {
                Layout.fillWidth: true
                text: qsTr("Cancel")
                onClicked: close()
            }
        }
    }

}
