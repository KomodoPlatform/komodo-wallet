import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

List<Coin> sortByName(List<Coin> coins, SortDirection sortDirection) {
  if (sortDirection == SortDirection.none) return coins;
  if (sortDirection == SortDirection.increase) {
    coins.sort((a, b) => a.name.compareTo(b.name));
    return coins;
  } else {
    coins.sort((a, b) => b.name.compareTo(a.name));
    return coins;
  }
}

List<Coin> sortByProtocol(List<Coin> coins, SortDirection sortDirection) {
  if (sortDirection == SortDirection.none) return coins;
  if (sortDirection == SortDirection.increase) {
    coins
        .sort((a, b) => a.typeNameWithTestnet.compareTo(b.typeNameWithTestnet));
    return coins;
  } else {
    coins
        .sort((a, b) => b.typeNameWithTestnet.compareTo(a.typeNameWithTestnet));
    return coins;
  }
}

List<Coin> sortByLastKnownUsdBalance(
    List<Coin> coins, SortDirection sortDirection, KomodoDefiSdk sdk) {
  if (sortDirection == SortDirection.none) return coins;
  if (sortDirection == SortDirection.increase) {
    coins.sort((a, b) {
      final aBalance = a.lastKnownUsdBalance(sdk) ?? 0.0;
      final bBalance = b.lastKnownUsdBalance(sdk) ?? 0.0;
      if (aBalance == bBalance) return 0;
      return aBalance.compareTo(bBalance);
    });
    return coins;
  } else {
    coins.sort((a, b) {
      final aBalance = a.lastKnownUsdBalance(sdk) ?? 0.0;
      final bBalance = b.lastKnownUsdBalance(sdk) ?? 0.0;
      if (aBalance == bBalance) return 0;
      return bBalance.compareTo(aBalance);
    });
    return coins;
  }
}

List<Coin> sortByUsdBalance(
    List<Coin> coins, SortDirection sortDirection, KomodoDefiSdk sdk) {
  if (sortDirection == SortDirection.none) return coins;

  final List<({Coin coin, double balance})> coinsWithBalances = List.generate(
    coins.length,
    (i) => (coin: coins[i], balance: coins[i].lastKnownUsdBalance(sdk) ?? 0.0),
  );

  if (sortDirection == SortDirection.increase) {
    coinsWithBalances.sort((a, b) => a.balance.compareTo(b.balance));
  } else {
    coinsWithBalances.sort((a, b) => b.balance.compareTo(a.balance));
  }

  return coinsWithBalances.map((e) => e.coin).toList();
}
