import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:test/test.dart';

void main() {
  group('Coingecko CEX provider tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('fetchCoinList test', () async {
      // Arrange
      final provider = CoinGeckoCexProvider();

      // Act
      final result = await provider.fetchCoinList();

      // Assert
      expect(result, isA<List<CexCoin>>());
      expect(result.length, greaterThan(0));
    });

    test('fetchCoinMarketData test', () async {
      // Arrange
      final provider = CoinGeckoCexProvider();

      // Act
      final result = await provider.fetchCoinMarketData();

      // Assert
      expect(result, isA<List<CoinMarketData>>());
      expect(result.length, greaterThan(0));
    });

    test('fetchCoinMarketChart test', () async {
      // Arrange
      final provider = CoinGeckoCexProvider();

      // Act
      final result = await provider.fetchCoinMarketChart(
        id: 'bitcoin',
        vsCurrency: 'usd',
        fromUnixTimestamp: 1712403721,
        toUnixTimestamp: 1712749321,
      );

      // Assert
      expect(result, isA<CoinMarketChart>());
      expect(result.prices, isA<List<List<num>>>());
      expect(result.prices.length, greaterThan(0));
      expect(result.marketCaps, isA<List<List<num>>>());
      expect(result.marketCaps.length, greaterThan(0));
      expect(result.totalVolumes, isA<List<List<num>>>());
      expect(result.totalVolumes.length, greaterThan(0));
    });
  });

  // test('fetchCoinHistoricalData test', () async {
  //   // Arrange
  //   final CoinGeckoCexProvider provider = CoinGeckoCexProvider();
  //   const String id = 'bitcoin';
  //   const String date = '2023-04-20';

  //   // Act
  //   final CoinHistoricalData result = await provider.fetchCoinHistoricalData(
  //     id: id,
  //     date: date,
  //   );

  //   // Assert
  //   expect(result, isA<CoinHistoricalData>());
  //   expect(result.marketData, isA<CoinMarketData>());
  //   expect(result.marketData?.currentPrice, isNotNull);
  //   expect(result.marketData?.currentPrice?.usd, isA<num>());
  // });
}
