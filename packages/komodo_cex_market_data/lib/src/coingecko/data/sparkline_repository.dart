// ignore_for_file: strict_raw_type

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';

SparklineRepository sparklineRepository = SparklineRepository();

class SparklineRepository {
  SparklineRepository() {
    _binanceRepository = binanceRepository;
  }
  late BinanceRepository _binanceRepository;
  bool isInitialized = false;
  final Duration cacheExpiry = const Duration(hours: 1);

  Box<Map<dynamic, dynamic>>? _box;

  Set<String> _availableCoins = {};

  // Initialize the Hive box
  Future<void> init() async {
    if (isInitialized) {
      return;
    }

    // Check if the Hive box is already open
    if (!Hive.isBoxOpen('sparkline_data')) {
      try {
        _box = await Hive.openBox<Map>('sparkline_data');
      } catch (e) {
        _box = null;
        throw Exception('Failed to open Hive box: $e');
      }

      final coins = await _binanceRepository.getCoinList();
      _availableCoins = coins.map((e) => e.id).toSet();

      isInitialized = true;
    }
  }

  Future<List<double>?> fetchSparkline(String symbol) async {
    if (!isInitialized) {
      throw Exception('SparklineRepository is not initialized');
    }
    if (_box == null) {
      throw Exception('Hive box is not initialized');
    }

    // Check if data is cached and not expired
    if (_box!.containsKey(symbol)) {
      final cachedData = _box!.get(symbol)?.cast<String, dynamic>();
      if (cachedData != null) {
        final cachedTime = DateTime.parse(cachedData['timestamp'] as String);
        if (DateTime.now().difference(cachedTime) < cacheExpiry) {
          return (cachedData['data'] as List).cast<double>();
        }
      }
    }

    if (!_availableCoins.contains(symbol)) {
      return null;
    }

    try {
      final startAt = DateTime.now().subtract(const Duration(days: 7));
      final endAt = DateTime.now();

      CoinOhlc ohlcData;
      if (symbol.split('-').firstOrNull?.toUpperCase() == 'USDT') {
        final interval = endAt.difference(startAt).inSeconds ~/ 500;
        ohlcData = CoinOhlc.fromConstantPrice(
          startAt: startAt,
          endAt: endAt,
          intervalSeconds: interval,
        );
      } else {
        ohlcData = await _binanceRepository.getCoinOhlc(
          CexCoinPair(baseCoinTicker: symbol, relCoinTicker: 'USDT'),
          GraphInterval.oneDay,
          startAt: startAt,
          endAt: endAt,
        );
      }

      final sparklineData = ohlcData.ohlc.map((e) => e.close).toList();

      // Cache the data with a timestamp
      await _box!.put(symbol, {
        'data': sparklineData,
        'timestamp': endAt.toIso8601String(),
      });

      return sparklineData;
    } catch (e) {
      if (e is Exception) {
        final errorMessage = e.toString();
        if (['400', 'klines'].every(errorMessage.contains)) {
          // Cache the invalid symbol as null
          await _box!.put(symbol, {
            'data': null,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return null;
        }
      }
      // Handle other errors appropriately
      throw Exception('Failed to fetch sparkline data: $e');
    }
  }
}
