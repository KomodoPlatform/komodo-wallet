import 'dart:math';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/coin_type.dart';

abstract class ICustomTokenImportRepository {
  Future<Map<String, dynamic>> fetchCustomToken(
      CoinType network, String address);

  Future<void> importCustomToken(CoinType network, String address);
}

class CustomTokenImportMockRepository implements ICustomTokenImportRepository {
  @override
  Future<Map<String, dynamic>> fetchCustomToken(
      CoinType network, String address) async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    if (random.nextInt(3) == 0) {
      throw 'Not found';
    }

    return {
      "abbr": "BTC",
      "image_url": 'assets/coin_icons/png/btc.png',
      "balance": '50',
      "usd_balance": '200',
    };
  }

  @override
  Future<void> importCustomToken(CoinType network, String address) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  @override
  Future<Map<String, dynamic>> fetchCustomToken(
      CoinType network, String address) async {
    final response = await coinsRepo.getTokenInfo(network, address);
    final tokenInfo = response?['result'];

    if (tokenInfo == null) {
      throw 'Failed to get token info';
    }

    String abbr = tokenInfo['config_ticker'] ?? tokenInfo['info']['symbol'];

    return {
      "abbr": abbr,
      "decimals": tokenInfo['info']['decimals'],
      // TODO: Acquire image url from a web API
      "image_url": 'assets/coin_icons/png/${abbr.toLowerCase()}.png',

      // TODO: Get balance by temporarily activating the coin
      "balance": '50',
      "usd_balance": '200',
    };
  }

  @override
  Future<void> importCustomToken(CoinType network, String address) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
