import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/utils/balances_formatter.dart';

List<Coin> prepareCoinsForTable(
  BuildContext context,
  List<Coin> coins,
  String? searchString, {
  bool testCoinsEnabled = true,
}) {
  final authBloc = RepositoryProvider.of<AuthBloc>(context);
  coins = List.from(coins);
  if (!testCoinsEnabled) coins = removeTestCoins(coins);
  coins = removeWalletOnly(coins);
  coins = removeSuspended(coins, authBloc.state.isSignedIn);
  coins = sortByPriorityAndBalance(coins, GetIt.I<KomodoDefiSdk>());
  coins = filterCoinsByPhrase(coins, searchString ?? '').toList();
  return coins;
}

List<BestOrder> prepareOrdersForTable(
  BuildContext context,
  Map<String, List<BestOrder>>? orders,
  String? searchString,
  AuthorizeMode mode, {
  bool testCoinsEnabled = true,
}) {
  if (orders == null) return [];
  final List<BestOrder> sorted = _sortBestOrders(context, orders);
  if (sorted.isEmpty) return [];

  if (!testCoinsEnabled) {
    removeTestCoinOrders(sorted, context);
    if (sorted.isEmpty) return [];
  }

  removeSuspendedCoinOrders(sorted, mode, context);
  if (sorted.isEmpty) return [];

  removeWalletOnlyCoinOrders(sorted, context);
  if (sorted.isEmpty) return [];

  final String? filter = searchString?.toLowerCase();
  if (filter == null || filter.isEmpty) {
    return sorted;
  }

  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  final List<BestOrder> filtered = sorted.where((order) {
    final Coin? coin = coinsRepository.getCoin(order.coin);
    if (coin == null) return false;
    return compareCoinByPhrase(coin, filter);
  }).toList();

  return filtered;
}

List<BestOrder> _sortBestOrders(
    BuildContext context, Map<String, List<BestOrder>> unsorted) {
  if (unsorted.isEmpty) return [];

  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  final List<BestOrder> sorted = [];
  unsorted.forEach((ticker, list) {
    if (coinsRepository.getCoin(list[0].coin) == null) return;
    sorted.add(list[0]);
  });

  sorted.sort((a, b) {
    final Coin? coinA = coinsRepository.getCoin(a.coin);
    final Coin? coinB = coinsRepository.getCoin(b.coin);
    if (coinA == null || coinB == null) return 0;

    final double fiatPriceA = getFiatAmount(coinA, a.price);
    final double fiatPriceB = getFiatAmount(coinB, b.price);

    if (fiatPriceA > fiatPriceB) return -1;
    if (fiatPriceA < fiatPriceB) return 1;

    return coinA.abbr.compareTo(coinB.abbr);
  });

  return sorted;
}

void removeSuspendedCoinOrders(
  List<BestOrder> orders,
  AuthorizeMode authorizeMode,
  BuildContext context,
) {
  if (authorizeMode == AuthorizeMode.noLogin) return;
  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  orders.removeWhere((BestOrder order) {
    final Coin? coin = coinsRepository.getCoin(order.coin);
    if (coin == null) return true;

    return coin.isSuspended;
  });
}

void removeWalletOnlyCoinOrders(List<BestOrder> orders, BuildContext context) {
  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  orders.removeWhere((BestOrder order) {
    final Coin? coin = coinsRepository.getCoin(order.coin);
    if (coin == null) return true;

    return coin.walletOnly;
  });
}

void removeTestCoinOrders(List<BestOrder> orders, BuildContext context) {
  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  orders.removeWhere((BestOrder order) {
    final Coin? coin = coinsRepository.getCoin(order.coin);
    if (coin == null) return true;

    return coin.isTestCoin;
  });
}
