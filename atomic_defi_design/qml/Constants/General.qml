pragma Singleton
import QtQuick 2.15
import AtomicDEX.TradingError 1.0
import AtomicDEX.MarketMode 1.0

QtObject {
    readonly property int width: 1280
    readonly property int height: 800
    readonly property int minimumWidth: 1280
    readonly property int minimumHeight: 800
    readonly property double delta_time: 1000/60

    readonly property string os_file_prefix: Qt.platform.os == "windows" ? "file:///" : "file://"
    readonly property string assets_path: "qrc:///"
    readonly property string image_path: assets_path + "atomic_defi_design/assets/images/"
    readonly property string coin_icons_path: image_path + "coins/"
    readonly property string custom_coin_icons_path: os_file_prefix + API.app.settings_pg.get_custom_coins_icons_path() + "/"
    readonly property string providerIconsPath: image_path + "providers/"

    function coinIcon(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        }else {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            return (coin_info.is_custom_coin ? custom_coin_icons_path : coin_icons_path) + atomic_qt_utilities.retrieve_main_ticker(ticker.toString()).toLowerCase() + ".png"
        }
    }

    function coinName(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        }else {
            const name = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker).name
            return name
        }
    }

    // Returns the icon full path of a coin type.
    // If the given coin type has spaces, it will be replaced by '-' characters.
    // If the given coin type is empty, returns an empty string.
    function coinTypeIcon(type) {
        if (type === "") return ""

        var filename = type.toLowerCase().replace(" ", "-");
        return coin_icons_path + filename + ".png"
    }

    // Returns the full path of a provider icon.
    function providerIcon(providerName)
    {
        if (providerName === "") return ""
        return providerIconsPath + providerName + ".png";
    }

    function qaterialIcon(name) {
        return "qrc:/Qaterial/Icons/" + name + ".svg"
    }

    readonly property string cex_icon: 'ⓘ'
    readonly property string download_icon: '📥'
    readonly property string right_arrow_icon: "⮕"
    readonly property string privacy_text: "*****"

    readonly property string version_string: "Desktop v" + API.app.settings_pg.get_version()

    property bool privacy_mode: false

    readonly property var reg_pass_input: /[A-Za-z0-9@#$€£%{}[\]()\/\\'"`~,;:.<>+\-_=!^&*|?]+/
    readonly property var reg_pass_valid_low_security: /^(?=.{1,}).*$/
    readonly property var reg_pass_valid: /^(?=.{16,})(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[@#$%€£{}[\]()\/\\'"`~,;:.<>+\-_=!^&*|?]).*$/
    readonly property var reg_pass_uppercase: /(?=.*[A-Z])/
    readonly property var reg_pass_lowercase: /(?=.*[a-z])/
    readonly property var reg_pass_numeric: /(?=.*[0-9])/
    readonly property var reg_pass_special: /(?=.*[@#$%{}[\]()\/\\'"`~,€$£;:.<>+\-_=!^&*|?])/
    readonly property var reg_pass_count_low_security: /(?=.{1,})/
    readonly property var reg_pass_count: /(?=.{16,})/

    readonly property double time_toast_important_error: 10000
    readonly property double time_toast_basic_info: 3000

    readonly property var chart_times: (["1m", "3m", "5m", "15m", "30m", "1h", "2h", "4h", "6h", "12h", "1d", "3d"/*, "1w"*/])
    readonly property var time_seconds: ({ "1m": 60, "3m": 180, "5m": 300, "15m": 900, "30m": 1800, "1h": 3600, "2h": 7200, "4h": 14400, "6h": 21600, "12h": 43200, "1d": 86400, "3d": 259200, "1w": 604800 })


    property bool initialized_orderbook_pair: false
    readonly property string default_base: atomic_app_primary_coin
    readonly property string default_rel: atomic_app_secondary_coin

    function timestampToDouble(timestamp) {
        return (new Date(timestamp)).getTime()
    }

    function timestampToString(timestamp) {
        return (new Date(timestamp)).toUTCString()
    }

    function timestampToDate(timestamp) {
        return (new Date(timestamp * 1000))
    }

    function getDuration(total_ms) {
        let delta = Math.abs(total_ms)

        let days = Math.floor(delta / 86400000)
        delta -= days * 86400000

        let hours = Math.floor(delta / 3600000) % 24
        delta -= hours * 3600000

        let minutes = Math.floor(delta / 60000) % 60
        delta -= minutes * 60000

        let seconds = Math.floor(delta / 1000) % 60
        delta -= seconds * 1000

        let milliseconds = Math.floor(delta)

        return { days, hours, minutes, seconds, milliseconds }
    }

    function secondsToTimeLeft(date_now, date_future) {
        const r = getDuration((date_future - date_now)*1000)
        let days = r.days
        let hours = r.hours
        let minutes = r.minutes
        let seconds = r.seconds

        if(hours < 10) hours = '0' + hours
        if(minutes < 10) minutes = '0' + minutes
        if(seconds < 10) seconds = '0' + seconds
        return qsTr("%n day(s)", "", days) + '  ' + hours + ':' + minutes + ':' + seconds
    }

    function durationTextShort(total) {
        if(!General.exists(total))
            return "-"

        const r = getDuration(total)

        let text = ""
        if(r.days > 0) text += qsTr("%nd", "day", r.days) + "  "
        if(r.hours > 0) text += qsTr("%nh", "hours", r.hours) + "  "
        if(r.minutes > 0) text += qsTr("%nm", "minutes", r.minutes) + "  "
        if(r.seconds > 0) text += qsTr("%ns", "seconds", r.seconds) + "  "
        if(text === "" && r.milliseconds > 0) text += qsTr("%nms", "milliseconds", r.milliseconds) + "  "
        if(text === "") text += qsTr("-")

        return text
    }

    function absString(str) {
        return str.replace("-", "")
    }

    function clone(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    function prettifyJSON(j) {
        const j_obj = typeof j === "string" ? JSON.parse(j) : j
        return JSON.stringify(j_obj, null, 4)
    }

    function viewTxAtExplorer(ticker, id, add_0x=true) {
        if(id !== '') {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            const id_prefix = add_0x && (coin_info.type === 'ERC-20' || coin_info.type === 'BEP-20') ? '0x' : ''
            Qt.openUrlExternally(coin_info.explorer_url + coin_info.tx_uri + id_prefix + id)
        }
    }

    function viewAddressAtExplorer(ticker, address) {
        if(address !== '') {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            Qt.openUrlExternally(coin_info.explorer_url + coin_info.address_uri + address)
        }
    }

    function diffPrefix(received) {
        return received === "" ? "" : received === true ? "+ " :  "- "
    }

    function filterCoins(list, text, type) {
        return list.filter(c => (c.ticker.indexOf(text.toUpperCase()) !== -1 || c.name.toUpperCase().indexOf(text.toUpperCase()) !== -1) &&
                           (type === undefined || c.type === type)).sort((a, b) => {
                               if(a.ticker < b.ticker) return -1
                               if(a.ticker > b.ticker) return 1
                               return 0
                           })
    }

    function validFiatRates(data, fiat) {
        return data && data.rates && data.rates[fiat]
    }

    function nFormatter(num, digits) {
      if(num < 1E5) return General.formatDouble(num)

      const si = [
        { value: 1, symbol: "" },
        { value: 1E3, symbol: "k" },
        { value: 1E6, symbol: "M" },
        { value: 1E9, symbol: "G" },
        { value: 1E12, symbol: "T" },
        { value: 1E15, symbol: "P" },
        { value: 1E18, symbol: "E" }
      ]
      const rx = /\.0+$|(\.[0-9]*[1-9])0+$/

      let i
      for (i = si.length - 1; i > 0; --i)
        if (num >= si[i].value) break

      return (num / si[i].value).toFixed(digits).replace(rx, "$1") + si[i].symbol
    }

    function formatFiat(received, amount, fiat) {
        return diffPrefix(received) +
                (fiat === API.app.settings_pg.current_fiat ? API.app.settings_pg.current_fiat_sign : API.app.settings_pg.current_currency_sign)
                + " " + nFormatter(parseFloat(amount), 2)
    }

    function formatPercent(value, show_prefix=true) {
        let prefix = ''
        if(value > 0) prefix = '+ '
        else if(value < 0) {
            prefix = '- '
            value *= -1
        }

        return (show_prefix ? prefix : '') + value + ' %'
    }

    readonly property int amountPrecision: 8
    readonly property int sliderDigitLimit: 9
    readonly property int recommendedPrecision: -1337

    function getDigitCount(v) {
        return v.toString().replace("-", "").split(".")[0].length
    }

    function getRecommendedPrecision(v, limit) {
        const lim = limit || sliderDigitLimit
        return Math.min(Math.max(lim - getDigitCount(v), 0), amountPrecision)
    }

    function formatDouble(v, precision, trail_zeros) {
        if(v === '') return "0"
        if(precision === recommendedPrecision) precision = getRecommendedPrecision(v)

        if(precision === 0) return parseInt(v).toString()

        // Remove more than n decimals, then convert to string without trailing zeros
        const full_double = parseFloat(v).toFixed(precision || amountPrecision)

        return trail_zeros ? full_double : full_double.replace(/\.?0+$/,"")
    }

    function formatCrypto(received, amount, ticker, fiat_amount, fiat) {
        return diffPrefix(received) +  atomic_qt_utilities.retrieve_main_ticker(ticker) + " " + formatDouble(amount) + (fiat_amount ? " (" + formatFiat("", fiat_amount, fiat) + ")" : "")
    }
    

    function fullCoinName(name, ticker) {
        return name + " (" + ticker + ")"
    }

    function fullNamesOfCoins(coins) {
        return coins.map(c => {
         return { value: c.ticker, text: fullCoinName(c.name, c.ticker) }
        })
    }

    function tickersOfCoins(coins) {
        return coins.map(c => {
            return { value: c.ticker, text: c.ticker }
        })
    }

    function getMinTradeAmount() {
        /*if (API.app.trading_pg.market_mode == MarketMode.Buy) {
            return API.app.trading_pg.orderbook.rel_min_taker_vol
        }*/
        return API.app.trading_pg.min_trade_vol
    }

    function getReversedMinTradeAmount() {
            if (API.app.trading_pg.market_mode == MarketMode.Buy) {
               return API.app.trading_pg.min_trade_vol
            }
            return API.app.trading_pg.orderbook.rel_min_taker_vol
        }

    function hasEnoughFunds(sell, base, rel, price, volume) {
        if(sell) {
            if(volume === "") return true
            return API.app.do_i_have_enough_funds(base, volume)
        }
        else {
            if(price === "") return true
            const needed_amount = parseFloat(price) * parseFloat(volume)
            return API.app.do_i_have_enough_funds(rel, needed_amount)
        }
    }

    function isZero(v) {
        return !isFilled(v) || parseFloat(v) === 0
    }


    function exists(v) {
        return v !== undefined && v !== null
    }

    function isFilled(v) {
        return exists(v) && v !== ""
    }

    function isParentCoinNeeded(ticker, type) {
        for(const c of API.app.portfolio_pg.get_all_enabled_coins())
            if(c.type === type && c.ticker !== ticker) return true

        return false
    }

    property Timer prevent_coin_disabling: Timer { interval: 5000 }

    function canDisable(ticker) {
        if(prevent_coin_disabling.running)
            return false

        if(ticker === atomic_app_primary_coin || ticker === atomic_app_secondary_coin) return false
        else if(ticker === "ETH") return !General.isParentCoinNeeded("ETH", "ERC-20")
        else if(ticker === "QTUM") return !General.isParentCoinNeeded("QTUM", "QRC-20")

        return true
    }

    function tokenUnitName(type) {
        return type === "ERC-20" ? "Gwei" : "Satoshi"
    }

    function isParentCoin(ticker) {
        return ticker === "KMD" || ticker === "ETH" || ticker === "QTUM"
    }

    function isTokenType(type) {
        return type === "ERC-20" || type === "QRC-20"
    }

    function getParentCoin(type) {
        if(type === "ERC-20") return "ETH"
        else if(type === "QRC-20") return "QTUM"
        else if(type === "Komodo Chain") return "KMD"
        return "?"
    }

    function getRandomInt(min, max) {
        min = Math.ceil(min)
        max = Math.floor(max)
        return Math.floor(Math.random() * (max - min + 1)) + min
    }

    function getFiatText(v, ticker, has_info_icon=true) {
        return General.formatFiat('', v === '' ? 0 : API.app.get_fiat_from_amount(ticker, v), API.app.settings_pg.current_fiat)
                + (has_info_icon ? " " +  General.cex_icon : "")
    }

    function hasParentCoinFees(trade_info) {
        return General.isFilled(trade_info.rel_transaction_fees) && parseFloat(trade_info.rel_transaction_fees) > 0
    }

    function feeText(trade_info, base_ticker, has_info_icon=true, has_limited_space=false) {


        if(!trade_info || !trade_info.trading_fee) return ""

        const tx_fee = txFeeText(trade_info, base_ticker, has_info_icon, has_limited_space)
        const trading_fee = tradingFeeText(trade_info, base_ticker, has_info_icon)
        const minimum_amount = minimumtradingFeeText(trade_info, base_ticker, has_info_icon)


        return tx_fee + "\n" + trading_fee +"<br>"+minimum_amount
    }

    function txFeeText(trade_info, base_ticker, has_info_icon=true, has_limited_space=false) {

        if(!trade_info || !trade_info.trading_fee) return ""

        const has_parent_coin_fees = hasParentCoinFees(trade_info)

         var info =  qsTr('%1 Transaction Fee'.arg(trade_info.base_transaction_fees_ticker))+': '+ trade_info.base_transaction_fees + " (%1)".arg(getFiatText(trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker, has_info_icon))

        if (has_parent_coin_fees) {
            info = info+"<br>"+qsTr('%1 Transaction Fee'.arg(trade_info.rel_transaction_fees_ticker))+': '+ trade_info.rel_transaction_fees + " (%1)".arg(getFiatText(trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker, has_info_icon))
        }

        return info+"<br>"
//        const main_fee = (qsTr('Transaction Fee') + ': ' + General.formatCrypto("", trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker)) +
//                                 // Rel Fees
//                                 (has_parent_coin_fees ? " + " + General.formatCrypto("", trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker) : '')

//        let fiat_part = "("
//        fiat_part += getFiatText(trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker, false)
//        if(has_parent_coin_fees) fiat_part += (has_limited_space ? "\n\t\t+ " : " + ") + getFiatText(trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker, has_info_icon)
//        fiat_part += ")"

//        return main_fee + " " + fiat_part
    }
//    function txFeeText2(trade_info, base_ticker, has_info_icon=true, has_limited_space=false) {
//        if(!trade_info || !trade_info.trading_fee) return ""

//        const has_parent_coin_fees = hasParentCoinFees(trade_info)
//        const main_fee = (qsTr('Transaction Fee') + ': ' + General.formatCrypto("", trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker)) +
//                                 // Rel Fees
//                                 (has_parent_coin_fees ? " + " + General.formatCrypto("", trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker) : '')

//        let fiat_part = "("
//        fiat_part += getFiatText(trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker, false)
//        if(has_parent_coin_fees) fiat_part += (has_limited_space ? "\n\t\t+ " : " + ") + getFiatText(trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker, has_info_icon)
//        fiat_part += ")"

//        return main_fee + " " + fiat_part
//    }

    function tradingFeeText(trade_info, base_ticker, has_info_icon=true) {
        if(!trade_info || !trade_info.trading_fee) return ""

        return trade_info.trading_fee_ticker+" "+qsTr('Trading Fee') + ': ' + General.formatCrypto("", trade_info.trading_fee, "") +

                // Fiat part
                (" ("+
                    getFiatText(trade_info.trading_fee, trade_info.trading_fee_ticker, has_info_icon)
                 +")")
    }
    function minimumtradingFeeText(trade_info, base_ticker, has_info_icon=true) {
        if(!trade_info || !trade_info.trading_fee) return ""

        return API.app.trading_pg.market_pairs_mdl.left_selected_coin+" "+qsTr('Minimum Trading Amount') + ': ' + General.formatCrypto("", API.app.trading_pg.min_trade_vol , "") +

                // Fiat part
                (" ("+
                    getFiatText(API.app.trading_pg.min_trade_vol , API.app.trading_pg.market_pairs_mdl.left_selected_coin, has_info_icon)
                 +")")
    }

    function checkIfWalletExists(name) {
        if(API.app.wallet_mgr.get_wallets().indexOf(name) !== -1)
            return qsTr("Wallet %1 already exists", "WALLETNAME").arg(name)
        return ""
    }

    function getTradingError(error, fee_info, base_ticker, rel_ticker, left_ticker, right_ticker) {
        switch(error) {
        case TradingError.None:
            return ""
        case TradingError.TotalFeesNotEnoughFunds:
            return qsTr("%1 balance is lower than the fees amount: %2 %3").arg(fee_info.error_fees.coin).arg(fee_info.error_fees.required_balance).arg(fee_info.error_fees.coin)
        case TradingError.BalanceIsLessThanTheMinimalTradingAmount:
            return qsTr("Tradable (after fees) %1 balance is lower than minimum trade amount").arg(base_ticker) + " : " + General.getMinTradeAmount()
        case TradingError.PriceFieldNotFilled:
            return qsTr("Please fill the price field")
        case TradingError.VolumeFieldNotFilled:
            return qsTr("Please fill the volume field")
        case TradingError.VolumeIsLowerThanTheMinimum:
            return qsTr("%1 volume is lower than minimum trade amount").arg(API.app.trading_pg.market_pairs_mdl.left_selected_coin) + " : " + General.getMinTradeAmount()
        case TradingError.ReceiveVolumeIsLowerThanTheMinimum:
            return qsTr("%1 volume is lower than minimum trade amount").arg(rel_ticker) + " : " + General.getReversedMinTradeAmount()
        case TradingError.LeftParentChainNotEnabled:
            return qsTr("%1 needs to be enabled in order to use %2").arg(API.app.portfolio_pg.global_cfg_mdl.get_parent_coin(left_ticker)).arg(left_ticker)
        case TradingError.LeftParentChainNotEnoughBalance:
            return qsTr("%1 balance needs to be funded, a non-zero balance is required to pay the gas of %2 transactions").arg(API.app.portfolio_pg.global_cfg_mdl.get_parent_coin(left_ticker)).arg(left_ticker)
        case TradingError.RightParentChainNotEnabled:
             return qsTr("%1 needs to be enabled in order to use %2").arg(API.app.portfolio_pg.global_cfg_mdl.get_parent_coin(right_ticker)).arg(right_ticker)
        case TradingError.RightParentChainNotEnoughBalance:
             return qsTr("%1 balance needs to be funded, a non-zero balance is required to pay the gas of %2 transactions").arg(API.app.portfolio_pg.global_cfg_mdl.get_parent_coin(right_ticker)).arg(right_ticker)
        default:
            return qsTr("Unknown Error") + ": " + error
        }
    }

    readonly property var supported_pairs: ({
                                                "1INCH/BTC": "BINANCE:1INCHBTC",
                                                "1INCH/ETH": "HUOBI:1INCHETH",
                                                "1INCH/USDT": "BINANCE:1INCHUSD",
                                                "1INCH/BUSD": "BINANCE:1INCHUSD",
                                                "1INCH/USDC": "BINANCE:1INCHUSD",
                                                "1INCH/TUSD": "BINANCE:1INCHUSD",
                                                "1INCH/HUSD": "BINANCE:1INCHUSD",
                                                "1INCH/DAI": "BINANCE:1INCHUSD",
                                                "1INCH/PAX": "BINANCE:1INCHUSD",
                                                "ADA/BTC": "BINANCE:ADABTC",
                                                "ADA/ETH": "BINANCE:ADAETH",
                                                "ADA/USDT": "BINANCE:ADAUSD",
                                                "ADA/BUSD": "BINANCE:ADAUSD",
                                                "ADA/USDC": "BINANCE:ADAUSD",
                                                "ADA/TUSD": "BINANCE:ADAUSD",
                                                "ADA/HUSD": "BINANCE:ADAUSD",
                                                "ADA/DAI": "BINANCE:ADAUSD",
                                                "ADA/PAX": "BINANCE:ADAUSD",
                                                "ADA/EURS": "BINANCE:ADAEUR",
                                                "ADA/TRYB": "BINANCE:ADATRY",
                                                "ADA/BIDR": "BINANCE:ADABIDR",
                                                "ADA/BNB": "BINANCE:ADABNB",
                                                "ADA/BCH": "HITBTC:ADABCH",
                                                "ADX/BTC": "BINANCE:ADXBTC",
                                                "ADX/ETH": "BINANCE:ADXETH",
                                                "ADX/USDT": "BINANCE:ADXUSD",
                                                "ADX/BUSD": "BINANCE:ADXUSD",
                                                "ADX/USDC": "BINANCE:ADXUSD",
                                                "ADX/TUSD": "BINANCE:ADXUSD",
                                                "ADX/HUSD": "BINANCE:ADXUSD",
                                                "ADX/DAI": "BINANCE:ADXUSD",
                                                "ADX/PAX": "BINANCE:ADXUSD",
                                                "AAVE/BTC": "BINANCE:AAVEBTC",
                                                "AAVE/ETH": "BINANCE:AAVEETH",
                                                "AAVE/BNB": "BINANCE:AAVEBNB",
                                                "AAVE/USDT": "BINANCE:AAVEUSD",
                                                "AAVE/BUSD": "BINANCE:AAVEUSD",
                                                "AAVE/USDC": "BINANCE:AAVEUSD",
                                                "AAVE/TUSD": "BINANCE:AAVEUSD",
                                                "AAVE/HUSD": "BINANCE:AAVEUSD",
                                                "AAVE/DAI": "BINANCE:AAVEUSD",
                                                "AAVE/PAX": "BINANCE:AAVEUSD",
                                                "AAVE/EURS": "KRAKEN:AAVEEUR",
                                                "AGI/BTC": "BINANCE:AGIBTC",
                                                "AGI/ETH": "KUCOIN:AGIETH",
                                                "AGI/USDT": "BINANCE:AGIUSD",
                                                "AGI/BUSD": "BINANCE:AGIUSD",
                                                "AGI/USDC": "BINANCE:AGIUSD",
                                                "AGI/TUSD": "BINANCE:AGIUSD",
                                                "AGI/HUSD": "BINANCE:AGIUSD",
                                                "AGI/DAI": "BINANCE:AGIUSD",
                                                "AGI/PAX": "BINANCE:AGIUSD",
                                                "ANKR/BTC": "BINANCE:ANKRBTC",
                                                "ANKR/ETH": "BITTREX:ANKRETH",
                                                "ANKR/USDT": "BINANCE:ANKRUSD",
                                                "ANKR/BUSD": "BINANCE:ANKRUSD",
                                                "ANKR/USDC": "BINANCE:ANKRUSD",
                                                "ANKR/TUSD": "BINANCE:ANKRUSD",
                                                "ANKR/HUSD": "BINANCE:ANKRUSD",
                                                "ANKR/DAI": "BINANCE:ANKRUSD",
                                                "ANKR/PAX": "BINANCE:ANKRUSD",
                                                "ANKR/BNB": "BINANCE:ANKRBNB",
                                                "ANKR/EURS": "COINBASE:ANKREUR",
                                                "ANKR/HT": "HUOBI:ANKRHT",
                                                "ANT/BTC": "BINANCE:ANTBTC",
                                                "ANT/ETH": "BITFINEX:ANTETH",
                                                "ANT/USDT": "BINANCE:ANTUSD",
                                                "ANT/BUSD": "BINANCE:ANTUSD",
                                                "ANT/USDC": "BINANCE:ANTUSD",
                                                "ANT/TUSD": "BINANCE:ANTUSD",
                                                "ANT/HUSD": "BINANCE:ANTUSD",
                                                "ANT/DAI": "BINANCE:ANTUSD",
                                                "ANT/PAX": "BINANCE:ANTUSD",
                                                "ANT/BNB": "BINANCE:ANTBNB",
                                                "ANT/EURS": "KRAKEN:ANTEUR",
                                                "ARPA/BTC": "BINANCE:ARPABTC",
                                                "ARPA/BNB": "BINANCE:ARPABNB",
                                                "ARPA/HT": "HUOBI:ARPAHT",
                                                "ARPA/USDT": "BINANCE:ARPAUSD",
                                                "ARPA/BUSD": "BINANCE:ARPAUSD",
                                                "ARPA/USDC": "BINANCE:ARPAUSD",
                                                "ARPA/TUSD": "BINANCE:ARPAUSD",
                                                "ARPA/HUSD": "BINANCE:ARPAUSD",
                                                "ARPA/DAI": "BINANCE:ARPAUSD",
                                                "ARPA/PAX": "BINANCE:ARPAUSD",
                                                "ARPA/TRYB": "BINANCE:ARPATRY",
                                                "ATOM/BTC": "BINANCE:ATOMBTC",
                                                "ATOM/ETH": "KRAKEN:ATOMETH",
                                                "ATOM/USDT": "COINBASE:ATOMUSD",
                                                "ATOM/BUSD": "COINBASE:ATOMUSD",
                                                "ATOM/USDC": "COINBASE:ATOMUSD",
                                                "ATOM/TUSD": "COINBASE:ATOMUSD",
                                                "ATOM/HUSD": "COINBASE:ATOMUSD",
                                                "ATOM/DAI": "COINBASE:ATOMUSD",
                                                "ATOM/PAX": "COINBASE:ATOMUSD",
                                                "ATOM/BNB": "BINANCE:ATOMBNB",
                                                "ATOM/EURS": "KRAKEN:ATOMEUR",
                                                "ATOM/BCH": "HITBTC:ATOMBCH",
                                                "AVA/BTC": "BINANCE:AVABTC",
                                                "AVA/ETH": "KUCOIN:AVAETH",
                                                "AVA/USDT": "BINANCE:AVAUSD",
                                                "AVA/BUSD": "BINANCE:AVAUSD",
                                                "AVA/USDC": "BINANCE:AVAUSD",
                                                "AVA/TUSD": "BINANCE:AVAUSD",
                                                "AVA/HUSD": "BINANCE:AVAUSD",
                                                "AVA/DAI": "BINANCE:AVAUSD",
                                                "AVA/PAX": "BINANCE:AVAUSD",
                                                "AVA/BNB": "BINANCE:AVABNB",
                                                "AVAX/BTC": "BINANCE:AVAXBTC",
                                                "AVAX/ETH": "OKEX:AVAXETH",
                                                "AVAX/USDT": "BINANCE:AVAXUSD",
                                                "AVAX/BUSD": "BINANCE:AVAXUSD",
                                                "AVAX/USDC": "BINANCE:AVAXUSD",
                                                "AVAX/TUSD": "BINANCE:AVAXUSD",
                                                "AVAX/HUSD": "BINANCE:AVAXUSD",
                                                "AVAX/DAI": "BINANCE:AVAXUSD",
                                                "AVAX/PAX": "BINANCE:AVAXUSD",
                                                "AVAX/BNB": "BINANCE:AVAXBNB",
                                                "AVAX/EURS": "BINANCE:AVAXEUR",
                                                "AXS/BTC": "BINANCE:AXSBTC",
                                                "AXS/ETH": "HUOBI:AXSETH",
                                                "AXS/USDT": "BINANCE:AXSUSD",
                                                "AXS/BUSD": "BINANCE:AXSUSD",
                                                "AXS/USDC": "BINANCE:AXSUSD",
                                                "AXS/TUSD": "BINANCE:AXSUSD",
                                                "AXS/HUSD": "BINANCE:AXSUSD",
                                                "AXS/DAI": "BINANCE:AXSUSD",
                                                "AXS/PAX": "BINANCE:AXSUSD",
                                                "AXS/BNB": "BINANCE:AXSBNB",
                                                "AXS/EURS": "KRAKEN:AXSEUR",
                                                "BAL/BTC": "BINANCE:BALBTC",
                                                "BAL/ETH": "HUOBI:BALETH",
                                                "BAL/USDT": "BINANCE:BALUSD",
                                                "BAL/BUSD": "BINANCE:BALUSD",
                                                "BAL/USDC": "BINANCE:BALUSD",
                                                "BAL/TUSD": "BINANCE:BALUSD",
                                                "BAL/HUSD": "BINANCE:BALUSD",
                                                "BAL/DAI": "BINANCE:BALUSD",
                                                "BAL/PAX": "BINANCE:BALUSD",
                                                "BAL/EURS": "KRAKEN:BALEUR",
                                                "BAND/BTC": "BINANCE:BANDBTC",
                                                "BAND/ETH": "HUOBI:BANDETH",
                                                "BAND/BNB": "BINANCE:BANDBNB",
                                                "BAND/USDT": "BINANCE:BANDUSD",
                                                "BAND/BUSD": "BINANCE:BANDUSD",
                                                "BAND/USDC": "BINANCE:BANDUSD",
                                                "BAND/TUSD": "BINANCE:BANDUSD",
                                                "BAND/HUSD": "BINANCE:BANDUSD",
                                                "BAND/DAI": "BINANCE:BANDUSD",
                                                "BAND/PAX": "BINANCE:BANDUSD",
                                                "BAND/EURS": "COINBASE:BANDEUR",
                                                "BAT/BTC": "BINANCE:BATBTC",
                                                "BAT/ETH": "BINANCE:BATETH",
                                                "BAT/BNB": "BINANCE:BATBNB",
                                                "BAT/USDT": "BINANCE:BATUSD",
                                                "BAT/BUSD": "BINANCE:BATUSD",
                                                "BAT/USDC": "BINANCE:BATUSD",
                                                "BAT/TUSD": "BINANCE:BATUSD",
                                                "BAT/HUSD": "BINANCE:BATUSD",
                                                "BAT/DAI": "BINANCE:BATUSD",
                                                "BAT/PAX": "BINANCE:BATUSD",
                                                "BAT/EURS": "KRAKEN:BATEUR",
                                                "BEST/BTC": "BITPANDAPRO:BESTBTC",
                                                "BEST/USDT": "HITBTC:BESTUSD",
                                                "BEST/BUSD": "HITBTC:BESTUSD",
                                                "BEST/USDC": "HITBTC:BESTUSD",
                                                "BEST/TUSD": "HITBTC:BESTUSD",
                                                "BEST/HUSD": "HITBTC:BESTUSD",
                                                "BEST/DAI": "HITBTC:BESTUSD",
                                                "BEST/PAX": "HITBTC:BESTUSD",
                                                "BEST/EURS": "BITPANDAPRO:BESTEUR",
                                                "BCH/BTC": "BINANCE:BCHBTC",
                                                "BCH/ETH": "BITTREX:BCHETH",
                                                "BCH/USDT": "COINBASE:BCHUSD",
                                                "BCH/BUSD": "COINBASE:BCHUSD",
                                                "BCH/USDC": "COINBASE:BCHUSD",
                                                "BCH/TUSD": "COINBASE:BCHUSD",
                                                "BCH/HUSD": "COINBASE:BCHUSD",
                                                "BCH/DAI": "COINBASE:BCHUSD",
                                                "BCH/PAX": "COINBASE:BCHUSD",
                                                "BCH/BNB": "BINANCE:BCHBNB",
                                                "BCH/EURS": "HITBTC:BCHEURS",
                                                "BCH/HT": "HUOBI:BCHHT",
                                                "BIDR/USDT": "BINANCE:USDTBIDR",
                                                "BIDR/BUSD": "BINANCE:USDTBIDR",
                                                "BIDR/USDC": "BINANCE:USDTBIDR",
                                                "BIDR/TUSD": "BINANCE:USDTBIDR",
                                                "BIDR/HUSD": "BINANCE:USDTBIDR",
                                                "BIDR/DAI": "BINANCE:USDTBIDR",
                                                "BIDR/PAX": "BINANCE:USDTBIDR",
                                                "BLK/BTC": "BITTREX:BLKBTC",
                                                "BLK/USDT": "BITTREX:BLKUSD",
                                                "BLK/BUSD": "BITTREX:BLKUSD",
                                                "BLK/USDC": "BITTREX:BLKUSD",
                                                "BLK/TUSD": "BITTREX:BLKUSD",
                                                "BLK/HUSD": "BITTREX:BLKUSD",
                                                "BLK/DAI": "BITTREX:BLKUSD",
                                                "BLK/PAX": "BITTREX:BLKUSD",
                                                "BNB/BTC": "BINANCE:BNBBTC",
                                                "BNB/ETH": "BINANCE:BNBETH",
                                                "BNB/USDT": "BINANCE:BNBUSD",
                                                "BNB/BUSD": "BINANCE:BNBUSD",
                                                "BNB/USDC": "BINANCE:BNBUSD",
                                                "BNB/TUSD": "BINANCE:BNBUSD",
                                                "BNB/HUSD": "BINANCE:BNBUSD",
                                                "BNB/DAI": "BINANCE:BNBUSD",
                                                "BNB/PAX": "BINANCE:BNBUSD",
                                                "BNB/EURS": "BINANCE:BNBEUR",
                                                "BNB/TRYB": "BINANCE:BNBTRY",
                                                "BNB/BIDR": "BINANCE:BNBBIDR",
                                                "BNT/BTC": "BINANCE:BNTBTC",
                                                "BNT/ETH": "BINANCE:BNTETH",
                                                "BNT/USDT": "BINANCE:BNTUSD",
                                                "BNT/BUSD": "BINANCE:BNTUSD",
                                                "BNT/USDC": "BINANCE:BNTUSD",
                                                "BNT/TUSD": "BINANCE:BNTUSD",
                                                "BNT/HUSD": "BINANCE:BNTUSD",
                                                "BNT/DAI": "BINANCE:BNTUSD",
                                                "BNT/PAX": "BINANCE:BNTUSD",
                                                "BNT/EURS": "COINBASE:BNTEUR",
                                                "BTC/USDT": "COINBASE:BTCUSD",
                                                "BTC/BUSD": "COINBASE:BTCUSD",
                                                "BTC/USDC": "COINBASE:BTCUSD",
                                                "BTC/TUSD": "COINBASE:BTCUSD",
                                                "BTC/HUSD": "COINBASE:BTCUSD",
                                                "BTC/DAI": "COINBASE:BTCUSD",
                                                "BTC/PAX": "COINBASE:BTCUSD",
                                                "BTC/EURS": "COINBASE:BTCEUR",
                                                "BTC/TRYB": "BINANCE:BTCTRY",
                                                "BTC/BIDR": "BITFINEX:BTCIDR",
                                                "BTC/QC": "BITFINEX:BTCCNHT",
                                                "BTT/BTC": "BITFINEX:BTTBTC",
                                                "BTT/ETH": "KUCOIN:BTTETH",
                                                "BTT/USDT": "BITFINEX:BTTUSD",
                                                "BTT/BUSD": "BITFINEX:BTTUSD",
                                                "BTT/USDC": "BITFINEX:BTTUSD",
                                                "BTT/TUSD": "BITFINEX:BTTUSD",
                                                "BTT/HUSD": "BITFINEX:BTTUSD",
                                                "BTT/DAI": "BITFINEX:BTTUSD",
                                                "BTT/PAX": "BITFINEX:BTTUSD",
                                                "BTT/BNB": "BINANCE:BTTBNB",
                                                "BTT/EURS": "BINANCE:BTTEUR",
                                                "BTT/TRYB": "BINANCE:BTTTRY",
                                                "BTU/BTC": "BITTREX:BTUBTC",
                                                "BTU/USDT": "BITTREX:BTUUSD",
                                                "BTU/BUSD": "BITTREX:BTUUSD",
                                                "BTU/USDC": "BITTREX:BTUUSD",
                                                "BTU/TUSD": "BITTREX:BTUUSD",
                                                "BTU/HUSD": "BITTREX:BTUUSD",
                                                "BTU/DAI": "BITTREX:BTUUSD",
                                                "BTU/PAX": "BITTREX:BTUUSD",
                                                "CAKE/BTC": "BINANCE:CAKEBTC",
                                                "CAKE/USDT": "BINANCE:CAKEUSD",
                                                "CAKE/BUSD": "BINANCE:CAKEUSD",
                                                "CAKE/USDC": "BINANCE:CAKEUSD",
                                                "CAKE/TUSD": "BINANCE:CAKEUSD",
                                                "CAKE/HUSD": "BINANCE:CAKEUSD",
                                                "CAKE/DAI": "BINANCE:CAKEUSD",
                                                "CAKE/PAX": "BINANCE:CAKEUSD",
                                                "CAKE/BNB": "BINANCE:CAKEBNB",
                                                "CEL/BTC": "HITBTC:CELBTC",
                                                "CEL/ETH": "HITBTC:CELETH",
                                                "CEL/USDT": "HITBTC:CELUSD",
                                                "CEL/BUSD": "HITBTC:CELUSD",
                                                "CEL/USDC": "HITBTC:CELUSD",
                                                "CEL/TUSD": "HITBTC:CELUSD",
                                                "CEL/HUSD": "HITBTC:CELUSD",
                                                "CEL/DAI": "HITBTC:CELUSD",
                                                "CEL/PAX": "HITBTC:CELUSD",
                                                "CENNZ/BTC": "HITBTC:CENNZBTC",
                                                "CENNZ/ETH": "HITBTC:CENNZETH",
                                                "CENNZ/USDT": "HITBTC:CENNZUSD",
                                                "CENNZ/BUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/USDC": "HITBTC:CENNZUSD",
                                                "CENNZ/TUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/HUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/DAI": "HITBTC:CENNZUSD",
                                                "CENNZ/PAX": "HITBTC:CENNZUSD",
                                                "CHSB/BTC": "KUCOIN:CHSBBTC",
                                                "CHSB/ETH": "KUCOIN:CHSBETH",
                                                "CHSB/USDT": "HITBTC:CHSBUSD",
                                                "CHSB/BUSD": "HITBTC:CHSBUSD",
                                                "CHSB/USDC": "HITBTC:CHSBUSD",
                                                "CHSB/TUSD": "HITBTC:CHSBUSD",
                                                "CHSB/HUSD": "HITBTC:CHSBUSD",
                                                "CHSB/DAI": "HITBTC:CHSBUSD",
                                                "CHSB/PAX": "HITBTC:CHSBUSD",
                                                "CHZ/BTC": "BINANCE:CHZBTC",
                                                "CHZ/ETH": "HUOBI:CHZETH",
                                                "CHZ/USDT": "BINANCE:CHZUSD",
                                                "CHZ/BUSD": "BINANCE:CHZUSD",
                                                "CHZ/USDC": "BINANCE:CHZUSD",
                                                "CHZ/TUSD": "BINANCE:CHZUSD",
                                                "CHZ/HUSD": "BINANCE:CHZUSD",
                                                "CHZ/DAI": "BINANCE:CHZUSD",
                                                "CHZ/PAX": "BINANCE:CHZUSD",
                                                "CHZ/BNB": "BINANCE:CHZBNB",
                                                "CHZ/EURS": "BINANCE:CHZEUR",
                                                "COMP/BTC": "BINANCE:COMPBTC",
                                                "COMP/ETH": "KRAKEN:COMPETH",
                                                "COMP/USDT": "BINANCE:COMPUSD",
                                                "COMP/BUSD": "BINANCE:COMPUSD",
                                                "COMP/USDC": "BINANCE:COMPUSD",
                                                "COMP/TUSD": "BINANCE:COMPUSD",
                                                "COMP/HUSD": "BINANCE:COMPUSD",
                                                "COMP/DAI": "BINANCE:COMPUSD",
                                                "COMP/PAX": "BINANCE:COMPUSD",
                                                "COMP/EURS": "KRAKEN:COMPEUR",
                                                "CRO/BTC": "BITTREX:CROBTC",
                                                "CRO/ETH": "BITTREX:CROETH",
                                                "CRO/USDT": "BITTREX:CROUSD",
                                                "CRO/BUSD": "BITTREX:CROUSD",
                                                "CRO/USDC": "BITTREX:CROUSD",
                                                "CRO/TUSD": "BITTREX:CROUSD",
                                                "CRO/HUSD": "BITTREX:CROUSD",
                                                "CRO/DAI": "BITTREX:CROUSD",
                                                "CRO/PAX": "BITTREX:CROUSD",
                                                "CRO/EURS": "BITTREX:CROEUR",
                                                "CRO/HT": "HUOBI:CROHT",
                                                "CRV/BTC": "BINANCE:CRVBTC",
                                                "CRV/ETH": "KRAKEN:CRVETH",
                                                "CRV/USDT": "BINANCE:CRVUSD",
                                                "CRV/BUSD": "BINANCE:CRVUSD",
                                                "CRV/USDC": "BINANCE:CRVUSD",
                                                "CRV/TUSD": "BINANCE:CRVUSD",
                                                "CRV/HUSD": "BINANCE:CRVUSD",
                                                "CRV/DAI": "BINANCE:CRVUSD",
                                                "CRV/PAX": "BINANCE:CRVUSD",
                                                "CRV/BNB": "BINANCE:CRVBNB",
                                                "CRV/EURS": "KRAKEN:CRVEUR",
                                                "CVC/BTC": "BINANCE:CVCBTC",
                                                "CVC/ETH": "BINANCE:CVCETH",
                                                "CVC/USDT": "BINANCE:CVCUSD",
                                                "CVC/BUSD": "BINANCE:CVCUSD",
                                                "CVC/USDC": "BINANCE:CVCUSD",
                                                "CVC/TUSD": "BINANCE:CVCUSD",
                                                "CVC/HUSD": "BINANCE:CVCUSD",
                                                "CVC/DAI": "BINANCE:CVCUSD",
                                                "CVC/PAX": "BINANCE:CVCUSD",
                                                "CVT/BTC": "BITTREX:CVTBTC",
                                                "CVT/ETH": "HITBTC:CVTETH",
                                                "CVT/USDT": "BITTREX:CVTUSD",
                                                "CVT/BUSD": "BITTREX:CVTUSD",
                                                "CVT/USDC": "BITTREX:CVTUSD",
                                                "CVT/TUSD": "BITTREX:CVTUSD",
                                                "CVT/HUSD": "BITTREX:CVTUSD",
                                                "CVT/DAI": "BITTREX:CVTUSD",
                                                "CVT/PAX": "BITTREX:CVTUSD",
                                                "DASH/BTC": "BINANCE:DASHBTC",
                                                "DASH/ETH": "BINANCE:DASHETH",
                                                "DASH/USDT": "KRAKEN:DASHUSD",
                                                "DASH/BUSD": "KRAKEN:DASHUSD",
                                                "DASH/USDC": "KRAKEN:DASHUSD",
                                                "DASH/TUSD": "KRAKEN:DASHUSD",
                                                "DASH/HUSD": "KRAKEN:DASHUSD",
                                                "DASH/DAI": "KRAKEN:DASHUSD",
                                                "DASH/PAX": "KRAKEN:DASHUSD",
                                                "DASH/BNB": "BINANCE:DASHBNB",
                                                "DASH/EURS": "KRAKEN:DASHEUR",
                                                "DASH/BCH": "HITBTC:DASHBCH",
                                                "DASH/HT": "HUOBI:DASHHT",
                                                "DOGE/BTC": "BINANCE:DOGEBTC",
                                                "DOGE/ETH": "HITBTC:DOGEETH",
                                                "DOGE/USDT": "BINANCE:DOGEUSD",
                                                "DOGE/BUSD": "BINANCE:DOGEUSD",
                                                "DOGE/USDC": "BINANCE:DOGEUSD",
                                                "DOGE/TUSD": "BINANCE:DOGEUSD",
                                                "DOGE/HUSD": "BINANCE:DOGEUSD",
                                                "DOGE/DAI": "BINANCE:DOGEUSD",
                                                "DOGE/PAX": "BINANCE:DOGEUSD",
                                                "DOGE/EURS": "BINANCE:DOGEEUR",
                                                "DOGE/TRYB": "BINANCE:DOGETRY",
                                                "DOGE/BIDR": "BINANCE:DOGEBIDR",
                                                "DGB/BTC": "BINANCE:DGBBTC",
                                                "DGB/ETH": "BITTREX:DGBETH",
                                                "DGB/USDT": "BITTREX:DGBUSD",
                                                "DGB/BUSD": "BITTREX:DGBUSD",
                                                "DGB/USDC": "BITTREX:DGBUSD",
                                                "DGB/TUSD": "BITTREX:DGBUSD",
                                                "DGB/HUSD": "BITTREX:DGBUSD",
                                                "DGB/DAI": "BITTREX:DGBUSD",
                                                "DGB/PAX": "BITTREX:DGBUSD",
                                                "DGB/BNB": "BINANCE:DGBBNB",
                                                "DGB/EURS": "BITTREX:DGBEUR",
                                                "DIA/BTC": "BINANCE:DIABTC",
                                                "DIA/ETH": "OKEX:DIAETH",
                                                "DIA/USDT": "BINANCE:DIAUSD",
                                                "DIA/BUSD": "BINANCE:DIAUSD",
                                                "DIA/USDC": "BINANCE:DIAUSD",
                                                "DIA/TUSD": "BINANCE:DIAUSD",
                                                "DIA/HUSD": "BINANCE:DIAUSD",
                                                "DIA/DAI": "BINANCE:DIAUSD",
                                                "DIA/PAX": "BINANCE:DIAUSD",
                                                "DIA/BNB": "BINANCE:DIABNB",
                                                "DODO/BTC": "BINANCE:DODOBTC",
                                                "DODO/USDT": "BINANCE:DODOUSD",
                                                "DODO/BUSD": "BINANCE:DODOUSD",
                                                "DODO/USDC": "BINANCE:DODOUSD",
                                                "DODO/TUSD": "BINANCE:DODOUSD",
                                                "DODO/HUSD": "BINANCE:DODOUSD",
                                                "DODO/DAI": "BINANCE:DODOUSD",
                                                "DODO/PAX": "BINANCE:DODOUSD",
                                                "DOT/BTC": "BINANCE:DOTBTC",
                                                "DOT/ETH": "KRAKEN:DOTETH",
                                                "DOT/USDT": "BINANCE:DOTUSD",
                                                "DOT/BUSD": "BINANCE:DOTUSD",
                                                "DOT/USDC": "BINANCE:DOTUSD",
                                                "DOT/TUSD": "BINANCE:DOTUSD",
                                                "DOT/HUSD": "BINANCE:DOTUSD",
                                                "DOT/DAI": "BINANCE:DOTUSD",
                                                "DOT/PAX": "BINANCE:DOTUSD",
                                                "DOT/EURS": "BINANCE:DOTEUR",
                                                "DOT/TRYB": "BINANCE:DOTTRY",
                                                "DOT/BIDR": "BINANCE:DOTBIDR",
                                                "DOT/BNB": "BINANCE:DOTBNB",
                                                "DX/BTC": "KUCOIN:DXBTC",
                                                "DX/ETH": "KUCOIN:DXETH",
                                                "EGLD/BTC": "BINANCE:EGLDBTC",
                                                "EGLD/USDT": "BINANCE:EGLDUSD",
                                                "EGLD/BUSD": "BINANCE:EGLDUSD",
                                                "EGLD/USDC": "BINANCE:EGLDUSD",
                                                "EGLD/TUSD": "BINANCE:EGLDUSD",
                                                "EGLD/HUSD": "BINANCE:EGLDUSD",
                                                "EGLD/DAI": "BINANCE:EGLDUSD",
                                                "EGLD/PAX": "BINANCE:EGLDUSD",
                                                "EGLD/BNB": "BINANCE:EGLDBNB",
                                                "EGLD/EURS": "BINANCE:EGLDEUR",
                                                "ELF/BTC": "BINANCE:ELFBTC",
                                                "ELF/ETH": "BINANCE:ELFETH",
                                                "ELF/USDT": "BINANCE:ELFUSD",
                                                "ELF/BUSD": "BINANCE:ELFUSD",
                                                "ELF/USDC": "BINANCE:ELFUSD",
                                                "ELF/TUSD": "BINANCE:ELFUSD",
                                                "ELF/HUSD": "BINANCE:ELFUSD",
                                                "ELF/DAI": "BINANCE:ELFUSD",
                                                "ELF/PAX": "BINANCE:ELFUSD",
                                                "EMC2/BTC": "BITTREX:EMC2BTC",
                                                "EMC2/USDT": "BITTREX:EMC2USD",
                                                "EMC2/BUSD": "BITTREX:EMC2USD",
                                                "EMC2/USDC": "BITTREX:EMC2USD",
                                                "EMC2/TUSD": "BITTREX:EMC2USD",
                                                "EMC2/HUSD": "BITTREX:EMC2USD",
                                                "EMC2/DAI": "BITTREX:EMC2USD",
                                                "EMC2/PAX": "BITTREX:EMC2USD",
                                                "ENJ/BTC": "BINANCE:ENJBTC",
                                                "ENJ/ETH": "BINANCE:ENJETH",
                                                "ENJ/USDT": "BINANCE:ENJUSD",
                                                "ENJ/BUSD": "BINANCE:ENJUSD",
                                                "ENJ/USDC": "BINANCE:ENJUSD",
                                                "ENJ/TUSD": "BINANCE:ENJUSD",
                                                "ENJ/HUSD": "BINANCE:ENJUSD",
                                                "ENJ/DAI": "BINANCE:ENJUSD",
                                                "ENJ/PAX": "BINANCE:ENJUSD",
                                                "ENJ/BNB": "BINANCE:ENJBNB",
                                                "ENJ/EURS": "BINANCE:ENJEUR",
                                                "EOS/BTC": "BINANCE:EOSBTC",
                                                "EOS/ETH": "BINANCE:EOSETH",
                                                "EOS/USDT": "BITFINEX:EOSUSD",
                                                "EOS/BUSD": "BITFINEX:EOSUSD",
                                                "EOS/USDC": "BITFINEX:EOSUSD",
                                                "EOS/TUSD": "BITFINEX:EOSUSD",
                                                "EOS/HUSD": "BITFINEX:EOSUSD",
                                                "EOS/DAI": "BITFINEX:EOSUSD",
                                                "EOS/PAX": "BITFINEX:EOSUSD",
                                                "EOS/BNB": "BINANCE:EOSBNB",
                                                "EOS/BCH": "HITBTC:EOSBCH",
                                                "EOS/EURS": "HITBTC:EOSEURS",
                                                "EOS/TRYB": "BINANCE:EOSTRY",
                                                "EOS/BIDR": "BITFINEX:EOSIDR",
                                                "ETC/BTC": "BINANCE:ETCBTC",
                                                "ETC/ETH": "BINANCE:ETCETH",
                                                "ETC/USDT": "BINANCE:ETCUSD",
                                                "ETC/BUSD": "BINANCE:ETCUSD",
                                                "ETC/USDC": "BINANCE:ETCUSD",
                                                "ETC/TUSD": "BINANCE:ETCUSD",
                                                "ETC/HUSD": "BINANCE:ETCUSD",
                                                "ETC/DAI": "BINANCE:ETCUSD",
                                                "ETC/PAX": "BINANCE:ETCUSD",
                                                "ETC/BNB": "BINANCE:ETCBNB",
                                                "ETC/EURS": "KRAKEN:ETCEUR",
                                                "ETC/BCH": "HITBTC:ETCBCH",
                                                "ETH/BTC": "BINANCE:ETHBTC",
                                                "ETH/USDT": "BITSTAMP:ETHUSD",
                                                "ETH/BUSD": "BITSTAMP:ETHUSD",
                                                "ETH/USDC": "BITSTAMP:ETHUSD",
                                                "ETH/TUSD": "BITSTAMP:ETHUSD",
                                                "ETH/HUSD": "BITSTAMP:ETHUSD",
                                                "ETH/DAI": "BITSTAMP:ETHUSD",
                                                "ETH/PAX": "BITSTAMP:ETHUSD",
                                                "ETH/EURS": "KRAKEN:ETHEUR",
                                                "ETH/TRYB": "BINANCE:ETHTRY",
                                                "ETH/BIDR": "BITFINEX:ETHIDR",
                                                "EURS/USDT": "FX:EURUSD",
                                                "EURS/BUSD": "FX:EURUSD",
                                                "EURS/USDC": "FX:EURUSD",
                                                "EURS/TUSD": "FX:EURUSD",
                                                "EURS/HUSD": "FX:EURUSD",
                                                "EURS/DAI": "FX:EURUSD",
                                                "EURS/PAX": "FX:EURUSD",
                                                "EURS/BIDR": "FX_IDC:EURIDR",
                                                "FIL/BTC": "BINANCE:FILBTC",
                                                "FIL/ETH": "HUOBI:FILETH",
                                                "FIL/USDT": "BINANCE:FILUSD",
                                                "FIL/BUSD": "BINANCE:FILUSD",
                                                "FIL/USDC": "BINANCE:FILUSD",
                                                "FIL/TUSD": "BINANCE:FILUSD",
                                                "FIL/HUSD": "BINANCE:FILUSD",
                                                "FIL/DAI": "BINANCE:FILUSD",
                                                "FIL/PAX": "BINANCE:FILUSD",
                                                "FIL/BNB": "BINANCE:FILBNB",
                                                "FIL/EURS": "COINBASE:FILEUR",
                                                "FIRO/BTC": "BINANCE:FIROBTC",
                                                "FIRO/ETH": "BINANCE:FIROETH",
                                                "FIRO/USDT": "BITTREX:FIROUSD",
                                                "FIRO/BUSD": "BITTREX:FIROUSD",
                                                "FIRO/USDC": "BITTREX:FIROUSD",
                                                "FIRO/TUSD": "BITTREX:FIROUSD",
                                                "FIRO/HUSD": "BITTREX:FIROUSD",
                                                "FIRO/DAI": "BITTREX:FIROUSD",
                                                "FIRO/PAX": "BITTREX:FIROUSD",
                                                "FTC/BTC": "BITTREX:FTCBTC",
                                                "FTC/USDT": "BITTREX:FTCUSD",
                                                "FTC/BUSD": "BITTREX:FTCUSD",
                                                "FTC/USDC": "BITTREX:FTCUSD",
                                                "FTC/TUSD": "BITTREX:FTCUSD",
                                                "FTC/HUSD": "BITTREX:FTCUSD",
                                                "FTC/DAI": "BITTREX:FTCUSD",
                                                "FTC/PAX": "BITTREX:FTCUSD",
                                                "FTM/BTC": "BINANCE:FTMBTC",
                                                "FTM/ETH": "KUCOIN:FTMETH",
                                                "FTM/USDT": "BINANCE:FTMUSD",
                                                "FTM/BUSD": "BINANCE:FTMUSD",
                                                "FTM/USDC": "BINANCE:FTMUSD",
                                                "FTM/FTM": "BINANCE:FTMUSD",
                                                "FTM/HUSD": "BINANCE:FTMUSD",
                                                "FTM/DAI": "BINANCE:FTMUSD",
                                                "FTM/PAX": "BINANCE:FTMUSD",
                                                "FTM/BNB": "BINANCE:FTMBNB",
                                                "FUN/BTC": "BINANCE:FUNBTC",
                                                "FUN/ETH": "BINANCE:FUNETH",
                                                "FUN/USDT": "BINANCE:FUNUSD",
                                                "FUN/BUSD": "BINANCE:FUNUSD",
                                                "FUN/USDC": "BINANCE:FUNUSD",
                                                "FUN/FUN": "BINANCE:FUNUSD",
                                                "FUN/HUSD": "BINANCE:FUNUSD",
                                                "FUN/DAI": "BINANCE:FUNUSD",
                                                "FUN/PAX": "BINANCE:FUNUSD",
                                                "GLEEC/BTC": "BITTREX:GLEECBTC",
                                                "GLEEC/USDT": "BITTREX:GLEECUSD",
                                                "GLEEC/BUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/USDC": "BITTREX:GLEECUSD",
                                                "GLEEC/TUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/HUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/DAI": "BITTREX:GLEECUSD",
                                                "GLEEC/PAX": "BITTREX:GLEECUSD",
                                                "GNO/BTC": "BITTREX:GNOBTC",
                                                "GNO/ETH": "KRAKEN:GNOETH",
                                                "GNO/USDT": "KRAKEN:GNOUSD",
                                                "GNO/BUSD": "KRAKEN:GNOUSD",
                                                "GNO/USDC": "KRAKEN:GNOUSD",
                                                "GNO/TUSD": "KRAKEN:GNOUSD",
                                                "GNO/HUSD": "KRAKEN:GNOUSD",
                                                "GNO/DAI": "KRAKEN:GNOUSD",
                                                "GNO/PAX": "KRAKEN:GNOUSD",
                                                "GNO/EURS": "KRAKEN:GNOEUR",
                                                "GRS/BTC": "BINANCE:GRSBTC",
                                                "GRS/ETH": "HUOBI:GRSETH",
                                                "GRS/USDT": "BINANCE:GRSUSD",
                                                "GRS/BUSD": "BINANCE:GRSUSD",
                                                "GRS/USDC": "BINANCE:GRSUSD",
                                                "GRS/TUSD": "BINANCE:GRSUSD",
                                                "GRS/HUSD": "BINANCE:GRSUSD",
                                                "GRS/DAI": "BINANCE:GRSUSD",
                                                "GRS/PAX": "BINANCE:GRSUSD",
                                                "HEX/BTC": "HITBTC:HEXBTC",
                                                "HEX/USDC": "UNISWAP:HEXUSDC",
                                                "HOT/BTC": "HITBTC:HOTBTC",
                                                "HOT/ETH": "BINANCE:HOTETH",
                                                "HOT/USDT": "HITBTC:HOTUSD",
                                                "HOT/BUSD": "HITBTC:HOTUSD",
                                                "HOT/USDC": "HITBTC:HOTUSD",
                                                "HOT/TUSD": "HITBTC:HOTUSD",
                                                "HOT/HUSD": "HITBTC:HOTUSD",
                                                "HOT/DAI": "HITBTC:HOTUSD",
                                                "HOT/PAX": "HITBTC:HOTUSD",
                                                "HOT/BNB": "BINANCE:HOTBNB",
                                                "HOT/EURS": "BINANCE:HOTEUR",
                                                "HT/BTC": "HUOBI:HTBTC",
                                                "HT/ETH": "HUOBI:HTETH",
                                                "HT/USDT": "FTX:HTUSD",
                                                "HT/BUSD": "FTX:HTUSD",
                                                "HT/USDC": "FTX:HTUSD",
                                                "HT/TUSD": "FTX:HTUSD",
                                                "HT/HUSD": "FTX:HTUSD",
                                                "HT/DAI": "FTX:HTUSD",
                                                "HT/PAX": "FTX:HTUSD",
                                                "INJ/BTC": "BINANCE:INJBTC",
                                                "INJ/ETH": "HUOBI:INJETH",
                                                "INJ/USDT": "BINANCE:INJUSD",
                                                "INJ/BUSD": "BINANCE:INJUSD",
                                                "INJ/USDC": "BINANCE:INJUSD",
                                                "INJ/TUSD": "BINANCE:INJUSD",
                                                "INJ/HUSD": "BINANCE:INJUSD",
                                                "INJ/DAI": "BINANCE:INJUSD",
                                                "INJ/PAX": "BINANCE:INJUSD",
                                                "INJ/BNB": "BINANCE:INJBNB",
                                                "INK/BTC": "HITBTC:INKBTC",
                                                "INK/ETH": "HITBTC:INKETH",
                                                "INK/USDT": "HITBTC:INKUSDT",
                                                "IOTA/BTC": "BINANCE:IOTABTC",
                                                "IOTA/ETH": "BINANCE:IOTAETH",
                                                "IOTA/USDT": "BINANCE:IOTAUSD",
                                                "IOTA/BUSD": "BINANCE:IOTAUSD",
                                                "IOTA/USDC": "BINANCE:IOTAUSD",
                                                "IOTA/TUSD": "BINANCE:IOTAUSD",
                                                "IOTA/HUSD": "BINANCE:IOTAUSD",
                                                "IOTA/DAI": "BINANCE:IOTAUSD",
                                                "IOTA/PAX": "BINANCE:IOTAUSD",
                                                "IOTA/BNB": "BINANCE:IOTABNB",
                                                "IOTA/EURS": "BITPANDAPRO:MIOTAEUR",
                                                "IOTX/BTC": "BINANCE:IOTXBTC",
                                                "IOTX/ETH": "BINANCE:IOTXETH",
                                                "IOTX/USDT": "BINANCE:IOTXUSD",
                                                "IOTX/BUSD": "BINANCE:IOTXUSD",
                                                "IOTX/USDC": "BINANCE:IOTXUSD",
                                                "IOTX/TUSD": "BINANCE:IOTXUSD",
                                                "IOTX/HUSD": "BINANCE:IOTXUSD",
                                                "IOTX/DAI": "BINANCE:IOTXUSD",
                                                "IOTX/PAX": "BINANCE:IOTXUSD",
                                                "KMD/BTC": "BINANCE:KMDBTC",
                                                "KMD/ETH": "BINANCE:KMDETH",
                                                "KMD/USDT": "BINANCE:KMDUSD",
                                                "KMD/BUSD": "BINANCE:KMDUSD",
                                                "KMD/USDC": "BINANCE:KMDUSD",
                                                "KMD/TUSD": "BINANCE:KMDUSD",
                                                "KMD/HUSD": "BINANCE:KMDUSD",
                                                "KMD/DAI": "BINANCE:KMDUSD",
                                                "KMD/PAX": "BINANCE:KMDUSD",
                                                "KMD/TRYB": "BITTREX:KMDTRY",
                                                "KMD/BIDR": "BITTREX:KMDIDR",
                                                "KNC/BTC": "BINANCE:KNCBTC",
                                                "KNC/ETH": "BINANCE:KNCETH",
                                                "KNC/USDT": "COINBASE:KNCUSD",
                                                "KNC/BUSD": "COINBASE:KNCUSD",
                                                "KNC/USDC": "COINBASE:KNCUSD",
                                                "KNC/TUSD": "COINBASE:KNCUSD",
                                                "KNC/HUSD": "COINBASE:KNCUSD",
                                                "KNC/DAI": "COINBASE:KNCUSD",
                                                "KNC/PAX": "COINBASE:KNCUSD",
                                                "KNC/EURS": "KRAKEN:KNCEUR",
                                                "LBC/BTC": "BITTREX:LBCBTC",
                                                "LBC/ETH": "BITTREX:LBCETH",
                                                "LBC/USDT": "BITTREX:LBCUSD",
                                                "LBC/BUSD": "BITTREX:LBCUSD",
                                                "LBC/USDC": "BITTREX:LBCUSD",
                                                "LBC/TUSD": "BITTREX:LBCUSD",
                                                "LBC/HUSD": "BITTREX:LBCUSD",
                                                "LBC/DAI": "BITTREX:LBCUSD",
                                                "LBC/PAX": "BITTREX:LBCUSD",
                                                "LCC/BTC": "HITBTC:LCCBTC",
                                                "LCC/USDT": "HITBTC:LCCUSD",
                                                "LCC/BUSD": "HITBTC:LCCUSD",
                                                "LCC/USDC": "HITBTC:LCCUSD",
                                                "LCC/TUSD": "HITBTC:LCCUSD",
                                                "LCC/HUSD": "HITBTC:LCCUSD",
                                                "LCC/DAI": "HITBTC:LCCUSD",
                                                "LCC/PAX": "HITBTC:LCCUSD",
                                                "LEO/BTC": "BITFINEX:LEOBTC",
                                                "LEO/ETH": "BITFINEX:LEOETH",
                                                "LEO/USDT": "BITFINEX:LEOUSD",
                                                "LEO/BUSD": "BITFINEX:LEOUSD",
                                                "LEO/USDC": "BITFINEX:LEOUSD",
                                                "LEO/TUSD": "BITFINEX:LEOUSD",
                                                "LEO/HUSD": "BITFINEX:LEOUSD",
                                                "LEO/DAI": "BITFINEX:LEOUSD",
                                                "LEO/PAX": "BITFINEX:LEOUSD",
                                                "LINK/BTC": "BINANCE:LINKBTC",
                                                "LINK/ETH": "BINANCE:LINKETH",
                                                "LINK/BCH": "HITBTC:LINKBCH",
                                                "LINK/USDT": "BINANCE:LINKUSD",
                                                "LINK/BUSD": "BINANCE:LINKUSD",
                                                "LINK/USDC": "BINANCE:LINKUSD",
                                                "LINK/TUSD": "BINANCE:LINKUSD",
                                                "LINK/HUSD": "BINANCE:LINKUSD",
                                                "LINK/DAI": "BINANCE:LINKUSD",
                                                "LINK/PAX": "BINANCE:LINKUSD",
                                                "LINK/EURS": "KRAKEN:LINKEUR",
                                                "LINK/TRYB": "BINANCE:LINKTRY",
                                                "LRC/BTC": "BINANCE:LRCBTC",
                                                "LRC/ETH": "BINANCE:LRCETH",
                                                "LRC/USDT": "BINANCE:LRCUSD",
                                                "LRC/BUSD": "BINANCE:LRCUSD",
                                                "LRC/USDC": "BINANCE:LRCUSD",
                                                "LRC/TUSD": "BINANCE:LRCUSD",
                                                "LRC/HUSD": "BINANCE:LRCUSD",
                                                "LRC/DAI": "BINANCE:LRCUSD",
                                                "LRC/PAX": "BINANCE:LRCUSD",
                                                "LTC/BTC": "BINANCE:LTCBTC",
                                                "LTC/ETH": "BINANCE:LTCETH",
                                                "LTC/USDT": "COINBASE:LTCUSD",
                                                "LTC/BUSD": "COINBASE:LTCUSD",
                                                "LTC/USDC": "COINBASE:LTCUSD",
                                                "LTC/TUSD": "COINBASE:LTCUSD",
                                                "LTC/HUSD": "COINBASE:LTCUSD",
                                                "LTC/DAI": "COINBASE:LTCUSD",
                                                "LTC/PAX": "COINBASE:LTCUSD",
                                                "LTC/BNB": "BINANCE:LTCBNB",
                                                "LTC/EURS": "COINBASE:LTCEUR",
                                                "LTC/TRYB": "BITFINEX:LTCTRY",
                                                "LTC/BIDR": "BITFINEX:LTCIDR",
                                                "LTC/BCH": "HITBTC:LTCBCH",
                                                "LTC/HT": "HUOBI:LTCHT",
                                                "MANA/BTC": "BINANCE:MANABTC",
                                                "MANA/ETH": "BINANCE:MANAETH",
                                                "MANA/USDT": "BINANCE:MANAUSD",
                                                "MANA/BUSD": "BINANCE:MANAUSD",
                                                "MANA/USDC": "BINANCE:MANAUSD",
                                                "MANA/TUSD": "BINANCE:MANAUSD",
                                                "MANA/HUSD": "BINANCE:MANAUSD",
                                                "MANA/DAI": "BINANCE:MANAUSD",
                                                "MANA/PAX": "BINANCE:MANAUSD",
                                                "MANA/EURS": "KRAKEN:MANAEUR",
                                                "MATIC/BTC": "BINANCE:MATICBTC",
                                                "MATIC/ETH": "HUOBI:MATICETH",
                                                "MATIC/USDT": "BINANCE:MATICUSD",
                                                "MATIC/BUSD": "BINANCE:MATICUSD",
                                                "MATIC/USDC": "BINANCE:MATICUSD",
                                                "MATIC/TUSD": "BINANCE:MATICUSD",
                                                "MATIC/HUSD": "BINANCE:MATICUSD",
                                                "MATIC/DAI": "BINANCE:MATICUSD",
                                                "MATIC/PAX": "BINANCE:MATICUSD",
                                                "MATIC/BNB": "BINANCE:MATICBNB",
                                                "MATIC/EURS": "COINBASE:MATICEUR",
                                                "MATIC/TRYB": "BINANCE:MATICTRY",
                                                "MATIC/BIDR": "BINANCE:MATICBIDR",
                                                "MKR/BTC": "BINANCE:MKRBTC",
                                                "MKR/ETH": "BITFINEX:MKRETH",
                                                "MKR/BNB": "BINANCE:MKRBNB",
                                                "MKR/USDT": "BINANCE:MKRUSD",
                                                "MKR/BUSD": "BINANCE:MKRUSD",
                                                "MKR/USDC": "BINANCE:MKRUSD",
                                                "MKR/TUSD": "BINANCE:MKRUSD",
                                                "MKR/HUSD": "BINANCE:MKRUSD",
                                                "MKR/DAI": "BINANCE:MKRUSD",
                                                "MKR/PAX": "BINANCE:MKRUSD",
                                                "MKR/EURS": "BITSTAMP:MKREUR",
                                                "MONA/BTC": "BITTREX:MONABTC",
                                                "MONA/USDT": "BITTREX:MONAUSD",
                                                "MONA/BUSD": "BITTREX:MONAUSD",
                                                "MONA/USDC": "BITTREX:MONAUSD",
                                                "MONA/TUSD": "BITTREX:MONAUSD",
                                                "MONA/HUSD": "BITTREX:MONAUSD",
                                                "MONA/DAI": "BITTREX:MONAUSD",
                                                "MONA/PAX": "BITTREX:MONAUSD",
                                                "NAV/BTC": "BINANCE:NAVBTC",
                                                "NAV/USDT": "BINANCE:NAVUSD",
                                                "NAV/BUSD": "BINANCE:NAVUSD",
                                                "NAV/USDC": "BINANCE:NAVUSD",
                                                "NAV/TUSD": "BINANCE:NAVUSD",
                                                "NAV/HUSD": "BINANCE:NAVUSD",
                                                "NAV/DAI": "BINANCE:NAVUSD",
                                                "NAV/PAX": "BINANCE:NAVUSD",
                                                "NEAR/BTC": "BINANCE:NEARBTC",
                                                "NEAR/ETH": "OKEX:NEARETH",
                                                "NEAR/USDT": "BINANCE:NEARUSD",
                                                "NEAR/BUSD": "BINANCE:NEARUSD",
                                                "NEAR/USDC": "BINANCE:NEARUSD",
                                                "NEAR/TUSD": "BINANCE:NEARUSD",
                                                "NEAR/HUSD": "BINANCE:NEARUSD",
                                                "NEAR/DAI": "BINANCE:NEARUSD",
                                                "NEAR/PAX": "BINANCE:NEARUSD",
                                                "NEAR/BNB": "BINANCE:NEARBNB",
                                                "OCEAN/BTC": "BINANCE:OCEANBTC",
                                                "OCEAN/ETH": "KUCOIN:OCEANETH",
                                                "OCEAN/USDT": "BINANCE:OCEANUSD",
                                                "OCEAN/BUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/USDC": "BINANCE:OCEANUSD",
                                                "OCEAN/TUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/HUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/DAI": "BINANCE:OCEANUSD",
                                                "OCEAN/PAX": "BINANCE:OCEANUSD",
                                                "OCEAN/BNB": "BINANCE:OCEANBNB",
                                                "OCEAN/EURS": "KRAKEN:OCEANEUR",
                                                "OKB/BTC": "OKEX:OKBBTC",
                                                "OKB/ETH": "OKEX:OKBETH",
                                                "OKB/USDT": "FTX:OKBUSD",
                                                "OKB/BUSD": "FTX:OKBUSD",
                                                "OKB/USDC": "FTX:OKBUSD",
                                                "OKB/TUSD": "FTX:OKBUSD",
                                                "OKB/HUSD": "FTX:OKBUSD",
                                                "OKB/DAI": "FTX:OKBUSD",
                                                "OKB/PAX": "FTX:OKBUSD",
                                                "ONT/BTC": "BINANCE:ONTBTC",
                                                "ONT/ETH": "BINANCE:ONTETH",
                                                "ONT/USDT": "BINANCE:ONTUSD",
                                                "ONT/BUSD": "BINANCE:ONTUSD",
                                                "ONT/USDC": "BINANCE:ONTUSD",
                                                "ONT/TUSD": "BINANCE:ONTUSD",
                                                "ONT/HUSD": "BINANCE:ONTUSD",
                                                "ONT/DAI": "BINANCE:ONTUSD",
                                                "ONT/PAX": "BINANCE:ONTUSD",
                                                "ONT/TRYB": "BINANCE:ONTTRY",
                                                "ONT/BNB": "BINANCE:ONTBNB",
                                                "ONT/BCH": "HITBTC:ONTBCH",
                                                "PAXG/BTC": "BINANCE:PAXGBTC",
                                                "PAXG/ETH": "KRAKEN:PAXGETH",
                                                "PAXG/USDT": "KRAKEN:PAXGUSD",
                                                "PAXG/BUSD": "KRAKEN:PAXGUSD",
                                                "PAXG/USDC": "KRAKEN:PAXGUSD",
                                                "PAXG/TUSD": "KRAKEN:PAXGUSD",
                                                "PAXG/HUSD": "KRAKEN:PAXGUSD",
                                                "PAXG/DAI": "KRAKEN:PAXGUSD",
                                                "PAXG/PAX": "KRAKEN:PAXGUSD",
                                                "PAXG/BNB": "BINANCE:PAXGBNB",
                                                "PAXG/EURS": "KRAKEN:PAXGEUR",
                                                "PNK/BTC": "BITFINEX:PNKBTC",
                                                "PNK/ETH": "BITFINEX:PNKETH",
                                                "PNK/USDT": "BITFINEX:PNKUSD",
                                                "PNK/BUSD": "BITFINEX:PNKUSD",
                                                "PNK/USDC": "BITFINEX:PNKUSD",
                                                "PNK/TUSD": "BITFINEX:PNKUSD",
                                                "PNK/HUSD": "BITFINEX:PNKUSD",
                                                "PNK/DAI": "BITFINEX:PNKUSD",
                                                "PNK/PAX": "BITFINEX:PNKUSD",
                                                "POWR/BTC": "BINANCE:POWRBTC",
                                                "POWR/ETH": "BINANCE:POWRETH",
                                                "POWR/USDT": "BINANCE:POWRUSD",
                                                "POWR/BUSD": "BINANCE:POWRUSD",
                                                "POWR/USDC": "BINANCE:POWRUSD",
                                                "POWR/TUSD": "BINANCE:POWRUSD",
                                                "POWR/HUSD": "BINANCE:POWRUSD",
                                                "POWR/DAI": "BINANCE:POWRUSD",
                                                "POWR/PAX": "BINANCE:POWRUSD",
                                                "QC/USDT": "FX_IDC:CNYUSD",
                                                "QC/BUSD": "FX_IDC:CNYUSD",
                                                "QC/USDC": "FX_IDC:CNYUSD",
                                                "QC/TUSD": "FX_IDC:CNYUSD",
                                                "QC/HUSD": "FX_IDC:CNYUSD",
                                                "QC/DAI": "FX_IDC:CNYUSD",
                                                "QC/PAX": "FX_IDC:CNYUSD",
                                                "QC/EURS": "FX_IDC:CNYEUR",
                                                "QC/TRYB": "FX_IDC:CNYTRY",
                                                "QC/BIDR": "FX_IDC:CNYIDR",
                                                "QKC/BTC": "BINANCE:QKCBTC",
                                                "QKC/ETH": "BINANCE:QKCETH",
                                                "QKC/USDT": "BINANCE:QKCUSD",
                                                "QKC/BUSD": "BINANCE:QKCUSD",
                                                "QKC/USDC": "BINANCE:QKCUSD",
                                                "QKC/TUSD": "BINANCE:QKCUSD",
                                                "QKC/HUSD": "BINANCE:QKCUSD",
                                                "QKC/DAI": "BINANCE:QKCUSD",
                                                "QKC/PAX": "BINANCE:QKCUSD",
                                                "QNT/BTC": "BITTREX:QNTBTC",
                                                "QNT/USDT": "BITTREX:QNTUSD",
                                                "QNT/BUSD": "BITTREX:QNTUSD",
                                                "QNT/USDC": "BITTREX:QNTUSD",
                                                "QNT/TUSD": "BITTREX:QNTUSD",
                                                "QNT/HUSD": "BITTREX:QNTUSD",
                                                "QNT/DAI": "BITTREX:QNTUSD",
                                                "QNT/PAX": "BITTREX:QNTUSD",
                                                "QTUM/BTC": "BINANCE:QTUMBTC",
                                                "QTUM/ETH": "BINANCE:QTUMETH",
                                                "QTUM/USDT": "BINANCE:QTUMUSD",
                                                "QTUM/BUSD": "BINANCE:QTUMUSD",
                                                "QTUM/USDC": "BINANCE:QTUMUSD",
                                                "QTUM/TUSD": "BINANCE:QTUMUSD",
                                                "QTUM/HUSD": "BINANCE:QTUMUSD",
                                                "QTUM/DAI": "BINANCE:QTUMUSD",
                                                "QTUM/PAX": "BINANCE:QTUMUSD",
                                                "QTUM/EURS": "KRAKEN:QTUMEUR",
                                                "REN/BTC": "BINANCE:RENBTC",
                                                "REN/ETH": "HUOBI:RENETH",
                                                "REN/USDT": "BINANCE:RENUSD",
                                                "REN/BUSD": "BINANCE:RENUSD",
                                                "REN/USDC": "BINANCE:RENUSD",
                                                "REN/TUSD": "BINANCE:RENUSD",
                                                "REN/HUSD": "BINANCE:RENUSD",
                                                "REN/DAI": "BINANCE:RENUSD",
                                                "REN/PAX": "BINANCE:RENUSD",
                                                "REN/EURS": "BITTREX:RENEUR",
                                                "REP/BTC": "BINANCE:REPBTC",
                                                "REP/ETH": "BINANCE:REPETH",
                                                "REP/USDT": "COINBASE:REPUSD",
                                                "REP/BUSD": "COINBASE:REPUSD",
                                                "REP/USDC": "COINBASE:REPUSD",
                                                "REP/REP": "COINBASE:REPUSD",
                                                "REP/HUSD": "COINBASE:REPUSD",
                                                "REP/DAI": "COINBASE:REPUSD",
                                                "REP/PAX": "COINBASE:REPUSD",
                                                "REP/EURS": "KRAKEN:REPEUR",
                                                "REV/BTC": "BITTREX:REVBTC",
                                                "REV/USDT": "BITTREX:REVUSD",
                                                "REV/BUSD": "BITTREX:REVUSD",
                                                "REV/USDC": "BITTREX:REVUSD",
                                                "REV/TUSD": "BITTREX:REVUSD",
                                                "REV/HUSD": "BITTREX:REVUSD",
                                                "REV/DAI": "BITTREX:REVUSD",
                                                "REV/PAX": "BITTREX:REVUSD",
                                                "RLC/BTC": "BINANCE:RLCBTC",
                                                "RLC/ETH": "BINANCE:RLCETH",
                                                "RLC/USDT": "BINANCE:RLCUSD",
                                                "RLC/BUSD": "BINANCE:RLCUSD",
                                                "RLC/USDC": "BINANCE:RLCUSD",
                                                "RLC/TUSD": "BINANCE:RLCUSD",
                                                "RLC/HUSD": "BINANCE:RLCUSD",
                                                "RLC/DAI": "BINANCE:RLCUSD",
                                                "RLC/PAX": "BINANCE:RLCUSD",
                                                "RSR/BTC": "BINANCE:RSRBTC",
                                                "RSR/ETH": "OKEX:RSRETH",
                                                "RSR/USDT": "BINANCE:RSRUSD",
                                                "RSR/BUSD": "BINANCE:RSRUSD",
                                                "RSR/USDC": "BINANCE:RSRUSD",
                                                "RSR/TUSD": "BINANCE:RSRUSD",
                                                "RSR/HUSD": "BINANCE:RSRUSD",
                                                "RSR/DAI": "BINANCE:RSRUSD",
                                                "RSR/PAX": "BINANCE:RSRUSD",
                                                "RSR/BNB": "BINANCE:RSRBNB",
                                                "RSR/HT": "HUOBI:RSRHT",
                                                "RVN/BTC": "BINANCE:RVNBTC",
                                                "RVN/USDT": "BINANCE:RVNUSD",
                                                "RVN/BUSD": "BINANCE:RVNUSD",
                                                "RVN/USDC": "BINANCE:RVNUSD",
                                                "RVN/TUSD": "BINANCE:RVNUSD",
                                                "RVN/HUSD": "BINANCE:RVNUSD",
                                                "RVN/DAI": "BINANCE:RVNUSD",
                                                "RVN/PAX": "BINANCE:RVNUSD",
                                                "RVN/TRYB": "BINANCE:RVNTRY",
                                                "RVN/BNB": "BINANCE:RVNBNB",
                                                "RVN/HT": "HUOBI:RVNHT",
                                                "SHR/BTC": "KUCOIN:SHRBTC",
                                                "SHR/USDT": "BITTREX:SHRUSD",
                                                "SHR/BUSD": "BITTREX:SHRUSD",
                                                "SHR/USDC": "BITTREX:SHRUSD",
                                                "SHR/TUSD": "BITTREX:SHRUSD",
                                                "SHR/HUSD": "BITTREX:SHRUSD",
                                                "SHR/DAI": "BITTREX:SHRUSD",
                                                "SHR/PAX": "BITTREX:SHRUSD",
                                                "SKL/BTC": "BINANCE:SKLBTC",
                                                "SKL/ETH": "HUOBI:SKLETH",
                                                "SKL/USDT": "COINBASE:SKLUSD",
                                                "SKL/BUSD": "COINBASE:SKLUSD",
                                                "SKL/USDC": "COINBASE:SKLUSD",
                                                "SKL/TUSD": "COINBASE:SKLUSD",
                                                "SKL/HUSD": "COINBASE:SKLUSD",
                                                "SKL/DAI": "COINBASE:SKLUSD",
                                                "SKL/PAX": "COINBASE:SKLUSD",
                                                "SKL/EURS": "COINBASE:SKLEUR",
                                                "SNT/BTC": "BINANCE:SNTBTC",
                                                "SNT/ETH": "BINANCE:SNTETH",
                                                "SNT/USDT": "BINANCE:SNTUSD",
                                                "SNT/BUSD": "BINANCE:SNTUSD",
                                                "SNT/USDC": "BINANCE:SNTUSD",
                                                "SNT/TUSD": "BINANCE:SNTUSD",
                                                "SNT/HUSD": "BINANCE:SNTUSD",
                                                "SNT/DAI": "BINANCE:SNTUSD",
                                                "SNT/PAX": "BINANCE:SNTUSD",
                                                "SNX/BTC": "BINANCE:SNXBTC",
                                                "SNX/ETH": "KRAKEN:SNXETH",
                                                "SNX/BNB": "BINANCE:SNXBNB",
                                                "SNX/USDT": "BINANCE:SNXUSD",
                                                "SNX/BUSD": "BINANCE:SNXUSD",
                                                "SNX/USDC": "BINANCE:SNXUSD",
                                                "SNX/TUSD": "BINANCE:SNXUSD",
                                                "SNX/HUSD": "BINANCE:SNXUSD",
                                                "SNX/DAI": "BINANCE:SNXUSD",
                                                "SNX/PAX": "BINANCE:SNXUSD",
                                                "SNX/EURS": "KRAKEN:SNXEUR",
                                                "SPC/BTC": "BITTREX:SPCBTC",
                                                "SPC/ETH": "HITBTC:SPCETH",
                                                "SPC/USDT": "HITBTC:SPCUSDT",
                                                "SRM/BTC": "BINANCE:SRMBTC",
                                                "SRM/USDT": "FTX:SRMUSD",
                                                "SRM/BUSD": "FTX:SRMUSD",
                                                "SRM/USDC": "FTX:SRMUSD",
                                                "SRM/TUSD": "FTX:SRMUSD",
                                                "SRM/HUSD": "FTX:SRMUSD",
                                                "SRM/DAI": "FTX:SRMUSD",
                                                "SRM/PAX": "FTX:SRMUSD",
                                                "SRM/BNB": "BINANCE:SRMBNB",
                                                "SRM/EURS": "KRAKEN:SRMEUR",
                                                "STFIRO/ETH": "SUSHISWAP:STFIROWETH",
                                                "STORJ/BTC": "BINANCE:STORJBTC",
                                                "STORJ/ETH": "KRAKEN:STORJETH",
                                                "STORJ/USDT": "BINANCE:STORJUSD",
                                                "STORJ/BUSD": "BINANCE:STORJUSD",
                                                "STORJ/USDC": "BINANCE:STORJUSD",
                                                "STORJ/TUSD": "BINANCE:STORJUSD",
                                                "STORJ/HUSD": "BINANCE:STORJUSD",
                                                "STORJ/DAI": "BINANCE:STORJUSD",
                                                "STORJ/PAX": "BINANCE:STORJUSD",
                                                "STORJ/EURS": "KRAKEN:STORJEUR",
                                                "SUSHI/BTC": "BINANCE:SUSHIBTC",
                                                "SUSHI/ETH": "HUOBI:SUSHIETH",
                                                "SUSHI/USDT": "BINANCE:SUSHIUSD",
                                                "SUSHI/BUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/USDC": "BINANCE:SUSHIUSD",
                                                "SUSHI/TUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/HUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/DAI": "BINANCE:SUSHIUSD",
                                                "SUSHI/PAX": "BINANCE:SUSHIUSD",
                                                "SUSHI/BNB": "BINANCE:SUSHIBNB",
                                                "SUSHI/EURS": "COINBASE:SUSHIEUR",
                                                "SXP/BTC": "BINANCE:SXPBTC",
                                                "SXP/BNB": "BINANCE:SXPBNB",
                                                "SXP/USDT": "BINANCE:SXPUSD",
                                                "SXP/BUSD": "BINANCE:SXPUSD",
                                                "SXP/USDC": "BINANCE:SXPUSD",
                                                "SXP/TUSD": "BINANCE:SXPUSD",
                                                "SXP/HUSD": "BINANCE:SXPUSD",
                                                "SXP/DAI": "BINANCE:SXPUSD",
                                                "SXP/PAX": "BINANCE:SXPUSD",
                                                "SXP/EURS": "BINANCE:SXPEUR",
                                                "SXP/TRYB": "BINANCE:SXPTRY",
                                                "SXP/BIDR": "BINANCE:SXPBIDR",
                                                "SYS/BTC": "BINANCE:SYSBTC",
                                                "SYS/USDT": "BINANCE:SYSUSD",
                                                "SYS/BUSD": "BINANCE:SYSUSD",
                                                "SYS/USDC": "BINANCE:SYSUSD",
                                                "SYS/TUSD": "BINANCE:SYSUSD",
                                                "SYS/HUSD": "BINANCE:SYSUSD",
                                                "SYS/DAI": "BINANCE:SYSUSD",
                                                "SYS/PAX": "BINANCE:SYSUSD",
                                                "TMTG/BTC": "OKEX:TMTGBTC",
                                                "TMTG/USDT": "OKEX:TMTGUSDT",
                                                "TRAC/BTC": "KUCOIN:TRACBTC",
                                                "TRAC/ETH": "KUCOIN:TRACETH",
                                                "TRAC/USDT": "BITTREX:TRACUSD",
                                                "TRAC/BUSD": "BITTREX:TRACUSD",
                                                "TRAC/USDC": "BITTREX:TRACUSD",
                                                "TRAC/TUSD": "BITTREX:TRACUSD",
                                                "TRAC/HUSD": "BITTREX:TRACUSD",
                                                "TRAC/DAI": "BITTREX:TRACUSD",
                                                "TRAC/PAX": "BITTREX:TRACUSD",
                                                "TRX/BTC": "BINANCE:TRXBTC",
                                                "TRX/ETH": "BINANCE:TRXETH",
                                                "TRX/USDT": "KRAKEN:TRXUSD",
                                                "TRX/BUSD": "KRAKEN:TRXUSD",
                                                "TRX/USDC": "KRAKEN:TRXUSD",
                                                "TRX/TUSD": "KRAKEN:TRXUSD",
                                                "TRX/HUSD": "KRAKEN:TRXUSD",
                                                "TRX/DAI": "KRAKEN:TRXUSD",
                                                "TRX/PAX": "KRAKEN:TRXUSD",
                                                "TRX/BNB": "BINANCE:TRXBNB",
                                                "TRX/EURS": "KRAKEN:TRXEUR",
                                                "TRX/TRYB": "BINANCE:TRXTRY",
                                                "TRX/BCH": "HITBTC:TRXBCH",
                                                "TRYB/USDT": "FX_IDC:TRYUSD",
                                                "TRYB/BUSD": "FX_IDC:TRYUSD",
                                                "TRYB/USDC": "FX_IDC:TRYUSD",
                                                "TRYB/TUSD": "FX_IDC:TRYUSD",
                                                "TRYB/HUSD": "FX_IDC:TRYUSD",
                                                "TRYB/DAI": "FX_IDC:TRYUSD",
                                                "TRYB/PAX": "FX_IDC:TRYUSD",
                                                "TRYB/EURS": "FX_IDC:TRYEUR",
                                                "THC/BTC": "BITTREX:THCBTC",
                                                "THC/USDT": "BITTREX:THCUSD",
                                                "THC/BUSD": "BITTREX:THCUSD",
                                                "THC/USDC": "BITTREX:THCUSD",
                                                "THC/TUSD": "BITTREX:THCUSD",
                                                "THC/HUSD": "BITTREX:THCUSD",
                                                "THC/DAI": "BITTREX:THCUSD",
                                                "THC/PAX": "BITTREX:THCUSD",
                                                "UBT/BTC": "BITTREX:UBTBTC",
                                                "UBT/ETH": "BITTREX:UBTETH",
                                                "UBT/USDT": "BITTREX:UBTUSD",
                                                "UBT/BUSD": "BITTREX:UBTUSD",
                                                "UBT/USDC": "BITTREX:UBTUSD",
                                                "UBT/TUSD": "BITTREX:UBTUSD",
                                                "UBT/HUSD": "BITTREX:UBTUSD",
                                                "UBT/DAI": "BITTREX:UBTUSD",
                                                "UBT/PAX": "BITTREX:UBTUSD",
                                                "UBT/EURS": "BITTREX:UBTEUR",
                                                "UMA/BTC": "BINANCE:UMABTC",
                                                "UMA/ETH": "OKEX:UMAETH",
                                                "UMA/USDT": "COINBASE:UMAUSD",
                                                "UMA/BUSD": "COINBASE:UMAUSD",
                                                "UMA/USDC": "COINBASE:UMAUSD",
                                                "UMA/TUSD": "COINBASE:UMAUSD",
                                                "UMA/HUSD": "COINBASE:UMAUSD",
                                                "UMA/DAI": "COINBASE:UMAUSD",
                                                "UMA/PAX": "COINBASE:UMAUSD",
                                                "UMA/EURS": "COINBASE:UMAEUR",
                                                "UNI/BTC": "BINANCE:UNIBTC",
                                                "UNI/ETH": "KRAKEN:UNIETH",
                                                "UNI/USDT": "COINBASE:UNIUSD",
                                                "UNI/BUSD": "COINBASE:UNIUSD",
                                                "UNI/USDC": "COINBASE:UNIUSD",
                                                "UNI/TUSD": "COINBASE:UNIUSD",
                                                "UNI/HUSD": "COINBASE:UNIUSD",
                                                "UNI/DAI": "COINBASE:UNIUSD",
                                                "UNI/PAX": "COINBASE:UNIUSD",
                                                "UNI/BNB": "BINANCE:UNIBNB",
                                                "UNI/EURS": "KRAKEN:UNIEUR",
                                                "UOS/BTC": "BITFINEX:UOSBTC",
                                                "UOS/USDT": "BITFINEX:UOSUSD",
                                                "UOS/BUSD": "BITFINEX:UOSUSD",
                                                "UOS/USDC": "BITFINEX:UOSUSD",
                                                "UOS/TUSD": "BITFINEX:UOSUSD",
                                                "UOS/HUSD": "BITFINEX:UOSUSD",
                                                "UOS/DAI": "BITFINEX:UOSUSD",
                                                "UOS/PAX": "BITFINEX:UOSUSD",
                                                "UQC/BTC": "BITTREX:UQCBTC",
                                                "UQC/ETH": "KUCOIN:UQCETH",
                                                "UQC/USDT": "BITTREX:UQCUSD",
                                                "UQC/BUSD": "BITTREX:UQCUSD",
                                                "UQC/USDC": "BITTREX:UQCUSD",
                                                "UQC/TUSD": "BITTREX:UQCUSD",
                                                "UQC/HUSD": "BITTREX:UQCUSD",
                                                "UQC/DAI": "BITTREX:UQCUSD",
                                                "UQC/PAX": "BITTREX:UQCUSD",
                                                "UTK/BTC": "BINANCE:UTKBTC",
                                                "UTK/ETH": "HUOBI:UTKETH",
                                                "UTK/USDT": "BINANCE:UTKUSD",
                                                "UTK/BUSD": "BINANCE:UTKUSD",
                                                "UTK/USDC": "BINANCE:UTKUSD",
                                                "UTK/TUSD": "BINANCE:UTKUSD",
                                                "UTK/HUSD": "BINANCE:UTKUSD",
                                                "UTK/DAI": "BINANCE:UTKUSD",
                                                "UTK/PAX": "BINANCE:UTKUSD",
                                                "VAL/BTC": "BITTREX:VALBTC",
                                                "VAL/USDT": "BITTREX:VALUSD",
                                                "VAL/BUSD": "BITTREX:VALUSD",
                                                "VAL/USDC": "BITTREX:VALUSD",
                                                "VAL/TUSD": "BITTREX:VALUSD",
                                                "VAL/HUSD": "BITTREX:VALUSD",
                                                "VAL/DAI": "BITTREX:VALUSD",
                                                "VAL/PAX": "BITTREX:VALUSD",
                                                "VITE/BTC": "BINANCE:VITEBTC",
                                                "VITE/USDT": "BINANCE:VITEUSD",
                                                "VITE/BUSD": "BINANCE:VITEUSD",
                                                "VITE/USDC": "BINANCE:VITEUSD",
                                                "VITE/TUSD": "BINANCE:VITEUSD",
                                                "VITE/HUSD": "BINANCE:VITEUSD",
                                                "VITE/DAI": "BINANCE:VITEUSD",
                                                "VITE/PAX": "BINANCE:VITEUSD",
                                                "VRA/BTC": "KUCOIN:VRABTC",
                                                "VRA/USDT": "BITTREX:VRAUSD",
                                                "VRA/BUSD": "BITTREX:VRAUSD",
                                                "VRA/USDC": "BITTREX:VRAUSD",
                                                "VRA/TUSD": "BITTREX:VRAUSD",
                                                "VRA/HUSD": "BITTREX:VRAUSD",
                                                "VRA/DAI": "BITTREX:VRAUSD",
                                                "VRA/PAX": "BITTREX:VRAUSD",
                                                "WBTC/BTC": "BINANCE:WBTCBTC",
                                                "WBTC/ETH": "BINANCE:WBTCETH",
                                                "WBTC/USDT": "COINBASE:WBTCUSD",
                                                "WBTC/BUSD": "COINBASE:WBTCUSD",
                                                "WBTC/USDC": "COINBASE:WBTCUSD",
                                                "WBTC/TUSD": "COINBASE:WBTCUSD",
                                                "WBTC/HUSD": "COINBASE:WBTCUSD",
                                                "WBTC/DAI": "COINBASE:WBTCUSD",
                                                "WBTC/PAX": "COINBASE:WBTCUSD",
                                                "XLM/BTC": "BINANCE:XLMBTC",
                                                "XLM/ETH": "BINANCE:XLMETH",
                                                "XLM/USDT": "COINBASE:XLMUSD",
                                                "XLM/BUSD": "COINBASE:XLMUSD",
                                                "XLM/USDC": "COINBASE:XLMUSD",
                                                "XLM/TUSD": "COINBASE:XLMUSD",
                                                "XLM/HUSD": "COINBASE:XLMUSD",
                                                "XLM/DAI": "COINBASE:XLMUSD",
                                                "XLM/PAX": "COINBASE:XLMUSD",
                                                "XLM/BNB": "BINANCE:XLMBNB",
                                                "XLM/EURS": "KRAKEN:XLMEUR",
                                                "XLM/TRYB": "BINANCE:XLMTRY",
                                                "XLM/BCH": "HITBTC:XLMBCH",
                                                "XMY/BTC": "BITTREX:XMYBTC",
                                                "XMY/USDT": "BITTREX:XMYUSD",
                                                "XMY/BUSD": "BITTREX:XMYUSD",
                                                "XMY/USDC": "BITTREX:XMYUSD",
                                                "XMY/TUSD": "BITTREX:XMYUSD",
                                                "XMY/HUSD": "BITTREX:XMYUSD",
                                                "XMY/DAI": "BITTREX:XMYUSD",
                                                "XMY/PAX": "BITTREX:XMYUSD",
                                                "XRP/BTC": "BINANCE:XRPBTC",
                                                "XRP/ETH": "BINANCE:XRPETH",
                                                "XRP/USDT": "BITSTAMP:XRPUSD",
                                                "XRP/BUSD": "BITSTAMP:XRPUSD",
                                                "XRP/USDC": "BITSTAMP:XRPUSD",
                                                "XRP/TUSD": "BITSTAMP:XRPUSD",
                                                "XRP/HUSD": "BITSTAMP:XRPUSD",
                                                "XRP/DAI": "BITSTAMP:XRPUSD",
                                                "XRP/PAX": "BITSTAMP:XRPUSD",
                                                "XRP/BNB": "BINANCE:XRPBNB",
                                                "XRP/EURS": "HITBTC:XRPEURS",
                                                "XRP/TRYB": "BINANCE:XRPTRY",
                                                "XRP/BIDR": "BITFINEX:XRPIDR",
                                                "XRP/BCH": "HITBTC:XRPBCH",
                                                "XRP/HT": "HUOBI:XRPHT",
                                                "XRP/TRX": "POLONIEX:XRPTRX",
                                                "XTZ/BTC": "BINANCE:XTZBTC",
                                                "XTZ/ETH": "KRAKEN:XTZETH",
                                                "XTZ/USDT": "COINBASE:XTZUSD",
                                                "XTZ/BUSD": "COINBASE:XTZUSD",
                                                "XTZ/USDC": "COINBASE:XTZUSD",
                                                "XTZ/TUSD": "COINBASE:XTZUSD",
                                                "XTZ/HUSD": "COINBASE:XTZUSD",
                                                "XTZ/DAI": "COINBASE:XTZUSD",
                                                "XTZ/PAX": "COINBASE:XTZUSD",
                                                "XTZ/BNB": "BINANCE:XTZBNB",
                                                "XTZ/EURS": "KRAKEN:XTZEUR",
                                                "XTZ/TRX": "POLONIEX:XTZTRX",
                                                "XVS/BTC": "BINANCE:XVSBTC",
                                                "XVS/USDT": "BINANCE:XVSUSD",
                                                "XVS/BUSD": "BINANCE:XVSUSD",
                                                "XVS/USDC": "BINANCE:XVSUSD",
                                                "XVS/TUSD": "BINANCE:XVSUSD",
                                                "XVS/HUSD": "BINANCE:XVSUSD",
                                                "XVS/DAI": "BINANCE:XVSUSD",
                                                "XVS/PAX": "BINANCE:XVSUSD",
                                                "XVS/BNB": "BINANCE:XVSBNB",
                                                "YFI/BTC": "BINANCE:YFIBTC",
                                                "YFI/ETH": "HUOBI:YFIETH",
                                                "YFI/BNB": "BINANCE:YFIBNB",
                                                "YFI/USDT": "BINANCE:YFIUSD",
                                                "YFI/BUSD": "BINANCE:YFIUSD",
                                                "YFI/USDC": "BINANCE:YFIUSD",
                                                "YFI/TUSD": "BINANCE:YFIUSD",
                                                "YFI/HUSD": "BINANCE:YFIUSD",
                                                "YFI/DAI": "BINANCE:YFIUSD",
                                                "YFI/PAX": "BINANCE:YFIUSD",
                                                "YFI/EURS": "KRAKEN:YFIEUR",
                                                "YFII/BTC": "BINANCE:YFIIBTC",
                                                "YFII/ETH": "HUOBI:YFIIETH",
                                                "YFII/BNB": "BINANCE:YFIIBNB",
                                                "YFII/USDT": "BINANCE:YFIIUSD",
                                                "YFII/BUSD": "BINANCE:YFIIUSD",
                                                "YFII/USDC": "BINANCE:YFIIUSD",
                                                "YFII/TUSD": "BINANCE:YFIIUSD",
                                                "YFII/HUSD": "BINANCE:YFIIUSD",
                                                "YFII/DAI": "BINANCE:YFIIUSD",
                                                "YFII/PAX": "BINANCE:YFIIUSD",
                                                "ZEC/BTC": "BINANCE:ZECBTC",
                                                "ZEC/ETH": "BINANCE:ZECETH",
                                                "ZEC/USDT": "KRAKEN:ZECUSD",
                                                "ZEC/BUSD": "KRAKEN:ZECUSD",
                                                "ZEC/USDC": "KRAKEN:ZECUSD",
                                                "ZEC/TUSD": "KRAKEN:ZECUSD",
                                                "ZEC/HUSD": "KRAKEN:ZECUSD",
                                                "ZEC/DAI": "KRAKEN:ZECUSD",
                                                "ZEC/PAX": "KRAKEN:ZECUSD",
                                                "ZEC/BNB": "BINANCE:ZECBNB",
                                                "ZEC/EURS": "HITBTC:ZECEURS",
                                                "ZEC/BCH": "HITBTC:ZECBCH",
                                                "ZEC/LTC": "GEMINI:ZECLTC",
                                                "ZIL/BTC": "BINANCE:ZILBTC",
                                                "ZIL/ETH": "BINANCE:ZILETH",
                                                "ZIL/USDT": "BINANCE:ZILUSD",
                                                "ZIL/BUSD": "BINANCE:ZILUSD",
                                                "ZIL/USDC": "BINANCE:ZILUSD",
                                                "ZIL/TUSD": "BINANCE:ZILUSD",
                                                "ZIL/HUSD": "BINANCE:ZILUSD",
                                                "ZIL/DAI": "BINANCE:ZILUSD",
                                                "ZIL/PAX": "BINANCE:ZILUSD",
                                                "ZIL/BIDR": "BINANCE:ZILBIDR",
                                                "ZIL/BNB": "BINANCE:ZILBNB",
                                                "ZRX/BTC": "BINANCE:ZRXBTC",
                                                "ZRX/ETH": "BINANCE:ZRXETH",
                                                "ZRX/USDT": "BINANCE:ZRXUSD",
                                                "ZRX/BUSD": "BINANCE:ZRXUSD",
                                                "ZRX/USDC": "BINANCE:ZRXUSD",
                                                "ZRX/TUSD": "BINANCE:ZRXUSD",
                                                "ZRX/HUSD": "BINANCE:ZRXUSD",
                                                "ZRX/DAI": "BINANCE:ZRXUSD",
                                                "ZRX/PAX": "BINANCE:ZRXUSD",
                                                "ZRX/EURS": "COINBASE:ZRXEUR"
                                            })
}
