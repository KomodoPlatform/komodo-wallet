pragma Singleton
import QtQuick 2.10

QtObject {
    readonly property int width: 1280
    readonly property int height: 800
    readonly property int minimumWidth: 1280
    readonly property int minimumHeight: 800
    readonly property string assets_path: Qt.resolvedUrl(".") + "../../assets/"
    readonly property string image_path: assets_path + "images/"
    readonly property string coin_icons_path: image_path + "coins/"
    function coinIcon(ticker) {
        return ticker === "" ? "" : coin_icons_path + ticker.toLowerCase() + ".png"
    }

    readonly property int idx_dashboard_portfolio: 0
    readonly property int idx_dashboard_wallet: 1
    readonly property int idx_dashboard_exchange: 2
    readonly property int idx_dashboard_news: 3
    readonly property int idx_dashboard_dapps: 4
    readonly property int idx_dashboard_settings: 5

    readonly property int idx_exchange_trade: 0
    readonly property int idx_exchange_orders: 1
    readonly property int idx_exchange_history: 2

    function diffPrefix(received) {
        return received === "" ? "" : received === true ? "+ " :  "- "
    }

    function filterCoins(list, text, type) {
        return list.filter(c => (c.ticker.indexOf(text.toUpperCase()) !== -1 || c.name.toUpperCase().indexOf(text.toUpperCase()) !== -1) &&
                           (type === undefined || c.type === type))
    }

    function formatFiat(received, amount, fiat) {
        const symbols = {
            "USD": "$",
            "EUR": "€"
        }

        return diffPrefix(received) + symbols[fiat] + " " + amount
    }

    function formatCrypto(received, amount, ticker, fiat_amount, fiat) {
        return diffPrefix(received) + amount + " " + ticker + (fiat_amount ? " (" + formatFiat("", fiat_amount, fiat) + ")" : "")
    }

    function fullCoinName(name, ticker) {
        return name + " (" + ticker + ")"
    }

    function fullNamesOfCoins(coins) {
        return coins.map(c => fullCoinName(c.name, c.ticker))
    }

    function getTickers(coins) {
        return coins.map(c => c.ticker)
    }


    function tickerAndBalance(ticker) {
        return ticker + " (" + API.get().get_balance(ticker) + ")"
    }

    function getTickersAndBalances(coins) {
        return coins.map(c => c.ticker + " (" + c.balance + ")")
    }

    function hasEnoughFunds(sell, base, rel, price, volume) {
        if(sell) {
            if(volume === "") return true
            return API.get().do_i_have_enough_funds(base, volume)
        }
        else {
            if(price === "") return true
            const needed_amount = parseFloat(price) * parseFloat(volume)
            return API.get().do_i_have_enough_funds(rel, needed_amount)
        }
    }

    function isZero(v) {
        return parseFloat(v) === 0
    }

    function fieldExists(v) {
        return v !== undefined && v !== ""
    }

    function filterRecentSwaps(all_orders, finished_option, ticker) {
        let orders = all_orders

        Object.keys(orders).map((key, index) => {
          orders[key].uuid = key
          orders[key].is_recent_swap = true
        })

        let arr = Object.values(orders).sort((a, b) => b.events[b.events.length-1].timestamp - a.events[a.events.length-1].timestamp)

        // Filter by finished
        if(finished_option !== undefined && finished_option !== "")
            arr = arr.filter(o => {
                for(let e of o.events) {
                    if(e.state === "Finished")
                        return finished_option === "include"
                }

                return finished_option === "exclude"
            })

        // Filter by ticker
        if(ticker)
            arr = arr.filter(o => o.my_info.my_coin === ticker || o.my_info.other_coin === ticker)

        return arr
    }

    function formatOrder(o) {
        if(o.is_recent_swap) {
            o.date = o.events[o.events.length-1].human_timestamp
        }
        else {
            o.my_info = {
                my_coin: o.base,
                my_amount: o.base_amount,
                other_coin: o.rel,
                other_amount: o.rel_amount
            }
        }
        return o
    }

    function isEthNeeded() {
        for(const c of API.get().enabled_coins)
            if(c.type === "ERC-20" && c.ticker !== "ETH") return true

        return false
    }

    function canDisable(ticker) {
        if(API.get().enabled_coins.length <= 2) return false
        if(ticker === "ETH") return !General.isEthNeeded()

        return true
    }

    function isEthEnabled() {
        for(const c of API.get().enabled_coins)
            if(c.ticker === "ETH") return true

        return false
    }

    function enableEthIfNeeded() {
        if(!isEthEnabled() && isEthNeeded()) {
            API.get().enable_coins(["ETH"])
            return true
        }

        return false
    }
}
