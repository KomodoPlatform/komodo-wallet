import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/utils/balances_formatter.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

List<Coin> prepareCoinsForTable(
  List<Coin> coins,
  String? searchString, {
  bool testCoinsEnabled = true,
}) {
  coins = List.from(coins);
  if (!testCoinsEnabled) coins = removeTestCoins(coins);
  coins = removeWalletOnly(coins);
  coins = removeSuspended(coins);
  coins = sortFiatBalance(coins);
  coins = filterCoinsByPhrase(coins, searchString ?? '').toList();
  return coins;
}

List<BestOrder> prepareOrdersForTable(
  Map<String, List<BestOrder>>? orders,
  String? searchString,
  AuthorizeMode mode, {
  bool testCoinsEnabled = true,
}) {
  if (orders == null) return [];
  final List<BestOrder> sorted = _sortBestOrders(orders);
  if (sorted.isEmpty) return [];

  if (!testCoinsEnabled) {
    removeTestCoinOrders(sorted);
    if (sorted.isEmpty) return [];
  }

  removeSuspendedCoinOrders(sorted, mode);
  if (sorted.isEmpty) return [];

  removeWalletOnlyCoinOrders(sorted);
  if (sorted.isEmpty) return [];

  final String? filter = searchString?.toLowerCase();
  if (filter == null || filter.isEmpty) {
    return sorted;
  }
  final List<BestOrder> filtered = sorted.where((order) {
    final Coin? coin = coinsBloc.getCoin(order.coin);
    if (coin == null) return false;
    return compareCoinByPhrase(coin, filter);
  }).toList();

  return filtered;
}

List<BestOrder> _sortBestOrders(Map<String, List<BestOrder>> unsorted) {
  if (unsorted.isEmpty) return [];

  final List<BestOrder> sorted = [];
  unsorted.forEach((ticker, list) {
    if (coinsBloc.getCoin(list[0].coin) == null) return;
    sorted.add(list[0]);
  });

  sorted.sort((a, b) {
    final Coin? coinA = coinsBloc.getCoin(a.coin);
    final Coin? coinB = coinsBloc.getCoin(b.coin);
    if (coinA == null || coinB == null) return 0;

    final double fiatPriceA = getFiatAmount(coinA, a.price);
    final double fiatPriceB = getFiatAmount(coinB, b.price);

    if (fiatPriceA > fiatPriceB) return -1;
    if (fiatPriceA < fiatPriceB) return 1;

    return coinA.abbr.compareTo(coinB.abbr);
  });

  return sorted;
}
