import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generate_demo_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';

final _transactionsCache = <String, Map<PerformanceMode, List<Transaction>>>{};

class DemoDataCache {
  DemoDataCache(this._generator);
  DemoDataCache.withDefaults(KomodoDefiSdk sdk)
    : _generator = DemoDataGenerator(sdk);
  final DemoDataGenerator _generator;

  Future<List<Transaction>> loadTransactionsDemoData(
    PerformanceMode performanceMode,
    String coin,
  ) async {
    final cacheKey = coin;
    if (_transactionsCache.containsKey(cacheKey) &&
        _transactionsCache[cacheKey]!.containsKey(performanceMode)) {
      return _transactionsCache[cacheKey]![performanceMode]!;
    }

    final result = await _generator.generateTransactions(
      cacheKey,
      performanceMode,
    );

    _transactionsCache.putIfAbsent(cacheKey, () => {});
    _transactionsCache[cacheKey]![performanceMode] = result;

    return result;
  }
}
