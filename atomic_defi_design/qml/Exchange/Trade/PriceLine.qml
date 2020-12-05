import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"

// Price
RowLayout {
    readonly property string price: non_null_price
    readonly property string price_reversed: API.app.trading_pg.price_reversed
    readonly property string cex_price: API.app.trading_pg.cex_price
    readonly property string cex_price_reversed: API.app.trading_pg.cex_price_reversed
    readonly property string cex_price_diff: API.app.trading_pg.cex_price_diff
    readonly property bool invalid_cex_price: API.app.trading_pg.invalid_cex_price
    readonly property bool price_entered: !General.isZero(non_null_price)

    readonly property int fontSize: Style.textSizeSmall1
    readonly property int fontSizeBigger: Style.textSizeSmall2
    readonly property int line_scale: getComparisonScale(cex_price_diff)

    function getComparisonScale(value) {
        return Math.min(Math.pow(10, General.getDigitCount(parseFloat(value))), 1000000000)
    }

    function limitDigits(value) {
        return parseFloat(General.formatDouble(value, 2))
    }

    DefaultText {
        visible: !price_entered && invalid_cex_price
        Layout.alignment: Qt.AlignHCenter
        text_value: qsTr("Set swap price for evaluation")
        font.pixelSize: fontSizeBigger
    }


    ColumnLayout {
        visible: price_entered
        Layout.alignment: Qt.AlignHCenter

        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: qsTr("Exchange rate") + (preffered_order.price !== undefined ? (" (" + qsTr("Selected") + ")") : "")
            font.pixelSize: fontSize
        }

        // Price reversed
        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: General.formatCrypto("", "1", right_ticker) + " = " + General.formatCrypto("", price_reversed, left_ticker)
            font.pixelSize: fontSizeBigger
            font.weight: Font.Medium
        }

        // Price
        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: General.formatCrypto("", price, right_ticker) + " = " + General.formatCrypto("", "1", left_ticker)
            font.pixelSize: fontSize
        }
    }


    // Price Comparison
    ColumnLayout {
        visible: price_entered && !invalid_cex_price
        Layout.alignment: Qt.AlignHCenter

        DefaultText {
            id: price_diff_text
            Layout.topMargin: 10
            Layout.bottomMargin: Layout.topMargin
            Layout.alignment: Qt.AlignHCenter
            color: parseFloat(cex_price_diff) <= 0 ? Style.colorGreen : Style.colorRed
            text_value: (parseFloat(cex_price_diff) > 0 ? qsTr("Expensive") : qsTr("Expedient")) + ":&nbsp;&nbsp;&nbsp;&nbsp;" + qsTr("%1 compared to CEX", "PRICE_DIFF%").arg("<b>" + General.formatPercent(limitDigits(cex_price_diff)) + "</b>")
            font.pixelSize: fontSize
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            DefaultText {
                text_value: General.formatPercent(line_scale)
                font.pixelSize: fontSize
            }

            GradientRectangle {
                width: 125
                height: 6

                start_color: Style.colorGreen
                end_color: Style.colorRed

                AnimatedRectangle {
                    width: 4
                    height: parent.height * 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: 0.5 * parent.width * Math.min(Math.max(parseFloat(cex_price_diff) / line_scale, -1), 1)
                }
            }

            DefaultText {
                text_value: General.formatPercent(-line_scale)
                font.pixelSize: fontSize
            }
        }
    }





    // CEXchange
    ColumnLayout {
        visible: !invalid_cex_price
        Layout.alignment: Qt.AlignHCenter

        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: General.cex_icon + " " + qsTr("CEXchange rate")
            font.pixelSize: fontSize

            CexInfoTrigger {}
        }

        // Price reversed
        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: General.formatCrypto("", "1", right_ticker) + " = " + General.formatCrypto("", cex_price_reversed, left_ticker)
            font.pixelSize: fontSizeBigger
            font.weight: Font.Medium
        }

        // Price
        DefaultText {
            Layout.alignment: Qt.AlignHCenter
            text_value: General.formatCrypto("", cex_price, right_ticker) + " = " + General.formatCrypto("", "1", left_ticker)
            font.pixelSize: fontSize
        }
    }
}
