pragma Singleton
import QtQuick 2.15
import AtomicDEX.TradingError 1.0

QtObject {
    readonly property int width: 1280
    readonly property int height: 800
    readonly property int minimumWidth: 1280
    readonly property int minimumHeight: 800

    readonly property string os_file_prefix: Qt.platform.os == "windows" ? "file:///" : "file://"
    readonly property string assets_path: Qt.resolvedUrl(".") + "../../assets/"
    readonly property string image_path: assets_path + "images/"
    readonly property string coin_icons_path: image_path + "coins/"
    readonly property string custom_coin_icons_path: os_file_prefix + API.app.settings_pg.get_custom_coins_icons_path() + "/"
    function coinIcon(ticker) {
        if(ticker === "") return ""

        const coin_info = API.app.get_coin_info(ticker)
        return (coin_info.is_custom_coin ? custom_coin_icons_path : coin_icons_path) + ticker.toLowerCase() + ".png"
    }

    function qaterialIcon(name) {
        return "qrc:/Qaterial/Icons/" + name + ".svg"
    }

    readonly property string cex_icon: 'ⓘ'
    readonly property string download_icon: '📥'
    readonly property string right_arrow_icon: "⮕"
    readonly property string privacy_text: "*****"

    readonly property string version_string: "Desktop v" + API.app.get_version()

    property bool privacy_mode: false

    readonly property int idx_dashboard_portfolio: 0
    readonly property int idx_dashboard_wallet: 1
    readonly property int idx_dashboard_exchange: 2
    readonly property int idx_dashboard_addressbook: 3
    readonly property int idx_dashboard_news: 4
    readonly property int idx_dashboard_dapps: 5
    readonly property int idx_dashboard_settings: 6
    readonly property int idx_dashboard_support: 7
    readonly property int idx_dashboard_light_ui: 8
    readonly property int idx_dashboard_privacy_mode: 9

    readonly property int idx_exchange_trade: 0
    readonly property int idx_exchange_orders: 1
    readonly property int idx_exchange_history: 2

    readonly property var reg_pass_input: /[A-Za-z0-9@#$%{}[\]()\/\\'"`~,;:.<>+\-_=!^&*|?]+/
    readonly property var reg_pass_valid_low_security: /^(?=.{1,}).*$/
    readonly property var reg_pass_valid: /^(?=.{16,})(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[@#$%{}[\]()\/\\'"`~,;:.<>+\-_=!^&*|?]).*$/
    readonly property var reg_pass_uppercase: /(?=.*[A-Z])/
    readonly property var reg_pass_lowercase: /(?=.*[a-z])/
    readonly property var reg_pass_numeric: /(?=.*[0-9])/
    readonly property var reg_pass_special: /(?=.*[@#$%{}[\]()\/\\'"`~,;:.<>+\-_=!^&*|?])/
    readonly property var reg_pass_count_low_security: /(?=.{1,})/
    readonly property var reg_pass_count: /(?=.{16,})/

    readonly property double time_toast_important_error: 10000
    readonly property double time_toast_basic_info: 3000

    readonly property var chart_times: (["1m", "3m", "5m", "15m", "30m", "1h", "2h", "4h", "6h", "12h", "1d", "3d"/*, "1w"*/])
    readonly property var time_seconds: ({ "1m": 60, "3m": 180, "5m": 300, "15m": 900, "30m": 1800, "1h": 3600, "2h": 7200, "4h": 14400, "6h": 21600, "12h": 43200, "1d": 86400, "3d": 259200, "1w": 604800 })

    property var all_coins

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
            const coin_info = API.app.get_coin_info(ticker)
            const id_prefix = add_0x && coin_info.type === 'ERC-20' ? '0x' : ''
            Qt.openUrlExternally(coin_info.explorer_url + coin_info.tx_uri + id_prefix + id)
        }
    }

    function viewAddressAtExplorer(ticker, address) {
        if(address !== '') {
            const coin_info = API.app.get_coin_info(ticker)
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
        return diffPrefix(received) + ticker + " " + formatDouble(amount) + (fiat_amount ? " (" + formatFiat("", fiat_amount, fiat) + ")" : "")
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
        return 0.00777
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
        for(const c of API.app.enabled_coins)
            if(c.type === type && c.ticker !== ticker) return true

        return false
    }

    property Timer prevent_coin_disabling: Timer { interval: 5000 }

    function canDisable(ticker) {
        if(prevent_coin_disabling.running)
            return false

        if(ticker === "KMD" || ticker === "BTC") return false
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
        else if(type === "Smart Chain") return "KMD"
        return "?"
    }

    function isCoinEnabled(ticker) {
        for(const c of API.app.enabled_coins)
            if(c.ticker === ticker) return true

        return false
    }

    function enableParentCoinIfNeeded(ticker, type) {
        if(!isCoinEnabled(ticker) && isParentCoinNeeded(ticker, type)) {
            API.app.enable_coins([ticker])
            return true
        }

        return false
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

        return tx_fee + "\n" + trading_fee
    }

    function txFeeText(trade_info, base_ticker, has_info_icon=true, has_limited_space=false) {
        if(!trade_info || !trade_info.trading_fee) return ""

        const has_parent_coin_fees = hasParentCoinFees(trade_info)
        const main_fee = (qsTr('Transaction Fee') + ': ' + General.formatCrypto("", trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker)) +
                                 // Rel Fees
                                 (has_parent_coin_fees ? " + " + General.formatCrypto("", trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker) : '')

        let fiat_part = "("
        fiat_part += getFiatText(trade_info.base_transaction_fees, trade_info.base_transaction_fees_ticker, false)
        if(has_parent_coin_fees) fiat_part += (has_limited_space ? "\n\t\t+ " : " + ") + getFiatText(trade_info.rel_transaction_fees, trade_info.rel_transaction_fees_ticker, has_info_icon)
        fiat_part += ")"

        return main_fee + " " + fiat_part
    }

    function tradingFeeText(trade_info, base_ticker, has_info_icon=true) {
        if(!trade_info || !trade_info.trading_fee) return ""

        return qsTr('Trading Fee') + ': ' + General.formatCrypto("", trade_info.trading_fee, trade_info.trading_fee_ticker) +

                // Fiat part
                (" ("+
                    getFiatText(trade_info.trading_fee, trade_info.trading_fee_ticker, has_info_icon)
                 +")")
    }

    function checkIfWalletExists(name) {
        if(API.app.get_wallets().indexOf(name) !== -1)
            return qsTr("Wallet %1 already exists", "WALLETNAME").arg(name)

        return ""
    }

    function getTradingError(error, fee_info, base_ticker, rel_ticker) {
        switch(error) {
        case TradingError.None:
            return ""
        case TradingError.TradingFeesNotEnoughFunds:
            return qsTr("Not enough balance for trading fees: %1", "AMT TICKER").arg(General.formatCrypto("", fee_info.trading_fee, fee_info.trading_fee_ticker))
        case TradingError.BaseNotEnoughFunds:
            return qsTr("Not enough balance for fees: %1", "AMT TICKER").arg(General.formatCrypto("", fee_info.total_base_fees, base_ticker))
        case TradingError.BaseTransactionFeesNotEnough:
            return qsTr("Not enough balance for transaction fees: %1", "AMT TICKER").arg(General.formatCrypto("", fee_info.base_transaction_fees, fee_info.base_transaction_fees_ticker))
        case TradingError.RelTransactionFeesNotEnough:
            return qsTr("Not enough balance for transaction fees: %1", "AMT TICKER").arg(General.formatCrypto("", fee_info.rel_transaction_fees, fee_info.rel_transaction_fee_ticker))
        case TradingError.BalanceIsLessThanTheMinimalTradingAmount:
            return qsTr("Tradable (after fees) %1 balance is lower than minimum trade amount").arg(base_ticker) + " : " + General.getMinTradeAmount()
        case TradingError.PriceFieldNotFilled:
            return qsTr("Please fill the price field")
        case TradingError.VolumeFieldNotFilled:
            return qsTr("Please fill the volume field")
        case TradingError.VolumeIsLowerThanTheMinimum:
            return qsTr("%1 volume is lower than minimum trade amount").arg(base_ticker) + " : " + General.getMinTradeAmount()
        case TradingError.ReceiveVolumeIsLowerThanTheMinimum:
            return qsTr("%1 volume is lower than minimum trade amount").arg(rel_ticker) + " : " + General.getMinTradeAmount()
        default:
            return qsTr("Unknown Error") + ": " + error
        }
    }

    readonly property var supported_pairs: ({
                                                "KMD/BTC": "BINANCE:KMDBTC",
                                                "KMD/ETH": "BINANCE:KMDETH",
                                                "KMD/BUSD": "BINANCE:KMDBUSD",
                                                "KMD/USDT": "BINANCE:KMDUSDT",
                                                "ETH/BTC": "BINANCE:ETHBTC",
                                                "ETH/USDC": "BINANCE:ETHUSDC",
                                                "ETH/BUSD": "BINANCE:ETHBUSD",
                                                "BTC/UDSC": "BINANCE:BTCUSDC",
                                                "BTC/BUSD": "BINANCE:BTCBUSD",
                                                "LTC/BTC": "BINANCE:LTCBTC",
                                                "LTC/ETH": "BINANCE:LTCETH",
                                                "LTC/BUSD": "BINANCE:LTCBUSD",
                                                "LTC/USDC": "BINANCE:LTCUSDC",
                                                "BCH/BTC": "BINANCE:BCHBTC",
                                                "BCH/ETH": "BITTREX:BCHETH",
                                                "BCH/BUSD": "BINANCE:BCHBUSD",
                                                "BCH/USDC": "BINANCE:BCHUSDC",
                                                "BCH/PAX": "BINANCE:BCHPAX",
                                                "BAT/BUSD": "BINANCE:BATBUSD",
                                                "BAT/USDC": "BINANCE:BATUSDC",
                                                "BAT/BTC": "BINANCE:BATBTC",
                                                "BAT/ETH": "BITTREX:BATETH",
                                                "DASH/BUSD": "BINANCE:DASHBUSD",
                                                "DASH/ETH": "BINANCE:DASHETH",
                                                "DASH/BTC": "BINANCE:DASHBTC",
                                                "QTUM/BUSD": "BINANCE:QTUMBUSD",
                                                "QTUM/ETH": "BINANCE:QTUMETH",
                                                "QTUM/BTC": "BINANCE:QTUMBTC",
                                                "RVN/BUSD": "BINANCE:RVNBUSD",
                                                "RVN/BTC": "BINANCE:RVNBTC",
                                                "XZC/ETH": "BINANCE:XZCETH",
                                                "XZC/BTC": "BINANCE:XZCBTC",
                                                "DOGE/BTC": "BINANCE:DOGEBTC",
                                                "DOGE/BUSD": "BINANCE:DOGEBUSD",
                                                "DGB/BUSD": "BINANCE:DGBBUSD",
                                                "DGB/BTC": "BINANCE:DGBBTC",
                                                "FTC/BTC": "BITTREX:FTCBTC",
                                                "EMC2/BTC": "BITTREX:EMC2BTC",
                                                "DAI/BTC": "BITTREX:DAIBTC",
                                                "ZEC/BUSD": "BINANCE:ZECBUSD",
                                                "ZEC/ETH": "BINANCE:ZECETH",
                                                "ZEC/BTC": "BINANCE:ZECBTC",
                                                "ZEC/USDC": "BINANCE:ZECUSDC"
                                            })
}
