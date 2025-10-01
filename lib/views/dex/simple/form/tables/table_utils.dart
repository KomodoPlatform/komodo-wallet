import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show AssetId;
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';

List<Coin> prepareCoinsForTable(
  BuildContext context,
  List<Coin> coins,
  String? searchString, {
  bool testCoinsEnabled = true,
}) {
  final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);

  coins = List.of(coins);
  if (!testCoinsEnabled) {
    coins = removeTestCoins(coins);
  }
  coins = removeWalletOnly(coins);
  coins = removeDisallowedCoins(context, coins);
  coins = sortByPriorityAndBalance(coins, sdk);
  coins = filterCoinsByPhrase(coins, searchString ?? '').toList();
  return coins;
}

List<BestOrder> prepareOrdersForTable(
  BuildContext context,
  Map<String, List<BestOrder>>? orders,
  String? searchString,
  AuthorizeMode _mode, {
  bool testCoinsEnabled = true,
  Coin? Function(String)? coinLookup,
}) {
  if (orders == null) return [];
  final caches = buildOrderCoinCaches(context, orders, coinLookup: coinLookup);

  final ordersByAssetId = caches.ordersByAssetId;
  final coinsByAssetId = caches.coinsByAssetId;
  final assetIdByAbbr = caches.assetIdByAbbr;

  final List<BestOrder> sorted = _sortBestOrders(
    ordersByAssetId,
    coinsByAssetId,
  );
  if (sorted.isEmpty) {
    return [];
  }

  if (!testCoinsEnabled) {
    removeTestCoinOrders(
      sorted,
      ordersByAssetId,
      coinsByAssetId,
      assetIdByAbbr,
    );
    if (sorted.isEmpty) {
      return [];
    }
  }

  removeWalletOnlyCoinOrders(
    sorted,
    ordersByAssetId,
    coinsByAssetId,
    assetIdByAbbr,
  );
  if (sorted.isEmpty) {
    return [];
  }

  removeDisallowedCoinOrders(sorted, context);
  if (sorted.isEmpty) return [];
  final String? filter = searchString?.toLowerCase();
  if (filter == null || filter.isEmpty) {
    return sorted;
  }

  final List<BestOrder> filtered = sorted.where((order) {
    final AssetId? assetId = assetIdByAbbr[order.coin];
    if (assetId == null) return false;
    final Coin? coin = coinsByAssetId[assetId];
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

({
  Map<AssetId, BestOrder> ordersByAssetId,
  Map<AssetId, Coin> coinsByAssetId,
  Map<String, AssetId> assetIdByAbbr,
})
buildOrderCoinCaches(
  BuildContext context,
  Map<String, List<BestOrder>> orders, {
  Coin? Function(String)? coinLookup,
}) {
  final Coin? Function(String) resolveCoin =
      coinLookup ?? RepositoryProvider.of<CoinsRepo>(context).getCoin;

  final ordersByAssetId = <AssetId, BestOrder>{};
  final coinsByAssetId = <AssetId, Coin>{};
  final assetIdByAbbr = <String, AssetId>{};

  orders.forEach((_, list) {
    if (list.isEmpty) return;
    final BestOrder order = list[0];
    final Coin? coin = resolveCoin(order.coin);
    if (coin == null) return;

    final AssetId assetId = coin.assetId;
    ordersByAssetId[assetId] = order;
    coinsByAssetId[assetId] = coin;
    assetIdByAbbr[coin.abbr] = assetId;
  });

  return (
    ordersByAssetId: ordersByAssetId,
    coinsByAssetId: coinsByAssetId,
    assetIdByAbbr: assetIdByAbbr,
  );
}

List<BestOrder> _sortBestOrders(
  Map<AssetId, BestOrder> ordersByAssetId,
  Map<AssetId, Coin> coinsByAssetId,
) {
  if (ordersByAssetId.isEmpty) return [];
  final entries =
      <({AssetId assetId, BestOrder order, Coin coin, double fiatPrice})>[];

  ordersByAssetId.forEach((assetId, order) {
    final Coin? coin = coinsByAssetId[assetId];
    if (coin == null) return;

    final Decimal? usdPrice = coin.usdPrice?.price;
    final double fiatPrice =
        order.price.toDouble() * (usdPrice?.toDouble() ?? 0.0);
    entries.add((
      assetId: assetId,
      order: order,
      coin: coin,
      fiatPrice: fiatPrice,
    ));
  });

  entries.sort((a, b) {
    final int fiatComparison = b.fiatPrice.compareTo(a.fiatPrice);
    if (fiatComparison != 0) return fiatComparison;
    return a.coin.abbr.compareTo(b.coin.abbr);
  });

  final result = entries.map((entry) => entry.order).toList();
  return result;
}

void removeWalletOnlyCoinOrders(
  List<BestOrder> orders,
  Map<AssetId, BestOrder> ordersByAssetId,
  Map<AssetId, Coin> coinsByAssetId,
  Map<String, AssetId> assetIdByAbbr,
) {
  orders.removeWhere((BestOrder order) {
    final AssetId? assetId = assetIdByAbbr[order.coin];
    if (assetId == null) return true;
    final Coin? coin = coinsByAssetId[assetId];
    if (coin == null) return true;

    final bool shouldRemove = coin.walletOnly;
    if (shouldRemove) {
      ordersByAssetId.remove(assetId);
      coinsByAssetId.remove(assetId);
      assetIdByAbbr.remove(order.coin);
    }
    return shouldRemove;
  });
}

void removeTestCoinOrders(
  List<BestOrder> orders,
  Map<AssetId, BestOrder> ordersByAssetId,
  Map<AssetId, Coin> coinsByAssetId,
  Map<String, AssetId> assetIdByAbbr,
) {
  orders.removeWhere((BestOrder order) {
    final AssetId? assetId = assetIdByAbbr[order.coin];
    if (assetId == null) return true;
    final Coin? coin = coinsByAssetId[assetId];
    if (coin == null) return true;

    final bool shouldRemove = coin.isTestCoin;
    if (shouldRemove) {
      ordersByAssetId.remove(assetId);
      coinsByAssetId.remove(assetId);
      assetIdByAbbr.remove(order.coin);
    }
    return shouldRemove;
  });
}
