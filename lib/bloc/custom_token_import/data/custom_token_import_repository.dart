import 'dart:math';
import 'package:web_dex/model/coin_type.dart';

abstract class ICustomTokenImportRepository {
  Future<Map<String, dynamic>> fetchCustomToken(
      CoinType network, String address, int decimals);

  Future<void> importCustomToken(
      CoinType network, String address, int decimals);
}

class CustomTokenImportMockRepository implements ICustomTokenImportRepository {
  @override
  Future<Map<String, dynamic>> fetchCustomToken(
      CoinType network, String address, int decimals) async {
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
  Future<void> importCustomToken(
      CoinType network, String address, int decimals) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
