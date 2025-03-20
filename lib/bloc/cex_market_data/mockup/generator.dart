import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generate_demo_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';

final _supportedCoinsCache = <String, List<String>>{};
final _transactionsCache = <String, Map<PerformanceMode, List<Transaction>>>{};

class DemoDataCache {
  DemoDataCache(this._generator);
  DemoDataCache.withDefaults()
      : _generator = DemoDataGenerator(
          BinanceRepository(binanceProvider: const BinanceProvider()),
        );
  final DemoDataGenerator _generator;

  Future<List<String>> supportedCoinsDemoData() async {
    const cacheKey = 'supportedCoins';
    if (_supportedCoinsCache.containsKey(cacheKey)) {
      return _supportedCoinsCache[cacheKey]!;
    }

    final String response =
        await rootBundle.loadString('assets/debug/demo_trade_data.json');
    final data = json.decode(response) as Map<String, dynamic>;
    final result = (data['profit'] as Map<String, dynamic>).keys.toList();
    _supportedCoinsCache[cacheKey] = result;
    return result;
  }

  Future<List<Transaction>> loadTransactionsDemoData(
    PerformanceMode performanceMode,
    String coin,
  ) async {
    final cacheKey = coin;
    if (_transactionsCache.containsKey(cacheKey) &&
        _transactionsCache[cacheKey]!.containsKey(performanceMode)) {
      return _transactionsCache[cacheKey]![performanceMode]!;
    }

    final result =
        await _generator.generateTransactions(cacheKey, performanceMode);

    _transactionsCache.putIfAbsent(cacheKey, () => {});
    _transactionsCache[cacheKey]![performanceMode] = result;

    return result;
  }
}
