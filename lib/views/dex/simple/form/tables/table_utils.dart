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
