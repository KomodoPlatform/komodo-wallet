import 'package:web_dex/model/coin.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

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

List<Coin> sortByUsdBalance(List<Coin> coins, SortDirection sortDirection) {
  if (sortDirection == SortDirection.none) return coins;
  if (sortDirection == SortDirection.increase) {
    coins.sort((a, b) {
      final double firstUsdBalance = a.usdBalance ?? 0;
      final double secondUsdBalance = b.usdBalance ?? 0;
      return firstUsdBalance == secondUsdBalance
          ? -1
          : firstUsdBalance - secondUsdBalance > 0
              ? 1
              : -1;
    });
    return coins;
  } else {
    coins.sort((a, b) {
      final double firstUsdBalance = a.usdBalance ?? 0;
      final double secondUsdBalance = b.usdBalance ?? 0;
      return firstUsdBalance == secondUsdBalance
          ? -1
          : secondUsdBalance - firstUsdBalance > 0
              ? 1
              : -1;
    });
    return coins;
  }
}
