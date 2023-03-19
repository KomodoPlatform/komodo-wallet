import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../Components"
import "../Constants"
import App 1.0
import Dex.Themes 1.0 as Dex

ColumnLayout
{
    id: root
    property string linkURL: ""
    property string onCopyNotificationTitle: ""
    property alias title: title.text
    property alias model: list.model
    property real  addressFontSize: 12

    TitleText
    {
        id: title
        color: Dex.CurrentTheme.foregroundColor2
    }

    ListView
    {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: contentItem.childrenRect.height

        clip: true

        delegate: TextEditWithCopy
        {
            id: address_text
            text_value: model.modelData
            privacy: true
            font_size: 13
            align_left: true
            text_box_width: 600
            linkURL: root.linkURL
            onCopyNotificationTitle: root.onCopyNotificationTitle
        }
    }
}
