import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generate_demo_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';

import 'mocks/mock_binance_provider.dart';

void main() {
  testGenerateDemoData();
}

void testGenerateDemoData() {
  late DemoDataGenerator generator;
  late CexRepository cexRepository;

  setUp(() async {
    // TODO: Replace with a mock repository
    cexRepository = BinanceRepository(
      binanceProvider: const MockBinanceProvider(),
    );
    // Pre-fetch & cache the coins list to avoid making multiple requests
    await cexRepository.getCoinList();

    generator = DemoDataGenerator(
      cexRepository,
    );
  });

  group(
    'DemoDataGenerator with live BinanceAPI repository',
    () {
      test('generateTransactions returns correct number of transactions',
          () async {
        final transactions =
            await generator.generateTransactions('BTC', PerformanceMode.good);
        expect(
          transactions.length,
          closeTo(generator.transactionsPerMode[PerformanceMode.good] ?? 0, 4),
        );
      });

      test('generateTransactions returns empty list for invalid coin',
          () async {
        final transactions = await generator.generateTransactions(
          'INVALID_COIN',
          PerformanceMode.good,
        );
        expect(transactions, isEmpty);
      });

      test('generateTransactions respects performance mode', () async {
        final goodTransactions =
            await generator.generateTransactions('BTC', PerformanceMode.good);
        final badTransactions = await generator.generateTransactions(
          'BTC',
          PerformanceMode.veryBad,
        );

        double goodBalance = generator.initialBalance;
        double badBalance = generator.initialBalance;

        for (final tx in goodTransactions) {
          goodBalance += tx.balanceChanges.netChange.toDouble();
        }

        for (final tx in badTransactions) {
          badBalance += tx.balanceChanges.netChange.toDouble();
        }

        expect(goodBalance, greaterThan(badBalance));
      });

      test('generateTransactions produces valid transaction objects', () async {
        final transactions = await generator.generateTransactions(
          'BTC',
          PerformanceMode.mediocre,
        );

        for (final tx in transactions) {
          expect(tx.assetId.id, equals('BTC'));
          expect(tx.confirmations, inInclusiveRange(1, 3));
          expect(tx.from, isNotEmpty);
          expect(tx.to, isNotEmpty);
          expect(tx.internalId, isNotEmpty);
          expect(tx.txHash, isNotEmpty);
        }
      });

      test('fetchOhlcData returns data for all supported coin pairs', () async {
        final ohlcData = await generator.fetchOhlcData();
        final supportedCoins = await cexRepository.getCoinList();

        for (final coinPair in generator.coinPairs) {
          final supportedCoin = supportedCoins.where(
            (coin) => coin.id == coinPair.baseCoinTicker,
          );
          if (supportedCoin.isEmpty) {
            expect(ohlcData[coinPair], isNull);
            continue;
          }

          expect(ohlcData[coinPair], isNotNull);
          expect(ohlcData[coinPair]!, isNotEmpty);
        }
      });
    },
    skip: true,
  );
}
