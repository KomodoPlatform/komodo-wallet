import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';

extension KdfAuthMetadataExtension on KomodoDefiSdk {
  Future<bool> walletExists(String walletId) async {
    final users = await auth.getUsers();
    return users.any((user) => user.walletId.name == walletId);
  }

  Future<Wallet?> currentWallet() async {
    final user = await auth.currentUser;
    return user?.wallet;
  }

  Future<void> addActivatedCoins(Iterable<String> coins) async {
    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<String>>('activated_coins') ??
        [];

    final mergedCoins = <dynamic>{...existingCoins, ...coins}.toList();
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', mergedCoins);
  }

  Future<void> removeActivatedCoins(List<String> coins) async {
    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<String>>('activated_coins') ??
        [];

    existingCoins.removeWhere((coin) => coins.contains(coin));
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', existingCoins);
  }

  Future<void> confirmSeedBackup({bool hasBackup = true}) async {
    await auth.setOrRemoveActiveUserKeyValue('has_backup', true);
  }

  Future<void> setWalletType(WalletType type) async {
    await auth.setOrRemoveActiveUserKeyValue('type', type.name);
  }

  Future<List<Coin>> getCustomCoins() async {
    return (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<Coin>>('custom_coins') ??
        [];
  }

  Future<void> addCustomCoin(Coin coin) async {
    final asset = assets.assetsFromTicker(coin.abbr).single;
    final ActivationProgress progress =
        await customAssets.activateAsset(asset).last;
    if (progress.isError) {
      throw Exception(
        progress.errorMessage ?? 'Failed to activate asset ${coin.abbr}',
      );
    }

    final existingCoins = (await auth.currentUser)
            ?.metadata
            .valueOrNull<List<Coin>>('custom_coins') ??
        [];

    final mergedCoins = <dynamic>{...existingCoins, coin}.toList();
    await auth.setOrRemoveActiveUserKeyValue('custom_coins', mergedCoins);
  }
}
