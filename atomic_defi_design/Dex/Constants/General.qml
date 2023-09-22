pragma Singleton
import QtQuick 2.15
import AtomicDEX.TradingError 1.0
import AtomicDEX.MarketMode 1.0

QtObject {
    readonly property int width: 1280 // Set for maximum user compatibility 
    readonly property int height: 720 // See https://gs.statcounter.com/screen-resolution-stats/desktop/worldwide
    readonly property int minimumWidth: 1280
    readonly property int minimumHeight: 720
    readonly property int max_camo_pw_length: 256
    readonly property int max_std_pw_length: 256
    readonly property int max_pw_length: max_std_pw_length + max_camo_pw_length
    readonly property double delta_time: 1000/60

    readonly property string os_file_prefix: Qt.platform.os == "windows" ? "file:///" : "file://"
    readonly property string assets_path: "qrc:///"
    readonly property string image_path: assets_path + "assets/images/"
    readonly property string coin_icons_path: image_path + "coins/"
    readonly property string custom_coin_icons_path: os_file_prefix + API.app.settings_pg.get_custom_coins_icons_path() + "/"
    readonly property string providerIconsPath: image_path + "providers/"

    function coinIcon(ticker)
    {
        if (ticker === "" || ticker === "All" || ticker===undefined)
        {
            return ""
        }
        else
        {
            if (['THC-BEP20'].indexOf(ticker) >= 0)
            {
                return coin_icons_path + ticker.toString().toLowerCase().replace('-', '_') + ".png"
            }
            if (['Smart Chain'].indexOf(ticker) >= 0)
            {
                return coin_icons_path + ticker.toString().toLowerCase().replace(' ', '_') + ".png"
            }
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            let icon = atomic_qt_utilities.retrieve_main_ticker(ticker.toString()).toLowerCase() + ".png"
            return (coin_info.is_custom_coin ? custom_coin_icons_path : coin_icons_path) + icon
        }
    }

    function getChartTicker(ticker)
    {
        let coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
        return coin_info.livecoinwatch_id
    }

    function coinWithoutSuffix(ticker)
    {
        if (ticker.search("-") > -1)
        {
            return ticker.split("-")[0]
        }
        else
        {
            return ticker
        }
    }

    function is_testcoin(ticker)
    {
        let coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
        return coin_info.is_testnet
    }

    function coinName(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        } else {
            const name = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker).name
            return name
        }
    }

    function canSend(ticker, progress=100)
    {
        if (!API.app.wallet_pg.send_available) return false
        if (isZhtlc(ticker) && progress < 100) return false
        return true
    }

    function isWalletOnly(ticker)
    {
        return API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker).is_wallet_only
    }

    function isFaucetCoin(ticker)
    {
        return API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker).is_faucet_coin
    }

    function isCoinWithMemo(ticker) {
        const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
        return coin_info.has_memos
    }

    function getLanguage()
    {
        return API.app.settings_pg.lang
    }

    function isZhtlc(ticker)
    {
        const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
        return coin_info.is_zhtlc_family
    }

    function isZhtlcReady(ticker)
    {
        if (!isZhtlc(ticker)) return true
        let activation_status = API.app.get_zhtlc_status(ticker)
        let progress = zhtlcActivationProgress(activation_status, ticker)
        if (progress == 100) return true
        return false
    }

    function zhtlcActivationProgress(activation_status, coin='ARRR')
    {
        let progress = 100
        if (!activation_status.hasOwnProperty("result")) return progress
        const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin)
        let block_offset = coin_info.checkpoint_height
        let status = activation_status.result.status
        let details = activation_status.result.details
        // use range from checkpoint block to present
        if (!status)
        {
            return -1
        }
        else if (status == "Ok")
        {
            if (details.hasOwnProperty("error"))
                console.log("["+coin+"] [zhtlcActivationProgress] Error enabling: " + JSON.stringify(details.error))
        }
        else if (status == "InProgress")
        {
            if (details.hasOwnProperty("UpdatingBlocksCache"))
            {
                block_offset = details.UpdatingBlocksCache.first_sync_block.actual
                let n = details.UpdatingBlocksCache.current_scanned_block - block_offset
                let d = details.UpdatingBlocksCache.latest_block - block_offset
                progress = 5 + parseInt(n/d*20)
            }
            else if (details.hasOwnProperty("BuildingWalletDb"))
            {
                block_offset = details.BuildingWalletDb.first_sync_block.actual
                let n = details.BuildingWalletDb.current_scanned_block - block_offset
                let d = details.BuildingWalletDb.latest_block - block_offset
                progress = 45 + parseInt(n/d*60)
                if (progress > 95) {
                    progress = 95
                }
                
            }
            else if (details.hasOwnProperty("RequestingBalance")) progress = 95
            else if (details.hasOwnProperty("ActivatingCoin")) progress = 5
            else progress = 5
        }
        else console.log("["+coin+"] [zhtlcActivationProgress] Unexpected status: " + status)
        if (progress > 100) {
            progress = 98
        }
        
        return progress
    }

    function coinContractAddress(ticker) {
        var cfg = API.app.trading_pg.get_raw_mm2_coin_cfg(ticker)
        if (cfg.hasOwnProperty('protocol')) {
            if (cfg.protocol.hasOwnProperty('protocol_data')) {
                if (cfg.protocol.protocol_data.hasOwnProperty('contract_address')) {
                    return cfg.protocol.protocol_data.contract_address
                }
            }
        }
        return ""
    }

    function coinPlatform(ticker) {
        var cfg = API.app.trading_pg.get_raw_mm2_coin_cfg(ticker)
        if (cfg.hasOwnProperty('protocol')) {
            if (cfg.protocol.hasOwnProperty('protocol_data')) {
                if (cfg.protocol.protocol_data.hasOwnProperty('platform')) {
                    return cfg.protocol.protocol_data.platform
                }
            }
        }
        return ""
    }

    function platformIcon(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        } else {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            return (coin_info.is_custom_coin ? custom_coin_icons_path : coin_icons_path)
                + atomic_qt_utilities.retrieve_main_ticker(ticker.toString()).toLowerCase() + ".png"
        }
    }

    function contractURL(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        } else {
            let token_platform = coinPlatform(ticker)
            switch(token_platform) {
                case "BNB":
                    return "https://bscscan.com/token/" + coinContractAddress(ticker)
                case "FTM":
                    return "https://ftmscan.com/token/" + coinContractAddress(ticker)
                case "HT":
                    return "https://hecoinfo.com/token/" + coinContractAddress(ticker)
                case "MATIC":
                    return "https://polygonscan.com/token/" + coinContractAddress(ticker)
                case "AVAX":
                    return "https://avascan.info/blockchain/c/address/" + coinContractAddress(ticker)
                case "KCS":
                    return "https://explorer.kcc.io/en/token/" + coinContractAddress(ticker)
                case "ETH":
                    return "https://etherscan.io/token/" + coinContractAddress(ticker)
                case "ONE":
                    return "https://explorer.harmony.one/address/" + coinContractAddress(ticker)
                case "MOVR":
                    return "https://moonriver.moonscan.io/token/" + coinContractAddress(ticker)
                default:
                    return ""
            }
        }
    }


    function getProtocolText(ticker) {
        if(ticker === "" || ticker === "All" || ticker===undefined) {
            return ""
        } else {
            let token_platform = coinPlatform(ticker)
            switch(token_platform) {
                case "BNB":
                    return "Binance Smart Chain (BEP20 token)"
                case "FTM":
                    return "Fantom (FTM20 token)"
                case "ONE":
                    return "Harmony (HRC20 token)"
                case "ETH":
                    return "Ethereum (ERC20 token)"
                case "KCS":
                    return "KuCoin (KRC20 token)"
                case "MATIC":
                    return "Polygon (PLG20 token)"
                case "AVAX":
                    return "Avalanche (AVX20 token)"
                case "HT":
                    return "Heco Chain (HCO20 token)"
                case "MOVR":
                    return "Moonriver (MVR20 token)"
                case "QTUM":
                    return "QTUM (QRC20 token)"
                default:
                    return ticker + " (" + token_platform + ")"
            }
        }
    }

    function isIDO(ticker) {
        let IDO_chains = []
        return IDO_chains.includes(ticker)
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

    function logObject(obj) {
        for (var key in obj) {
            console.log(key + ": " + obj[key]);
        }
    }

    function flipFalse(obj) {
        if (obj === false) return true
        return obj
    }

    function flipTrue(obj) {
        if (obj === true) return false
        return obj
    }

    function getCustomFeeType(ticker_infos)
    {
        if (["SLP", "ZHTLC", "Moonbeam", "QRC-20"].includes(ticker_infos.type)) return ""
        if (!General.isSpecialToken(ticker_infos) && !General.isParentCoin(ticker_infos.ticker) ||  ["KMD"].includes(ticker_infos.ticker))
        {
            return "UTXO"
        }
        else
        {
            return "Gas"
        }
    }

    function getFeesDetail(fees) {
        return [
            {"label": qsTr("<b>Taker tx fee:</b> "), "fee": fees.base_transaction_fees, "ticker": fees.base_transaction_fees_ticker},
            {"label": qsTr("<b>Dex tx fee:</b> "), "fee": fees.fee_to_send_taker_fee, "ticker": fees.fee_to_send_taker_fee_ticker},
            {"label": qsTr("<b>Dex fee:</b> "), "fee": fees.trading_fee, "ticker": fees.trading_fee_ticker},
            {"label": qsTr("<b>Maker tx fee:</b> "), "fee": fees.rel_transaction_fees, "ticker": fees.rel_transaction_fees_ticker}
        ]
    }

    function getFeesDetailText(feetype, amount, ticker) {
        if ([feetype, amount, ticker].includes(undefined)) return ""
        let fiat_text = General.getFiatText(amount, ticker, false)
        amount = formatDouble(amount, 8, false).toString()
        return feetype + " " + amount + " " + ticker + " (" + fiat_text + ")"
    }

    function getSimpleFromPlaceholder(selectedTicker, selectedOrder, sell_ticker_balance) {
        if (sell_ticker_balance == 0)
        {
            return qsTr("%1 balance is zero").arg(selectedTicker)
        }
        if (!isZhtlcReady(selectedTicker))
        {
            return qsTr("Activating %1 (%2%)").arg(atomic_qt_utilities.retrieve_main_ticker(selectedTicker)).arg(progress)
        }
        if (API.app.trading_pg.max_volume == 0)
        {
            return qsTr("Loading wallet...")
        }
        if (typeof selectedOrder !== 'undefined')
        {
            return qsTr("Min: %1").arg(API.app.trading_pg.min_trade_vol)
        }
        return qsTr("Enter an amount")
    }

    function arrayExclude(arr, excl) {
        let i = arr.indexOf(excl)
        if (i > -1) arr.splice(i, 1);
        return arr
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

    function addressTxUri(coin_info) {
        if (coin_info.tx_uri == "") return "address/"
            return coin_info.address_uri
    }

    function getTxUri(coin_info) {
        if (coin_info.tx_uri == "") return "tx/"
        return coin_info.tx_uri
    }

    function getTxExplorerURL(ticker, txid, add_0x=true) {
        if(txid !== '') {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            const txid_prefix = (add_0x && coin_info.is_erc_family) ? '0x' : ''
            return coin_info.explorer_url + getTxUri(coin_info) + txid_prefix + txid
        }
    }

    function getAddressExplorerURL(ticker, address) {
        if(address !== '') {
            const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
            return coin_info.explorer_url + addressTxUri(coin_info) + address
        }
        return ""
    }

    function viewTxAtExplorer(ticker, txid, add_0x=true) {
        if(txid !== '') {
            Qt.openUrlExternally(getTxExplorerURL(ticker, txid, add_0x))
        }
    }

    function viewAddressAtExplorer(ticker, address) {
        if(address !== '') {
            Qt.openUrlExternally(getAddressExplorerURL(ticker, address))
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

    function formatFiat(received, amount, fiat, precision=2) {
        return diffPrefix(received) +
                (fiat === API.app.settings_pg.current_fiat ? API.app.settings_pg.current_fiat_sign : API.app.settings_pg.current_currency_sign)
                + " " + (amount < 1E5 ? formatDouble(parseFloat(amount), precision, true) : nFormatter(parseFloat(amount), 2))
    }

    function formatPercent(value, show_prefix=true) {
        let prefix = ''
        if(value > 0) prefix = '+ '
        else if(value < 0) {
            prefix = '- '
            value *= -1
        }

        return (show_prefix ? prefix : '') + parseFloat(value).toFixed(3) + ' %'
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

    function getComparisonScale(value) {
        return Math.min(Math.pow(10, getDigitCount(parseFloat(value))), 1000000000)
    }

    function limitDigits(value) {
        return parseFloat(formatDouble(value, 2))
    }

    function formatCrypto(received, amount, ticker, fiat_amount, fiat, precision, trail_zeros) {
        return diffPrefix(received) + ticker + " " + formatDouble(amount, precision, trail_zeros) + (fiat_amount ? " (" + formatFiat("", fiat_amount, fiat) + ")" : "")
    }

    function formatFullCrypto(received, amount, ticker, fiat_amount, fiat, use_full_ticker) {
        if (!use_full_ticker) ticker = atomic_qt_utilities.retrieve_main_ticker(ticker)
        return formatCrypto(received, amount, ticker, fiat_amount, fiat)
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
        return formatDouble(API.app.trading_pg.min_trade_vol, 8, false).toString()
    }

    function getReversedMinTradeAmount() {
        if (API.app.trading_pg.market_mode == MarketMode.Buy) {
           return getMinTradeAmount()
        }
        return formatDouble(API.app.trading_pg.orderbook.rel_min_taker_vol, 8, false).toString()
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

    function isParentCoinNeeded(ticker, coin_type)
    {
        let enabled_coins = API.app.portfolio_pg.get_all_enabled_coins()
        for (const coin of enabled_coins)
        {
            let c_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(coin)
            if(c_info.type === coin_type && c_info.ticker !== ticker) return true
        }
        return false
    }

    property Timer prevent_coin_disabling: Timer { interval: 5000 }

    function canDisable(ticker) {
        if (prevent_coin_disabling.running) return false
        if (ticker === atomic_app_primary_coin || ticker === atomic_app_secondary_coin) return false
        if (ticker === "ETH") return !General.isParentCoinNeeded("ETH", "ERC-20")
        if (ticker === "MATIC") return !General.isParentCoinNeeded("MATIC", "Matic")
        if (ticker === "FTM") return !General.isParentCoinNeeded("FTM", "FTM-20")
        if (ticker === "AVAX") return !General.isParentCoinNeeded("AVAX", "AVX-20")
        if (ticker === "BNB") return !General.isParentCoinNeeded("BNB", "BEP-20")
        if (ticker === "ONE") return !General.isParentCoinNeeded("ONE", "HRC-20")
        if (ticker === "QTUM") return !General.isParentCoinNeeded("QTUM", "QRC-20")
        if (ticker === "KCS") return !General.isParentCoinNeeded("KCS", "KRC-20")
        if (ticker === "HT") return !General.isParentCoinNeeded("HT", "HecoChain")
        if (ticker === "BCH") return !General.isParentCoinNeeded("BCH", "SLP")
        if (ticker === "UBQ") return !General.isParentCoinNeeded("UBQ", "Ubiq")
        if (ticker === "MOVR") return !General.isParentCoinNeeded("MOVR", "Moonriver")
        if (ticker === "GLMR") return !General.isParentCoinNeeded("GLMR", "Moonbeam")
        if (General.isZhtlc(ticker))
        {
            let progress = General.zhtlcActivationProgress(API.app.wallet_pg.ticker_infos.activation_status, ticker)
            if (progress != 100) return false
        }

        return true
    }

    function tokenUnitName(type)
    {
        return type === "QRC-20" ? "Satoshi" : "Gwei"
    }

    function isSpecialToken(current_ticker_infos)
    {
        if (current_ticker_infos.hasOwnProperty("has_parent_fees_ticker"))
            return current_ticker_infos.has_parent_fees_ticker
        return false
    }

    function isERC20(current_ticker_infos) {
        return current_ticker_infos.type === "ERC-20" || current_ticker_infos.type === "BEP-20" || current_ticker_infos.type == "Matic"
    }

    function isParentCoin(ticker) {
        return ["KMD", "ETH", "MATIC", "AVAX", "FTM", "QTUM", "BNB", "ONE", "KCS"].includes(ticker)
    }

    function isTokenType(type) {
        return ["ERC-20", "QRC-20", "PLG-20", "AVX-20", "FTM-20"].includes(type)
    }

    function getFeesTicker(coin_info) {
        if (coin_info.has_parent_fees_ticker)
            return coin_info.fees_ticker
    }

    function getParentCoin(type) {
        if(type === "ERC-20") return "ETH"
        else if(type === "PLG-20") return "MATIC"
        else if(type === "AVX-20") return "AVAX"
        else if(type === "FTM-20") return "FTM"
        else if(type === "QRC-20") return "QTUM"
        else if(type === "Smart Chain") return "KMD"
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

    function is_swap_safe(checkbox)
    {
        if (checkbox.checked == true || checkbox.visible == false)
        {
            return (!API.app.trading_pg.buy_sell_rpc_busy && API.app.trading_pg.last_trading_error == TradingError.None)
        }
        return false
    }

    function validateWallet(wallet_name) {
        if (wallet_name.length >= 25) return "Wallet name must 25 chars or less"
        return checkIfWalletExists(wallet_name)
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

    function checkIfWalletExists(name)
    {
        if(API.app.wallet_mgr.get_wallets().indexOf(name) !== -1)
            return qsTr("Wallet %1 already exists", "WALLETNAME").arg(name)
        return ""
    }

    function getTradingError(error, fee_info, base_ticker, rel_ticker, left_ticker, right_ticker) {
        switch(error) {
        case TradingError.None:
            return ""
        case TradingError.LeftZhtlcChainNotEnabled:
            return qsTr("Please wait for %1 to fully activate").arg(left_ticker)
        case TradingError.RightZhtlcChainNotEnabled:
            return qsTr("Please wait for %1 to fully activate").arg(right_ticker)
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

    readonly property var zcash_params_filesize: ({
        "sapling-output.params": 3592860,
        "sapling-spend.params": 47958396
    })

    readonly property var supported_pairs: ({
                                                "1INCH/BTC": "BINANCE:1INCHBTC",
                                                "1INCH/ETH": "HUOBI:1INCHETH",
                                                "1INCH/USDT": "BINANCE:1INCHUSD",
                                                "1INCH/BUSD": "BINANCE:1INCHUSD",
                                                "1INCH/USDC": "BINANCE:1INCHUSD",
                                                "1INCH/TUSD": "BINANCE:1INCHUSD",
                                                "1INCH/HUSD": "BINANCE:1INCHUSD",
                                                "1INCH/UST": "BINANCE:1INCHUSD",
                                                "1INCH/DAI": "BINANCE:1INCHUSD",
                                                "1INCH/PAX": "BINANCE:1INCHUSD",
                                                "ADA/BTC": "BINANCE:ADABTC",
                                                "ADA/ETH": "BINANCE:ADAETH",
                                                "ADA/USDT": "BINANCE:ADAUSD",
                                                "ADA/BUSD": "BINANCE:ADAUSD",
                                                "ADA/USDC": "BINANCE:ADAUSD",
                                                "ADA/TUSD": "BINANCE:ADAUSD",
                                                "ADA/HUSD": "BINANCE:ADAUSD",
                                                "ADA/UST": "BINANCE:ADAUSD",
                                                "ADA/DAI": "BINANCE:ADAUSD",
                                                "ADA/PAX": "BINANCE:ADAUSD",
                                                "ADA/EURS": "BINANCE:ADAEUR",
                                                "ADA/JEUR": "BINANCE:ADAEUR",
                                                "ADA/JGBP": "COINBASE:ADAGBP",
                                                "ADA/TRYB": "BINANCE:ADATRY",
                                                "ADA/BIDR": "BINANCE:ADABIDR",
                                                "ADA/BRZ": "BINANCE:ADABRL",
                                                "ADA/CADC": "EIGHTCAP:ADACAD",
                                                "ADA/BNB": "BINANCE:ADABNB",
                                                "ADA/BCH": "COINEX:ADABCH",
                                                "ADA/KCS": "KUCOIN:ADAKCS",
                                                "ADX/BTC": "BINANCE:ADXBTC",
                                                "ADX/ETH": "BINANCE:ADXETH",
                                                "ADX/USDT": "BINANCE:ADXUSD",
                                                "ADX/BUSD": "BINANCE:ADXUSD",
                                                "ADX/USDC": "BINANCE:ADXUSD",
                                                "ADX/TUSD": "BINANCE:ADXUSD",
                                                "ADX/HUSD": "BINANCE:ADXUSD",
                                                "ADX/UST": "BINANCE:ADXUSD",
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
                                                "AAVE/UST": "BINANCE:AAVEUSD",
                                                "AAVE/DAI": "BINANCE:AAVEUSD",
                                                "AAVE/PAX": "BINANCE:AAVEUSD",
                                                "AAVE/EURS": "KRAKEN:AAVEEUR",
                                                "AAVE/JEUR": "KRAKEN:AAVEEUR",
                                                "AAVE/KCS": "KUCOIN:AAVEKCS",
                                                "AGIX/BTC": "BINANCE:AGIXBTC",
                                                "AGIX/ETH": "KUCOIN:AGIXETH",
                                                "AGIX/USDT": "BINANCE:AGIXUSD",
                                                "AGIX/BUSD": "BINANCE:AGIXUSD",
                                                "AGIX/USDC": "BINANCE:AGIXUSD",
                                                "AGIX/TUSD": "BINANCE:AGIXUSD",
                                                "AGIX/HUSD": "BINANCE:AGIXUSD",
                                                "AGIX/UST": "BINANCE:AGIXUSD",
                                                "AGIX/DAI": "BINANCE:AGIXUSD",
                                                "AGIX/PAX": "BINANCE:AGIXUSD",
                                                "ANKR/BTC": "BINANCE:ANKRBTC",
                                                "ANKR/ETH": "BITTREX:ANKRETH",
                                                "ANKR/USDT": "BINANCE:ANKRUSD",
                                                "ANKR/BUSD": "BINANCE:ANKRUSD",
                                                "ANKR/USDC": "BINANCE:ANKRUSD",
                                                "ANKR/TUSD": "BINANCE:ANKRUSD",
                                                "ANKR/HUSD": "BINANCE:ANKRUSD",
                                                "ANKR/UST": "BINANCE:ANKRUSD",
                                                "ANKR/DAI": "BINANCE:ANKRUSD",
                                                "ANKR/PAX": "BINANCE:ANKRUSD",
                                                "ANKR/BNB": "BINANCE:ANKRBNB",
                                                "ANKR/JEUR": "COINBASE:ANKREUR",
                                                "ANKR/EURS": "COINBASE:ANKREUR",
                                                "ANKR/HT": "HUOBI:ANKRHT",
                                                "ANT/BTC": "BINANCE:ANTBTC",
                                                "ANT/ETH": "BITFINEX:ANTETH",
                                                "ANT/USDT": "BINANCE:ANTUSD",
                                                "ANT/BUSD": "BINANCE:ANTUSD",
                                                "ANT/USDC": "BINANCE:ANTUSD",
                                                "ANT/TUSD": "BINANCE:ANTUSD",
                                                "ANT/HUSD": "BINANCE:ANTUSD",
                                                "ANT/UST": "BINANCE:ANTUSD",
                                                "ANT/DAI": "BINANCE:ANTUSD",
                                                "ANT/PAX": "BINANCE:ANTUSD",
                                                "ANT/BNB": "BINANCE:ANTBNB",
                                                "ANT/EURS": "KRAKEN:ANTEUR",
                                                "ANT/JEUR": "KRAKEN:ANTEUR",
                                                "APE/BTC": "BINANCE:APEBTC",
                                                "APE/ETH": "BINANCE:APEETH",
                                                "APE/USDT": "FTX:APEUSD",
                                                "APE/BUSD": "FTX:APEUSD",
                                                "APE/USDC": "FTX:APEUSD",
                                                "APE/TUSD": "FTX:APEUSD",
                                                "APE/HUSD": "FTX:APEUSD",
                                                "APE/UST": "FTX:APEUSD",
                                                "APE/DAI": "FTX:APEUSD",
                                                "APE/PAX": "FTX:APEUSD",
                                                "APE/EURS": "COINBASE:APEEUR",
                                                "APE/JEUR": "COINBASE:APEEUR",
                                                "APE/JGBP": "BINANCE:APEGBP",
                                                "APE/TRYB": "BINANCE:APETRY",
                                                "APE/BRZ": "MERCADO:APEBRL",
                                                "APE/BNB": "BINANCE:APEBNB",
                                                "ARPA/BTC": "BINANCE:ARPABTC",
                                                "ARPA/BNB": "BINANCE:ARPABNB",
                                                "ARPA/HT": "HUOBI:ARPAHT",
                                                "ARPA/USDT": "BINANCE:ARPAUSD",
                                                "ARPA/BUSD": "BINANCE:ARPAUSD",
                                                "ARPA/USDC": "BINANCE:ARPAUSD",
                                                "ARPA/TUSD": "BINANCE:ARPAUSD",
                                                "ARPA/HUSD": "BINANCE:ARPAUSD",
                                                "ARPA/UST": "BINANCE:ARPAUSD",
                                                "ARPA/DAI": "BINANCE:ARPAUSD",
                                                "ARPA/PAX": "BINANCE:ARPAUSD",
                                                "ARPA/TRYB": "BINANCE:ARPATRY",
                                                "ARRR/BTC": "KUCOIN:ARRRBTC",
                                                "ARRR/USDT": "KUCOIN:ARRRUSDT",
                                                "ARRR/BUSD": "KUCOIN:ARRRUSDT",
                                                "ARRR/USDC": "KUCOIN:ARRRUSDT",
                                                "ARRR/TUSD": "KUCOIN:ARRRUSDT",
                                                "ARRR/HUSD": "KUCOIN:ARRRUSDT",
                                                "ARRR/UST": "KUCOIN:ARRRUSDT",
                                                "ARRR/DAI": "KUCOIN:ARRRUSDT",
                                                "ARRR/PAX": "KUCOIN:ARRRUSDT",
                                                "ATOM/BTC": "BINANCE:ATOMBTC",
                                                "ATOM/ETH": "KRAKEN:ATOMETH",
                                                "ATOM/USDT": "COINBASE:ATOMUSD",
                                                "ATOM/BUSD": "COINBASE:ATOMUSD",
                                                "ATOM/USDC": "COINBASE:ATOMUSD",
                                                "ATOM/TUSD": "COINBASE:ATOMUSD",
                                                "ATOM/HUSD": "COINBASE:ATOMUSD",
                                                "ATOM/UST": "COINBASE:ATOMUSD",
                                                "ATOM/DAI": "COINBASE:ATOMUSD",
                                                "ATOM/PAX": "COINBASE:ATOMUSD",
                                                "ATOM/BNB": "BINANCE:ATOMBNB",
                                                "ATOM/EURS": "KRAKEN:ATOMEUR",
                                                "ATOM/JEUR": "KRAKEN:ATOMEUR",
                                                "ATOM/JGBP": "KRAKEN:ATOMGBP",
                                                "ATOM/TRYB": "BINANCE:ATOMTRY",
                                                "ATOM/BRZ": "BINANCE:ATOMBRL",
                                                "ATOM/BCH": "HITBTC:ATOMBCH",
                                                "ATOM/KCS": "KUCOIN:ATOMKCS",
                                                "AVA/BTC": "BINANCE:AVABTC",
                                                "AVA/ETH": "KUCOIN:AVAETH",
                                                "AVA/USDT": "BINANCE:AVAUSD",
                                                "AVA/BUSD": "BINANCE:AVAUSD",
                                                "AVA/USDC": "BINANCE:AVAUSD",
                                                "AVA/TUSD": "BINANCE:AVAUSD",
                                                "AVA/HUSD": "BINANCE:AVAUSD",
                                                "AVA/UST": "BINANCE:AVAUSD",
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
                                                "AVAX/UST": "BINANCE:AVAXUSD",
                                                "AVAX/DAI": "BINANCE:AVAXUSD",
                                                "AVAX/PAX": "BINANCE:AVAXUSD",
                                                "AVAX/BNB": "BINANCE:AVAXBNB",
                                                "AVAX/EURS": "BINANCE:AVAXEUR",
                                                "AVAX/JEUR": "BINANCE:AVAXEUR",
                                                "AVAX/BIDR": "BINANCE:AVAXBIDR",
                                                "AVAX/BRZ": "BINANCE:AVAXBRL",
                                                "AVAX/TRYB": "BINANCE:AVAXTRY",
                                                "AVAX/BCH": "COINEX:AVAXBCH",
                                                "AXS/BTC": "BINANCE:AXSBTC",
                                                "AXS/ETH": "HUOBI:AXSETH",
                                                "AXS/USDT": "BINANCE:AXSUSD",
                                                "AXS/BUSD": "BINANCE:AXSUSD",
                                                "AXS/USDC": "BINANCE:AXSUSD",
                                                "AXS/TUSD": "BINANCE:AXSUSD",
                                                "AXS/HUSD": "BINANCE:AXSUSD",
                                                "AXS/UST": "BINANCE:AXSUSD",
                                                "AXS/DAI": "BINANCE:AXSUSD",
                                                "AXS/PAX": "BINANCE:AXSUSD",
                                                "AXS/BNB": "BINANCE:AXSBNB",
                                                "AXS/EURS": "KRAKEN:AXSEUR",
                                                "AXS/JEUR": "KRAKEN:AXSEUR",
                                                "AXS/BRZ": "BINANCE:AXSBRL",
                                                "AXS/BIDR": "BINANCE:AXSBIDR",
                                                "AXS/TRYB": "BINANCE:AXSTRY",
                                                "BAL/BTC": "BINANCE:BALBTC",
                                                "BAL/ETH": "HUOBI:BALETH",
                                                "BAL/USDT": "BINANCE:BALUSD",
                                                "BAL/BUSD": "BINANCE:BALUSD",
                                                "BAL/USDC": "BINANCE:BALUSD",
                                                "BAL/TUSD": "BINANCE:BALUSD",
                                                "BAL/HUSD": "BINANCE:BALUSD",
                                                "BAL/UST": "BINANCE:BALUSD",
                                                "BAL/DAI": "BINANCE:BALUSD",
                                                "BAL/PAX": "BINANCE:BALUSD",
                                                "BAL/EURS": "KRAKEN:BALEUR",
                                                "BAL/JEUR": "KRAKEN:BALEUR",
                                                "BAND/BTC": "BINANCE:BANDBTC",
                                                "BAND/ETH": "HUOBI:BANDETH",
                                                "BAND/BNB": "BINANCE:BANDBNB",
                                                "BAND/USDT": "BINANCE:BANDUSD",
                                                "BAND/BUSD": "BINANCE:BANDUSD",
                                                "BAND/USDC": "BINANCE:BANDUSD",
                                                "BAND/TUSD": "BINANCE:BANDUSD",
                                                "BAND/HUSD": "BINANCE:BANDUSD",
                                                "BAND/UST": "BINANCE:BANDUSD",
                                                "BAND/DAI": "BINANCE:BANDUSD",
                                                "BAND/PAX": "BINANCE:BANDUSD",
                                                "BAND/EURS": "COINBASE:BANDEUR",
                                                "BAND/JEUR": "COINBASE:BANDEUR",
                                                "BAT/BTC": "BINANCE:BATBTC",
                                                "BAT/ETH": "BINANCE:BATETH",
                                                "BAT/USDT": "BINANCE:BATUSD",
                                                "BAT/BUSD": "BINANCE:BATUSD",
                                                "BAT/USDC": "BINANCE:BATUSD",
                                                "BAT/TUSD": "BINANCE:BATUSD",
                                                "BAT/HUSD": "BINANCE:BATUSD",
                                                "BAT/UST": "BINANCE:BATUSD",
                                                "BAT/DAI": "BINANCE:BATUSD",
                                                "BAT/PAX": "BINANCE:BATUSD",
                                                "BAT/EURS": "KRAKEN:BATEUR",
                                                "BAT/JEUR": "KRAKEN:BATEUR",
                                                "BAT/JPYC": "KRAKEN:BATJPY",
                                                "BAT/BRZ": "MERCADO:BATBRL",
                                                "BEST/BTC": "BITPANDAPRO:BESTBTC",
                                                "BEST/USDT": "HITBTC:BESTUSD",
                                                "BEST/BUSD": "HITBTC:BESTUSD",
                                                "BEST/USDC": "HITBTC:BESTUSD",
                                                "BEST/TUSD": "HITBTC:BESTUSD",
                                                "BEST/HUSD": "HITBTC:BESTUSD",
                                                "BEST/UST": "HITBTC:BESTUSD",
                                                "BEST/DAI": "HITBTC:BESTUSD",
                                                "BEST/PAX": "HITBTC:BESTUSD",
                                                "BEST/EURS": "BITPANDAPRO:BESTEUR",
                                                "BEST/JEUR": "BITPANDAPRO:BESTEUR",
                                                "BCH/BTC": "BINANCE:BCHBTC",
                                                "BCH/ETH": "BITTREX:BCHETH",
                                                "BCH/USDT": "COINBASE:BCHUSD",
                                                "BCH/BUSD": "COINBASE:BCHUSD",
                                                "BCH/USDC": "COINBASE:BCHUSD",
                                                "BCH/TUSD": "COINBASE:BCHUSD",
                                                "BCH/HUSD": "COINBASE:BCHUSD",
                                                "BCH/UST": "COINBASE:BCHUSD",
                                                "BCH/DAI": "COINBASE:BCHUSD",
                                                "BCH/PAX": "COINBASE:BCHUSD",
                                                "BCH/BNB": "BINANCE:BCHBNB",
                                                "BCH/EURS": "KRAKEN:BCHEUR",
                                                "BCH/JEUR": "KRAKEN:BCHEUR",
                                                "BCH/JGBP": "COINBASE:BCHGBP",
                                                "BCH/BRZ": "MERCADO:BCHBRL",
                                                "BCH/JPYC": "KRAKEN:BCHJPY",
                                                "BCH/CADC": "EIGHTCAP:BCHCAD",
                                                "BCH/HT": "HUOBI:BCHHT",
                                                "BCH/KCS": "KUCOIN:BCHKCS",
                                                "BIDR/USDT": "BINANCE:USDTBIDR",
                                                "BIDR/BUSD": "BINANCE:USDTBIDR",
                                                "BIDR/USDC": "BINANCE:USDTBIDR",
                                                "BIDR/TUSD": "BINANCE:USDTBIDR",
                                                "BIDR/HUSD": "BINANCE:USDTBIDR",
                                                "BIDR/UST": "BINANCE:USDTBIDR",
                                                "BIDR/DAI": "BINANCE:USDTBIDR",
                                                "BIDR/PAX": "BINANCE:USDTBIDR",
                                                "BLK/BTC": "BITTREX:BLKBTC",
                                                "BLK/USDT": "BITTREX:BLKUSD",
                                                "BLK/BUSD": "BITTREX:BLKUSD",
                                                "BLK/USDC": "BITTREX:BLKUSD",
                                                "BLK/TUSD": "BITTREX:BLKUSD",
                                                "BLK/HUSD": "BITTREX:BLKUSD",
                                                "BLK/UST": "BITTREX:BLKUSD",
                                                "BLK/DAI": "BITTREX:BLKUSD",
                                                "BLK/PAX": "BITTREX:BLKUSD",
                                                "BNB/BTC": "BINANCE:BNBBTC",
                                                "BNB/ETH": "BINANCE:BNBETH",
                                                "BNB/USDT": "BINANCE:BNBUSD",
                                                "BNB/BUSD": "BINANCE:BNBUSD",
                                                "BNB/USDC": "BINANCE:BNBUSD",
                                                "BNB/TUSD": "BINANCE:BNBUSD",
                                                "BNB/HUSD": "BINANCE:BNBUSD",
                                                "BNB/UST": "BINANCE:BNBUSD",
                                                "BNB/DAI": "BINANCE:BNBUSD",
                                                "BNB/PAX": "BINANCE:BNBUSD",
                                                "BNB/EURS": "BINANCE:BNBEUR",
                                                "BNB/JEUR": "BINANCE:BNBEUR",
                                                "BNB/JGBP": "BINANCE:BNBGBP",
                                                "BNB/TRYB": "BINANCE:BNBTRY",
                                                "BNB/BIDR": "BINANCE:BNBBIDR",
                                                "BNB/BRZ": "BINANCE:BNBBRL",
                                                "BNB/CADC": "EIGHTCAP:BNBCAD",
                                                "BNB/KCS": "KUCOIN:BNBKCS",
                                                "BNT/BTC": "BINANCE:BNTBTC",
                                                "BNT/ETH": "BINANCE:BNTETH",
                                                "BNT/USDT": "BINANCE:BNTUSD",
                                                "BNT/BUSD": "BINANCE:BNTUSD",
                                                "BNT/USDC": "BINANCE:BNTUSD",
                                                "BNT/TUSD": "BINANCE:BNTUSD",
                                                "BNT/HUSD": "BINANCE:BNTUSD",
                                                "BNT/UST": "BINANCE:BNTUSD",
                                                "BNT/DAI": "BINANCE:BNTUSD",
                                                "BNT/PAX": "BINANCE:BNTUSD",
                                                "BNT/EURS": "COINBASE:BNTEUR",
                                                "BNT/JEUR": "COINBASE:BNTEUR",
                                                "BRZ/USDT": "FX_IDC:BRLUSD",
                                                "BRZ/BUSD": "FX_IDC:BRLUSD",
                                                "BRZ/USDC": "FX_IDC:BRLUSD",
                                                "BRZ/TUSD": "FX_IDC:BRLUSD",
                                                "BRZ/HUSD": "FX_IDC:BRLUSD",
                                                "BRZ/UST": "FX_IDC:BRLUSD",
                                                "BRZ/DAI": "FX_IDC:BRLUSD",
                                                "BRZ/PAX": "FX_IDC:BRLUSD",
                                                "BRZ/EURS": "FX_IDC:BRLEUR",
                                                "BRZ/JEUR": "FX_IDC:BRLEUR",
                                                "BRZ/BIDR": "FX_IDC:BRLIDR",
                                                "BRZ/QC": "FX_IDC:BRLCNY",
                                                "BTC/USDT": "COINBASE:BTCUSD",
                                                "BTC/BUSD": "COINBASE:BTCUSD",
                                                "BTC/USDC": "COINBASE:BTCUSD",
                                                "BTC/TUSD": "COINBASE:BTCUSD",
                                                "BTC/HUSD": "COINBASE:BTCUSD",
                                                "BTC/UST": "COINBASE:BTCUSD",
                                                "BTC/DAI": "COINBASE:BTCUSD",
                                                "BTC/PAX": "COINBASE:BTCUSD",
                                                "BTC/EURS": "COINBASE:BTCEUR",
                                                "BTC/JEUR": "COINBASE:BTCEUR",
                                                "BTC/JGBP": "COINBASE:BTCGBP",
                                                "BTC/JCHF": "BITPANDAPRO:BTCCHF",
                                                "BTC/TRYB": "BINANCE:BTCTRY",
                                                "BTC/BIDR": "BITFINEX:BTCIDR",
                                                "BTC/BRZ": "BINANCE:BTCBRL",
                                                "BTC/QC": "BITFINEX:BTCCNHT",
                                                "BTC/CADC": "CAPITALCOM:BTCCAD",
                                                "BTC/JPYC": "BITFLYER:BTCJPY",
                                                "BTC/XSGD": "GEMINI:BTCSGD",
                                                "BTC/NZDS": "CAPITALCOM:BTCNZD",
                                                "BTT/BTC": "BITFINEX:BTTBTC",
                                                "BTT/ETH": "KUCOIN:BTTETH",
                                                "BTT/USDT": "BITFINEX:BTTUSD",
                                                "BTT/BUSD": "BITFINEX:BTTUSD",
                                                "BTT/USDC": "BITFINEX:BTTUSD",
                                                "BTT/TUSD": "BITFINEX:BTTUSD",
                                                "BTT/HUSD": "BITFINEX:BTTUSD",
                                                "BTT/UST": "BITFINEX:BTTUSD",
                                                "BTT/DAI": "BITFINEX:BTTUSD",
                                                "BTT/PAX": "BITFINEX:BTTUSD",
                                                "BTT/BNB": "BINANCE:BTTBNB",
                                                "BTT/EURS": "BINANCE:BTTEUR",
                                                "BTT/JEUR": "BINANCE:BTTEUR",
                                                "BTT/TRYB": "BINANCE:BTTTRY",
                                                "BTT/BRZ": "BINANCE:BTTBRL",
                                                "BTTC/USDT": "BINANCE:BTTCUSDT",
                                                "BTTC/BUSD": "BINANCE:BTTCUSDT",
                                                "BTTC/USDC": "BINANCE:BTTCUSDT",
                                                "BTTC/TUSD": "BINANCE:BTTCUSDT",
                                                "BTTC/HUSD": "BINANCE:BTTCUSDT",
                                                "BTTC/UST": "BINANCE:BTTCUSDT",
                                                "BTTC/DAI": "BINANCE:BTTCUSDT",
                                                "BTTC/PAX": "BINANCE:BTTCUSDT",
                                                "BTTC/TRYB": "BINANCE:BTTCTRY",
                                                "BTU/BTC": "BITTREX:BTUBTC",
                                                "BTU/USDT": "BITTREX:BTUUSD",
                                                "BTU/BUSD": "BITTREX:BTUUSD",
                                                "BTU/USDC": "BITTREX:BTUUSD",
                                                "BTU/TUSD": "BITTREX:BTUUSD",
                                                "BTU/HUSD": "BITTREX:BTUUSD",
                                                "BTU/UST": "BITTREX:BTUUSD",
                                                "BTU/DAI": "BITTREX:BTUUSD",
                                                "BTU/PAX": "BITTREX:BTUUSD",
                                                "CADC/USDT": "FX_IDC:CADUSD",
                                                "CADC/BUSD": "FX_IDC:CADUSD",
                                                "CADC/USDC": "FX_IDC:CADUSD",
                                                "CADC/TUSD": "FX_IDC:CADUSD",
                                                "CADC/HUSD": "FX_IDC:CADUSD",
                                                "CADC/UST": "FX_IDC:CADUSD",
                                                "CADC/DAI": "FX_IDC:CADUSD",
                                                "CADC/PAX": "FX_IDC:CADUSD",
                                                "CADC/EURS": "FX_IDC:CADEUR",
                                                "CADC/JEUR": "FX_IDC:CADEUR",
                                                "CADC/BIDR": "FX_IDC:CADIDR",
                                                "CADC/QC": "FX_IDC:CADCNY",
                                                "CADC/BRZ": "FX_IDC:CADBRL",
                                                "CADC/TRYB": "FX_IDC:CADTRY",
                                                "CADC/JPYC": "FX:CADJPY",
                                                "CADC/XSGD": "FX_IDC:CADSGD",
                                                "CAKE/BTC": "BINANCE:CAKEBTC",
                                                "CAKE/USDT": "BINANCE:CAKEUSD",
                                                "CAKE/BUSD": "BINANCE:CAKEUSD",
                                                "CAKE/USDC": "BINANCE:CAKEUSD",
                                                "CAKE/TUSD": "BINANCE:CAKEUSD",
                                                "CAKE/HUSD": "BINANCE:CAKEUSD",
                                                "CAKE/UST": "BINANCE:CAKEUSD",
                                                "CAKE/DAI": "BINANCE:CAKEUSD",
                                                "CAKE/PAX": "BINANCE:CAKEUSD",
                                                "CAKE/BNB": "BINANCE:CAKEBNB",
                                                "CAKE/BRZ": "BINANCE:CAKEBRL",
                                                "CAKE/JGBP": "BINANCE:CAKEGBP",
                                                "CEL/BTC": "HITBTC:CELBTC",
                                                "CEL/ETH": "HITBTC:CELETH",
                                                "CEL/USDT": "HITBTC:CELUSD",
                                                "CEL/BUSD": "HITBTC:CELUSD",
                                                "CEL/USDC": "HITBTC:CELUSD",
                                                "CEL/TUSD": "HITBTC:CELUSD",
                                                "CEL/HUSD": "HITBTC:CELUSD",
                                                "CEL/UST": "HITBTC:CELUSD",
                                                "CEL/DAI": "HITBTC:CELUSD",
                                                "CEL/PAX": "HITBTC:CELUSD",
                                                "CELR/BTC": "BINANCE:CELRBTC",
                                                "CELR/USDT": "BINANCE:CELRUSD",
                                                "CELR/BUSD": "BINANCE:CELRUSD",
                                                "CELR/USDC": "BINANCE:CELRUSD",
                                                "CELR/TUSD": "BINANCE:CELRUSD",
                                                "CELR/HUSD": "BINANCE:CELRUSD",
                                                "CELR/UST": "BINANCE:CELRUSD",
                                                "CELR/DAI": "BINANCE:CELRUSD",
                                                "CELR/PAX": "BINANCE:CELRUSD",
                                                "CELR/BNB": "BINANCE:CELRBNB",
                                                "CENNZ/BTC": "HITBTC:CENNZBTC",
                                                "CENNZ/ETH": "HITBTC:CENNZETH",
                                                "CENNZ/USDT": "HITBTC:CENNZUSD",
                                                "CENNZ/BUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/USDC": "HITBTC:CENNZUSD",
                                                "CENNZ/TUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/HUSD": "HITBTC:CENNZUSD",
                                                "CENNZ/UST": "HITBTC:CENNZUSD",
                                                "CENNZ/DAI": "HITBTC:CENNZUSD",
                                                "CENNZ/PAX": "HITBTC:CENNZUSD",
                                                "CHSB/BTC": "KUCOIN:CHSBBTC",
                                                "CHSB/ETH": "KUCOIN:CHSBETH",
                                                "CHSB/USDT": "HITBTC:CHSBUSD",
                                                "CHSB/BUSD": "HITBTC:CHSBUSD",
                                                "CHSB/USDC": "HITBTC:CHSBUSD",
                                                "CHSB/TUSD": "HITBTC:CHSBUSD",
                                                "CHSB/HUSD": "HITBTC:CHSBUSD",
                                                "CHSB/UST": "HITBTC:CHSBUSD",
                                                "CHSB/DAI": "HITBTC:CHSBUSD",
                                                "CHSB/PAX": "HITBTC:CHSBUSD",
                                                "CHZ/BTC": "BINANCE:CHZBTC",
                                                "CHZ/ETH": "HUOBI:CHZETH",
                                                "CHZ/USDT": "BINANCE:CHZUSD",
                                                "CHZ/BUSD": "BINANCE:CHZUSD",
                                                "CHZ/USDC": "BINANCE:CHZUSD",
                                                "CHZ/TUSD": "BINANCE:CHZUSD",
                                                "CHZ/HUSD": "BINANCE:CHZUSD",
                                                "CHZ/UST": "BINANCE:CHZUSD",
                                                "CHZ/DAI": "BINANCE:CHZUSD",
                                                "CHZ/PAX": "BINANCE:CHZUSD",
                                                "CHZ/BNB": "BINANCE:CHZBNB",
                                                "CHZ/EURS": "BINANCE:CHZEUR",
                                                "CHZ/JEUR": "BINANCE:CHZEUR",
                                                "CHZ/JGBP": "COINBASE:CHZGBP",
                                                "CHZ/TRYB": "BINANCE:CHZTRY",
                                                "CHZ/BRZ": "BINANCE:CHZBRL",
                                                "COMP/BTC": "BINANCE:COMPBTC",
                                                "COMP/ETH": "KRAKEN:COMPETH",
                                                "COMP/USDT": "BINANCE:COMPUSD",
                                                "COMP/BUSD": "BINANCE:COMPUSD",
                                                "COMP/USDC": "BINANCE:COMPUSD",
                                                "COMP/TUSD": "BINANCE:COMPUSD",
                                                "COMP/HUSD": "BINANCE:COMPUSD",
                                                "COMP/UST": "BINANCE:COMPUSD",
                                                "COMP/DAI": "BINANCE:COMPUSD",
                                                "COMP/PAX": "BINANCE:COMPUSD",
                                                "COMP/EURS": "KRAKEN:COMPEUR",
                                                "COMP/JEUR": "KRAKEN:COMPEUR",
                                                "CRO/BTC": "BITTREX:CROBTC",
                                                "CRO/ETH": "BITTREX:CROETH",
                                                "CRO/USDT": "BITTREX:CROUSD",
                                                "CRO/BUSD": "BITTREX:CROUSD",
                                                "CRO/USDC": "BITTREX:CROUSD",
                                                "CRO/TUSD": "BITTREX:CROUSD",
                                                "CRO/HUSD": "BITTREX:CROUSD",
                                                "CRO/UST": "BITTREX:CROUSD",
                                                "CRO/DAI": "BITTREX:CROUSD",
                                                "CRO/PAX": "BITTREX:CROUSD",
                                                "CRO/EURS": "BITTREX:CROEUR",
                                                "CRO/JEUR": "BITTREX:CROEUR",
                                                "CRO/HT": "HUOBI:CROHT",
                                                "CRV/BTC": "BINANCE:CRVBTC",
                                                "CRV/ETH": "KRAKEN:CRVETH",
                                                "CRV/USDT": "BINANCE:CRVUSD",
                                                "CRV/BUSD": "BINANCE:CRVUSD",
                                                "CRV/USDC": "BINANCE:CRVUSD",
                                                "CRV/TUSD": "BINANCE:CRVUSD",
                                                "CRV/HUSD": "BINANCE:CRVUSD",
                                                "CRV/UST": "BINANCE:CRVUSD",
                                                "CRV/DAI": "BINANCE:CRVUSD",
                                                "CRV/PAX": "BINANCE:CRVUSD",
                                                "CRV/BNB": "BINANCE:CRVBNB",
                                                "CRV/EURS": "KRAKEN:CRVEUR",
                                                "CRV/JEUR": "KRAKEN:CRVEUR",
                                                "CRV/JGBP": "COINBASE:CRVGBP",
                                                "CRV/BRZ": "MERCADO:CRVBRL",
                                                "CVC/BTC": "BINANCE:CVCBTC",
                                                "CVC/ETH": "BINANCE:CVCETH",
                                                "CVC/USDT": "BINANCE:CVCUSD",
                                                "CVC/BUSD": "BINANCE:CVCUSD",
                                                "CVC/USDC": "BINANCE:CVCUSD",
                                                "CVC/TUSD": "BINANCE:CVCUSD",
                                                "CVC/HUSD": "BINANCE:CVCUSD",
                                                "CVC/UST": "BINANCE:CVCUSD",
                                                "CVC/DAI": "BINANCE:CVCUSD",
                                                "CVC/PAX": "BINANCE:CVCUSD",
                                                "CVT/BTC": "BITTREX:CVTBTC",
                                                "CVT/ETH": "HITBTC:CVTETH",
                                                "CVT/USDT": "BITTREX:CVTUSD",
                                                "CVT/BUSD": "BITTREX:CVTUSD",
                                                "CVT/USDC": "BITTREX:CVTUSD",
                                                "CVT/TUSD": "BITTREX:CVTUSD",
                                                "CVT/HUSD": "BITTREX:CVTUSD",
                                                "CVT/UST": "BITTREX:CVTUSD",
                                                "CVT/DAI": "BITTREX:CVTUSD",
                                                "CVT/PAX": "BITTREX:CVTUSD",
                                                "DASH/BTC": "BINANCE:DASHBTC",
                                                "DASH/ETH": "BINANCE:DASHETH",
                                                "DASH/USDT": "KRAKEN:DASHUSD",
                                                "DASH/BUSD": "KRAKEN:DASHUSD",
                                                "DASH/USDC": "KRAKEN:DASHUSD",
                                                "DASH/TUSD": "KRAKEN:DASHUSD",
                                                "DASH/HUSD": "KRAKEN:DASHUSD",
                                                "DASH/UST": "KRAKEN:DASHUSD",
                                                "DASH/DAI": "KRAKEN:DASHUSD",
                                                "DASH/PAX": "KRAKEN:DASHUSD",
                                                "DASH/BNB": "BINANCE:DASHBNB",
                                                "DASH/EURS": "KRAKEN:DASHEUR",
                                                "DASH/JEUR": "KRAKEN:DASHEUR",
                                                "DASH/JGBP": "EIGHTCAP:DSHGBP",
                                                "DASH/CADC": "EIGHTCAP:DSHCAD",
                                                "DASH/HT": "HUOBI:DASHHT",
                                                "DASH/KCS": "KUCOIN:DASHKCS",
                                                "DOGE/BTC": "BINANCE:DOGEBTC",
                                                "DOGE/ETH": "HITBTC:DOGEETH",
                                                "DOGE/USDT": "BINANCE:DOGEUSD",
                                                "DOGE/BUSD": "BINANCE:DOGEUSD",
                                                "DOGE/USDC": "BINANCE:DOGEUSD",
                                                "DOGE/TUSD": "BINANCE:DOGEUSD",
                                                "DOGE/HUSD": "BINANCE:DOGEUSD",
                                                "DOGE/UST": "BINANCE:DOGEUSD",
                                                "DOGE/DAI": "BINANCE:DOGEUSD",
                                                "DOGE/PAX": "BINANCE:DOGEUSD",
                                                "DOGE/EURS": "BINANCE:DOGEEUR",
                                                "DOGE/JEUR": "BINANCE:DOGEEUR",
                                                "DOGE/JGBP": "BINANCE:DOGEGBP",
                                                "DOGE/TRYB": "BINANCE:DOGETRY",
                                                "DOGE/BIDR": "BINANCE:DOGEBIDR",
                                                "DOGE/BRZ": "BINANCE:DOGEBRL",
                                                "DOGE/BCH": "COINEX:DOGEBCH",
                                                "DOGE/KCS": "KUCOIN:DOGEKCS",
                                                "DGB/BTC": "BINANCE:DGBBTC",
                                                "DGB/ETH": "BITTREX:DGBETH",
                                                "DGB/USDT": "BITTREX:DGBUSD",
                                                "DGB/BUSD": "BITTREX:DGBUSD",
                                                "DGB/USDC": "BITTREX:DGBUSD",
                                                "DGB/TUSD": "BITTREX:DGBUSD",
                                                "DGB/HUSD": "BITTREX:DGBUSD",
                                                "DGB/UST": "BITTREX:DGBUSD",
                                                "DGB/DAI": "BITTREX:DGBUSD",
                                                "DGB/PAX": "BITTREX:DGBUSD",
                                                "DGB/EURS": "BITTREX:DGBEUR",
                                                "DGB/JEUR": "BITTREX:DGBEUR",
                                                "DIA/BTC": "BINANCE:DIABTC",
                                                "DIA/ETH": "OKEX:DIAETH",
                                                "DIA/USDT": "BINANCE:DIAUSD",
                                                "DIA/BUSD": "BINANCE:DIAUSD",
                                                "DIA/USDC": "BINANCE:DIAUSD",
                                                "DIA/TUSD": "BINANCE:DIAUSD",
                                                "DIA/HUSD": "BINANCE:DIAUSD",
                                                "DIA/UST": "BINANCE:DIAUSD",
                                                "DIA/DAI": "BINANCE:DIAUSD",
                                                "DIA/PAX": "BINANCE:DIAUSD",
                                                "DIA/EURS": "COINBASE:DIAEUR",
                                                "DIA/JEUR": "COINBASE:DIAEUR",
                                                "DIA/BNB": "BINANCE:DIABNB",
                                                "DODO/BTC": "BINANCE:DODOBTC",
                                                "DODO/USDT": "BINANCE:DODOUSD",
                                                "DODO/BUSD": "BINANCE:DODOUSD",
                                                "DODO/USDC": "BINANCE:DODOUSD",
                                                "DODO/TUSD": "BINANCE:DODOUSD",
                                                "DODO/HUSD": "BINANCE:DODOUSD",
                                                "DODO/UST": "BINANCE:DODOUSD",
                                                "DODO/DAI": "BINANCE:DODOUSD",
                                                "DODO/PAX": "BINANCE:DODOUSD",
                                                "DOT/BTC": "BINANCE:DOTBTC",
                                                "DOT/ETH": "KRAKEN:DOTETH",
                                                "DOT/USDT": "BINANCE:DOTUSD",
                                                "DOT/BUSD": "BINANCE:DOTUSD",
                                                "DOT/USDC": "BINANCE:DOTUSD",
                                                "DOT/TUSD": "BINANCE:DOTUSD",
                                                "DOT/HUSD": "BINANCE:DOTUSD",
                                                "DOT/UST": "BINANCE:DOTUSD",
                                                "DOT/DAI": "BINANCE:DOTUSD",
                                                "DOT/PAX": "BINANCE:DOTUSD",
                                                "DOT/EURS": "BINANCE:DOTEUR",
                                                "DOT/JEUR": "BINANCE:DOTEUR",
                                                "DOT/JGBP": "COINBASE:DOTGBP",
                                                "DOT/TRYB": "BINANCE:DOTTRY",
                                                "DOT/BIDR": "BINANCE:DOTBIDR",
                                                "DOT/BRZ": "BINANCE:DOTBRL",
                                                "DOT/CADC": "EIGHTCAP:DOTCAD",
                                                "DOT/BNB": "BINANCE:DOTBNB",
                                                "DOT/BCH": "COINEX:DOTBCH",
                                                "DOT/KCS": "KUCOIN:DOTKCS",
                                                "DX/ETH": "SUSHISWAP:DXWETH",
                                                "DX/USDT": "GATEIO:DXUSDT",
                                                "DX/BUSD": "GATEIO:DXUSDT",
                                                "DX/USDC": "GATEIO:DXUSDT",
                                                "DX/TUSD": "GATEIO:DXUSDT",
                                                "DX/HUSD": "GATEIO:DXUSDT",
                                                "DX/UST": "GATEIO:DXUSDT",
                                                "DX/DAI": "GATEIO:DXUSDT",
                                                "DX/PAX": "GATEIO:DXUSDT",
                                                "EGLD/BTC": "BINANCE:EGLDBTC",
                                                "EGLD/USDT": "BINANCE:EGLDUSD",
                                                "EGLD/BUSD": "BINANCE:EGLDUSD",
                                                "EGLD/USDC": "BINANCE:EGLDUSD",
                                                "EGLD/TUSD": "BINANCE:EGLDUSD",
                                                "EGLD/HUSD": "BINANCE:EGLDUSD",
                                                "EGLD/UST": "BINANCE:EGLDUSD",
                                                "EGLD/DAI": "BINANCE:EGLDUSD",
                                                "EGLD/PAX": "BINANCE:EGLDUSD",
                                                "EGLD/BNB": "BINANCE:EGLDBNB",
                                                "EGLD/EURS": "BINANCE:EGLDEUR",
                                                "EGLD/JEUR": "BINANCE:EGLDEUR",
                                                "ELF/BTC": "BINANCE:ELFBTC",
                                                "ELF/ETH": "BINANCE:ELFETH",
                                                "ELF/USDT": "BINANCE:ELFUSD",
                                                "ELF/BUSD": "BINANCE:ELFUSD",
                                                "ELF/USDC": "BINANCE:ELFUSD",
                                                "ELF/TUSD": "BINANCE:ELFUSD",
                                                "ELF/HUSD": "BINANCE:ELFUSD",
                                                "ELF/UST": "BINANCE:ELFUSD",
                                                "ELF/DAI": "BINANCE:ELFUSD",
                                                "ELF/PAX": "BINANCE:ELFUSD",
                                                "EMC2/BTC": "BITTREX:EMC2BTC",
                                                "EMC2/ETH": "BITTREX:EMC2ETH",
                                                "EMC2/USDT": "BITTREX:EMC2USD",
                                                "EMC2/BUSD": "BITTREX:EMC2USD",
                                                "EMC2/USDC": "BITTREX:EMC2USD",
                                                "EMC2/TUSD": "BITTREX:EMC2USD",
                                                "EMC2/HUSD": "BITTREX:EMC2USD",
                                                "EMC2/UST": "BITTREX:EMC2USD",
                                                "EMC2/DAI": "BITTREX:EMC2USD",
                                                "EMC2/PAX": "BITTREX:EMC2USD",
                                                "ENJ/BTC": "BINANCE:ENJBTC",
                                                "ENJ/ETH": "BINANCE:ENJETH",
                                                "ENJ/USDT": "BINANCE:ENJUSD",
                                                "ENJ/BUSD": "BINANCE:ENJUSD",
                                                "ENJ/USDC": "BINANCE:ENJUSD",
                                                "ENJ/TUSD": "BINANCE:ENJUSD",
                                                "ENJ/HUSD": "BINANCE:ENJUSD",
                                                "ENJ/UST": "BINANCE:ENJUSD",
                                                "ENJ/DAI": "BINANCE:ENJUSD",
                                                "ENJ/PAX": "BINANCE:ENJUSD",
                                                "ENJ/BNB": "BINANCE:ENJBNB",
                                                "ENJ/EURS": "BINANCE:ENJEUR",
                                                "ENJ/JEUR": "BINANCE:ENJEUR",
                                                "ENJ/JGBP": "BINANCE:ENJGBP",
                                                "ENJ/TRYB": "BINANCE:ENJTRY",
                                                "ENJ/BRZ": "BINANCE:ENJBRL",
                                                "EOS/BTC": "BINANCE:EOSBTC",
                                                "EOS/ETH": "BINANCE:EOSETH",
                                                "EOS/USDT": "BITFINEX:EOSUSD",
                                                "EOS/BUSD": "BITFINEX:EOSUSD",
                                                "EOS/USDC": "BITFINEX:EOSUSD",
                                                "EOS/TUSD": "BITFINEX:EOSUSD",
                                                "EOS/HUSD": "BITFINEX:EOSUSD",
                                                "EOS/UST": "BITFINEX:EOSUSD",
                                                "EOS/DAI": "BITFINEX:EOSUSD",
                                                "EOS/PAX": "BITFINEX:EOSUSD",
                                                "EOS/BNB": "BINANCE:EOSBNB",
                                                "EOS/BCH": "HITBTC:EOSBCH",
                                                "EOS/EURS": "KRAKEN:EOSEUR",
                                                "EOS/JEUR": "KRAKEN:EOSEUR",
                                                "EOS/JGBP": "BITFINEX:EOSGBP",
                                                "EOS/TRYB": "BINANCE:EOSTRY",
                                                "EOS/BIDR": "BITFINEX:EOSIDR",
                                                "EOS/JPYC": "BITFINEX:EOSJPY",
                                                "EOS/CADC": "EIGHTCAP:EOSCAD",
                                                "EOS/KCS": "KUCOIN:EOSKCS",
                                                "ETC/BTC": "BINANCE:ETCBTC",
                                                "ETC/ETH": "BINANCE:ETCETH",
                                                "ETC/USDT": "BINANCE:ETCUSD",
                                                "ETC/BUSD": "BINANCE:ETCUSD",
                                                "ETC/USDC": "BINANCE:ETCUSD",
                                                "ETC/TUSD": "BINANCE:ETCUSD",
                                                "ETC/HUSD": "BINANCE:ETCUSD",
                                                "ETC/UST": "BINANCE:ETCUSD",
                                                "ETC/DAI": "BINANCE:ETCUSD",
                                                "ETC/PAX": "BINANCE:ETCUSD",
                                                "ETC/BNB": "BINANCE:ETCBNB",
                                                "ETC/EURS": "KRAKEN:ETCEUR",
                                                "ETC/JEUR": "KRAKEN:ETCEUR",
                                                "ETC/BRZ": "BINANCE:ETCBRL",
                                                "ETC/BCH": "HITBTC:ETCBCH",
                                                "ETH/BTC": "BINANCE:ETHBTC",
                                                "ETH/USDT": "BITSTAMP:ETHUSD",
                                                "ETH/BUSD": "BITSTAMP:ETHUSD",
                                                "ETH/USDC": "BITSTAMP:ETHUSD",
                                                "ETH/TUSD": "BITSTAMP:ETHUSD",
                                                "ETH/HUSD": "BITSTAMP:ETHUSD",
                                                "ETH/UST": "BITSTAMP:ETHUSD",
                                                "ETH/DAI": "BITSTAMP:ETHUSD",
                                                "ETH/PAX": "BITSTAMP:ETHUSD",
                                                "ETH/EURS": "KRAKEN:ETHEUR",
                                                "ETH/JEUR": "KRAKEN:ETHEUR",
                                                "ETH/JGBP": "COINBASE:ETHGBP",
                                                "ETH/JCHF": "KRAKEN:ETHCHF",
                                                "ETH/TRYB": "BINANCE:ETHTRY",
                                                "ETH/BIDR": "BINANCE:ETHBIDR",
                                                "ETH/BRZ": "BINANCE:ETHBRL",
                                                "ETH/JPYC": "BITFLYER:ETHJPY",
                                                "ETH/CADC": "KRAKEN:ETHCAD",
                                                "ETH/XSGD": "GEMINI:ETHSGD",
                                                "ETH/NZDS": "CAPITALCOM:ETHNZD",
                                                "EURS/USDT": "FX:EURUSD",
                                                "EURS/BUSD": "FX:EURUSD",
                                                "EURS/USDC": "FX:EURUSD",
                                                "EURS/TUSD": "FX:EURUSD",
                                                "EURS/HUSD": "FX:EURUSD",
                                                "EURS/UST": "FX:EURUSD",
                                                "EURS/DAI": "FX:EURUSD",
                                                "EURS/PAX": "FX:EURUSD",
                                                "EURS/BIDR": "FX_IDC:EURIDR",
                                                "JEUR/USDT": "FX:EURUSD",
                                                "JEUR/BUSD": "FX:EURUSD",
                                                "JEUR/USDC": "FX:EURUSD",
                                                "JEUR/TUSD": "FX:EURUSD",
                                                "JEUR/HUSD": "FX:EURUSD",
                                                "JEUR/UST": "FX:EURUSD",
                                                "JEUR/DAI": "FX:EURUSD",
                                                "JEUR/PAX": "FX:EURUSD",
                                                "JEUR/BIDR": "FX_IDC:EURIDR",
                                                "JGBP/USDT": "FX:GBPUSD",
                                                "JGBP/BUSD": "FX:GBPUSD",
                                                "JGBP/USDC": "FX:GBPUSD",
                                                "JGBP/TUSD": "FX:GBPUSD",
                                                "JGBP/HUSD": "FX:GBPUSD",
                                                "JGBP/UST": "FX:GBPUSD",
                                                "JGBP/DAI": "FX:GBPUSD",
                                                "JGBP/PAX": "FX:GBPUSD",
                                                "JGBP/EURS": "FX_IDC:GBPEUR",
                                                "JGBP/JEUR": "FX_IDC:GBPEUR",
                                                "JGBP/BIDR": "FX_IDC:GBPIDR",
                                                "JGBP/QC": "FX_IDC:GBPCNY",
                                                "JGBP/BRZ": "FX_IDC:GBPBRL",
                                                "JGBP/TRYB": "FX_IDC:GBPTRY",
                                                "JGBP/JPYC": "FX:GBPJPY",
                                                "JGBP/XSGD": "FX_IDC:GBPSGD",
                                                "JGBP/CADC": "FX:GBPCAD",
                                                "FET/BTC": "BINANCE:FETBTC",
                                                "FET/ETH": "KUCOIN:FETETH",
                                                "FET/USDT": "BINANCE:FETUSD",
                                                "FET/BUSD": "BINANCE:FETUSD",
                                                "FET/USDC": "BINANCE:FETUSD",
                                                "FET/TUSD": "BINANCE:FETUSD",
                                                "FET/HUSD": "BINANCE:FETUSD",
                                                "FET/UST": "BINANCE:FETUSD",
                                                "FET/DAI": "BINANCE:FETUSD",
                                                "FET/PAX": "BINANCE:FETUSD",
                                                "FET/EURS": "BITSTAMP:FETEUR",
                                                "FET/JEUR": "BITSTAMP:FETEUR",
                                                "FET/BNB": "BINANCE:FETBNB",
                                                "FIL/BTC": "BINANCE:FILBTC",
                                                "FIL/ETH": "HUOBI:FILETH",
                                                "FIL/USDT": "BINANCE:FILUSD",
                                                "FIL/BUSD": "BINANCE:FILUSD",
                                                "FIL/USDC": "BINANCE:FILUSD",
                                                "FIL/TUSD": "BINANCE:FILUSD",
                                                "FIL/HUSD": "BINANCE:FILUSD",
                                                "FIL/UST": "BINANCE:FILUSD",
                                                "FIL/DAI": "BINANCE:FILUSD",
                                                "FIL/PAX": "BINANCE:FILUSD",
                                                "FIL/BNB": "BINANCE:FILBNB",
                                                "FIL/EURS": "COINBASE:FILEUR",
                                                "FIL/JEUR": "COINBASE:FILEUR",
                                                "FIL/TRYB": "BINANCE:FILTRY",
                                                "FIRO/BTC": "BINANCE:FIROBTC",
                                                "FIRO/ETH": "HUOBI:FIROETH",
                                                "FIRO/USDT": "BINANCE:FIROUSD",
                                                "FIRO/BUSD": "BINANCE:FIROUSD",
                                                "FIRO/USDC": "BINANCE:FIROUSD",
                                                "FIRO/TUSD": "BINANCE:FIROUSD",
                                                "FIRO/HUSD": "BINANCE:FIROUSD",
                                                "FIRO/UST": "BINANCE:FIROUSD",
                                                "FIRO/DAI": "BINANCE:FIROUSD",
                                                "FIRO/PAX": "BINANCE:FIROUSD",
                                                "FLOW/BTC": "BINANCE:FLOWBTC",
                                                "FLOW/ETH": "KRAKEN:FLOWETH",
                                                "FLOW/USDT": "BINANCE:FLOWUSD",
                                                "FLOW/BUSD": "BINANCE:FLOWUSD",
                                                "FLOW/USDC": "BINANCE:FLOWUSD",
                                                "FLOW/TUSD": "BINANCE:FLOWUSD",
                                                "FLOW/HUSD": "BINANCE:FLOWUSD",
                                                "FLOW/UST": "BINANCE:FLOWUSD",
                                                "FLOW/DAI": "BINANCE:FLOWUSD",
                                                "FLOW/PAX": "BINANCE:FLOWUSD",
                                                "FLOW/EURS": "KRAKEN:FLOWEUR",
                                                "FLOW/JEUR": "KRAKEN:FLOWEUR",
                                                "FLOW/JGBP": "KRAKEN:FLOWGBP",
                                                "FLOW/BNB": "BINANCE:FLOWBNB",
                                                "FLUX/BTC": "KUCOIN:FLUXBTC",
                                                "FLUX/USDT": "KUCOIN:FLUXUSDT",
                                                "FLUX/BUSD": "KUCOIN:FLUXUSDT",
                                                "FLUX/USDC": "KUCOIN:FLUXUSDT",
                                                "FLUX/TUSD": "KUCOIN:FLUXUSDT",
                                                "FLUX/HUSD": "KUCOIN:FLUXUSDT",
                                                "FLUX/UST": "KUCOIN:FLUXUSDT",
                                                "FLUX/DAI": "KUCOIN:FLUXUSDT",
                                                "FLUX/PAX": "KUCOIN:FLUXUSDT",
                                                "FTC/BTC": "BITTREX:FTCBTC",
                                                "FTC/USDT": "BITTREX:FTCUSD",
                                                "FTC/BUSD": "BITTREX:FTCUSD",
                                                "FTC/USDC": "BITTREX:FTCUSD",
                                                "FTC/TUSD": "BITTREX:FTCUSD",
                                                "FTC/HUSD": "BITTREX:FTCUSD",
                                                "FTC/UST": "BITTREX:FTCUSD",
                                                "FTC/DAI": "BITTREX:FTCUSD",
                                                "FTC/PAX": "BITTREX:FTCUSD",
                                                "FTM/BTC": "BINANCE:FTMBTC",
                                                "FTM/ETH": "KUCOIN:FTMETH",
                                                "FTM/USDT": "BINANCE:FTMUSD",
                                                "FTM/BUSD": "BINANCE:FTMUSD",
                                                "FTM/USDC": "BINANCE:FTMUSD",
                                                "FTM/TUSD": "BINANCE:FTMUSD",
                                                "FTM/HUSD": "BINANCE:FTMUSD",
                                                "FTM/UST": "BINANCE:FTMUSD",
                                                "FTM/DAI": "BINANCE:FTMUSD",
                                                "FTM/PAX": "BINANCE:FTMUSD",
                                                "FTM/EURS": "BITSTAMP:FTMEUR",
                                                "FTM/JEUR": "BITSTAMP:FTMEUR",
                                                "FTM/BNB": "BINANCE:FTMBNB",
                                                "FTM/BIDR": "BINANCE:FTMBIDR",
                                                "FTM/BRZ": "BINANCE:FTMBRL",
                                                "FTM/TRYB": "BINANCE:FTMTRY",
                                                "FUN/BTC": "BINANCE:FUNBTC",
                                                "FUN/ETH": "BINANCE:FUNETH",
                                                "FUN/USDT": "BINANCE:FUNUSD",
                                                "FUN/BUSD": "BINANCE:FUNUSD",
                                                "FUN/USDC": "BINANCE:FUNUSD",
                                                "FUN/FUN": "BINANCE:FUNUSD",
                                                "FUN/HUSD": "BINANCE:FUNUSD",
                                                "FUN/UST": "BINANCE:FUNUSD",
                                                "FUN/DAI": "BINANCE:FUNUSD",
                                                "FUN/PAX": "BINANCE:FUNUSD",
                                                "FUN/BNB": "BINANCE:FUNBNB",
                                                "GALA/BTC": "BINANCE:GALABTC",
                                                "GALA/ETH": "BINANCE:GALAETH",
                                                "GALA/USDT": "BINANCE:GALAUSD",
                                                "GALA/BUSD": "BINANCE:GALAUSD",
                                                "GALA/USDC": "BINANCE:GALAUSD",
                                                "GALA/TUSD": "BINANCE:GALAUSD",
                                                "GALA/HUSD": "BINANCE:GALAUSD",
                                                "GALA/UST": "BINANCE:GALAUSD",
                                                "GALA/DAI": "BINANCE:GALAUSD",
                                                "GALA/PAX": "BINANCE:GALAUSD",
                                                "GALA/EURS": "BITSTAMP:GALAEUR",
                                                "GALA/JEUR": "BITSTAMP:GALAEUR",
                                                "GALA/TRYB": "BINANCE:GALATRY",
                                                "GALA/BRZ": "BINANCE:GALABRL",
                                                "GALA/BNB": "BINANCE:GALABNB",
                                                "GLEEC/BTC": "BITTREX:GLEECBTC",
                                                "GLEEC/USDT": "BITTREX:GLEECUSD",
                                                "GLEEC/BUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/USDC": "BITTREX:GLEECUSD",
                                                "GLEEC/TUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/HUSD": "BITTREX:GLEECUSD",
                                                "GLEEC/UST": "BITTREX:GLEECUSD",
                                                "GLEEC/DAI": "BITTREX:GLEECUSD",
                                                "GLEEC/PAX": "BITTREX:GLEECUSD",
                                                "GLMR/BTC": "BINANCE:GLMRBTC",
                                                "GLMR/USDT": "BINANCE:GLMRUSD",
                                                "GLMR/BUSD": "BINANCE:GLMRUSD",
                                                "GLMR/USDC": "BINANCE:GLMRUSD",
                                                "GLMR/TUSD": "BINANCE:GLMRUSD",
                                                "GLMR/HUSD": "BINANCE:GLMRUSD",
                                                "GLMR/UST": "BINANCE:GLMRUSD",
                                                "GLMR/DAI": "BINANCE:GLMRUSD",
                                                "GLMR/PAX": "BINANCE:GLMRUSD",
                                                "GLMR/EURS": "KRAKEN:GLMREUR",
                                                "GLMR/JEUR": "KRAKEN:GLMREUR",
                                                "GLMR/BNB": "BINANCE:GLMRBNB",
                                                "GMT/BTC": "BINANCE:GMTBTC",
                                                "GMT/ETH": "BINANCE:GMTETH",
                                                "GMT/USDT": "BINANCE:GMTUSD",
                                                "GMT/BUSD": "BINANCE:GMTUSD",
                                                "GMT/USDC": "BINANCE:GMTUSD",
                                                "GMT/TUSD": "BINANCE:GMTUSD",
                                                "GMT/HUSD": "BINANCE:GMTUSD",
                                                "GMT/UST": "BINANCE:GMTUSD",
                                                "GMT/DAI": "BINANCE:GMTUSD",
                                                "GMT/PAX": "BINANCE:GMTUSD",
                                                "GMT/EURS": "BINANCE:GMTEUR",
                                                "GMT/JEUR": "BINANCE:GMTEUR",
                                                "GMT/JGBP": "BINANCE:GMTGBP",
                                                "GMT/TRYB": "BINANCE:GMTTRY",
                                                "GMT/BRZ": "BINANCE:GMTBRL",
                                                "GMT/BNB": "BINANCE:GMTBNB",
                                                "GNO/BTC": "BITTREX:GNOBTC",
                                                "GNO/ETH": "KRAKEN:GNOETH",
                                                "GNO/USDT": "KRAKEN:GNOUSD",
                                                "GNO/BUSD": "KRAKEN:GNOUSD",
                                                "GNO/USDC": "KRAKEN:GNOUSD",
                                                "GNO/TUSD": "KRAKEN:GNOUSD",
                                                "GNO/HUSD": "KRAKEN:GNOUSD",
                                                "GNO/UST": "KRAKEN:GNOUSD",
                                                "GNO/DAI": "KRAKEN:GNOUSD",
                                                "GNO/PAX": "KRAKEN:GNOUSD",
                                                "GNO/EURS": "KRAKEN:GNOEUR",
                                                "GNO/JEUR": "KRAKEN:GNOEUR",
                                                "GRS/BTC": "BINANCE:GRSBTC",
                                                "GRS/ETH": "HUOBI:GRSETH",
                                                "GRS/USDT": "BINANCE:GRSUSD",
                                                "GRS/BUSD": "BINANCE:GRSUSD",
                                                "GRS/USDC": "BINANCE:GRSUSD",
                                                "GRS/TUSD": "BINANCE:GRSUSD",
                                                "GRS/HUSD": "BINANCE:GRSUSD",
                                                "GRS/UST": "BINANCE:GRSUSD",
                                                "GRS/DAI": "BINANCE:GRSUSD",
                                                "GRS/PAX": "BINANCE:GRSUSD",
                                                "GRT/BTC": "BINANCE:GRTBTC",
                                                "GRT/ETH": "BINANCE:GRTETH",
                                                "GRT/USDT": "BINANCE:GRTUSD",
                                                "GRT/BUSD": "BINANCE:GRTUSD",
                                                "GRT/USDC": "BINANCE:GRTUSD",
                                                "GRT/TUSD": "BINANCE:GRTUSD",
                                                "GRT/HUSD": "BINANCE:GRTUSD",
                                                "GRT/UST": "BINANCE:GRTUSD",
                                                "GRT/DAI": "BINANCE:GRTUSD",
                                                "GRT/PAX": "BINANCE:GRTUSD",
                                                "GRT/EURS": "COINBASE:GRTEUR",
                                                "GRT/JEUR": "COINBASE:GRTEUR",
                                                "GRT/TRYB": "BINANCE:GRTTRY",
                                                "GRT/BRZ": "MERCADO:GRTBRL",
                                                "GRT/KCS": "KUCOIN:GRTKCS",
                                                "GST/USDT": "COINBASE:GSTUSD",
                                                "GST/BUSD": "COINBASE:GSTUSD",
                                                "GST/USDC": "COINBASE:GSTUSD",
                                                "GST/TUSD": "COINBASE:GSTUSD",
                                                "GST/HUSD": "COINBASE:GSTUSD",
                                                "GST/UST": "COINBASE:GSTUSD",
                                                "GST/DAI": "COINBASE:GSTUSD",
                                                "GST/PAX": "COINBASE:GSTUSD",
                                                "GST/EURS": "KRAKEN:GSTEUR",
                                                "GST/JEUR": "KRAKEN:GSTEUR",
                                                "GST/TRYB": "FTX:GSTTRY",
                                                "HEX/BTC": "HITBTC:HEXBTC",
                                                "HEX/ETH": "UNISWAP:HEXWETH",
                                                "HEX/USDT": "POLONIEX:HEXUSDT",
                                                "HEX/BUSD": "POLONIEX:HEXUSDT",
                                                "HEX/USDC": "POLONIEX:HEXUSDT",
                                                "HEX/TUSD": "POLONIEX:HEXUSDT",
                                                "HEX/HUSD": "POLONIEX:HEXUSDT",
                                                "HEX/UST": "POLONIEX:HEXUSDT",
                                                "HEX/DAI": "POLONIEX:HEXUSDT",
                                                "HEX/PAX": "POLONIEX:HEXUSDT",
                                                "HOT/BTC": "HITBTC:HOTBTC",
                                                "HOT/ETH": "BINANCE:HOTETH",
                                                "HOT/USDT": "HITBTC:HOTUSD",
                                                "HOT/BUSD": "HITBTC:HOTUSD",
                                                "HOT/USDC": "HITBTC:HOTUSD",
                                                "HOT/TUSD": "HITBTC:HOTUSD",
                                                "HOT/HUSD": "HITBTC:HOTUSD",
                                                "HOT/UST": "HITBTC:HOTUSD",
                                                "HOT/DAI": "HITBTC:HOTUSD",
                                                "HOT/PAX": "HITBTC:HOTUSD",
                                                "HOT/BNB": "BINANCE:HOTBNB",
                                                "HOT/EURS": "BINANCE:HOTEUR",
                                                "HOT/JEUR": "BINANCE:HOTEUR",
                                                "HOT/TRYB": "BINANCE:HOTTRY",
                                                "HT/BTC": "HUOBI:HTBTC",
                                                "HT/ETH": "HUOBI:HTETH",
                                                "HT/USDT": "FTX:HTUSD",
                                                "HT/BUSD": "FTX:HTUSD",
                                                "HT/USDC": "FTX:HTUSD",
                                                "HT/TUSD": "FTX:HTUSD",
                                                "HT/HUSD": "FTX:HTUSD",
                                                "HT/UST": "FTX:HTUSD",
                                                "HT/DAI": "FTX:HTUSD",
                                                "HT/PAX": "FTX:HTUSD",
                                                "INJ/BTC": "BINANCE:INJBTC",
                                                "INJ/ETH": "HUOBI:INJETH",
                                                "INJ/USDT": "BINANCE:INJUSD",
                                                "INJ/BUSD": "BINANCE:INJUSD",
                                                "INJ/USDC": "BINANCE:INJUSD",
                                                "INJ/TUSD": "BINANCE:INJUSD",
                                                "INJ/HUSD": "BINANCE:INJUSD",
                                                "INJ/UST": "BINANCE:INJUSD",
                                                "INJ/DAI": "BINANCE:INJUSD",
                                                "INJ/PAX": "BINANCE:INJUSD",
                                                "INJ/EURS": "KRAKEN:INJEUR",
                                                "INJ/JEUR": "KRAKEN:INJEUR",
                                                "INJ/TRYB": "BINANCE:INJTRY",
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
                                                "IOTA/UST": "BINANCE:IOTAUSD",
                                                "IOTA/DAI": "BINANCE:IOTAUSD",
                                                "IOTA/PAX": "BINANCE:IOTAUSD",
                                                "IOTA/BNB": "BINANCE:IOTABNB",
                                                "IOTA/EURS": "BITPANDAPRO:MIOTAEUR",
                                                "IOTA/JEUR": "BITPANDAPRO:MIOTAEUR",
                                                "IOTA/JGBP": "BITFINEX:IOTGBP",
                                                "IOTA/JPYC": "BITFINEX:IOTJPY",
                                                "IOTA/BIDR": "BITFINEX:IOTIDR",
                                                "IOTX/BTC": "BINANCE:IOTXBTC",
                                                "IOTX/ETH": "BINANCE:IOTXETH",
                                                "IOTX/USDT": "BINANCE:IOTXUSD",
                                                "IOTX/BUSD": "BINANCE:IOTXUSD",
                                                "IOTX/USDC": "BINANCE:IOTXUSD",
                                                "IOTX/TUSD": "BINANCE:IOTXUSD",
                                                "IOTX/HUSD": "BINANCE:IOTXUSD",
                                                "IOTX/UST": "BINANCE:IOTXUSD",
                                                "IOTX/DAI": "BINANCE:IOTXUSD",
                                                "IOTX/PAX": "BINANCE:IOTXUSD",
                                                "JCHF/USDT": "FX_IDC:CHFUSD",
                                                "JCHF/BUSD": "FX_IDC:CHFUSD",
                                                "JCHF/USDC": "FX_IDC:CHFUSD",
                                                "JCHF/TUSD": "FX_IDC:CHFUSD",
                                                "JCHF/HUSD": "FX_IDC:CHFUSD",
                                                "JCHF/UST": "FX_IDC:CHFUSD",
                                                "JCHF/DAI": "FX_IDC:CHFUSD",
                                                "JCHF/PAX": "FX_IDC:CHFUSD",
                                                "JCHF/EURS": "FX_IDC:CHFEUR",
                                                "JCHF/JEUR": "FX_IDC:CHFEUR",
                                                "JCHF/JGBP": "FX_IDC:CHFGBP",
                                                "JCHF/BIDR": "FX_IDC:CHFIDR",
                                                "JCHF/QC": "FX_IDC:CHFCNY",
                                                "JCHF/BRZ": "FX_IDC:CHFBRL",
                                                "JCHF/TRYB": "FX_IDC:CHFTRY",
                                                "JCHF/JPYC": "FX:CHFJPY",
                                                "JCHF/XSGD": "FX_IDC:CHFSGD",
                                                "JCHF/CADC": "FX_IDC:CHFCAD",
                                                "JPYC/USDT": "FX_IDC:JPYUSD",
                                                "JPYC/BUSD": "FX_IDC:JPYUSD",
                                                "JPYC/USDC": "FX_IDC:JPYUSD",
                                                "JPYC/TUSD": "FX_IDC:JPYUSD",
                                                "JPYC/HUSD": "FX_IDC:JPYUSD",
                                                "JPYC/UST": "FX_IDC:JPYUSD",
                                                "JPYC/DAI": "FX_IDC:JPYUSD",
                                                "JPYC/PAX": "FX_IDC:JPYUSD",
                                                "JPYC/EURS": "FX_IDC:JPYEUR",
                                                "JPYC/JEUR": "FX_IDC:JPYEUR",
                                                "JPYC/BIDR": "FX_IDC:JPYIDR",
                                                "JPYC/QC": "FX_IDC:JPYCNY",
                                                "JPYC/BRZ": "FX_IDC:JPYBRL",
                                                "JPYC/TRYB": "FX_IDC:JPYTRY",
                                                "JRT/ETH": "UNISWAP:JRTWETH",
                                                "KCS/BTC": "KUCOIN:KCSBTC",
                                                "KCS/ETH": "KUCOIN:KCSETH",
                                                "KCS/USDT": "KUCOIN:KCSUSDT",
                                                "KCS/BUSD": "KUCOIN:KCSUSDT",
                                                "KCS/USDC": "KUCOIN:KCSUSDT",
                                                "KCS/TUSD": "KUCOIN:KCSUSDT",
                                                "KCS/HUSD": "KUCOIN:KCSUSDT",
                                                "KCS/UST": "KUCOIN:KCSUSDT",
                                                "KCS/DAI": "KUCOIN:KCSUSDT",
                                                "KCS/PAX": "KUCOIN:KCSUSDT",
                                                "KMD/BTC": "BINANCE:KMDBTC",
                                                "KMD/USDT": "BINANCE:KMDUSD",
                                                "KMD/BUSD": "BINANCE:KMDUSD",
                                                "KMD/USDC": "BINANCE:KMDUSD",
                                                "KMD/TUSD": "BINANCE:KMDUSD",
                                                "KMD/HUSD": "BINANCE:KMDUSD",
                                                "KMD/UST": "BINANCE:KMDUSD",
                                                "KMD/DAI": "BINANCE:KMDUSD",
                                                "KMD/PAX": "BINANCE:KMDUSD",
                                                "KNC/BTC": "BINANCE:KNCBTC",
                                                "KNC/ETH": "BINANCE:KNCETH",
                                                "KNC/USDT": "COINBASE:KNCUSD",
                                                "KNC/BUSD": "COINBASE:KNCUSD",
                                                "KNC/USDC": "COINBASE:KNCUSD",
                                                "KNC/TUSD": "COINBASE:KNCUSD",
                                                "KNC/HUSD": "COINBASE:KNCUSD",
                                                "KNC/UST": "COINBASE:KNCUSD",
                                                "KNC/DAI": "COINBASE:KNCUSD",
                                                "KNC/PAX": "COINBASE:KNCUSD",
                                                "KNC/EURS": "KRAKEN:KNCEUR",
                                                "KNC/JEUR": "KRAKEN:KNCEUR",
                                                "KSM/BTC": "BINANCE:KSMBTC",
                                                "KSM/ETH": "KRAKEN:KSMETH",
                                                "KSM/USDT": "KRAKEN:KSMUSD",
                                                "KSM/BUSD": "KRAKEN:KSMUSD",
                                                "KSM/USDC": "KRAKEN:KSMUSD",
                                                "KSM/TUSD": "KRAKEN:KSMUSD",
                                                "KSM/HUSD": "KRAKEN:KSMUSD",
                                                "KSM/UST": "KRAKEN:KSMUSD",
                                                "KSM/DAI": "KRAKEN:KSMUSD",
                                                "KSM/PAX": "KRAKEN:KSMUSD",
                                                "KSM/EURS": "KRAKEN:KSMEUR",
                                                "KSM/JEUR": "KRAKEN:KSMEUR",
                                                "KSM/JGBP": "KRAKEN:KSMGBP",
                                                "KSM/CADC": "EIGHTCAP:KSMCAD",
                                                "KSM/BNB": "BINANCE:KSMBNB",
                                                "KSM/HT": "HUOBI:KSMHT",
                                                "LBC/BTC": "BITTREX:LBCBTC",
                                                "LBC/ETH": "BITTREX:LBCETH",
                                                "LBC/USDT": "BITTREX:LBCUSD",
                                                "LBC/BUSD": "BITTREX:LBCUSD",
                                                "LBC/USDC": "BITTREX:LBCUSD",
                                                "LBC/TUSD": "BITTREX:LBCUSD",
                                                "LBC/HUSD": "BITTREX:LBCUSD",
                                                "LBC/UST": "BITTREX:LBCUSD",
                                                "LBC/DAI": "BITTREX:LBCUSD",
                                                "LBC/PAX": "BITTREX:LBCUSD",
                                                "LCC/BTC": "HITBTC:LCCBTC",
                                                "LCC/USDT": "HITBTC:LCCUSD",
                                                "LCC/BUSD": "HITBTC:LCCUSD",
                                                "LCC/USDC": "HITBTC:LCCUSD",
                                                "LCC/TUSD": "HITBTC:LCCUSD",
                                                "LCC/HUSD": "HITBTC:LCCUSD",
                                                "LCC/UST": "HITBTC:LCCUSD",
                                                "LCC/DAI": "HITBTC:LCCUSD",
                                                "LCC/PAX": "HITBTC:LCCUSD",
                                                "LEO/BTC": "BITFINEX:LEOBTC",
                                                "LEO/ETH": "BITFINEX:LEOETH",
                                                "LEO/USDT": "BITFINEX:LEOUSD",
                                                "LEO/BUSD": "BITFINEX:LEOUSD",
                                                "LEO/USDC": "BITFINEX:LEOUSD",
                                                "LEO/TUSD": "BITFINEX:LEOUSD",
                                                "LEO/HUSD": "BITFINEX:LEOUSD",
                                                "LEO/UST": "BITFINEX:LEOUSD",
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
                                                "LINK/UST": "BINANCE:LINKUSD",
                                                "LINK/DAI": "BINANCE:LINKUSD",
                                                "LINK/PAX": "BINANCE:LINKUSD",
                                                "LINK/EURS": "KRAKEN:LINKEUR",
                                                "LINK/JEUR": "KRAKEN:LINKEUR",
                                                "LINK/JGBP": "COINBASE:LINKGBP",
                                                "LINK/TRYB": "BINANCE:LINKTRY",
                                                "LINK/BRZ": "BINANCE:LINKBRL",
                                                "LINK/KCS": "KUCOIN:LINKKCS",
                                                "LRC/BTC": "BINANCE:LRCBTC",
                                                "LRC/ETH": "BINANCE:LRCETH",
                                                "LRC/USDT": "BINANCE:LRCUSD",
                                                "LRC/BUSD": "BINANCE:LRCUSD",
                                                "LRC/USDC": "BINANCE:LRCUSD",
                                                "LRC/TUSD": "BINANCE:LRCUSD",
                                                "LRC/HUSD": "BINANCE:LRCUSD",
                                                "LRC/UST": "BINANCE:LRCUSD",
                                                "LRC/DAI": "BINANCE:LRCUSD",
                                                "LRC/PAX": "BINANCE:LRCUSD",
                                                "LRC/TRYB": "BINANCE:LRCTRY",
                                                "LTC/BTC": "BINANCE:LTCBTC",
                                                "LTC/ETH": "BINANCE:LTCETH",
                                                "LTC/USDT": "COINBASE:LTCUSD",
                                                "LTC/BUSD": "COINBASE:LTCUSD",
                                                "LTC/USDC": "COINBASE:LTCUSD",
                                                "LTC/TUSD": "COINBASE:LTCUSD",
                                                "LTC/HUSD": "COINBASE:LTCUSD",
                                                "LTC/UST": "COINBASE:LTCUSD",
                                                "LTC/DAI": "COINBASE:LTCUSD",
                                                "LTC/PAX": "COINBASE:LTCUSD",
                                                "LTC/BNB": "BINANCE:LTCBNB",
                                                "LTC/EURS": "COINBASE:LTCEUR",
                                                "LTC/JEUR": "COINBASE:LTCEUR",
                                                "LTC/JGBP": "COINBASE:LTCGBP",
                                                "LTC/BRZ": "MERCADO:LTCBRL",
                                                "LTC/JPYC": "KRAKEN:LTCJPY",
                                                "LTC/CADC": "EIGHTCAP:LTCCAD",
                                                "LTC/BCH": "COINEX:LTCBCH",
                                                "LTC/HT": "HUOBI:LTCHT",
                                                "LTC/KCS": "KUCOIN:LTCKCS",
                                                "LUNA/BTC": "BINANCE:LUNABTC",
                                                "LUNA/ETH": "KUCOIN:LUNAETH",
                                                "LUNA/USDT": "BINANCE:LUNAUSD",
                                                "LUNA/BUSD": "BINANCE:LUNAUSD",
                                                "LUNA/USDC": "BINANCE:LUNAUSD",
                                                "LUNA/TUSD": "BINANCE:LUNAUSD",
                                                "LUNA/HUSD": "BINANCE:LUNAUSD",
                                                "LUNA/UST": "BINANCE:LUNAUSD",
                                                "LUNA/DAI": "BINANCE:LUNAUSD",
                                                "LUNA/PAX": "BINANCE:LUNAUSD",
                                                "LUNA/EURS": "BINANCE:LUNAEUR",
                                                "LUNA/JEUR": "BINANCE:LUNAEUR",
                                                "LUNA/TRYB": "BINANCE:LUNATRY",
                                                "LUNA/BNB": "BINANCE:LUNABNB",
                                                "LUNA/HT": "HUOBI:LUNAHT",
                                                "LUNA/BCH": "COINEX:LUNABCH",
                                                "LUNA/KCS": "KUCOIN:LUNAKCS",
                                                "MANA/BTC": "BINANCE:MANABTC",
                                                "MANA/ETH": "BINANCE:MANAETH",
                                                "MANA/USDT": "BINANCE:MANAUSD",
                                                "MANA/BUSD": "BINANCE:MANAUSD",
                                                "MANA/USDC": "BINANCE:MANAUSD",
                                                "MANA/TUSD": "BINANCE:MANAUSD",
                                                "MANA/HUSD": "BINANCE:MANAUSD",
                                                "MANA/UST": "BINANCE:MANAUSD",
                                                "MANA/DAI": "BINANCE:MANAUSD",
                                                "MANA/PAX": "BINANCE:MANAUSD",
                                                "MANA/EURS": "KRAKEN:MANAEUR",
                                                "MANA/JEUR": "KRAKEN:MANAEUR",
                                                "MANA/TRYB": "BINANCE:MANATRY",
                                                "MANA/BRZ": "BINANCE:MANABRL",
                                                "MANA/BNB": "BINANCE:MANABNB",
                                                "MATIC/BTC": "BINANCE:MATICBTC",
                                                "MATIC/ETH": "HUOBI:MATICETH",
                                                "MATIC/USDT": "BINANCE:MATICUSD",
                                                "MATIC/BUSD": "BINANCE:MATICUSD",
                                                "MATIC/USDC": "BINANCE:MATICUSD",
                                                "MATIC/TUSD": "BINANCE:MATICUSD",
                                                "MATIC/HUSD": "BINANCE:MATICUSD",
                                                "MATIC/UST": "BINANCE:MATICUSD",
                                                "MATIC/DAI": "BINANCE:MATICUSD",
                                                "MATIC/PAX": "BINANCE:MATICUSD",
                                                "MATIC/BNB": "BINANCE:MATICBNB",
                                                "MATIC/EURS": "COINBASE:MATICEUR",
                                                "MATIC/JEUR": "COINBASE:MATICEUR",
                                                "MATIC/JGBP": "COINBASE:MATICGBP",
                                                "MATIC/TRYB": "BINANCE:MATICTRY",
                                                "MATIC/BIDR": "BINANCE:MATICBIDR",
                                                "MATIC/BRZ": "BINANCE:MATICBRL",
                                                "MINDS/ETH": "UNISWAP:MINDSWETH",
                                                "MIR/BTC": "BINANCE:MIRBTC",
                                                "MIR/ETH": "HUOBI:MIRETH",
                                                "MIR/USDT": "COINBASE:MIRUSD",
                                                "MIR/BUSD": "COINBASE:MIRUSD",
                                                "MIR/USDC": "COINBASE:MIRUSD",
                                                "MIR/TUSD": "COINBASE:MIRUSD",
                                                "MIR/HUSD": "COINBASE:MIRUSD",
                                                "MIR/UST": "COINBASE:MIRUSD",
                                                "MIR/DAI": "COINBASE:MIRUSD",
                                                "MIR/PAX": "COINBASE:MIRUSD",
                                                "MIR/EURS": "COINBASE:MIREUR",
                                                "MIR/JEUR": "COINBASE:MIREUR",
                                                "MIR/JGBP": "COINBASE:MIRGBP",
                                                "MIR/KCS": "KUCOIN:MIRKCS",
                                                "MKR/BTC": "BINANCE:MKRBTC",
                                                "MKR/ETH": "BITFINEX:MKRETH",
                                                "MKR/BNB": "BINANCE:MKRBNB",
                                                "MKR/USDT": "BINANCE:MKRUSD",
                                                "MKR/BUSD": "BINANCE:MKRUSD",
                                                "MKR/USDC": "BINANCE:MKRUSD",
                                                "MKR/TUSD": "BINANCE:MKRUSD",
                                                "MKR/HUSD": "BINANCE:MKRUSD",
                                                "MKR/UST": "BINANCE:MKRUSD",
                                                "MKR/DAI": "BINANCE:MKRUSD",
                                                "MKR/PAX": "BINANCE:MKRUSD",
                                                "MKR/EURS": "BITSTAMP:MKREUR",
                                                "MKR/JEUR": "BITSTAMP:MKREUR",
                                                "MKR/JGBP": "KRAKEN:MKRGBP",
                                                "MKR/CADC": "EIGHTCAP:MKRCAD",
                                                "MONA/BTC": "BITTREX:MONABTC",
                                                "MONA/USDT": "BITTREX:MONAUSD",
                                                "MONA/BUSD": "BITTREX:MONAUSD",
                                                "MONA/USDC": "BITTREX:MONAUSD",
                                                "MONA/TUSD": "BITTREX:MONAUSD",
                                                "MONA/HUSD": "BITTREX:MONAUSD",
                                                "MONA/UST": "BITTREX:MONAUSD",
                                                "MONA/DAI": "BITTREX:MONAUSD",
                                                "MONA/PAX": "BITTREX:MONAUSD",
                                                "MONA/JPYC": "BITFLYER:MONAJPY",
                                                "MOVR/BTC": "BINANCE:MOVRBTC",
                                                "MOVR/ETH": "KUCOIN:MOVRETH",
                                                "MOVR/USDT": "KRAKEN:MOVRUSD",
                                                "MOVR/BUSD": "KRAKEN:MOVRUSD",
                                                "MOVR/USDC": "KRAKEN:MOVRUSD",
                                                "MOVR/TUSD": "KRAKEN:MOVRUSD",
                                                "MOVR/HUSD": "KRAKEN:MOVRUSD",
                                                "MOVR/UST": "KRAKEN:MOVRUSD",
                                                "MOVR/DAI": "KRAKEN:MOVRUSD",
                                                "MOVR/PAX": "KRAKEN:MOVRUSD",
                                                "MOVR/EURS": "KRAKEN:MOVREUR",
                                                "MOVR/JEUR": "KRAKEN:MOVREUR",
                                                "NAV/BTC": "BINANCE:NAVBTC",
                                                "NAV/USDT": "BINANCE:NAVUSD",
                                                "NAV/BUSD": "BINANCE:NAVUSD",
                                                "NAV/USDC": "BINANCE:NAVUSD",
                                                "NAV/TUSD": "BINANCE:NAVUSD",
                                                "NAV/HUSD": "BINANCE:NAVUSD",
                                                "NAV/UST": "BINANCE:NAVUSD",
                                                "NAV/DAI": "BINANCE:NAVUSD",
                                                "NAV/PAX": "BINANCE:NAVUSD",
                                                "NEAR/BTC": "BINANCE:NEARBTC",
                                                "NEAR/ETH": "OKEX:NEARETH",
                                                "NEAR/USDT": "BINANCE:NEARUSD",
                                                "NEAR/BUSD": "BINANCE:NEARUSD",
                                                "NEAR/USDC": "BINANCE:NEARUSD",
                                                "NEAR/TUSD": "BINANCE:NEARUSD",
                                                "NEAR/HUSD": "BINANCE:NEARUSD",
                                                "NEAR/UST": "BINANCE:NEARUSD",
                                                "NEAR/DAI": "BINANCE:NEARUSD",
                                                "NEAR/PAX": "BINANCE:NEARUSD",
                                                "NEAR/TRYB": "BINANCE:NEARTRY",
                                                "NEAR/BNB": "BINANCE:NEARBNB",
                                                "NEXO/BTC": "HUOBI:NEXOBTC",
                                                "NEXO/ETH": "HUOBI:NEXOETH",
                                                "NEXO/USDT": "BITFINEX:NEXOUSD",
                                                "NEXO/BUSD": "BITFINEX:NEXOUSD",
                                                "NEXO/USDC": "BITFINEX:NEXOUSD",
                                                "NEXO/TUSD": "BITFINEX:NEXOUSD",
                                                "NEXO/HUSD": "BITFINEX:NEXOUSD",
                                                "NEXO/UST": "BITFINEX:NEXOUSD",
                                                "NEXO/DAI": "BITFINEX:NEXOUSD",
                                                "NEXO/PAX": "BITFINEX:NEXOUSD",
                                                "NMC/BTC": "COINEX:NMCBTC",
                                                "NMC/USDT": "COINEX:NMCUSDT",
                                                "NMC/BUSD": "COINEX:NMCUSDT",
                                                "NMC/USDC": "COINEX:NMCUSDT",
                                                "NMC/TUSD": "COINEX:NMCUSDT",
                                                "NMC/HUSD": "COINEX:NMCUSDT",
                                                "NMC/UST": "COINEX:NMCUSDT",
                                                "NMC/DAI": "COINEX:NMCUSDT",
                                                "NMC/PAX": "COINEX:NMCUSDT",
                                                "NZDS/USDT": "FX:NZDUSD",
                                                "NZDS/BUSD": "FX:NZDUSD",
                                                "NZDS/USDC": "FX:NZDUSD",
                                                "NZDS/TUSD": "FX:NZDUSD",
                                                "NZDS/HUSD": "FX:NZDUSD",
                                                "NZDS/UST": "FX:NZDUSD",
                                                "NZDS/DAI": "FX:NZDUSD",
                                                "NZDS/PAX": "FX:NZDUSD",
                                                "NZDS/EURS": "FX_IDC:NZDEUR",
                                                "NZDS/JEUR": "FX_IDC:NZDEUR",
                                                "NZDS/JGBP": "FX_IDC:NZDGBP",
                                                "NZDS/BIDR": "FX_IDC:NZDIDR",
                                                "NZDS/QC": "FX_IDC:NZDCNY",
                                                "NZDS/BRZ": "FX_IDC:NZDBRL",
                                                "NZDS/TRYB": "FX_IDC:NZDTRY",
                                                "NZDS/JPYC": "FX:NZDJPY",
                                                "NZDS/XSGD": "FX_IDC:NZDSGD",
                                                "NZDS/CADC": "FX:NZDCAD",
                                                "OCEAN/BTC": "BINANCE:OCEANBTC",
                                                "OCEAN/ETH": "KUCOIN:OCEANETH",
                                                "OCEAN/USDT": "BINANCE:OCEANUSD",
                                                "OCEAN/BUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/USDC": "BINANCE:OCEANUSD",
                                                "OCEAN/TUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/HUSD": "BINANCE:OCEANUSD",
                                                "OCEAN/UST": "BINANCE:OCEANUSD",
                                                "OCEAN/DAI": "BINANCE:OCEANUSD",
                                                "OCEAN/PAX": "BINANCE:OCEANUSD",
                                                "OCEAN/BNB": "BINANCE:OCEANBNB",
                                                "OCEAN/EURS": "KRAKEN:OCEANEUR",
                                                "OCEAN/JEUR": "KRAKEN:OCEANEUR",
                                                "OKB/BTC": "OKEX:OKBBTC",
                                                "OKB/ETH": "OKEX:OKBETH",
                                                "OKB/USDT": "FTX:OKBUSD",
                                                "OKB/BUSD": "FTX:OKBUSD",
                                                "OKB/USDC": "FTX:OKBUSD",
                                                "OKB/TUSD": "FTX:OKBUSD",
                                                "OKB/HUSD": "FTX:OKBUSD",
                                                "OKB/UST": "FTX:OKBUSD",
                                                "OKB/DAI": "FTX:OKBUSD",
                                                "OKB/PAX": "FTX:OKBUSD",
                                                "OMG/BTC": "BINANCE:OMGBTC",
                                                "OMG/ETH": "BINANCE:OMGETH",
                                                "OMG/USDT": "BINANCE:OMGUSD",
                                                "OMG/BUSD": "BINANCE:OMGUSD",
                                                "OMG/USDC": "BINANCE:OMGUSD",
                                                "OMG/TUSD": "BINANCE:OMGUSD",
                                                "OMG/HUSD": "BINANCE:OMGUSD",
                                                "OMG/UST": "BINANCE:OMGUSD",
                                                "OMG/DAI": "BINANCE:OMGUSD",
                                                "OMG/PAX": "BINANCE:OMGUSD",
                                                "OMG/EURS": "COINBASE:OMGEUR",
                                                "OMG/JEUR": "COINBASE:OMGEUR",
                                                "OMG/BRZ": "MERCADO:OMGBRL",
                                                "ONE/BTC": "BINANCE:ONEBTC",
                                                "ONE/USDT": "BINANCE:ONEUSD",
                                                "ONE/BUSD": "BINANCE:ONEUSD",
                                                "ONE/USDC": "BINANCE:ONEUSD",
                                                "ONE/TUSD": "BINANCE:ONEUSD",
                                                "ONE/HUSD": "BINANCE:ONEUSD",
                                                "ONE/UST": "BINANCE:ONEUSD",
                                                "ONE/DAI": "BINANCE:ONEUSD",
                                                "ONE/PAX": "BINANCE:ONEUSD",
                                                "ONE/TRYB": "BINANCE:ONETRY",
                                                "ONE/BNB": "BINANCE:ONEBNB",
                                                "ONE/HT": "HUOBI:ONEHT",
                                                "ONT/BTC": "BINANCE:ONTBTC",
                                                "ONT/ETH": "BINANCE:ONTETH",
                                                "ONT/USDT": "BINANCE:ONTUSD",
                                                "ONT/BUSD": "BINANCE:ONTUSD",
                                                "ONT/USDC": "BINANCE:ONTUSD",
                                                "ONT/TUSD": "BINANCE:ONTUSD",
                                                "ONT/HUSD": "BINANCE:ONTUSD",
                                                "ONT/UST": "BINANCE:ONTUSD",
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
                                                "PAXG/UST": "KRAKEN:PAXGUSD",
                                                "PAXG/DAI": "KRAKEN:PAXGUSD",
                                                "PAXG/PAX": "KRAKEN:PAXGUSD",
                                                "PAXG/BNB": "BINANCE:PAXGBNB",
                                                "PAXG/EURS": "KRAKEN:PAXGEUR",
                                                "PAXG/JEUR": "KRAKEN:PAXGEUR",
                                                "PNK/BTC": "BITFINEX:PNKBTC",
                                                "PNK/ETH": "BITFINEX:PNKETH",
                                                "PNK/USDT": "BITFINEX:PNKUSD",
                                                "PNK/BUSD": "BITFINEX:PNKUSD",
                                                "PNK/USDC": "BITFINEX:PNKUSD",
                                                "PNK/TUSD": "BITFINEX:PNKUSD",
                                                "PNK/HUSD": "BITFINEX:PNKUSD",
                                                "PNK/UST": "BITFINEX:PNKUSD",
                                                "PNK/DAI": "BITFINEX:PNKUSD",
                                                "PNK/PAX": "BITFINEX:PNKUSD",
                                                "POWR/BTC": "BINANCE:POWRBTC",
                                                "POWR/ETH": "BINANCE:POWRETH",
                                                "POWR/USDT": "BINANCE:POWRUSD",
                                                "POWR/BUSD": "BINANCE:POWRUSD",
                                                "POWR/USDC": "BINANCE:POWRUSD",
                                                "POWR/TUSD": "BINANCE:POWRUSD",
                                                "POWR/HUSD": "BINANCE:POWRUSD",
                                                "POWR/UST": "BINANCE:POWRUSD",
                                                "POWR/DAI": "BINANCE:POWRUSD",
                                                "POWR/PAX": "BINANCE:POWRUSD",
                                                "PPC/BTC": "BITTREX:PPCBTC",
                                                "PPC/USDT": "BITTREX:PPCUSD",
                                                "PPC/BUSD": "BITTREX:PPCUSD",
                                                "PPC/USDC": "BITTREX:PPCUSD",
                                                "PPC/TUSD": "BITTREX:PPCUSD",
                                                "PPC/HUSD": "BITTREX:PPCUSD",
                                                "PPC/UST": "BITTREX:PPCUSD",
                                                "PPC/DAI": "BITTREX:PPCUSD",
                                                "PPC/PAX": "BITTREX:PPCUSD",
                                                "PPC/EURS": "THEROCKTRADING:PPCEUR",
                                                "PPC/JEUR": "THEROCKTRADING:PPCEUR",
                                                "QC/USDT": "FX_IDC:CNYUSD",
                                                "QC/BUSD": "FX_IDC:CNYUSD",
                                                "QC/USDC": "FX_IDC:CNYUSD",
                                                "QC/TUSD": "FX_IDC:CNYUSD",
                                                "QC/HUSD": "FX_IDC:CNYUSD",
                                                "QC/UST": "FX_IDC:CNYUSD",
                                                "QC/DAI": "FX_IDC:CNYUSD",
                                                "QC/PAX": "FX_IDC:CNYUSD",
                                                "QC/EURS": "FX_IDC:CNYEUR",
                                                "QC/JEUR": "FX_IDC:CNYEUR",
                                                "QC/TRYB": "FX_IDC:CNYTRY",
                                                "QC/BIDR": "FX_IDC:CNYIDR",
                                                "QC/BRZ": "FX_IDC:CNYBRL",
                                                "QKC/BTC": "BINANCE:QKCBTC",
                                                "QKC/ETH": "BINANCE:QKCETH",
                                                "QKC/USDT": "BINANCE:QKCUSD",
                                                "QKC/BUSD": "BINANCE:QKCUSD",
                                                "QKC/USDC": "BINANCE:QKCUSD",
                                                "QKC/TUSD": "BINANCE:QKCUSD",
                                                "QKC/HUSD": "BINANCE:QKCUSD",
                                                "QKC/UST": "BINANCE:QKCUSD",
                                                "QKC/DAI": "BINANCE:QKCUSD",
                                                "QKC/PAX": "BINANCE:QKCUSD",
                                                "QNT/BTC": "BITTREX:QNTBTC",
                                                "QNT/ETH": "BITTREX:QNTETH",
                                                "QNT/USDT": "BITTREX:QNTUSD",
                                                "QNT/BUSD": "BITTREX:QNTUSD",
                                                "QNT/USDC": "BITTREX:QNTUSD",
                                                "QNT/TUSD": "BITTREX:QNTUSD",
                                                "QNT/HUSD": "BITTREX:QNTUSD",
                                                "QNT/UST": "BITTREX:QNTUSD",
                                                "QNT/DAI": "BITTREX:QNTUSD",
                                                "QNT/PAX": "BITTREX:QNTUSD",
                                                "QNT/BNB": "BINANCE:QNTBNB",
                                                "QTUM/BTC": "BINANCE:QTUMBTC",
                                                "QTUM/ETH": "BINANCE:QTUMETH",
                                                "QTUM/USDT": "BINANCE:QTUMUSD",
                                                "QTUM/BUSD": "BINANCE:QTUMUSD",
                                                "QTUM/USDC": "BINANCE:QTUMUSD",
                                                "QTUM/TUSD": "BINANCE:QTUMUSD",
                                                "QTUM/HUSD": "BINANCE:QTUMUSD",
                                                "QTUM/UST": "BINANCE:QTUMUSD",
                                                "QTUM/DAI": "BINANCE:QTUMUSD",
                                                "QTUM/PAX": "BINANCE:QTUMUSD",
                                                "QTUM/EURS": "KRAKEN:QTUMEUR",
                                                "QTUM/JEUR": "KRAKEN:QTUMEUR",
                                                "REN/BTC": "BINANCE:RENBTC",
                                                "REN/ETH": "HUOBI:RENETH",
                                                "REN/USDT": "BINANCE:RENUSD",
                                                "REN/BUSD": "BINANCE:RENUSD",
                                                "REN/USDC": "BINANCE:RENUSD",
                                                "REN/TUSD": "BINANCE:RENUSD",
                                                "REN/HUSD": "BINANCE:RENUSD",
                                                "REN/UST": "BINANCE:RENUSD",
                                                "REN/DAI": "BINANCE:RENUSD",
                                                "REN/PAX": "BINANCE:RENUSD",
                                                "REN/EURS": "BITTREX:RENEUR",
                                                "REN/JEUR": "BITTREX:RENEUR",
                                                "REN/JGBP": "KRAKEN:RENGBP",
                                                "REN/BRZ": "MERCADO:RENBRL",
                                                "REP/BTC": "BINANCE:REPBTC",
                                                "REP/ETH": "BINANCE:REPETH",
                                                "REP/USDT": "COINBASE:REPUSD",
                                                "REP/BUSD": "COINBASE:REPUSD",
                                                "REP/USDC": "COINBASE:REPUSD",
                                                "REP/REP": "COINBASE:REPUSD",
                                                "REP/HUSD": "COINBASE:REPUSD",
                                                "REP/UST": "COINBASE:REPUSD",
                                                "REP/DAI": "COINBASE:REPUSD",
                                                "REP/PAX": "COINBASE:REPUSD",
                                                "REP/EURS": "KRAKEN:REPEUR",
                                                "REP/JEUR": "KRAKEN:REPEUR",
                                                "REV/BTC": "BITTREX:REVBTC",
                                                "REV/USDT": "BITTREX:REVUSD",
                                                "REV/BUSD": "BITTREX:REVUSD",
                                                "REV/USDC": "BITTREX:REVUSD",
                                                "REV/TUSD": "BITTREX:REVUSD",
                                                "REV/HUSD": "BITTREX:REVUSD",
                                                "REV/UST": "BITTREX:REVUSD",
                                                "REV/DAI": "BITTREX:REVUSD",
                                                "REV/PAX": "BITTREX:REVUSD",
                                                "RLC/BTC": "BINANCE:RLCBTC",
                                                "RLC/ETH": "BINANCE:RLCETH",
                                                "RLC/USDT": "BINANCE:RLCUSD",
                                                "RLC/BUSD": "BINANCE:RLCUSD",
                                                "RLC/USDC": "BINANCE:RLCUSD",
                                                "RLC/TUSD": "BINANCE:RLCUSD",
                                                "RLC/HUSD": "BINANCE:RLCUSD",
                                                "RLC/UST": "BINANCE:RLCUSD",
                                                "RLC/DAI": "BINANCE:RLCUSD",
                                                "RLC/PAX": "BINANCE:RLCUSD",
                                                "RSR/BTC": "BINANCE:RSRBTC",
                                                "RSR/ETH": "OKEX:RSRETH",
                                                "RSR/USDT": "BINANCE:RSRUSD",
                                                "RSR/BUSD": "BINANCE:RSRUSD",
                                                "RSR/USDC": "BINANCE:RSRUSD",
                                                "RSR/TUSD": "BINANCE:RSRUSD",
                                                "RSR/HUSD": "BINANCE:RSRUSD",
                                                "RSR/UST": "BINANCE:RSRUSD",
                                                "RSR/DAI": "BINANCE:RSRUSD",
                                                "RSR/PAX": "BINANCE:RSRUSD",
                                                "RSR/BNB": "BINANCE:RSRBNB",
                                                "RSR/HT": "HUOBI:RSRHT",
                                                "RTM/BTC": "COINEX:RTMBTC",
                                                "RTM/USDT": "COINEX:RTMUSDT",
                                                "RTM/BUSD": "COINEX:RTMUSDT",
                                                "RTM/USDC": "COINEX:RTMUSDT",
                                                "RTM/TUSD": "COINEX:RTMUSDT",
                                                "RTM/HUSD": "COINEX:RTMUSDT",
                                                "RTM/UST": "COINEX:RTMUSDT",
                                                "RTM/DAI": "COINEX:RTMUSDT",
                                                "RTM/PAX": "COINEX:RTMUSDT",
                                                "RVN/BTC": "BINANCE:RVNBTC",
                                                "RVN/ETH": "BITTREX:RVNETH",
                                                "RVN/USDT": "BINANCE:RVNUSD",
                                                "RVN/BUSD": "BINANCE:RVNUSD",
                                                "RVN/USDC": "BINANCE:RVNUSD",
                                                "RVN/TUSD": "BINANCE:RVNUSD",
                                                "RVN/HUSD": "BINANCE:RVNUSD",
                                                "RVN/UST": "BINANCE:RVNUSD",
                                                "RVN/DAI": "BINANCE:RVNUSD",
                                                "RVN/PAX": "BINANCE:RVNUSD",
                                                "RVN/TRYB": "BINANCE:RVNTRY",
                                                "RVN/HT": "HUOBI:RVNHT",
                                                "SAND/BTC": "BINANCE:SANDBTC",
                                                "SAND/ETH": "BINANCE:SANDETH",
                                                "SAND/USDT": "BINANCE:SANDUSD",
                                                "SAND/BUSD": "BINANCE:SANDUSD",
                                                "SAND/USDC": "BINANCE:SANDUSD",
                                                "SAND/TUSD": "BINANCE:SANDUSD",
                                                "SAND/HUSD": "BINANCE:SANDUSD",
                                                "SAND/UST": "BINANCE:SANDUSD",
                                                "SAND/DAI": "BINANCE:SANDUSD",
                                                "SAND/PAX": "BINANCE:SANDUSD",
                                                "SAND/EURS": "KRAKEN:SANDEUR",
                                                "SAND/JEUR": "KRAKEN:SANDEUR",
                                                "SAND/JGBP": "KRAKEN:SANDGBP",
                                                "SAND/TRYB": "BINANCE:SANDTRY",
                                                "SAND/BIDR": "BINANCE:SANDBIDR",
                                                "SAND/BRZ": "BINANCE:SANDBRL",
                                                "SAND/BNB": "BINANCE:SANDBNB",
                                                "SAND/HT": "HUOBI:SANDHT",
                                                "SHIB/USDT": "FTX:SHIBUSD",
                                                "SHIB/BUSD": "FTX:SHIBUSD",
                                                "SHIB/USDC": "FTX:SHIBUSD",
                                                "SHIB/TUSD": "FTX:SHIBUSD",
                                                "SHIB/HUSD": "FTX:SHIBUSD",
                                                "SHIB/UST": "FTX:SHIBUSD",
                                                "SHIB/DAI": "FTX:SHIBUSD",
                                                "SHIB/PAX": "FTX:SHIBUSD",
                                                "SHIB/EURS": "BINANCE:SHIBEUR",
                                                "SHIB/JEUR": "BINANCE:SHIBEUR",
                                                "SHIB/JGBP": "COINBASE:SHIBGBP",
                                                "SHIB/TRYB": "BINANCE:SHIBTRY",
                                                "SHIB/BRZ": "BINANCE:SHIBBRL",
                                                "SHIB/DOGE": "BINANCE:SHIBDOGE",
                                                "SHR/BTC": "KUCOIN:SHRBTC",
                                                "SHR/USDT": "BITTREX:SHRUSD",
                                                "SHR/BUSD": "BITTREX:SHRUSD",
                                                "SHR/USDC": "BITTREX:SHRUSD",
                                                "SHR/TUSD": "BITTREX:SHRUSD",
                                                "SHR/HUSD": "BITTREX:SHRUSD",
                                                "SHR/UST": "BITTREX:SHRUSD",
                                                "SHR/DAI": "BITTREX:SHRUSD",
                                                "SHR/PAX": "BITTREX:SHRUSD",
                                                "SKL/BTC": "BINANCE:SKLBTC",
                                                "SKL/ETH": "HUOBI:SKLETH",
                                                "SKL/USDT": "COINBASE:SKLUSD",
                                                "SKL/BUSD": "COINBASE:SKLUSD",
                                                "SKL/USDC": "COINBASE:SKLUSD",
                                                "SKL/TUSD": "COINBASE:SKLUSD",
                                                "SKL/HUSD": "COINBASE:SKLUSD",
                                                "SKL/UST": "COINBASE:SKLUSD",
                                                "SKL/DAI": "COINBASE:SKLUSD",
                                                "SKL/PAX": "COINBASE:SKLUSD",
                                                "SKL/EURS": "COINBASE:SKLEUR",
                                                "SKL/JEUR": "COINBASE:SKLEUR",
                                                "SNT/BTC": "BINANCE:SNTBTC",
                                                "SNT/ETH": "BINANCE:SNTETH",
                                                "SNT/USDT": "BINANCE:SNTUSD",
                                                "SNT/BUSD": "BINANCE:SNTUSD",
                                                "SNT/USDC": "BINANCE:SNTUSD",
                                                "SNT/TUSD": "BINANCE:SNTUSD",
                                                "SNT/HUSD": "BINANCE:SNTUSD",
                                                "SNT/UST": "BINANCE:SNTUSD",
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
                                                "SNX/UST": "BINANCE:SNXUSD",
                                                "SNX/DAI": "BINANCE:SNXUSD",
                                                "SNX/PAX": "BINANCE:SNXUSD",
                                                "SNX/EURS": "KRAKEN:SNXEUR",
                                                "SNX/JEUR": "KRAKEN:SNXEUR",
                                                "SOL/BTC": "BINANCE:SOLBTC",
                                                "SOL/ETH": "HUOBI:SOLETH",
                                                "SOL/USDT": "FTX:SOLUSD",
                                                "SOL/BUSD": "FTX:SOLUSD",
                                                "SOL/USDC": "FTX:SOLUSD",
                                                "SOL/TUSD": "FTX:SOLUSD",
                                                "SOL/HUSD": "FTX:SOLUSD",
                                                "SOL/UST": "FTX:SOLUSD",
                                                "SOL/DAI": "FTX:SOLUSD",
                                                "SOL/PAX": "FTX:SOLUSD",
                                                "SOL/EURS": "BINANCE:SOLEUR",
                                                "SOL/JEUR": "BINANCE:SOLEUR",
                                                "SOL/JGBP": "COINBASE:SOLGBP",
                                                "SOL/TRYB": "BINANCE:SOLTRY",
                                                "SOL/BIDR": "BINANCE:SOLBIDR",
                                                "SOL/BRZ": "BINANCE:SOLBRL",
                                                "SOL/CADC": "EIGHTCAP:SOLCAD",
                                                "SOL/BNB": "BINANCE:SOLBNB",
                                                "SOL/BCH": "COINEX:SOLBCH",
                                                "SPC/BTC": "BITTREX:SPCBTC",
                                                "SPC/ETH": "HITBTC:SPCETH",
                                                "SPC/USDT": "HITBTC:SPCUSDT",
                                                "SRM/BTC": "BINANCE:SRMBTC",
                                                "SRM/USDT": "FTX:SRMUSD",
                                                "SRM/BUSD": "FTX:SRMUSD",
                                                "SRM/USDC": "FTX:SRMUSD",
                                                "SRM/TUSD": "FTX:SRMUSD",
                                                "SRM/HUSD": "FTX:SRMUSD",
                                                "SRM/UST": "FTX:SRMUSD",
                                                "SRM/DAI": "FTX:SRMUSD",
                                                "SRM/PAX": "FTX:SRMUSD",
                                                "SRM/BNB": "BINANCE:SRMBNB",
                                                "SRM/EURS": "KRAKEN:SRMEUR",
                                                "SRM/JEUR": "KRAKEN:SRMEUR",
                                                "STFIRO/ETH": "SUSHISWAP:STFIROWETH",
                                                "STORJ/BTC": "BINANCE:STORJBTC",
                                                "STORJ/ETH": "KRAKEN:STORJETH",
                                                "STORJ/USDT": "BINANCE:STORJUSD",
                                                "STORJ/BUSD": "BINANCE:STORJUSD",
                                                "STORJ/USDC": "BINANCE:STORJUSD",
                                                "STORJ/TUSD": "BINANCE:STORJUSD",
                                                "STORJ/HUSD": "BINANCE:STORJUSD",
                                                "STORJ/UST": "BINANCE:STORJUSD",
                                                "STORJ/DAI": "BINANCE:STORJUSD",
                                                "STORJ/PAX": "BINANCE:STORJUSD",
                                                "STORJ/EURS": "KRAKEN:STORJEUR",
                                                "STORJ/JEUR": "KRAKEN:STORJEUR",
                                                "SUSHI/BTC": "BINANCE:SUSHIBTC",
                                                "SUSHI/ETH": "HUOBI:SUSHIETH",
                                                "SUSHI/USDT": "BINANCE:SUSHIUSD",
                                                "SUSHI/BUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/USDC": "BINANCE:SUSHIUSD",
                                                "SUSHI/TUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/HUSD": "BINANCE:SUSHIUSD",
                                                "SUSHI/UST": "BINANCE:SUSHIUSD",
                                                "SUSHI/DAI": "BINANCE:SUSHIUSD",
                                                "SUSHI/PAX": "BINANCE:SUSHIUSD",
                                                "SUSHI/BNB": "BINANCE:SUSHIBNB",
                                                "SUSHI/EURS": "COINBASE:SUSHIEUR",
                                                "SUSHI/JEUR": "COINBASE:SUSHIEUR",
                                                "SUSHI/BIDR": "BINANCE:SUSHIBIDR",
                                                "SXP/BTC": "BINANCE:SXPBTC",
                                                "SXP/BNB": "BINANCE:SXPBNB",
                                                "SXP/USDT": "BINANCE:SXPUSD",
                                                "SXP/BUSD": "BINANCE:SXPUSD",
                                                "SXP/USDC": "BINANCE:SXPUSD",
                                                "SXP/TUSD": "BINANCE:SXPUSD",
                                                "SXP/HUSD": "BINANCE:SXPUSD",
                                                "SXP/UST": "BINANCE:SXPUSD",
                                                "SXP/DAI": "BINANCE:SXPUSD",
                                                "SXP/PAX": "BINANCE:SXPUSD",
                                                "SXP/EURS": "BINANCE:SXPEUR",
                                                "SXP/JEUR": "BINANCE:SXPEUR",
                                                "SXP/JGBP": "BINANCE:SXPGBP",
                                                "SXP/TRYB": "BINANCE:SXPTRY",
                                                "SXP/BIDR": "BINANCE:SXPBIDR",
                                                "SYS/BTC": "BINANCE:SYSBTC",
                                                "SYS/USDT": "BINANCE:SYSUSD",
                                                "SYS/BUSD": "BINANCE:SYSUSD",
                                                "SYS/USDC": "BINANCE:SYSUSD",
                                                "SYS/TUSD": "BINANCE:SYSUSD",
                                                "SYS/HUSD": "BINANCE:SYSUSD",
                                                "SYS/UST": "BINANCE:SYSUSD",
                                                "SYS/DAI": "BINANCE:SYSUSD",
                                                "SYS/PAX": "BINANCE:SYSUSD",
                                                "TEL/BTC": "KUCOIN:TELBTC",
                                                "TEL/ETH": "KUCOIN:TELETH",
                                                "TEL/USDT": "KUCOIN:TELUSDT",
                                                "TEL/BUSD": "KUCOIN:TELUSDT",
                                                "TEL/USDC": "KUCOIN:TELUSDT",
                                                "TEL/TUSD": "KUCOIN:TELUSDT",
                                                "TEL/HUSD": "KUCOIN:TELUSDT",
                                                "TEL/UST": "KUCOIN:TELUSDT",
                                                "TEL/DAI": "KUCOIN:TELUSDT",
                                                "TEL/PAX": "KUCOIN:TELUSDT",
                                                "TMTG/USDT": "OKEX:TMTGUSDT",
                                                "TMTG/BUSD": "OKEX:TMTGUSDT",
                                                "TMTG/USDC": "OKEX:TMTGUSDT",
                                                "TMTG/TUSD": "OKEX:TMTGUSDT",
                                                "TMTG/HUSD": "OKEX:TMTGUSDT",
                                                "TMTG/UST": "OKEX:TMTGUSDT",
                                                "TMTG/DAI": "OKEX:TMTGUSDT",
                                                "TMTG/PAX": "OKEX:TMTGUSDT",
                                                "TRAC/BTC": "KUCOIN:TRACBTC",
                                                "TRAC/ETH": "KUCOIN:TRACETH",
                                                "TRAC/USDT": "BITTREX:TRACUSD",
                                                "TRAC/BUSD": "BITTREX:TRACUSD",
                                                "TRAC/USDC": "BITTREX:TRACUSD",
                                                "TRAC/TUSD": "BITTREX:TRACUSD",
                                                "TRAC/HUSD": "BITTREX:TRACUSD",
                                                "TRAC/UST": "BITTREX:TRACUSD",
                                                "TRAC/DAI": "BITTREX:TRACUSD",
                                                "TRAC/PAX": "BITTREX:TRACUSD",
                                                "TRX/BTC": "BINANCE:TRXBTC",
                                                "TRX/ETH": "BINANCE:TRXETH",
                                                "TRX/USDT": "KRAKEN:TRXUSD",
                                                "TRX/BUSD": "KRAKEN:TRXUSD",
                                                "TRX/USDC": "KRAKEN:TRXUSD",
                                                "TRX/TUSD": "KRAKEN:TRXUSD",
                                                "TRX/HUSD": "KRAKEN:TRXUSD",
                                                "TRX/UST": "KRAKEN:TRXUSD",
                                                "TRX/DAI": "KRAKEN:TRXUSD",
                                                "TRX/PAX": "KRAKEN:TRXUSD",
                                                "TRX/BNB": "BINANCE:TRXBNB",
                                                "TRX/EURS": "KRAKEN:TRXEUR",
                                                "TRX/JEUR": "KRAKEN:TRXEUR",
                                                "TRX/JGBP": "EIGHTCAP:TRXGBP",
                                                "TRX/TRYB": "BINANCE:TRXTRY",
                                                "TRX/CADC": "EIGHTCAP:TRXCAD",
                                                "TRX/BCH": "HITBTC:TRXBCH",
                                                "TRX/KCS": "KUCOIN:TRXKCS",
                                                "TRYB/USDT": "FX_IDC:TRYUSD",
                                                "TRYB/BUSD": "FX_IDC:TRYUSD",
                                                "TRYB/USDC": "FX_IDC:TRYUSD",
                                                "TRYB/TUSD": "FX_IDC:TRYUSD",
                                                "TRYB/HUSD": "FX_IDC:TRYUSD",
                                                "TRYB/UST": "FX_IDC:TRYUSD",
                                                "TRYB/DAI": "FX_IDC:TRYUSD",
                                                "TRYB/PAX": "FX_IDC:TRYUSD",
                                                "TRYB/EURS": "FX_IDC:TRYEUR",
                                                "TRYB/JEUR": "FX_IDC:TRYEUR",
                                                "THC/BTC": "BITTREX:THCBTC",
                                                "THC/USDT": "BITTREX:THCUSD",
                                                "THC/BUSD": "BITTREX:THCUSD",
                                                "THC/USDC": "BITTREX:THCUSD",
                                                "THC/TUSD": "BITTREX:THCUSD",
                                                "THC/HUSD": "BITTREX:THCUSD",
                                                "THC/UST": "BITTREX:THCUSD",
                                                "THC/DAI": "BITTREX:THCUSD",
                                                "THC/PAX": "BITTREX:THCUSD",
                                                "UBT/BTC": "BITTREX:UBTBTC",
                                                "UBT/ETH": "BITTREX:UBTETH",
                                                "UBT/USDT": "BITTREX:UBTUSD",
                                                "UBT/BUSD": "BITTREX:UBTUSD",
                                                "UBT/USDC": "BITTREX:UBTUSD",
                                                "UBT/TUSD": "BITTREX:UBTUSD",
                                                "UBT/HUSD": "BITTREX:UBTUSD",
                                                "UBT/UST": "BITTREX:UBTUSD",
                                                "UBT/DAI": "BITTREX:UBTUSD",
                                                "UBT/PAX": "BITTREX:UBTUSD",
                                                "UBT/EURS": "BITTREX:UBTEUR",
                                                "UBT/JEUR": "BITTREX:UBTEUR",
                                                "UMA/BTC": "BINANCE:UMABTC",
                                                "UMA/ETH": "OKEX:UMAETH",
                                                "UMA/USDT": "COINBASE:UMAUSD",
                                                "UMA/BUSD": "COINBASE:UMAUSD",
                                                "UMA/USDC": "COINBASE:UMAUSD",
                                                "UMA/TUSD": "COINBASE:UMAUSD",
                                                "UMA/HUSD": "COINBASE:UMAUSD",
                                                "UMA/UST": "COINBASE:UMAUSD",
                                                "UMA/DAI": "COINBASE:UMAUSD",
                                                "UMA/PAX": "COINBASE:UMAUSD",
                                                "UMA/EURS": "COINBASE:UMAEUR",
                                                "UMA/JEUR": "COINBASE:UMAEUR",
                                                "UMA/TRYB": "BINANCE:UMATRY",
                                                "UNI/BTC": "BINANCE:UNIBTC",
                                                "UNI/ETH": "KRAKEN:UNIETH",
                                                "UNI/USDT": "COINBASE:UNIUSD",
                                                "UNI/BUSD": "COINBASE:UNIUSD",
                                                "UNI/USDC": "COINBASE:UNIUSD",
                                                "UNI/TUSD": "COINBASE:UNIUSD",
                                                "UNI/HUSD": "COINBASE:UNIUSD",
                                                "UNI/UST": "COINBASE:UNIUSD",
                                                "UNI/DAI": "COINBASE:UNIUSD",
                                                "UNI/PAX": "COINBASE:UNIUSD",
                                                "UNI/BNB": "BINANCE:UNIBNB",
                                                "UNI/EURS": "KRAKEN:UNIEUR",
                                                "UNI/JEUR": "KRAKEN:UNIEUR",
                                                "UNI/JGBP": "EIGHTCAP:UNIGBP",
                                                "UNI/CADC": "EIGHTCAP:UNICAD",
                                                "UNI/KCS": "KUCOIN:UNIKCS",
                                                "UOS/BTC": "BITFINEX:UOSBTC",
                                                "UOS/USDT": "BITFINEX:UOSUSD",
                                                "UOS/BUSD": "BITFINEX:UOSUSD",
                                                "UOS/USDC": "BITFINEX:UOSUSD",
                                                "UOS/TUSD": "BITFINEX:UOSUSD",
                                                "UOS/HUSD": "BITFINEX:UOSUSD",
                                                "UOS/UST": "BITFINEX:UOSUSD",
                                                "UOS/DAI": "BITFINEX:UOSUSD",
                                                "UOS/PAX": "BITFINEX:UOSUSD",
                                                "UQC/BTC": "BITTREX:UQCBTC",
                                                "UQC/ETH": "KUCOIN:UQCETH",
                                                "UQC/USDT": "BITTREX:UQCUSD",
                                                "UQC/BUSD": "BITTREX:UQCUSD",
                                                "UQC/USDC": "BITTREX:UQCUSD",
                                                "UQC/TUSD": "BITTREX:UQCUSD",
                                                "UQC/HUSD": "BITTREX:UQCUSD",
                                                "UQC/UST": "BITTREX:UQCUSD",
                                                "UQC/DAI": "BITTREX:UQCUSD",
                                                "UQC/PAX": "BITTREX:UQCUSD",
                                                "UTK/BTC": "BINANCE:UTKBTC",
                                                "UTK/ETH": "HUOBI:UTKETH",
                                                "UTK/USDT": "BINANCE:UTKUSD",
                                                "UTK/BUSD": "BINANCE:UTKUSD",
                                                "UTK/USDC": "BINANCE:UTKUSD",
                                                "UTK/TUSD": "BINANCE:UTKUSD",
                                                "UTK/HUSD": "BINANCE:UTKUSD",
                                                "UTK/UST": "BINANCE:UTKUSD",
                                                "UTK/DAI": "BINANCE:UTKUSD",
                                                "UTK/PAX": "BINANCE:UTKUSD",
                                                "VAL/BTC": "BITTREX:VALBTC",
                                                "VAL/USDT": "BITTREX:VALUSD",
                                                "VAL/BUSD": "BITTREX:VALUSD",
                                                "VAL/USDC": "BITTREX:VALUSD",
                                                "VAL/TUSD": "BITTREX:VALUSD",
                                                "VAL/HUSD": "BITTREX:VALUSD",
                                                "VAL/UST": "BITTREX:VALUSD",
                                                "VAL/DAI": "BITTREX:VALUSD",
                                                "VAL/PAX": "BITTREX:VALUSD",
                                                "VET/BTC": "BINANCE:VETBTC",
                                                "VET/ETH": "BINANCE:VETETH",
                                                "VET/USDT": "BINANCE:VETUSD",
                                                "VET/BUSD": "BINANCE:VETUSD",
                                                "VET/USDC": "BINANCE:VETUSD",
                                                "VET/TUSD": "BINANCE:VETUSD",
                                                "VET/HUSD": "BINANCE:VETUSD",
                                                "VET/UST": "BINANCE:VETUSD",
                                                "VET/DAI": "BINANCE:VETUSD",
                                                "VET/PAX": "BINANCE:VETUSD",
                                                "VET/EURS": "BINANCE:VETEUR",
                                                "VET/JEUR": "BINANCE:VETEUR",
                                                "VET/JGBP": "BINANCE:VETGBP",
                                                "VET/TRYB": "BINANCE:VETTRY",
                                                "VET/CADC": "EIGHTCAP:VETCAD",
                                                "VET/BNB": "BINANCE:VETBNB",
                                                "VET/KCS": "KUCOIN:VETKCS",
                                                "VITE/BTC": "BINANCE:VITEBTC",
                                                "VITE/USDT": "BINANCE:VITEUSD",
                                                "VITE/BUSD": "BINANCE:VITEUSD",
                                                "VITE/USDC": "BINANCE:VITEUSD",
                                                "VITE/TUSD": "BINANCE:VITEUSD",
                                                "VITE/HUSD": "BINANCE:VITEUSD",
                                                "VITE/UST": "BINANCE:VITEUSD",
                                                "VITE/DAI": "BINANCE:VITEUSD",
                                                "VITE/PAX": "BINANCE:VITEUSD",
                                                "VRA/BTC": "KUCOIN:VRABTC",
                                                "VRA/USDT": "BITTREX:VRAUSD",
                                                "VRA/BUSD": "BITTREX:VRAUSD",
                                                "VRA/USDC": "BITTREX:VRAUSD",
                                                "VRA/TUSD": "BITTREX:VRAUSD",
                                                "VRA/HUSD": "BITTREX:VRAUSD",
                                                "VRA/UST": "BITTREX:VRAUSD",
                                                "VRA/DAI": "BITTREX:VRAUSD",
                                                "VRA/PAX": "BITTREX:VRAUSD",
                                                "WAVES/BTC": "BINANCE:WAVESBTC",
                                                "WAVES/ETH": "BINANCE:WAVESETH",
                                                "WAVES/USDT": "BINANCE:WAVESUSD",
                                                "WAVES/BUSD": "BINANCE:WAVESUSD",
                                                "WAVES/USDC": "BINANCE:WAVESUSD",
                                                "WAVES/TUSD": "BINANCE:WAVESUSD",
                                                "WAVES/HUSD": "BINANCE:WAVESUSD",
                                                "WAVES/UST": "BINANCE:WAVESUSD",
                                                "WAVES/DAI": "BINANCE:WAVESUSD",
                                                "WAVES/PAX": "BINANCE:WAVESUSD",
                                                "WAVES/EURS": "KRAKEN:WAVESEUR",
                                                "WAVES/JEUR": "KRAKEN:WAVESEUR",
                                                "WAVES/TRYB": "BINANCE:WAVESTRY",
                                                "WAVES/BNB": "BINANCE:WAVESBNB",
                                                "WBTC/BTC": "BINANCE:WBTCBTC",
                                                "WBTC/ETH": "BINANCE:WBTCETH",
                                                "WBTC/USDT": "COINBASE:WBTCUSD",
                                                "WBTC/BUSD": "COINBASE:WBTCUSD",
                                                "WBTC/USDC": "COINBASE:WBTCUSD",
                                                "WBTC/TUSD": "COINBASE:WBTCUSD",
                                                "WBTC/HUSD": "COINBASE:WBTCUSD",
                                                "WBTC/DAI": "COINBASE:WBTCUSD",
                                                "WBTC/PAX": "COINBASE:WBTCUSD",
                                                "XEC/BTC": "BITFINEX:XECBTC",
                                                "XEC/USDT": "BITFINEX:XECUSD",
                                                "XEC/BUSD": "BITFINEX:XECUSD",
                                                "XEC/USDC": "BITFINEX:XECUSD",
                                                "XEC/TUSD": "BITFINEX:XECUSD",
                                                "XEC/HUSD": "BITFINEX:XECUSD",
                                                "XEC/UST": "BITFINEX:XECUSD",
                                                "XEC/DAI": "BITFINEX:XECUSD",
                                                "XEC/PAX": "BITFINEX:XECUSD",
                                                "XEC/BCH": "COINEX:XECBCH",
                                                "XEP/USDT": "BITTREX:XEPUSDT",
                                                "XEP/BUSD": "BITTREX:XEPUSDT",
                                                "XEP/USDC": "BITTREX:XEPUSDT",
                                                "XEP/TUSD": "BITTREX:XEPUSDT",
                                                "XEP/HUSD": "BITTREX:XEPUSDT",
                                                "XEP/UST": "BITTREX:XEPUSDT",
                                                "XEP/DAI": "BITTREX:XEPUSDT",
                                                "XEP/PAX": "BITTREX:XEPUSDT",
                                                "XLM/BTC": "BINANCE:XLMBTC",
                                                "XLM/ETH": "BINANCE:XLMETH",
                                                "XLM/USDT": "COINBASE:XLMUSD",
                                                "XLM/BUSD": "COINBASE:XLMUSD",
                                                "XLM/USDC": "COINBASE:XLMUSD",
                                                "XLM/TUSD": "COINBASE:XLMUSD",
                                                "XLM/HUSD": "COINBASE:XLMUSD",
                                                "XLM/UST": "COINBASE:XLMUSD",
                                                "XLM/DAI": "COINBASE:XLMUSD",
                                                "XLM/PAX": "COINBASE:XLMUSD",
                                                "XLM/BNB": "BINANCE:XLMBNB",
                                                "XLM/EURS": "KRAKEN:XLMEUR",
                                                "XLM/JEUR": "KRAKEN:XLMEUR",
                                                "XLM/TRYB": "BINANCE:XLMTRY",
                                                "XLM/JPYC": "BITFLYER:XLMJPY",
                                                "XLM/CADC": "EIGHTCAP:XLMCAD",
                                                "XLM/BCH": "HITBTC:XLMBCH",
                                                "XLM/KCS": "KUCOIN:XLMKCS",
                                                "XMY/USDT": "BITTREX:XMYUSDT",
                                                "XMY/BUSD": "BITTREX:XMYUSDT",
                                                "XMY/USDC": "BITTREX:XMYUSDT",
                                                "XMY/TUSD": "BITTREX:XMYUSDT",
                                                "XMY/HUSD": "BITTREX:XMYUSDT",
                                                "XMY/UST": "BITTREX:XMYUSDT",
                                                "XMY/DAI": "BITTREX:XMYUSDT",
                                                "XMY/PAX": "BITTREX:XMYUSDT",
                                                "XRP/BTC": "BINANCE:XRPBTC",
                                                "XRP/ETH": "BINANCE:XRPETH",
                                                "XRP/USDT": "BITSTAMP:XRPUSD",
                                                "XRP/BUSD": "BITSTAMP:XRPUSD",
                                                "XRP/USDC": "BITSTAMP:XRPUSD",
                                                "XRP/TUSD": "BITSTAMP:XRPUSD",
                                                "XRP/HUSD": "BITSTAMP:XRPUSD",
                                                "XRP/UST": "BITSTAMP:XRPUSD",
                                                "XRP/DAI": "BITSTAMP:XRPUSD",
                                                "XRP/PAX": "BITSTAMP:XRPUSD",
                                                "XRP/BNB": "BINANCE:XRPBNB",
                                                "XRP/EURS": "KRAKEN:XRPEUR",
                                                "XRP/JEUR": "KRAKEN:XRPEUR",
                                                "XRP/JGBP": "BINANCE:XRPGBP",
                                                "XRP/JCHF": "BITPANDAPRO:XRPCHF",
                                                "XRP/TRYB": "BINANCE:XRPTRY",
                                                "XRP/BIDR": "BITFINEX:XRPIDR",
                                                "XRP/BRZ": "MERCADO:XRPBRL",
                                                "XRP/JPYC": "KRAKEN:XRPJPY",
                                                "XRP/CADC": "KRAKEN:XRPCAD",
                                                "XRP/BCH": "COINEX:XRPBCH",
                                                "XRP/HT": "HUOBI:XRPHT",
                                                "XRP/TRX": "POLONIEX:XRPTRX",
                                                "XRP/KCS": "KUCOIN:XRPKCS",
                                                "XSGD/USDT": "FX_IDC:SGDUSD",
                                                "XSGD/BUSD": "FX_IDC:SGDUSD",
                                                "XSGD/USDC": "FX_IDC:SGDUSD",
                                                "XSGD/TUSD": "FX_IDC:SGDUSD",
                                                "XSGD/HUSD": "FX_IDC:SGDUSD",
                                                "XSGD/UST": "FX_IDC:SGDUSD",
                                                "XSGD/DAI": "FX_IDC:SGDUSD",
                                                "XSGD/PAX": "FX_IDC:SGDUSD",
                                                "XSGD/EURS": "FX_IDC:SGDEUR",
                                                "XSGD/JEUR": "FX_IDC:SGDEUR",
                                                "XSGD/BIDR": "FX_IDC:SGDIDR",
                                                "XSGD/QC": "FX_IDC:SGDCNY",
                                                "XSGD/BRZ": "FX_IDC:SGDBRL",
                                                "XSGD/TRYB": "FX_IDC:SGDTRY",
                                                "XSGD/JPYC": "FX_IDC:SGDJPY",
                                                "XTZ/BTC": "BINANCE:XTZBTC",
                                                "XTZ/ETH": "KRAKEN:XTZETH",
                                                "XTZ/USDT": "COINBASE:XTZUSD",
                                                "XTZ/BUSD": "COINBASE:XTZUSD",
                                                "XTZ/USDC": "COINBASE:XTZUSD",
                                                "XTZ/TUSD": "COINBASE:XTZUSD",
                                                "XTZ/HUSD": "COINBASE:XTZUSD",
                                                "XTZ/UST": "COINBASE:XTZUSD",
                                                "XTZ/DAI": "COINBASE:XTZUSD",
                                                "XTZ/PAX": "COINBASE:XTZUSD",
                                                "XTZ/BNB": "BINANCE:XTZBNB",
                                                "XTZ/EURS": "KRAKEN:XTZEUR",
                                                "XTZ/JEUR": "KRAKEN:XTZEUR",
                                                "XTZ/TRYB": "BINANCE:XTZTRY",
                                                "XTZ/TRX": "POLONIEX:XTZTRX",
                                                "XTZ/KCS": "KUCOIN:XTZKCS",
                                                "XVS/BTC": "BINANCE:XVSBTC",
                                                "XVS/USDT": "BINANCE:XVSUSD",
                                                "XVS/BUSD": "BINANCE:XVSUSD",
                                                "XVS/USDC": "BINANCE:XVSUSD",
                                                "XVS/TUSD": "BINANCE:XVSUSD",
                                                "XVS/HUSD": "BINANCE:XVSUSD",
                                                "XVS/UST": "BINANCE:XVSUSD",
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
                                                "YFI/UST": "BINANCE:YFIUSD",
                                                "YFI/DAI": "BINANCE:YFIUSD",
                                                "YFI/PAX": "BINANCE:YFIUSD",
                                                "YFI/EURS": "KRAKEN:YFIEUR",
                                                "YFI/JEUR": "KRAKEN:YFIEUR",
                                                "YFII/BTC": "BINANCE:YFIIBTC",
                                                "YFII/ETH": "HUOBI:YFIIETH",
                                                "YFII/BNB": "BINANCE:YFIIBNB",
                                                "YFII/USDT": "BINANCE:YFIIUSD",
                                                "YFII/BUSD": "BINANCE:YFIIUSD",
                                                "YFII/USDC": "BINANCE:YFIIUSD",
                                                "YFII/TUSD": "BINANCE:YFIIUSD",
                                                "YFII/HUSD": "BINANCE:YFIIUSD",
                                                "YFII/UST": "BINANCE:YFIIUSD",
                                                "YFII/DAI": "BINANCE:YFIIUSD",
                                                "YFII/PAX": "BINANCE:YFIIUSD",
                                                "ZEC/BTC": "BINANCE:ZECBTC",
                                                "ZEC/ETH": "BINANCE:ZECETH",
                                                "ZEC/USDT": "KRAKEN:ZECUSD",
                                                "ZEC/BUSD": "KRAKEN:ZECUSD",
                                                "ZEC/USDC": "KRAKEN:ZECUSD",
                                                "ZEC/TUSD": "KRAKEN:ZECUSD",
                                                "ZEC/HUSD": "KRAKEN:ZECUSD",
                                                "ZEC/UST": "KRAKEN:ZECUSD",
                                                "ZEC/DAI": "KRAKEN:ZECUSD",
                                                "ZEC/PAX": "KRAKEN:ZECUSD",
                                                "ZEC/BNB": "BINANCE:ZECBNB",
                                                "ZEC/EURS": "KRAKEN:ZECEUR",
                                                "ZEC/JEUR": "KRAKEN:ZECEUR",
                                                "ZEC/BCH": "GEMINI:ZECBCH",
                                                "ZEC/LTC": "GEMINI:ZECLTC",
                                                "ZEC/KCS": "KUCOIN:ZECKCS",
                                                "ZIL/BTC": "BINANCE:ZILBTC",
                                                "ZIL/ETH": "BINANCE:ZILETH",
                                                "ZIL/USDT": "BINANCE:ZILUSD",
                                                "ZIL/BUSD": "BINANCE:ZILUSD",
                                                "ZIL/USDC": "BINANCE:ZILUSD",
                                                "ZIL/TUSD": "BINANCE:ZILUSD",
                                                "ZIL/HUSD": "BINANCE:ZILUSD",
                                                "ZIL/UST": "BINANCE:ZILUSD",
                                                "ZIL/DAI": "BINANCE:ZILUSD",
                                                "ZIL/PAX": "BINANCE:ZILUSD",
                                                "ZIL/BIDR": "BINANCE:ZILBIDR",
                                                "ZIL/TRYB": "BINANCE:ZILTRY",
                                                "ZIL/BNB": "BINANCE:ZILBNB",
                                                "ZRX/BTC": "BINANCE:ZRXBTC",
                                                "ZRX/ETH": "BINANCE:ZRXETH",
                                                "ZRX/USDT": "BINANCE:ZRXUSD",
                                                "ZRX/BUSD": "BINANCE:ZRXUSD",
                                                "ZRX/USDC": "BINANCE:ZRXUSD",
                                                "ZRX/TUSD": "BINANCE:ZRXUSD",
                                                "ZRX/HUSD": "BINANCE:ZRXUSD",
                                                "ZRX/UST": "BINANCE:ZRXUSD",
                                                "ZRX/DAI": "BINANCE:ZRXUSD",
                                                "ZRX/PAX": "BINANCE:ZRXUSD",
                                                "ZRX/EURS": "COINBASE:ZRXEUR",
                                                "ZRX/JEUR": "COINBASE:ZRXEUR"
                                            })
}
