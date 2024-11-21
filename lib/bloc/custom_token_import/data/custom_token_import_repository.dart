import 'dart:convert';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:http/http.dart' as http;
import 'package:web_dex/shared/utils/utils.dart';

abstract class ICustomTokenImportRepository {
  Future<Coin> fetchCustomToken(CoinType network, String address);

  Future<void> importCustomToken(CoinType network, String address);
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  @override
    await _activatePlatformCoin(network);
  Future<Coin> fetchCustomToken(CoinType network, String address) async {

    final response = await coinsRepo.getTokenInfo(network, address);
    final tokenInfo = response?['result'];

    if (tokenInfo == null) {
      throw 'Failed to get token info';
    }

    String abbr = tokenInfo['config_ticker'] ?? tokenInfo['info']['symbol'];
    final imageUrl = await fetchTokenImageUrl(network, address);

    return {
      "abbr": abbr,
      "decimals": tokenInfo['info']['decimals'],
      "image_url":
          imageUrl ?? 'assets/coin_icons/png/${abbr.toLowerCase()}.png',

      // TODO: Get balance by temporarily activating the coin
      "balance": '50',
      "usd_balance": '200',
    };
  }

  Future<void> _activatePlatformCoin(CoinType network) async {
    final platformCoinAbbr = getEvmPlatformCoin(network);
    if (platformCoinAbbr == null) throw "Unsupported network";

    final platformCoin = coinsBloc.getCoin(platformCoinAbbr);
    if (platformCoin == null) throw "$platformCoinAbbr platform coin not found";

    await coinsBloc.activateCoins([platformCoin]);
  }

  @override
  Future<void> importCustomToken(CoinType network, String address) async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<String?> fetchTokenImageUrl(
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
      return data['image']['large'];
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
