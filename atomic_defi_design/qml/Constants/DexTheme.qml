pragma Singleton

import QtQuick 2.15

QtObject {

    // Main Color 

    property string theme: "dark"

    property color accentColor: Style.colorTheme4
    property color backgroundColor: Style.colorTheme7
    property color foregroundColor: Style.colorText
    property color primaryColor: accentColor


    property color backgroundLightColor0: backgroundColor
    property color backgroundLightColor1: Qt.darker(backgroundColor, 0.9)
    property color backgroundLightColor2: Qt.darker(backgroundColor, 0.8)
    property color backgroundLightColor3: Qt.darker(backgroundColor, 0.7)
    property color backgroundLightColor4: Qt.darker(backgroundColor, 0.6)
    property color backgroundLightColor5: Qt.darker(backgroundColor, 0.5)

    property color backgroundDarkColor0: backgroundColor
    property color backgroundDarkColor1: Qt.lighter(backgroundColor, 0.9)
    property color backgroundDarkColor2: Qt.lighter(backgroundColor, 0.8)
    property color backgroundDarkColor3: Qt.lighter(backgroundColor, 0.7)
    property color backgroundDarkColor4: Qt.lighter(backgroundColor, 0.6)
    property color backgroundDarkColor5: Qt.lighter(backgroundColor, 0.5)
    property color backgroundDarkColor6: Qt.lighter(backgroundColor, 0.4)
    property color backgroundDarkColor7: Qt.lighter(backgroundColor, 0.3)
    property color backgroundDarkColor8: Qt.lighter(backgroundColor, 0.2)
    property color backgroundDarkColor9: Qt.lighter(backgroundColor, 0.1)

    property color accentLightColor0: accentColor
    property color accentLightColor1: Qt.darker(accentColor, 0.9)
    property color accentLightColor2: Qt.darker(accentColor, 0.8)
    property color accentLightColor3: Qt.darker(accentColor, 0.7)
    property color accentLightColor4: Qt.darker(accentColor, 0.6)
    property color accentLightColor5: Qt.darker(accentColor, 0.5)

    property color accentDarkColor0: accentColor
    property color accentDarkColor1: Qt.lighter(accentColor, 0.9)
    property color accentDarkColor2: Qt.lighter(accentColor, 0.8)
    property color accentDarkColor3: Qt.lighter(accentColor, 0.7)
    property color accentDarkColor4: Qt.lighter(accentColor, 0.6)
    property color accentDarkColor5: Qt.lighter(accentColor, 0.5)
    property color accentDarkColor6: Qt.lighter(accentColor, 0.4)
    property color accentDarkColor7: Qt.lighter(accentColor, 0.3)
    property color accentDarkColor8: Qt.lighter(accentColor, 0.2)
    property color accentDarkColor9: Qt.lighter(accentColor, 0.1)

    property color primaryColorLightColor0: primaryColor
    property color primaryColorLightColor1: Qt.darker(primaryColor, 0.9)
    property color primaryColorLightColor2: Qt.darker(primaryColor, 0.8)
    property color primaryColorLightColor3: Qt.darker(primaryColor, 0.7)
    property color primaryColorLightColor4: Qt.darker(primaryColor, 0.6)
    property color primaryColorLightColor5: Qt.darker(primaryColor, 0.5)

    property color primaryColorDarkColor0: primaryColor
    property color primaryColorDarkColor1: Qt.lighter(primaryColor, 0.9)
    property color primaryColorDarkColor2: Qt.lighter(primaryColor, 0.8)
    property color primaryColorDarkColor3: Qt.lighter(primaryColor, 0.7)
    property color primaryColorDarkColor4: Qt.lighter(primaryColor, 0.6)
    property color primaryColorDarkColor5: Qt.lighter(primaryColor, 0.5)
    property color primaryColorDarkColor6: Qt.lighter(primaryColor, 0.4)
    property color primaryColorDarkColor7: Qt.lighter(primaryColor, 0.3)
    property color primaryColorDarkColor8: Qt.lighter(primaryColor, 0.2)
    property color primaryColorDarkColor9: Qt.lighter(primaryColor, 0.1)

    property color foregroundColorLightColor0: foregroundColor
    property color foregroundColorLightColor1: Qt.darker(foregroundColor, 0.9)
    property color foregroundColorLightColor2: Qt.darker(foregroundColor, 0.8)
    property color foregroundColorLightColor3: Qt.darker(foregroundColor, 0.7)
    property color foregroundColorLightColor4: Qt.darker(foregroundColor, 0.6)
    property color foregroundColorLightColor5: Qt.darker(foregroundColor, 0.5)

    property color foregroundColorDarkColor0: foregroundColor
    property color foregroundColorDarkColor1: Qt.lighter(foregroundColor, 0.9)
    property color foregroundColorDarkColor2: Qt.lighter(foregroundColor, 0.8)
    property color foregroundColorDarkColor3: Qt.lighter(foregroundColor, 0.7)
    property color foregroundColorDarkColor4: Qt.lighter(foregroundColor, 0.6)
    property color foregroundColorDarkColor5: Qt.lighter(foregroundColor, 0.5)
    property color foregroundColorDarkColor6: Qt.lighter(foregroundColor, 0.4)
    property color foregroundColorDarkColor7: Qt.lighter(foregroundColor, 0.3)
    property color foregroundColorDarkColor8: Qt.lighter(foregroundColor, 0.2)
    property color foregroundColorDarkColor9: Qt.lighter(foregroundColor, 0.1)

    property color headTextColor: accentColor

    property color proviewItemBoxBackgroundColor: dexBoxBackgroundColor
    property color proviewItemBoxBorderColor: 'transparent'
    property color proviewItemBoxTitleColor: headTextColor
    property color proviewItemBoxIconColor: accentColor
    property int proviewItemBoxBorderWidth: 0

    property color comboBoxBorderColor: rectangleBorderColor
    property color comboBoxBackgroundColor: dexBoxBackgroundColor


    property bool walletSidebarShadowVisibility: true
    property color walletSidebarLeftBorderColor: backgroundColorDeep


    property color leftSidebarBorderColor: rectangleBorderColor
    property color sideBarRightBorderColor: rectangleBorderColor
    property int sidebarHightLightHeight: 44


    property color contentColorTop: backgroundColor
    property color contentColorTopBold: backgroundColor
    property color tabBarBackgroudColor: accentColor
    property color tradeFieldBoxBackgroundColor: backgroundColor
    property color iconButtonColor: buttonColorEnabled
    property color iconButtonForegroundColor: buttonColorTextEnabled

    property bool portfolioPieGradient: false

    property color arrowUpColor: redColor
    property color arrowDownColor: greenColor



 // Old Theme
    property string chartTheme: Style.dark_theme ? "dark" : "light"
    
    property color surfaceColor: backgroundDarkColor2
    property color backgroundColorDeep: backgroundDarkColor2
    property color dexBoxBackgroundColor: backgroundDarkColor6//Style.colorTheme9

    property color hightlightColor: accentDarkColor3
    property color hoverColor: buttonColorHovered
    property color modalStepColor: accentColor
    property color modelStepBorderColor: hightlightColor

    property int sidebarShadowRadius: 32

    property color sideBarGradient1: DexTheme.primaryColorDarkColor8
    property color sideBarGradient2: DexTheme.primaryColorDarkColor4
    property real sideBarAnimationDuration: Style.animationDuration

    property color navigationSideBarButtonGradient1: DexTheme.accentLightColor2
    property color navigationSideBarButtonGradient2: DexTheme.accentLightColor1
    property color navigationSideBarButtonGradient3: DexTheme.accentDarkColor2
    property color navigationSideBarButtonGradient4: Style.colorSidebarHighlightGradient4

    property color chartTradingLineColor: Style.colorTrendingLine
    property color chartTradingLineBackgroundColor: Style.colorTrendingUnderLine
    property color lineChartColor: accentColor
    property color chartGridLineColor: Qt.rgba(255,255,255,0.4)

    
    // Button
    property color buttonColorDisabled: DexTheme.accentDarkColor5
    property color buttonColorHovered: DexTheme.accentLightColor4
    property color buttonColorPressed: DexTheme.accentDarkColor4
    property color buttonColorEnabled: DexTheme.accentLightColor2
    property color buttonColorTextDisabled: DexTheme.backgroundDarkColor7
    property color buttonColorTextHovered: DexTheme.backgroundDarkColor8
    property color buttonColorTextEnabled: DexTheme.backgroundDarkColor9
    property color buttonColorTextPressed: DexTheme.backgroundDarkColor0

    property color buttonGradientEnabled1: DexTheme.buttonColorEnabled
    property color buttonGradientEnabled2: DexTheme.buttonColorEnabled
    property color buttonGradientTextEnabled: DexTheme.foregroundColor




    property color colorInnerShadowBottom: Style.colorRectangleBorderGradient1
    property color colorInnerShadowTop: Style.colorRectangleBorderGradient2

    property color colorSidebarDropShadow: Style.colorSidebarDropShadow

    property color barColor: Style.colorTheme5

    property color colorLineGradient1: Style.colorLineGradient1
    property color colorLineGradient2: Style.colorLineGradient2
    property color colorLineGradient3: Style.colorLineGradient3
    property color colorLineGradient4: Style.colorLineGradient4

    property color floatShadow1: Style.colorDropShadowLight
    property color floatShadow2: Style.colorDropShadowLight2
    property color floatBoxShadowDark: Style.colorDropShadowDark

    property color textSelectionColor: Style.colorSelection
    property color textPlaceHolderColor: Style.colorPlaceholderText
    property color textSelectedColor: Style.colorSelectedText
    property color innerShadowColor: Style.colorInnerShadow

    property color whiteblack: Style.colorWhite1
    property color colorThemeDarkLight: Style.colorThemeDarkLight

    property color rectangleBorderColor: DexTheme.backgroundDarkColor2

    property color colorScrollbarGradient1: Style.colorScrollbarGradient1
    property color colorScrollbarGradient2: Style.colorScrollbarGradient2

    property color greenColor: Style.colorGreen
    property color redColor: Style.colorRed

    // Widget settings 

    property int rectangleRadius: Style.rectangleCornerRadius

    // Other Data

    property string bigSidebarLogo: "dex-logo-sidebar.png"
    property string smallSidebarLogo: "dex-logo.png"





















    // Old

    function setQaterialStyle() {
        Qaterial.Style.accentColorLight = Style.colorTheme4
        Qaterial.Style.accentColorDark = Style.colorTheme4
    }

    onDark_themeChanged: setQaterialStyle()


    readonly property string listItemPrefix:  " ⚬   "
    readonly property string successCharacter:  "✓"
    readonly property string failureCharacter:  "✘"
    readonly property string warningCharacter:  "⚠"

    readonly property int animationDuration: 125

    readonly property int textSizeVerySmall1: 1
    readonly property int textSizeVerySmall2: 2
    readonly property int textSizeVerySmall3: 3
    readonly property int textSizeVerySmall4: 4
    readonly property int textSizeVerySmall5: 5
    readonly property int textSizeVerySmall6: 6
    readonly property int textSizeVerySmall7: 7
    readonly property int textSizeVerySmall8: 8
    readonly property int textSizeVerySmall9: 9
    readonly property int textSizeSmall: 10
    readonly property int textSizeSmall1: 11
    readonly property int textSizeSmall2: 12
    readonly property int textSizeSmall3: 13
    readonly property int textSizeSmall4: 14
    readonly property int textSizeSmall5: 15
    readonly property int textSize: 16
    readonly property int textSizeMid: 17
    readonly property int textSizeMid1: 18
    readonly property int textSizeMid2: 19
    readonly property int textSize1: 20
    readonly property int textSize2: 24
    readonly property int textSize3: 36
    readonly property int textSize4: 48
    readonly property int textSize5: 60
    readonly property int textSize6: 72
    readonly property int textSize7: 84
    readonly property int textSize8: 96
    readonly property int textSize9: 108
    readonly property int textSize10: 120
    readonly property int textSize11: 132
    readonly property int textSize12: 144

    readonly property int rectangleCornerRadius: 7
    readonly property int itemPadding: 12
    readonly property int buttonSpacing: 12
    readonly property int rowSpacing: 12
    readonly property int rowSpacingSmall: 6
    readonly property int iconTextMargin: 5
    readonly property int sidebarLineHeight: 44
    readonly property double hoverLightMultiplier: 1.5
    readonly property double hoverOpacity: 0.6

    property bool dark_theme: true


    function applyOpacity(hex, opacity="00") {
        return "#" + opacity + hex.substr(hex.length - 6)
    }

    function colorOnlyIf(condition, color) {
        return applyOpacity(color, condition ? "FF" : "00")
    }

    readonly property string colorQtThemeAccent: colorGreen
    readonly property string colorQtThemeForeground: colorWhite1
    readonly property string colorQtThemeBackground: colorTheme9

    readonly property string sidebar_atomicdex_logo: dark_theme ? "dex-logo-sidebar.png" : "dex-logo-sidebar-dark.png"
    readonly property string colorRed: dark_theme ? "#D13990" : "#9a1165" // Light is 15% darker than Red2, same with the green set
    readonly property string colorRed2:  dark_theme ? "#b61477" : "#b61477"
    readonly property string colorRed3:  dark_theme ? "#6d0c47" : "#D13990"
    readonly property string colorYellow:  dark_theme ? "#FFC305" : "#FFC305"
    readonly property string colorOrange:  dark_theme ? "#F7931A" : "#F7931A"
    readonly property string colorBlue:  dark_theme ? "#3B78D1" : "#3B78D1"
    readonly property string colorGreen:  dark_theme ? "#74FBEE" : "#109f8d"
    readonly property string colorGreen2:  dark_theme ? "#14bca6" : "#14bca6"
    readonly property string colorGreen3:  dark_theme ? "#07433b" : "#74FBEE"

    readonly property string colorWhite1:  dark_theme ? "#FFFFFF" : "#000000"
    readonly property string colorWhite2:  dark_theme ? "#F9F9F9" : "#111111"
    readonly property string colorWhite3:  dark_theme ? "#F0F0F0" : "#222222"
    readonly property string colorWhite4:  dark_theme ? "#C9C9C9" : "#333333"
    readonly property string colorWhite5:  dark_theme ? "#8E9293" : "#444444"
    readonly property string colorWhite6:  dark_theme ? "#777777" : "#555555"
    readonly property string colorWhite7:  dark_theme ? "#666666" : "#666666"
    readonly property string colorWhite8:  dark_theme ? "#555555" : "#777777"
    readonly property string colorWhite9:  dark_theme ? "#444444" : "#8E9293"
    readonly property string colorWhite10:  dark_theme ? "#333333" : "#C9C9C9"
    readonly property string colorWhite11:  dark_theme ? "#222222" : "#F0F0F0"
    readonly property string colorWhite12:  dark_theme ? "#111111" : "#F9F9F9"
    readonly property string colorWhite13:  dark_theme ? "#000000" : "#FFFFFF"

    readonly property string colorTheme1:  dark_theme ? "#3CC9BF" : "#3CC9BF"
    readonly property string colorTheme2:  dark_theme ? "#36A8AA" : "#36A8AA"
    readonly property string colorTheme3:  dark_theme ? "#318795" : "#318795"
    readonly property string colorTheme4:  dark_theme ? "#2B6680" : "#2B6680"
    readonly property string colorTheme5:  dark_theme ? "#23273C" : "#ececf2"
    readonly property string colorTheme6:  dark_theme ? "#22263A" : "#efeff5"
    readonly property string colorTheme7:  dark_theme ? "#15182A" : "#f2f2f7"
    readonly property string colorTheme8:  dark_theme ? "#171A2C" : "#f6f6f9"
    readonly property string colorTheme9:  dark_theme ? "#0E1021" : "#F9F9FB"
    readonly property string colorTheme99:  dark_theme ? "#2A2C3B" : "#F9F9FB"

    readonly property string colorTheme10:  dark_theme ? "#2579E0" : "#2579E0"
    readonly property string colorTheme11:  dark_theme ? "#00A3FF" : "#00A3FF"
    readonly property string colorThemeLine:  dark_theme ? "#1D1F23" : "#1D1F23"
    readonly property string colorThemePassive:  dark_theme ? "#777F8C" : "#777F8C"
    readonly property string colorThemePassiveLight:  dark_theme ? "#CCCDD0" : "#CCCDD0"
    readonly property string colorThemeDark:  dark_theme ? "#26282C" : "#26282C"
    readonly property string colorThemeDark2:  dark_theme ? "#3C4150" : "#E6E8ED"
    readonly property string colorThemeDark3:  dark_theme ? "#78808D" : "#78808D"
    //readonly property string colorThemeDarkLight:  dark_theme ? "#78808D" : "#456078"

    readonly property string colorRectangle:  dark_theme ? colorTheme7 : colorTheme7
    readonly property string colorInnerBackground:  dark_theme ? colorTheme7 : colorTheme7

    readonly property string colorGradient1:  dark_theme ? colorTheme9 : colorTheme9
    readonly property string colorGradient2:  dark_theme ? colorTheme5 : colorTheme5
    readonly property string colorGradient3:  dark_theme ? "#24283D" : "#24283D"
    readonly property string colorGradient4:  dark_theme ? "#0D0F21" : "#0D0F21"
    //readonly property string colorLineGradient1:  dark_theme ? "#2c2f3c" : "#EEF1F7"
    //readonly property string colorLineGradient2:  dark_theme ? "#06070c" : "#DCE1E8"
    //readonly property string colorLineGradient3:  dark_theme ? "#090910" : "#EEF1F7"
    //readonly property string colorLineGradient4:  dark_theme ? "#24283b" : "#DCE1E8"
    readonly property string colorDropShadowLight:  dark_theme ? "#216975a4" : "#21FFFFFF"
    readonly property string colorDropShadowLight2:  dark_theme ? "#606975a4" : "#60FFFFFF"
    readonly property string colorDropShadowDark:  dark_theme ? "#FF050615" : "#BECDE2"
    readonly property string colorBorder:  dark_theme ? "#23273B" : "#DAE1EC"
    readonly property string colorBorder2:  dark_theme ? "#1C1F32" : "#DAE1EC"

    readonly property string colorInnerShadow:  dark_theme ? "#A0000000" : "#BECDE2"

    readonly property string colorGradientLine1:  dark_theme ? "#00FFFFFF" : "#00CFD4DB"
    readonly property string colorGradientLine2:  dark_theme ? "#0FFFFFFF" : "#FFCFD4DB"

    readonly property string colorWalletsHighlightGradient:  dark_theme ? "#1B5E7D" : "#1B5E7D"
    readonly property string colorWalletsSidebarDropShadow:  dark_theme ? "#B0000000" : "#BECDE2"

    readonly property string colorScrollbar:  dark_theme ? "#202339" : "#C4CCDA"
    readonly property string colorScrollbarBackground:  dark_theme ? "#10121F" : "#EFF1F6"

    readonly property string colorSidebarIconHighlighted:  dark_theme ? "#2BBEF2" : "#FFFFFF"
    readonly property string colorSidebarHighlightGradient1:  dark_theme ? "#FF1B5E7D" : "#8b95ed"
    readonly property string colorSidebarHighlightGradient2:  dark_theme ? "#BA1B5E7D" : "#AD7faaf0"
    readonly property string colorSidebarHighlightGradient3:  dark_theme ? "#5F1B5E7D" : "#A06dc9f3"
    readonly property string colorSidebarHighlightGradient4:  dark_theme ? "#001B5E7D" : "#006bcef4"
    //readonly property string colorSidebarDropShadow:  dark_theme ? "#90000000" : "#BECDE2"
    readonly property string colorSidebarSelectedText:  dark_theme ? "#FFFFFF" : "#FFFFFF"

    readonly property string colorCoinListHighlightGradient:  dark_theme ? "#2C2E40" : "#E0E6F0"

    readonly property string colorRectangleBorderGradient1:  dark_theme ? "#2A2F48" : "#DDDDDD"
    readonly property string colorRectangleBorderGradient2:  dark_theme ? "#0D1021" : "#EFEFEF"

    readonly property string colorChartText:  dark_theme ? "#405366" : "#B5B9C1"
    readonly property string colorChartLegendLine:  dark_theme ? "#3F5265" : "#BDC0C8"
    readonly property string colorChartGrid:  dark_theme ? "#202333" : "#E6E8ED"
    readonly property string colorChartLineText:  dark_theme ? "#405366" : "#FFFFFF"

    readonly property string colorChartMA1:  dark_theme ? "#5BC6FA" : "#5BC6FA"
    readonly property string colorChartMA2:  dark_theme ? "#F1D17F" : "#F1D17F"

    readonly property string colorLineBasic:  dark_theme ? "#303344" : "#303344"


    readonly property string colorText: dark_theme ? Style.colorWhite1 : "#405366"
    readonly property string colorText2: dark_theme ? "#79808C" : "#3C5368"
    readonly property string colorTextDisabled: dark_theme ? Style.colorWhite8 : "#B5B9C1"
    readonly property var colorButtonDisabled: ({
          "default": Style.colorTheme9,
          "primary": Style.colorGreen3,
          "danger": Style.colorRed3
        })
    readonly property var colorButtonHovered: ({
          "default": Style.colorTheme6,
          "primary": Style.colorGreen,
          "danger": Style.colorRed
        })
    readonly property var colorButtonEnabled: ({
          "default": Style.colorRectangle,
          "primary": Style.colorGreen2,
          "danger": Style.colorRed2
        })
    readonly property var colorButtonTextDisabled: ({
          "default": Style.colorWhite8,
          "primary": Style.colorWhite13,
          "danger": Style.colorWhite13
        })
    readonly property var colorButtonTextHovered: ({
          "default": Style.colorText,
          "primary": Style.colorWhite11,
          "danger": Style.colorWhite11
        })
    readonly property var colorButtonTextEnabled: ({
          "default": Style.colorText,
          "primary": Style.colorWhite11,
          "danger": Style.colorWhite11
        })
    readonly property string colorPlaceholderText: Style.colorWhite9
    readonly property string colorSelectedText: Style.colorTheme9
    readonly property string colorSelection: Style.colorGreen2

    readonly property string colorTrendingLine: dark_theme ? Style.colorGreen : "#37a6ef"
    readonly property string colorTrendingUnderLine: dark_theme ? Style.colorGradient3 : "#e3f2fd"

    readonly property string modalValueColor: colorWhite4

    function getValueColor(v) {
        v = parseFloat(v)
        if(v !== 0)
            return v > 0 ? greenColor : redColor

        return Style.colorWhite4
    }

    function getCoinColor(ticker) {
        const c = colorCoin[ticker]
        return c || Style.colorTheme2
    }

    readonly property var colorCoin: ({
                                          "ARPA": "#CCD9E2",
                                          "BCH": "#8DC351",
                                          "BTC": "#F7931A",
                                          "CLC": "#0970DC",
                                          "FTC": "#FFFFFF",
                                          "GLEEC": "#8C41FF",
                                          "GRS": "#377E96",
                                          "DOGE": "#C3A634",
                                          "ETH": "#627EEA",
                                          "KMD": "#2B6680",
                                          "MORTY": "#A4764D",
                                          "RICK": "#A5CBDD",
                                          "EMC2": "#00CCFF",
                                          "DASH": "#008CE7",
                                          "RVN": "#384182",
                                          "DGB": "#006AD2",
                                          "FIRO": "#BB2100",
                                          "LTC": "#BFBBBB",
                                          "ZEC": "#ECB244",
                                          "ZER": "#FFFFFF",
                                          "NAV": "#7D59B5",
                                          "DP": "#E41D25",
                                          "ECA": "#A915DC",
                                          "QTUM": "#2E9AD0",
                                          "CHIPS": "#598182",
                                          "AXE": "#C63877",
                                          "PANGEA": "#D88245",
                                          "JUMBLR": "#2B4649",
                                          "DEX": "#43B7B6",
                                          "COQUI": "#79A541",
                                          "CRYPTO": "#F58736",
                                          "LABS": "#C1F6E1",
                                          "MGW": "#854F2F",
                                          "MONA": "#DEC799",
                                          "NMC": "#186C9D",
                                          "RFOX": "#D83331",
                                          "BOTS": "#F69B57",
                                          "MCL": "#EA0000",
                                          "CCL": "#FFE400",
                                          "BET": "#F69B57",
                                          "SUPERNET": "#F69B57",
                                          "OOT": "#25AAE1",
                                          "REVS": "#F69B57",
                                          "ILN": "#523170",
                                          "VRSC": "#3164D3",
                                          "THC": "#819F6F",
                                          "1INCH": "#95A7C5",
                                          "BAT": "#FF5000",
                                          "BUSD": "#EDB70B",
                                          "DAI": "#B68900",
                                          "USDC": "#317BCB",
                                          "PAX": "#EDE70A",
                                          "SUSHI": "#E25DA8",
                                          "TUSD": "#2E3181",
                                          "AWC": "#31A5F6",
                                          "VRA": "#D70A41",
                                          "SPACE": "#E44C65",
                                          "QC": "#00D7B3",
                                          "PBC": "#64A3CB",
                                          "AAVE": "#9C64A6",
                                          "ANT": "#33DAE6",
                                          "AGI": "#6815FF",
                                          "BAND": "#526BFF",
                                          "BLK": "#191919",
                                          "BNT": "#000D2B",
                                          "BTCZ": "#F5B036",
                                          "CEL": "#4055A6",
                                          "CENNZ": "#2E87F1",
                                          "COMP": "#00DBA3",
                                          "CRO": "#243565",
                                          "CVC": "#3AB03E",
                                          "CVT": "#4B0082",
                                          "DODO": "#FFF706",
                                          "ELF": "#2B5EBB",
                                          "ENJ": "#6752C3",
                                          "EURS": "#2F77ED",
                                          "FUN": "#EF1C70",
                                          "GNO": "#00B0CC",
                                          "HOT": "#983EFF",
                                          "IOTX": "#00CDCE",
                                          "KNC": "#117980",
                                          "LEO": "#F79B2C",
                                          "LINK": "#356CE4",
                                          "LRC": "#32C2F8",
                                          "MANA": "#FF3C6C",
                                          "MATIC": "#1E61ED",
                                          "MED": "#00B5FF",
                                          "MKR": "#1BAF9F",
                                          "NPXS": "#F3CB00",
                                          "POWR": "#05BCAA",
                                          "QI": "#FFFFFF",
                                          "QIAIR": "#FEFEFE",
                                          "QKC": "#2175B4",
                                          "QNT": "#46DDC8",
                                          "REP": "#0E0E21",
                                          "REV": "#78034D",
                                          "RLC": "#FFE100",
                                          "SFUSD": "#9881B8",
                                          "SNT": "#596BED",
                                          "SNX": "#00D1FF",
                                          "SOULJA": "#8F734A",
                                          "STORJ": "#2683FF",
                                          "TSL": "#64B082",
                                          "VRM": "#586A7A",
                                          "WSB": "#FEBB84",
                                          "WBTC": "#CCCCCC",
                                          "YFI": "#006BE6",
                                          "ZRX": "#302C2C",
                                          "UNI": "#FF007A"
                                      })
}