import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:http/http.dart' as http;
import 'package:web_dex/shared/utils/utils.dart';

abstract class ICustomTokenImportRepository {
  Future<Coin> fetchCustomToken(CoinType network, String address);

  Future<void> importCustomToken(Coin coin);
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  @override
  Future<Coin> fetchCustomToken(CoinType network, String address) async {
    final platformCoin = await _activatePlatformCoin(network);
    address =
        await coinsRepo.convertLegacyAddress(platformCoin, address) ?? address;

    final response = await coinsRepo.getTokenInfo(network, address);
    final tokenInfo = response?['result'];

    if (tokenInfo == null) {
      throw 'Failed to get token info';
    }

    return await _getCoin(tokenInfo, network, address, platformCoin);
  }

  Future<Coin> _getCoin(
      tokenInfo, CoinType network, String address, Coin platformCoin) async {
    String tokenAbbr =
        tokenInfo['config_ticker'] ?? tokenInfo['info']['symbol'];
    int decimals = tokenInfo['info']['decimals'];
    final tokenApi = await fetchTokenInfoFromApi(network, address);

    final price = tokenApi?['market_data']?['current_price']?['usd'];
    Coin newCoin = Coin(
      abbr: tokenAbbr,
      type: network,
      decimals: decimals,
      name: tokenApi?['name'] ?? tokenAbbr,
      parentCoin: platformCoin,
      protocolType: 'ERC20',
      protocolData: ProtocolData(
        platform: platformCoin.abbr,
        contractAddress: address,
      ),
      coingeckoId: tokenApi?['id'],
      usdPrice: price == null
          ? null
          : CexPrice(
              ticker: tokenAbbr,
              price: price,
            ),
      explorerUrl: platformCoin.explorerUrl,
      explorerTxUrl: platformCoin.explorerTxUrl,
      explorerAddressUrl: platformCoin.explorerAddressUrl,
      swapContractAddress: platformCoin.swapContractAddress,
      fallbackSwapContract: platformCoin.fallbackSwapContract,
      state: CoinState.inactive,
      mode: CoinMode.standard,
      isTestCoin: false,
      walletOnly: false,
      electrum: [],
      nodes: [],
      rpcUrls: [],
      bchdUrls: [],
      priority: 0,
    );

    CoinIcon.registerCustomIcon(
        newCoin.abbr,
        NetworkImage(
          tokenApi?['image']?['large'] ??
              'assets/coin_icons/png/${tokenAbbr.toLowerCase()}.png',
        ));

    newCoin.balance = await _getBalance(newCoin);
    return newCoin;
  }

  Future<double> _getBalance(Coin coin) async {
    await coinsRepo.activateCoins([coin]);
    final balanceInfo = await coinsRepo.getBalanceInfo(coin.abbr);
    await coinsRepo.deactivateCoin(coin);

    return double.tryParse(balanceInfo?.balance.decimal ?? '0') ?? 0;
  }

  Future<Coin> _activatePlatformCoin(CoinType network) async {
    final platformCoinAbbr = getEvmPlatformCoin(network);
    if (platformCoinAbbr == null) throw "Unsupported network";

    final platformCoin = coinsBloc.getCoin(platformCoinAbbr);
    if (platformCoin == null) throw "$platformCoinAbbr platform coin not found";

    await coinsBloc.activateCoins([platformCoin]);
    return platformCoin;
  }

  @override
  Future<void> importCustomToken(Coin coin) async {
    await coinsBloc.activateCoins([coin]);
  }

  Future<Map<String, dynamic>?> fetchTokenInfoFromApi(
      CoinType coinType, String contractAddress) async {
    final platform = getNetworkApiName(coinType);
    if (platform == null) {
      log('Unsupported Image URL Network: $coinType');
      return null;
    }

    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/$platform/contract/$contractAddress');

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      log('Error fetching token image URL: $e');
      return null;
    }
  }

  String? getNetworkApiName(CoinType coinType) {
    switch (coinType) {
      case CoinType.erc20:
        return 'ethereum';
      case CoinType.bep20:
        return 'binance-smart-chain';
      case CoinType.qrc20:
        return 'qtum';
      case CoinType.ftm20:
        return 'fantom';
      case CoinType.arb20:
        return 'arbitrum-one';
      case CoinType.avx20:
        return 'avalanche';
      case CoinType.mvr20:
        return 'moonriver';
      case CoinType.hco20:
        return 'huobi-token';
      case CoinType.plg20:
        return 'polygon-pos';
      case CoinType.hrc20:
        return 'harmony-shard-0';
      case CoinType.krc20:
        return 'kcc';
      default:
        return null;
    }
  }
}
