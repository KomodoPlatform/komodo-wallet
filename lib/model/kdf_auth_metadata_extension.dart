import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show Asset;
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';

extension KdfAuthMetadataExtension on KomodoDefiSdk {
  /// Checks if a wallet with the specified ID exists in the system.
  ///
  /// Returns `true` if a user with the given [walletId] is found among
  /// all registered users, `false` otherwise.
  Future<bool> walletExists(String walletId) async {
    final users = await auth.getUsers();
    return users.any((user) => user.walletId.name == walletId);
  }

  /// Returns the wallet associated with the currently authenticated user.
  ///
  /// Returns `null` if no user is currently signed in.
  Future<Wallet?> currentWallet() async {
    final user = await auth.currentUser;
    return user?.wallet;
  }

  /// Returns the stored list of wallet coin/asset IDs.
  ///
  /// If no user is signed in, returns an empty list.
  Future<List<String>> getWalletCoinIds() async {
    final user = await auth.currentUser;
    return user?.metadata.valueOrNull<List<String>>('activated_coins') ?? [];
  }

  /// Returns the stored list of wallet coins converted from asset configuration IDs.
  ///
  /// This method retrieves the coin IDs from user metadata and converts them
  /// to [Coin] objects. Uses `single` to maintain existing behavior which will
  /// throw an exception if multiple assets share the same ticker.
  ///
  /// If no user is signed in, returns an empty list.
  ///
  /// Throws [StateError] if multiple assets are found with the same configuration ID.
  Future<List<Coin>> getWalletCoins() async {
    final assets = await getWalletAssets();
    return assets
        // use single to stick to the existing behaviour around assetByTicker
        // which will cause the application to crash if there are
        // multiple assets with the same ticker
        .map((asset) => asset.toCoin())
        .toList();
  }

  Future<List<Asset>> getWalletAssets() async {
    final coinIds = await getWalletCoinIds();
    return coinIds
        // use single to stick to the existing behaviour around assetByTicker
        // which will cause the application to crash if there are
        // multiple assets with the same ticker
        .map((coinId) => assets.findAssetsByConfigId(coinId).single)
        .toList();
  }

  /// Adds new coin/asset IDs to the current user's activated coins list.
  ///
  /// This method merges the provided [coins] with the existing activated coins,
  /// ensuring no duplicates. The merged list is then stored in user metadata.
  ///
  /// If no user is currently signed in, the operation will complete but have no effect.
  ///
  /// [coins] - An iterable of coin/asset configuration IDs to add.
  Future<void> addActivatedCoins(Iterable<String> coins) async {
    final existingCoins =
        (await auth.currentUser)?.metadata.valueOrNull<List<String>>(
          'activated_coins',
        ) ??
        [];

    final mergedCoins = <dynamic>{...existingCoins, ...coins}.toList();
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', mergedCoins);
  }

  /// Removes specified coin/asset IDs from the current user's activated coins list.
  ///
  /// This method removes all occurrences of the provided [coins] from the user's
  /// activated coins list and updates the stored metadata.
  ///
  /// If no user is currently signed in, the operation will complete but have no effect.
  ///
  /// [coins] - A list of coin/asset configuration IDs to remove.
  Future<void> removeActivatedCoins(List<String> coins) async {
    final existingCoins =
        (await auth.currentUser)?.metadata.valueOrNull<List<String>>(
          'activated_coins',
        ) ??
        [];

    existingCoins.removeWhere((coin) => coins.contains(coin));
    await auth.setOrRemoveActiveUserKeyValue('activated_coins', existingCoins);
  }

  /// Sets the seed backup confirmation status for the current user.
  ///
  /// This method stores whether the user has confirmed backing up their seed phrase.
  /// This is typically used to track wallet security compliance.
  ///
  /// If no user is currently signed in, the operation will complete but have no effect.
  ///
  /// [hasBackup] - Whether the seed has been backed up. Defaults to `true`.
  Future<void> confirmSeedBackup({bool hasBackup = true}) async {
    await auth.setOrRemoveActiveUserKeyValue('has_backup', hasBackup);
  }

  /// Sets the wallet type for the current user.
  ///
  /// This method stores the wallet type in user metadata, which can be used
  /// to determine wallet-specific behavior and features.
  ///
  /// If no user is currently signed in, the operation will complete but have no effect.
  ///
  /// [type] - The wallet type to set for the current user.
  Future<void> setWalletType(WalletType type) async {
    await auth.setOrRemoveActiveUserKeyValue('type', type.name);
  }
}
