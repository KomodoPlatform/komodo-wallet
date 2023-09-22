#pragma once

namespace atomic_dex
{
    inline const char*       g_dex_api{DEX_API};
    inline const std::string g_dex_rpc{DEX_RPC};
    inline const int64_t     g_dex_rpcport{std::stoi(DEX_RPCPORT)};
    inline const std::string g_primary_dex_coin{DEX_PRIMARY_COIN};
    inline const std::string g_second_primary_dex_coin{DEX_SECOND_PRIMARY_COIN};
    inline const std::vector<std::string> g_default_coins{
        g_primary_dex_coin,
        g_second_primary_dex_coin,
        "BTC",
        "BNB",
        "ETH",
        "DAI-BEP20",
        "FIRO-BEP20",
        "BUSD-BEP20",
        "USDC-BEP20",
        "USDT-BEP20"
    };
    inline const std::vector<std::string> g_wallet_only_coins{
        "ARRR-BEP20",
        "RBTC",
        "NVC",
        "PAXG-ERC20",
        "USDT-ERC20",
        "BET",
        "BOTS",
        "CRYPTO",
        "DEX",
        "HODL",
        "JUMBLR",
        "MGW",
        "MSHARK",
        "PANGEA",
        "REVS",
        "SUPERNET",
        "XPM",
        "VOTE2023",
        "ATOM"
    };
}
