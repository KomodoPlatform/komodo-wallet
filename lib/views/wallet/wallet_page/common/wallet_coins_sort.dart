import "package:komodo_defi_sdk/komodo_defi_sdk.dart";
import "package:komodo_ui_kit/komodo_ui_kit.dart";
import "package:web_dex/model/coin.dart";
import "package:web_dex/views/wallet/coins_manager/coins_manager_helpers.dart";

enum WalletCoinsSortType {
  name,
  price,
  value,
  change24h,
  none,
}

class WalletCoinsSortData implements SortData<WalletCoinsSortType> {
  const WalletCoinsSortData(
      {required this.sortDirection, required this.sortType});
  @override
  final WalletCoinsSortType sortType;
  @override
  final SortDirection sortDirection;
}

List<Coin> sortWalletCoins(
  List<Coin> coins,
  WalletCoinsSortData sortData,
  KomodoDefiSdk sdk,
) {
  switch (sortData.sortType) {
    case WalletCoinsSortType.name:
      return sortByName(coins, sortData.sortDirection);
    case WalletCoinsSortType.price:
      return sortByPrice(coins, sortData.sortDirection, sdk);
    case WalletCoinsSortType.value:
      return sortByUsdBalance(coins, sortData.sortDirection, sdk);
    case WalletCoinsSortType.change24h:
      return sortByChange24h(coins, sortData.sortDirection);
    case WalletCoinsSortType.none:
      return coins;
  }
}

List<Coin> sortByPrice(
  List<Coin> coins,
  SortDirection direction,
  KomodoDefiSdk sdk,
) {
  if (direction == SortDirection.none) return coins;
  coins.sort((a, b) {
    final double priceA = a.lastKnownUsdPrice(sdk) ?? a.usdPrice?.price ?? 0.0;
    final double priceB = b.lastKnownUsdPrice(sdk) ?? b.usdPrice?.price ?? 0.0;
    return direction == SortDirection.increase
        ? priceA.compareTo(priceB)
        : priceB.compareTo(priceA);
  });
  return coins;
}

List<Coin> sortByChange24h(List<Coin> coins, SortDirection direction) {
  if (direction == SortDirection.none) return coins;
  coins.sort((a, b) {
    final double changeA = a.usdPrice?.change24h ?? 0.0;
    final double changeB = b.usdPrice?.change24h ?? 0.0;
    return direction == SortDirection.increase
        ? changeA.compareTo(changeB)
        : changeB.compareTo(changeA);
  });
  return coins;
}
