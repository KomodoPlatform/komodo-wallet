import 'package:komodo_cex_market_data/src/cex_repository.dart';
import 'package:komodo_cex_market_data/src/coingecko/coingecko.dart';
import 'package:komodo_cex_market_data/src/models/models.dart';

/// The number of seconds in a day.
const int secondsInDay = 86400;

/// A repository class for interacting with the CoinGecko API.
class CoinGeckoRepository implements CexRepository {
  /// Creates a new instance of [CoinGeckoRepository].
  CoinGeckoRepository({required this.coinGeckoProvider});

  /// The CoinGecko provider to use for fetching data.
  final CoinGeckoCexProvider coinGeckoProvider;

  /// Fetches the CoinGecko market data.
  ///
  /// Returns a list of [CoinMarketData] objects containing the market data.
  ///
  /// Throws an [Exception] if the API request fails.
  ///
  /// Example usage:
  /// ```dart
  /// final List<CoinMarketData> marketData = await getCoinGeckoMarketData();
  /// ```
  Future<List<CoinMarketData>> getCoinGeckoMarketData() async {
    final coinGeckoMarketData = await coinGeckoProvider.fetchCoinMarketData();
    return coinGeckoMarketData;
  }

  @override
  Future<List<CexCoin>> getCoinList() async {
    final coins = await coinGeckoProvider.fetchCoinList();
    final supportedCurrencies =
        await coinGeckoProvider.fetchSupportedVsCurrencies();

    return coins
        .map((CexCoin e) => e.copyWith(currencies: supportedCurrencies.toSet()))
        .toList();
  }

  @override
  Future<CoinOhlc> getCoinOhlc(
    CexCoinPair symbol,
    GraphInterval interval, {
    DateTime? startAt,
    DateTime? endAt,
    int? limit,
  }) {
    var days = 1;
    if (startAt != null && endAt != null) {
      final timeDelta = endAt.difference(startAt);
      days = (timeDelta.inSeconds.toDouble() / secondsInDay).ceil();
    }

    return coinGeckoProvider.fetchCoinOhlc(
      symbol.baseCoinTicker,
      symbol.relCoinTicker,
      days,
    );
  }

  @override
  Future<double> getCoinFiatPrice(
    String coinId, {
    DateTime? priceDate,
    String fiatCoinId = 'usdt',
  }) async {
    final coinPrice = await coinGeckoProvider.fetchCoinHistoricalMarketData(
      id: coinId,
      date: priceDate ?? DateTime.now(),
    );
    return coinPrice.marketData?.currentPrice?.usd?.toDouble() ?? 0;
  }

  @override
  Future<Map<DateTime, double>> getCoinFiatPrices(
    String coinId,
    List<DateTime> dates, {
    String fiatCoinId = 'usdt',
  }) {
    // TODO: implement getCoinFiatPrices
    throw UnimplementedError();
  }
}
