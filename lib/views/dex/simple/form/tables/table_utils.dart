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
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';

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
  coins = removeDisallowedCoins(context, coins);
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

  removeDisallowedCoinOrders(sorted, context);
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

/// Filters out coins that are geo-blocked based on the current trading status.
///
/// TECH DEBT / BLoC ANTI-PATTERN WARNING:
/// This function uses [context.read] to access [TradingStatusBloc] state.
/// According to BLoC best practices, [context.read] should NOT be used to
/// retrieve state within build methods because it doesn't establish a subscription
/// to state changes.
///
/// IMPACT: When this function is called from a build method, the widget won't
/// automatically rebuild when [TradingStatusBloc] state changes (e.g., when
/// geo-blocking status updates).
///
/// FIX APPLIED: All widgets calling this function now wrap their build methods
/// with [BlocBuilder<TradingStatusBloc>] to ensure rebuilds when trading status changes.
///
/// RECOMMENDED REFACTOR:
/// Following SOLID principles (Single Responsibility), filtering logic should be
/// moved into the respective Blocs rather than utility functions that access
/// other Blocs' state. This would:
/// 1. Remove presentation layer's direct dependency on [TradingStatusBloc]
/// 2. Enable proper bloc-to-bloc communication through events
/// 3. Make state changes more predictable and testable
/// 4. Follow the unidirectional data flow pattern
List<Coin> removeDisallowedCoins(BuildContext context, List<Coin> coins) {
  final tradingState = context.read<TradingStatusBloc>().state;
  if (!tradingState.isEnabled) return <Coin>[];
  return coins.where((coin) => tradingState.canTradeAssets([coin.id])).toList();
}

/// Filters out orders for coins that are geo-blocked based on the current trading status.
/// Modifies the [orders] list in-place.
///
/// TECH DEBT / BLoC ANTI-PATTERN WARNING:
/// This function uses [context.read] to access [TradingStatusBloc] state.
/// According to BLoC best practices, [context.read] should NOT be used to
/// retrieve state within build methods because it doesn't establish a subscription
/// to state changes.
///
/// IMPACT: When this function is called from a build method, the widget won't
/// automatically rebuild when [TradingStatusBloc] state changes (e.g., when
/// geo-blocking status updates).
///
/// FIX APPLIED: All widgets calling this function now wrap their build methods
/// with [BlocBuilder<TradingStatusBloc>] to ensure rebuilds when trading status changes.
///
/// RECOMMENDED REFACTOR:
/// Following SOLID principles (Single Responsibility), filtering logic should be
/// moved into the respective Blocs rather than utility functions that access
/// other Blocs' state. This would:
/// 1. Remove presentation layer's direct dependency on [TradingStatusBloc]
/// 2. Enable proper bloc-to-bloc communication through events
/// 3. Make state changes more predictable and testable
/// 4. Follow the unidirectional data flow pattern
///
/// ADDITIONAL TECH DEBT:
/// This function mutates the input list in-place, which is a side effect that
/// can make code harder to reason about and test. Consider returning a new
/// filtered list instead (similar to [removeDisallowedCoins]).
void removeDisallowedCoinOrders(List<BestOrder> orders, BuildContext context) {
  final tradingState = context.read<TradingStatusBloc>().state;
  if (!tradingState.isEnabled) {
    orders.clear();
    return;
  }
  final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
  orders.removeWhere((order) {
    final Coin? coin = coinsRepository.getCoin(order.coin);
    if (coin == null) return true;
    return !tradingState.canTradeAssets([coin.id]);
  });
}

List<BestOrder> _sortBestOrders(
  BuildContext context,
  Map<String, List<BestOrder>> unsorted,
) {
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
