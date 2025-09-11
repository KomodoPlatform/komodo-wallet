import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook_depth/orderbook_depth_response.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/model/typedef.dart';
import 'package:web_dex/shared/utils/utils.dart';

class BridgeRepository {
  BridgeRepository(this._mm2Api, this._kdfSdk, this._coinsRepository);

  final Mm2Api _mm2Api;
  final KomodoDefiSdk _kdfSdk;
  final CoinsRepo _coinsRepository;

  Future<CoinsByTicker?> getSellCoins(CoinsByTicker? tickers) async {
    if (tickers == null) return null;

    final List<OrderBookDepth>? depths = await _getDepths(tickers);
    if (depths == null) return null;

    final CoinsByTicker sellCoins =
        tickers.entries.fold({}, (previousValue, entry) {
      final List<Coin> coins = previousValue[entry.key] ?? [];
      final List<OrderBookDepth> tickerDepths = depths
          .where(
            (depth) =>
                (abbr2Ticker(depth.source.abbr) == entry.key) &&
                (abbr2Ticker(depth.target.abbr) == entry.key),
          )
          .toList();

      if (tickerDepths.isEmpty) return previousValue;

      for (OrderBookDepth depth in tickerDepths) {
        if (depth.asks != 0) {
          if (!isCoinInList(depth.target, coins)) coins.add(depth.target);
        }
        if (depth.bids != 0) {
          if (!isCoinInList(depth.source, coins)) coins.add(depth.source);
        }
      }

      previousValue[entry.key] = coins;

      return previousValue;
    });

    return sellCoins;
  }

  Future<CoinsByTicker> getAvailableTickers() async {
    List<Coin> coins = _coinsRepository.getKnownCoins();
    coins = removeWalletOnly(coins);
    coins = removeSuspended(coins, await _kdfSdk.auth.isSignedIn());

    // Privacy coin gating is applied at the UI layer for tickers and orders

    final CoinsByTicker coinsByTicker = convertToCoinsByTicker(coins);
    final CoinsByTicker multiProtocolCoins =
        removeSingleProtocol(coinsByTicker);

    final List<OrderBookDepth>? orderBookDepths =
        await _getDepths(multiProtocolCoins);

    if (orderBookDepths == null || orderBookDepths.isEmpty) {
      return multiProtocolCoins;
    } else {
      return removeTokensWithEmptyOrderbook(
        multiProtocolCoins,
        orderBookDepths,
      );
    }
  }

  Future<List<OrderBookDepth>?> _getDepths(CoinsByTicker coinsByTicker) async {
    final List<List<String>> depthsPairs = _getDepthsPairs(coinsByTicker);

    List<OrderBookDepth>? orderBookDepths =
        await _getNotEmptyDepths(depthsPairs);
    if (orderBookDepths?.isEmpty ?? true) {
      orderBookDepths = await _frequentRequestDepth(depthsPairs);
    }

    return orderBookDepths;
  }

  Future<List<OrderBookDepth>?> _frequentRequestDepth(
    List<List<String>> depthsPairs,
  ) async {
    int attempts = 5;
    List<OrderBookDepth>? orderBookDepthsLocal;

    if (depthsPairs.isEmpty) {
      return null;
    }
    while (attempts > 0) {
      orderBookDepthsLocal = await _getNotEmptyDepths(depthsPairs);

      if (orderBookDepthsLocal?.isNotEmpty ?? false) {
        return orderBookDepthsLocal;
      }
      attempts -= 1;
      await Future.delayed(const Duration(milliseconds: 600));
    }
    return null;
  }

  Future<List<OrderBookDepth>?> _getNotEmptyDepths(
    List<List<String>> pairs,
  ) async {
    final OrderBookDepthResponse? depthResponse =
        await _mm2Api.getOrderBookDepth(pairs, _coinsRepository);

    return depthResponse?.list
        .where((d) => d.bids != 0 || d.asks != 0)
        .toList();
  }

  List<List<String>> _getDepthsPairs(CoinsByTicker coins) {
    return coins.values.fold<List<List<String>>>(
      [],
      (previousValue, entry) {
        previousValue.addAll(_createPairs(entry));
        return previousValue;
      },
    );
  }

  List<List<String>> _createPairs(List<Coin> group) {
    final List<Coin> cloneGroup = List<Coin>.from(group);
    final List<List<String>> pairs = [];
    while (cloneGroup.isNotEmpty) {
      final Coin coin = cloneGroup.removeLast();
      for (Coin item in cloneGroup) {
        pairs.add([item.abbr, coin.abbr]);
      }
    }
    return pairs;
  }
}
