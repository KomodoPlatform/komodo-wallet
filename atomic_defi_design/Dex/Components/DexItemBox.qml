import QtQuick 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import "../Exchange/Trade/"
import "../Constants/"
as Constants

InnerBackground {
    id: _control
    border.width: 1.1
    signal reload()

    property bool hideHeader: false
    property bool visibility: isVertical ? height >= 40 ? true : false : width >= 40 ? true : false
    property bool hidden: false
    property bool expandedVert: false
    property bool expandedHort: false
    property bool showed: true
    property bool duplicable: false
    property bool closable: false
    property bool expandable: true
    property string title: "Default Title"
    property int minimumHeight: isVertical ? 40 : 250
    property int minimumWidth: isVertical ? 40 : 250
    property int maximumHeight: 9999999
    property int maximumWidth: 9999999
    property int defaultHeight: 250
    property int defaultWidth: 250
    property bool reloadable: false
    property bool contentVisible: !hidden

    property bool isVertical: _control.parent.parent.orientation === Qt.Vertical
    function setHeight(height) {
        SplitView.preferredHeight = height
    }

    function setWidth(width) {
        SplitView.preferredWidth = width
    }

    onHiddenChanged: {
        if (isVertical && hidden) {
            SplitView.preferredHeight = 40
            SplitView.minimumHeight = 40
            SplitView.maximumHeight = 40
        } else if (isVertical && !hidden) {
            SplitView.preferredHeight = defaultHeight
            SplitView.minimumHeight = minimumHeight
            SplitView.maximumHeight = maximumHeight
            SplitView.fillHeight = true
            SplitView.view.update()
        } else if (!isVertical && hidden) {
            SplitView.preferredWidth = 40
            SplitView.minimumWidth = 40
            SplitView.maximumWidth = 40
        } else if (!isVertical && !hidden) {
            SplitView.preferredWidth = defaultWidth
            SplitView.minimumWidth = minimumWidth
            SplitView.maximumWidth = maximumWidth
            SplitView.fillWidth = true

        }
    }

    //shadowOff: true
    color: DexTheme.portfolioPieGradient ? 'transparent' : DexTheme.backgroundDarkColor6
    property alias titleLabel: _texto

    onExpandedVertChanged: {
        if (expandedVert) {
            if (DefaultSplitView.view != null) {
                for (var i = 0; i < DefaultSplitView.view.children.length; i++) {
                    if (DefaultSplitView.view.children[i] !== _control) {
                        try {
                            DefaultSplitView.view.children[i].expandedVert = false
                        } catch (e) {}

                    }
                }
                SplitView.fillHeight = true
            }
        } else {
            SplitView.fillHeight = false
        }
    }
    onExpandedHortChanged: {
        if (expandedHort) {
            if (DefaultSplitView.view != null) {
                for (var i = 0; i < SplitView.view.children.length; i++) {
                    if (SplitView.view.children[i] !== _control) {
                        try {
                            SplitView.view.children[i].expandedHort = false
                        } catch (e) {}
                    }
                }
                SplitView.fillHeight = true
            }
        } else {
            SplitView.fillHeight = false
        }
    }



    Behavior on SplitView.preferredHeight {
        SmoothedAnimation {
            duration: 200

        }
    }
    Behavior on SplitView.preferredWidth {
        SmoothedAnimation {
            duration: 200

        }
    }
    Component.onCompleted: {
        SplitView.minimumHeight = minimumHeight
        SplitView.minimumWidth = minimumWidth
        SplitView.maximumHeight = maximumHeight
        SplitView.maximumWidth = maximumWidth
        SplitView.preferredHeight = defaultHeight
        SplitView.preferredWidth = defaultWidth
        SplitView.fillHeight = expandedVert ? true : false
        SplitView.fillWidth = expandedHort ? true : false
    }


    //SplitView.maximumWidth: maximumWidth
    property Component contentItem

    radius: 8
    ClipRRect {
        anchors.fill: parent
        radius: parent.radius

        Rectangle {
            width: parent.width
            height: 40
            radius: parent.parent.height < 41 ? parent.parent.radius : 0
            color: DexTheme.portfolioPieGradient ? 'transparent' : DexTheme.backgroundDarkColor6
            visible: visibility && !_control.hideHeader
            RowLayout {
                anchors.fill: parent
                Layout.rightMargin: 10
                Layout.leftMargin: 10
                DefaultText {
                    id: _texto
                    leftPadding: 10
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: _control.title
                    color: DexTheme.foregroundColor
                    bottomPadding: 5
                }
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    opacity: .8
                    spacing: -8
                    Qaterial.AppBarButton {
                        Timer {
                            id: _tm
                            interval: 5000
                            running: false
                            onTriggered: {
                                parent.enabled = true
                            }
                        }

                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.reloadable
                        icon.source: Qaterial.Icons.refresh
                        onClicked: {
                            _tm.restart()
                            enabled = false
                            _control.reload()

                        }
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        icon.source: _control.expandable ? Qaterial.Icons.eyeOutline : Qaterial.Icons.eyeOffOutline
                        onClicked: _control.hidden = !_control.hidden
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.expandable && _control.parent.parent.orientation === Qt.Vertical
                        icon.source: _control.expandedVert ? Qaterial.Icons.unfoldLessHorizontal : Qaterial.Icons.unfoldMoreHorizontal
                        onClicked: _control.expandedVert = !_control.expandedVert
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.expandable && _control.parent.parent.orientation === Qt.Horizontal
                        icon.source: _control.expandedHort ? Qaterial.Icons.unfoldLessVertical : Qaterial.Icons.unfoldMoreVertical
                        onClicked: _control.expandedHort = !_control.expandedHort
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.duplicable
                        icon.source: Qaterial.Icons.plus
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.closable
                        icon.source: Qaterial.Icons.close
                    }
                }
            }
        }
        Rectangle {
            width: 40
            height: parent.height
            anchors.right: parent.right
            radius: parent.parent.height < 41 ? parent.parent.radius : 0
            color: DexTheme.backgroundDarkColor6
            visible: !isVertical && hidden
            DefaultText {
                id: _texto2
                leftPadding: 10
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: _control.title
                color: DexTheme.foregroundColor
                bottomPadding: 5
                rotation: 90
                anchors.centerIn: parent
            }
            ColumnLayout {
                anchors.fill: parent
                Layout.rightMargin: 10
                Layout.leftMargin: 10
                Column {
                    opacity: .8
                    spacing: -8

                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        icon.source: _control.expandable ? Qaterial.Icons.eyeOutline : Qaterial.Icons.eyeOffOutline
                        onClicked: {
                            _control.hidden = !_control.hidden
                        }
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.expandable && _control.parent.parent.orientation === Qt.Vertical
                        icon.source: _control.expandedVert ? Qaterial.Icons.unfoldLessHorizontal : Qaterial.Icons.unfoldMoreHorizontal
                        onClicked: _control.expandedVert = !_control.expandedVert
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.expandable && _control.parent.parent.orientation === Qt.Horizontal
                        icon.source: _control.expandedHort ? Qaterial.Icons.unfoldLessVertical : Qaterial.Icons.unfoldMoreVertical
                        onClicked: _control.expandedHort = !_control.expandedHort
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.duplicable
                        icon.source: Qaterial.Icons.plus
                    }
                    Qaterial.AppBarButton {
                        implicitHeight: 40
                        implicitWidth: 40
                        icon.height: 17
                        icon.width: 17
                        foregroundColor: DexTheme.foregroundColor
                        visible: _control.closable
                        icon.source: Qaterial.Icons.close
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
        Item {
            anchors.fill: parent
            visible: contentVisible
            Loader {
                id: _loader
                anchors.fill: parent
                anchors.topMargin: 40

                sourceComponent: _control.contentItem
            }
            LoaderBusyIndicator {
                target: _loader
            }
        }


    }
}