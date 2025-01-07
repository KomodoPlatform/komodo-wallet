import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

class WalletsRepository {
  WalletsRepository(this._kdfSdk, this._mm2Api, this._legacyWalletStorage);

  final KomodoDefiSdk _kdfSdk;
  final Mm2Api _mm2Api;
  final BaseStorage _legacyWalletStorage;

  List<Wallet>? _cachedWallets;
  List<Wallet>? get wallets => _cachedWallets;

  Future<List<Wallet>> getWallets() async {
    final legacyWallets = await _getLegacyWallets();
    _cachedWallets = (await _kdfSdk.wallets)
        .where(
          (wallet) => wallet.config.type != WalletType.trezor,
        )
        .toList();
    return [..._cachedWallets!, ...legacyWallets];
  }

  Future<List<Wallet>> _getLegacyWallets() async {
    var newVariable =
        await _legacyWalletStorage.read(allWalletsStorageKey) as List?;
    final List<Map<String, dynamic>> json =
        newVariable?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    return json
        .map((Map<String, dynamic> w) =>
            Wallet.fromJson(w)..config.isLegacyWallet = true)
        .toList();
  }

  Future<bool> deleteWallet(Wallet wallet) async {
    log(
      'Deleting a wallet ${wallet.id}',
      path: 'wallet_bloc => deleteWallet',
    ).ignore();

    if (wallet.isLegacyWallet) {
      final wallets = await _getLegacyWallets();
      wallets.removeWhere((w) => w.id == wallet.id);
      await _legacyWalletStorage.write(allWalletsStorageKey, wallets);
      return true;
    }

    // TODO!: implement
    throw UnimplementedError('Not yet supported');
  }

  String? validateWalletName(String name) {
    // This shouldn't happen, but just in case.
    if (_cachedWallets == null) {
      getWallets().ignore();
      return null;
    }

    if (_cachedWallets!.firstWhereOrNull((w) => w.name == name) != null) {
      return LocaleKeys.walletCreationExistNameError.tr();
    } else if (name.isEmpty || name.length > 40) {
      return LocaleKeys.walletCreationNameLengthError.tr();
    }

    return null;
  }

  Future<void> resetSpecificWallet(Wallet wallet) async {
    final coinsToDeactivate = wallet.config.activatedCoins
        .where((coin) => !enabledByDefaultCoins.contains(coin));
    for (final coin in coinsToDeactivate) {
      await _mm2Api.disableCoin(coin);
    }
  }
}
