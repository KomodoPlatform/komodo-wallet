import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import Qaterial 1.0 as Qaterial

import Dex.Themes 1.0 as Dex

Calendar
{
    width: 300
    height: 450
    style: CalendarStyle
    {
        gridColor: "transparent"
        gridVisible: false

        background: DefaultRectangle
        {
            color: Dex.CurrentTheme.floatingBackgroundColor
            radius: 18
        }

        navigationBar: DefaultRectangle
        {
            height: 50
            color: Dex.CurrentTheme.floatingBackgroundColor
            radius: 18

            DefaultButton
            {
                id: previousYear
                width: previousMonth.width
                height: width
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                iconSource: Qaterial.Icons.arrowLeft
                onClicked: control.showPreviousYear()
            }

            DefaultButton
            {
                id: previousMonth
                width: parent.height - 14
                height: width
                anchors.left: previousYear.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                iconSource: Qaterial.Icons.arrowLeft
                onClicked: control.showPreviousMonth()
            }

            DefaultText
            {
                id: dateText
                text: styleData.title
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: previousMonth.right
                anchors.leftMargin: 2
                anchors.right: nextMonth.left
                anchors.rightMargin: 2
            }

            DefaultButton
            {
                id: nextYear
                width: nextMonth.width
                height: width
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                iconSource: Qaterial.Icons.arrowRight
                onClicked: control.showNextYear()
            }

            DefaultButton
            {
                id: nextMonth
                width: parent.height - 14
                height: width
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: nextYear.left
                anchors.rightMargin: 2
                iconSource: Qaterial.Icons.arrowRight
                onClicked: control.showNextMonth()
            }
        }

        dayOfWeekDelegate: DefaultRectangle
        {
            color: "transparent"
            implicitHeight: 20
            Label
            {
                text: control.locale.dayName(styleData.dayOfWeek, control.dayOfWeekFormat)
                anchors.centerIn: parent
                color: Dex.CurrentTheme.foregroundColor
            }
        }

        dayDelegate: DefaultRectangle
        {
            anchors.fill: parent
            color: styleData.hasOwnProperty('date') && styleData.selected ? selectedDateColor : styleData.hovered ? hoveredDateColor : "transparent"

            readonly property bool addExtraMargin: control.frameVisible && styleData.selected
            readonly property color sameMonthDateTextColor: Dex.CurrentTheme.foregroundColor
            readonly property color hoveredDateColor: Dex.CurrentTheme.buttonColorHovered
            readonly property color selectedDateColor: Dex.CurrentTheme.buttonColorPressed
            readonly property color selectedDateTextColor: Dex.CurrentTheme.foregroundColor
            readonly property color differentMonthDateTextColor: Dex.CurrentTheme.foregroundColor3
            readonly property color invalidDateColor: Dex.CurrentTheme.textDisabledColor
            DefaultText
            {
                id: dayDelegateText
                text: styleData.hasOwnProperty('date') ? styleData.date.getDate() : ""
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Math.min(parent.height/3, parent.width/3)
                color: {
                    var theColor = invalidDateColor;
                    if (styleData.valid) {
                        // Date is within the valid range.
                        theColor = styleData.visibleMonth ? sameMonthDateTextColor : differentMonthDateTextColor;
                        if (styleData.selected)
                            theColor = selectedDateTextColor;
                    }
                    theColor;
                }
            }
        }
    }
}
