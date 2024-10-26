import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';

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
      throw LocaleKeys.tokenNotFound.tr();
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
