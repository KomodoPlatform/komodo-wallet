pragma Singleton
import QtQuick 2.15
import Qaterial 1.0 as Qaterial

QtObject {
    function setQaterialStyle() {
        Qaterial.Style.accentColorLight = Style.colorTheme4
        Qaterial.Style.accentColorDark = Style.colorTheme4
    }

    Component.onCompleted: {
        setQaterialStyle()
    }

    onDark_themeChanged: setQaterialStyle()

    readonly property FontLoader fontB: FontLoader { source: "../../assets/fonts/Ubuntu-B.ttf" }
    readonly property FontLoader fontBI: FontLoader { source: "../../assets/fonts/Ubuntu-BI.ttf" }
    readonly property FontLoader fontL: FontLoader { source: "../../assets/fonts/Ubuntu-L.ttf" }
    readonly property FontLoader fontLI: FontLoader { source: "../../assets/fonts/Ubuntu-LI.ttf" }
    readonly property FontLoader fontM: FontLoader { source: "../../assets/fonts/Ubuntu-M.ttf" }
    readonly property FontLoader fontMI: FontLoader { source: "../../assets/fonts/Ubuntu-MI.ttf" }
    readonly property FontLoader fontR: FontLoader { source: "../../assets/fonts/Ubuntu-R.ttf" }
    readonly property FontLoader fontRI: FontLoader { source: "../../assets/fonts/Ubuntu-R.ttf" }
    readonly property FontLoader fontTh: FontLoader { source: "../../assets/fonts/Ubuntu-Th.ttf" }
    readonly property string font_family: "Ubuntu"

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
    readonly property string colorThemeDarkLight:  dark_theme ? "#78808D" : "#456078"

    property string colorRectangle:  dark_theme ? colorTheme7 : colorTheme7
    readonly property string colorInnerBackground:  dark_theme ? colorTheme7 : colorTheme7

    readonly property string colorGradient1:  dark_theme ? colorTheme9 : colorTheme9
    readonly property string colorGradient2:  dark_theme ? colorTheme5 : colorTheme5
    readonly property string colorGradient3:  dark_theme ? "#24283D" : "#24283D"
    readonly property string colorGradient4:  dark_theme ? "#0D0F21" : "#0D0F21"
    readonly property string colorLineGradient1:  dark_theme ? "#2c2f3c" : "#EEF1F7"
    readonly property string colorLineGradient2:  dark_theme ? "#06070c" : "#DCE1E8"
    readonly property string colorLineGradient3:  dark_theme ? "#090910" : "#EEF1F7"
    readonly property string colorLineGradient4:  dark_theme ? "#24283b" : "#DCE1E8"
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
    readonly property string colorScrollbarGradient1:  dark_theme ? "#33395A" : "#C4CCDA"
    readonly property string colorScrollbarGradient2:  dark_theme ? "#292D48" : "#C4CCDA"

    readonly property string colorSidebarIconHighlighted:  dark_theme ? "#2BBEF2" : "#FFFFFF"
    readonly property string colorSidebarHighlightGradient1:  dark_theme ? "#FF1B5E7D" : "#8b95ed"
    readonly property string colorSidebarHighlightGradient2:  dark_theme ? "#BA1B5E7D" : "#AD7faaf0"
    readonly property string colorSidebarHighlightGradient3:  dark_theme ? "#5F1B5E7D" : "#A06dc9f3"
    readonly property string colorSidebarHighlightGradient4:  dark_theme ? "#001B5E7D" : "#006bcef4"
    readonly property string colorSidebarDropShadow:  dark_theme ? "#90000000" : "#BECDE2"
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
            return v > 0 ? Style.colorGreen : Style.colorRed

        return Style.colorWhite4
    }

    function getCoinTypeColor(type)
    {
        switch (type)
        {
            case 'ERC-20':      return getCoinColor("ETH")
            case 'QRC-20':      return getCoinColor("QTUM")
            case 'Komodo Chain': return getCoinColor("KMD")
            case 'UTXO':        return getCoinColor("BTC")
            case 'BEP-20':      return getCoinColor("BNB")
            case 'SLP':         return getCoinColor("BCH")
            case 'IDO':         return getCoinColor("TKL")
            default:            return getCoinColor("BTC")
        }
    }

    function getCoinColor(ticker) {
        const c = colorCoin[atomic_qt_utilities.retrieve_main_ticker(ticker)]
        return c || Style.colorTheme2
    }

    readonly property var colorCoin: ({
                                          "ABY": "#8B0D10",
                                          "ADA": "#214D78",
                                          "ADX": "#1B75BC",
                                          "ANKR": "#2075E8",
                                          "ARPA": "#CCD9E2",
                                          "ATOM": "#474B6C",
                                          "AUR": "#0A6C5E",
                                          "AVA": "#5B567F",
                                          "AVAX": "#E84142",
                                          "AXS": "#0055D5",
                                          "BAL": "#4D4D4D",
                                          "BNB": "#F3BA2F",
                                          "BCH": "#8DC351",
                                          "BIDR": "#F0B90B",
                                          "BSTY": "#78570D",
                                          "BTC": "#F7931A",
                                          "BTT": "#666666",
                                          "BTE": "#FFE201",
                                          "CAKE": "#D1884F",
                                          "CDN": "#90191C",
                                          "CLC": "#0970DC",
                                          "DGC": "#BC7600",
                                          "DIMI": "#0BFBE2",
                                          "EOS": "#4D4D4D",
                                          "FTC": "#FFFFFF",
                                          "FTM": "#13B5EC",
                                          "GLEEC": "#8C41FF",
                                          "GRMS": "#12B690",
                                          "GRS": "#377E96",
                                          "IOTA": "#404040",
                                          "JSTR": "#627EEA",
                                          "DOGE": "#C3A634",
                                          "ETC": "#328432",
                                          "ETH": "#627EEA",
                                          "ETHR": "#627EEA",
                                          "KMD": "#2B6680",
                                          "MORTY": "#A4764D",
                                          "RICK": "#A5CBDD",
                                          "EMC2": "#00CCFF",
                                          "INJ": "#17EAE9",
                                          "DASH": "#008CE7",
                                          "RVN": "#384182",
                                          "DGB": "#006AD2",
                                          "DOT": "#E80082",
                                          "FIRO": "#BB2100",
                                          "LBC": "#00775C",
                                          "LTC": "#BFBBBB",
                                          "LYNX": "#0071BA",
                                          "LTFN": "#0099CC",										  
                                          "XPM": "#A67522",
                                          "XVC": "#B50126",
                                          "ZEC": "#ECB244",
                                          "ZER": "#FFFFFF",
                                          "NAV": "#7D59B5",
                                          "DP": "#E41D25",
                                          "ECA": "#A915DC",
                                          "QTUM": "#2E9AD0",
                                          "CHIPS": "#598182",
                                          "CIPHS": "#ECD900",
                                          "AXE": "#C63877",
                                          "PANGEA": "#D88245",
                                          "JUMBLR": "#2B4649",
                                          "DEX": "#43B7B6",
                                          "COQUI": "#79A541",
                                          "CRYPTO": "#F58736",
                                          "LABS": "#C1F6E1",
                                          "LCC": "#068210",
                                          "MESH": "#0098DA",
                                          "MGW": "#854F2F",
                                          "MONA": "#DEC799",
                                          "NMC": "#186C9D",
                                          "RFOX": "#D83331",
                                          "BOTS": "#F69B57",
                                          "MCL": "#EA0000",
                                          "MM": "#F5B700",
                                          "CCL": "#FFE400",
                                          "BET": "#F69B57",
                                          "JRT": "#5EFC84",
                                          "SUPERNET": "#F69B57",
                                          "OOT": "#25AAE1",
                                          "REVS": "#F69B57",
                                          "ILN": "#523170",
                                          "VRSC": "#3164D3",
                                          "WCN": "#E49F00",
                                          "WWCN": "#E49F00",
                                          "THC": "#819F6F",
                                          "1INCH": "#95A7C5",
                                          "BABYDOGE": "#F3AA47",
                                          "BAT": "#FF5000",
                                          "BUSD": "#EDB70B",
                                          "DAI": "#B68900",
                                          "USDC": "#317BCB",
                                          "USDT": "#26A17B",
                                          "PAX": "#408C69",
                                          "PAXG": "#DABE37",
                                          "SMTF": "#F75836",
                                          "SUSHI": "#E25DA8",
                                          "TRYB": "#0929AA",
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
                                          "BLK": "#595959",
                                          "IL8P": "#696969",
                                          "BNT": "#0000FF",
                                          "BTCZ": "#F5B036",
                                          "CEL": "#4055A6",
                                          "CENNZ": "#2E87F1",
                                          "COMP": "#00DBA3",
                                          "CRO": "#243565",
                                          "CVC": "#3AB03E",
                                          "CVT": "#4B0082",
                                          "PIC": "#04D9FF",
                                          "DODO": "#FFF706",
                                          "EFL": "#FF940B",
                                          "EGLD": "#1D4CB5",
                                          "ELF": "#2B5EBB",
                                          "ENJ": "#6752C3",
                                          "EURS": "#2F77ED",
                                          "FIL": "#4CCAD2",
                                          "FJC": "#00AFEC",
                                          "FUN": "#EF1C70",
                                          "GNO": "#00B0CC",
                                          "HOT": "#983EFF",
                                          "IOTX": "#00CDCE",
                                          "KNC": "#117980",
                                          "LEO": "#F79B2C",
                                          "LINK": "#356CE4",
                                          "LRC": "#32C2F8",
                                          "MANA": "#FF3C6C",
                                          "MATIC": "#804EE1",
                                          "MKR": "#1BAF9F",
                                          "NEAR": "#595959",
                                          "NVC": "#FCF96D",
                                          "OCEAN": "#595959",
                                          "ONT": "#2692AF",
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
                                          "STFIRO": "#00D4F7",
                                          "STORJ": "#2683FF",
                                          "SXP": "#FD5F3B",
                                          "SYS": "#0084C7",
                                          "TKL": "#1E2835",
                                          "TRC": "#096432",
                                          "TRX": "#F30031",
                                          "TSL": "#64B082",
                                          "UIS": "#008DCD",
                                          "UNO": "#2F87BB",
                                          "VAL": "#1EEC84",
                                          "VITE": "#007AFF",
                                          "VRM": "#586A7A",
                                          "WSB": "#FEBB84",
                                          "WBTC": "#CCCCCC",
                                          "XLM": "#737373",
                                          "XMY": "#F01385",
                                          "XRP": "#2E353D",
                                          "XTZ": "#A8E000",
                                          "XVS": "#F4BC54",
                                          "YFI": "#006BE6",
                                          "YFII": "#FF2A79",
                                          "ZET": "#155169",
                                          "ZIL": "#42BBB9",
                                          "ZRX": "#302C2C",
                                          "UNI": "#FF007A"
                                      })
}
