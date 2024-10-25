import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

abstract class ICustomTokenImportRepository {
  Future<Map<String, dynamic>> fetchCustomToken(
      String network, String address, int decimals);

  Future<void> importCustomToken(String network, String address, int decimals);
}

class CustomTokenImportMockRepository implements ICustomTokenImportRepository {
  @override
  Future<Map<String, dynamic>> fetchCustomToken(
      String network, String address, int decimals) async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    if (random.nextInt(3) == 0) {
      throw LocaleKeys.tokenNotFound.tr();
    }

    return {
      "abbr": network,
      "image_url": 'assets/coin_icons/png/btc.png',
      "balance": '50',
      "usd_balance": '200',
    };
  }

  @override
  Future<void> importCustomToken(
      String network, String address, int decimals) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
