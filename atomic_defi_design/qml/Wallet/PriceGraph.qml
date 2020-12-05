import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import QtCharts 2.3
import "../Components"
import "../Constants"

// List
ChartView {
    readonly property bool has_data: series.count > 0

    AreaSeries {
        id: series_area2
        color: Style.colorTheme10

        onHovered: updateValueText(state, point.y, axisYRight.labelsColor, 0)

        borderWidth: series_area.borderWidth
        opacity: series_area.opacity

        axisX: series2.axisX
        axisYRight: series2.axisYRight
        upperSeries: series2
    }

    // Other, back
    LineSeries {
        id: series2
        color: Style.colorTheme10

        style: series.style
        width: series.width

        onHovered: updateValueText(state, point.y, axisYRight.labelsColor, 0)

        axisX: DateTimeAxis {
            visible: false
            titleVisible: series.axisX.titleVisible
            lineVisible: series.axisX.lineVisible
            labelsFont: series.axisX.labelsFont
            gridLineColor: series.axisX.gridLineColor
            labelsColor: series.axisX.labelsColor
            format: "MMM d"
        }
        axisYRight: ValueAxis {
            visible: true
            titleVisible: series.axisY.titleVisible
            lineVisible: series.axisY.lineVisible
            labelsFont: series.axisY.labelsFont
            gridLineColor: series.axisY.gridLineColor
            labelsColor: series2.color
            labelFormat:  "%." + General.getRecommendedPrecision(has_data ? parseFloat(historical[historical.length-1].volume_24h / 1000000) : 2, 3) + "f M"
        }
    }

    AreaSeries {
        id: series_area
        color: Style.colorTheme1
        onHovered: updateValueText(state, point.y, axisY.labelsColor, 2)

        borderWidth: 0
        opacity: 0.15

        axisX: series.axisX
        axisY: series.axisY
        upperSeries: series
    }

    // Price, front
    LineSeries {
        id: series
        color: Style.colorGreen

        style: Qt.SolidLine
        width: 1.5

        onHovered: updateValueText(state, point.y, axisY.labelsColor, 2)

        axisX: DateTimeAxis {
            titleVisible: false
            lineVisible: false
            labelsFont.family: Style.font_family
            labelsFont.weight: Font.Bold
            labelsFont.pixelSize: Style.textSizeSmall3
            gridLineColor: Style.colorThemeDark2
            labelsColor: Style.colorThemeDark3
            format: "<br>MMM d"
        }
        axisY: ValueAxis {
            titleVisible: series.axisX.titleVisible
            lineVisible: series.axisX.lineVisible
            labelsFont: series.axisX.labelsFont
            gridLineColor: series.axisX.gridLineColor
            labelsColor: series.color
            labelFormat:  "%." + General.getRecommendedPrecision(has_data ? parseInt(historical[historical.length-1].price) : 2, 6) + "f"
        }
    }

    function updateValueText(state, value, color, precision) {
        value_text.visible = state
        value_text.text = General.formatDouble(value, precision)
        value_text.color = color
    }

    DefaultText {
        id: value_text
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 50
        anchors.leftMargin: anchors.topMargin * 2
        font.pixelSize: Style.textSizeSmall3
    }


    function updateChart(historical) {
        series.clear()
        series2.clear()

        if(historical === undefined) return

        if(historical.length > 0) {
            let min_price = Infinity
            let max_price = -Infinity
            let min_other = Infinity
            let max_other = -Infinity

            for(let i = 0; i < historical.length; ++i) {
                const price = historical[i].price
                const other = historical[i].volume_24h / 1000000

                series.append(General.timestampToDouble(historical[i].timestamp), price)
                series2.append(General.timestampToDouble(historical[i].timestamp), other)

                min_price = Math.min(min_price, price)
                max_price = Math.max(max_price, price)
                min_other = Math.min(min_other, other)
                max_other = Math.max(max_other, other)
            }

            // Date
            series.axisX.min = historical[0].timestamp
            series.axisX.max = historical[historical.length-1].timestamp
            series.axisX.tickCount = 7

            series2.axisX.min = series.axisX.min
            series2.axisX.max = series.axisX.max
            series2.axisX.tickCount = series.axisX.tickCount

            const y_margin = 0.05

            // Price
            series.axisY.min = min_price * (1 - y_margin)
            series.axisY.max = max_price * (1 + y_margin)

            // Other
            series2.axisYRight.min = min_other * (1 - y_margin)
            series2.axisYRight.max = max_other * (1 + y_margin)
        }
    }

    property var historical: current_ticker_infos.trend_7d
    onHistoricalChanged: {
        updateChart(historical)
    }

    id: chart
    antialiasing: true

    legend.visible: false

    backgroundColor: "transparent"
}





/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
