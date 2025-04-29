// Using relative imports in this "package" to make it easier to track external
// dependencies when moving or copying this "package" to another project.
import 'package:komodo_cex_market_data/src/binance/data/binance_provider.dart';
import 'package:komodo_cex_market_data/src/binance/data/binance_provider_interface.dart';
import 'package:komodo_cex_market_data/src/binance/models/binance_exchange_info_reduced.dart';
import 'package:komodo_cex_market_data/src/cex_repository.dart';
import 'package:komodo_cex_market_data/src/models/models.dart';

// Declaring constants here to make this easier to copy & move around
/// The base URL for the Binance API.
List<String> get binanceApiEndpoint =>
    ['https://api.binance.com/api/v3', 'https://api.binance.us/api/v3'];

BinanceRepository binanceRepository = BinanceRepository(
  binanceProvider: const BinanceProvider(),
);

/// A repository class for interacting with the Binance API.
/// This class provides methods to fetch legacy tickers and OHLC candle data.
class BinanceRepository implements CexRepository {
  /// Creates a new [BinanceRepository] instance.
  BinanceRepository({required IBinanceProvider binanceProvider})
      : _binanceProvider = binanceProvider;

  final IBinanceProvider _binanceProvider;

  List<CexCoin>? _cachedCoinsList;

  @override
  Future<List<CexCoin>> getCoinList() async {
    if (_cachedCoinsList != null) {
      return _cachedCoinsList!;
    }

    try {
      return await _executeWithRetry((String baseUrl) async {
        final exchangeInfo =
            await _binanceProvider.fetchExchangeInfoReduced(baseUrl: baseUrl);
        _cachedCoinsList = _convertSymbolsToCoins(exchangeInfo);
        return _cachedCoinsList!;
      });
    } catch (e) {
      _cachedCoinsList = List.empty();
    }

    return _cachedCoinsList!;
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(String) callback) async {
    for (int i = 0; i < binanceApiEndpoint.length; i++) {
      try {
        return await callback(binanceApiEndpoint.elementAt(i));
      } catch (e) {
        if (i >= (binanceApiEndpoint.length - 1)) {
          rethrow;
        }
      }
    }

    throw Exception('Invalid state');
  }

  CexCoin _binanceCoin(String baseCoinAbbr, String quoteCoinAbbr) {
    return CexCoin(
      id: baseCoinAbbr,
      symbol: baseCoinAbbr,
      name: baseCoinAbbr,
      currencies: <String>{quoteCoinAbbr},
      source: 'binance',
    );
  }

  @override
  Future<CoinOhlc> getCoinOhlc(
    CexCoinPair symbol,
    GraphInterval interval, {
    DateTime? startAt,
    DateTime? endAt,
    int? limit,
  }) async {
    if (symbol.baseCoinTicker.toUpperCase() ==
        symbol.relCoinTicker.toUpperCase()) {
      throw ArgumentError('Base and rel coin tickers cannot be the same');
    }

    final startUnixTimestamp = startAt?.millisecondsSinceEpoch;
    final endUnixTimestamp = endAt?.millisecondsSinceEpoch;
    final intervalAbbreviation = interval.toAbbreviation();

    return await _executeWithRetry((String baseUrl) async {
      return await _binanceProvider.fetchKlines(
        symbol.toString(),
        intervalAbbreviation,
        startUnixTimestampMilliseconds: startUnixTimestamp,
        endUnixTimestampMilliseconds: endUnixTimestamp,
        limit: limit,
        baseUrl: baseUrl,
      );
    });
  }

  @override
  Future<double> getCoinFiatPrice(
    String coinId, {
    DateTime? priceDate,
    String fiatCoinId = 'usdt',
  }) async {
    if (coinId.toUpperCase() == fiatCoinId.toUpperCase()) {
      throw ArgumentError('Coin and fiat coin cannot be the same');
    }

    final trimmedCoinId = coinId.replaceAll(RegExp('-segwit'), '');

    final endAt = priceDate ?? DateTime.now();
    final startAt = endAt.subtract(const Duration(days: 1));

    final ohlcData = await getCoinOhlc(
      CexCoinPair(baseCoinTicker: trimmedCoinId, relCoinTicker: fiatCoinId),
      GraphInterval.oneDay,
      startAt: startAt,
      endAt: endAt,
      limit: 1,
    );
    return ohlcData.ohlc.first.close;
  }

  @override
  Future<Map<DateTime, double>> getCoinFiatPrices(
    String coinId,
    List<DateTime> dates, {
    String fiatCoinId = 'usdt',
  }) async {
    if (coinId.toUpperCase() == fiatCoinId.toUpperCase()) {
      throw ArgumentError('Coin and fiat coin cannot be the same');
    }

    dates.sort();
    final trimmedCoinId = coinId.replaceAll(RegExp('-segwit'), '');

    if (dates.isEmpty) {
      return {};
    }

    final startDate = dates.first.add(const Duration(days: -2));
    final endDate = dates.last.add(const Duration(days: 2));
    final daysDiff = endDate.difference(startDate).inDays;

    final result = <DateTime, double>{};

    for (var i = 0; i <= daysDiff; i += 500) {
      final batchStartDate = startDate.add(Duration(days: i));
      final batchEndDate =
          i + 500 > daysDiff ? endDate : startDate.add(Duration(days: i + 500));

      final ohlcData = await getCoinOhlc(
        CexCoinPair(baseCoinTicker: trimmedCoinId, relCoinTicker: fiatCoinId),
        GraphInterval.oneDay,
        startAt: batchStartDate,
        endAt: batchEndDate,
      );

      final batchResult =
          ohlcData.ohlc.fold<Map<DateTime, double>>({}, (map, ohlc) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          ohlc.closeTime,
        );
        map[DateTime(date.year, date.month, date.day)] = ohlc.close;
        return map;
      });

      result.addAll(batchResult);
    }

    return result;
  }

  List<CexCoin> _convertSymbolsToCoins(
    BinanceExchangeInfoResponseReduced exchangeInfo,
  ) {
    final coins = <String, CexCoin>{};
    for (final symbol in exchangeInfo.symbols) {
      final baseAsset = symbol.baseAsset;
      final quoteAsset = symbol.quoteAsset;

      // TODO(Anon): Decide if this belongs at the repository level considering
      // that the repository should provide and transform data as required
      // without implementing business logic (or make it an optional parameter).
      if (!symbol.isSpotTradingAllowed) {
        continue;
      }

      if (!coins.containsKey(baseAsset)) {
        coins[baseAsset] = _binanceCoin(baseAsset, quoteAsset);
      } else {
        coins[baseAsset] = coins[baseAsset]!.copyWith(
          currencies: {...coins[baseAsset]!.currencies, quoteAsset},
        );
      }
    }
    return coins.values.toList();
  }
}
