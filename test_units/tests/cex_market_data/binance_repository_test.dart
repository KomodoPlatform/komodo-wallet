import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';

import 'mocks/mock_failing_binance_provider.dart';

void testFailingBinanceRepository() {
  late BinanceRepository binanceRepository;

  setUp(() {
    binanceRepository = BinanceRepository(
      binanceProvider: const MockFailingBinanceProvider(),
    );
  });

  group('Failing BinanceRepository Requests', () {
    test('Coin list is empty if all requests to binance fail', () async {
      final response = await binanceRepository.getCoinList();
      expect(response, isEmpty);
    });

    test(
        'OHLC request rethrows [UnsupportedError] if all requests fail',
        () async {
      expect(
        () async {
          final response = await binanceRepository.getCoinOhlc(
            const CexCoinPair.usdtPrice('KMD'),
            GraphInterval.oneDay,
          );
          return response;
        },
        throwsUnsupportedError,
      );
    });

    test('Coin fiat price throws [UnsupportedError] if all requests fail',
        () async {
      expect(
        () async {
          final response = await binanceRepository.getCoinFiatPrice('KMD');
          return response;
        },
        throwsUnsupportedError,
      );
    });

    test('Coin fiat prices throws [UnsupportedError] if all requests fail',
        () async {
      expect(
        () async {
          final response = await binanceRepository
              .getCoinFiatPrices('KMD', [DateTime.now()]);
          return response;
        },
        throwsUnsupportedError,
      );
    });
  });
}
