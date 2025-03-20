import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart' as cex;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/demo_profit_loss_repository.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/adapters/adapters.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss_cache.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_calculator.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';

class ProfitLossRepository {
  ProfitLossRepository({
    required PersistenceProvider<String, ProfitLossCache>
        profitLossCacheProvider,
    required cex.CexRepository cexRepository,
    required TransactionHistoryRepo transactionHistoryRepo,
    required ProfitLossCalculator profitLossCalculator,
    required KomodoDefiSdk sdk,
  })  : _transactionHistoryRepo = transactionHistoryRepo,
        _cexRepository = cexRepository,
        _profitLossCacheProvider = profitLossCacheProvider,
        _profitLossCalculator = profitLossCalculator,
        _sdk = sdk;

  /// Return a new instance of [ProfitLossRepository] with default values.
  ///
  /// If [demoMode] is provided, it will return a [MockProfitLossRepository].
  factory ProfitLossRepository.withDefaults({
    required TransactionHistoryRepo transactionHistoryRepo,
    required cex.CexRepository cexRepository,
    required KomodoDefiSdk sdk,
    String cacheTableName = 'profit_loss',
    PerformanceMode? demoMode,
  }) {
    if (demoMode != null) {
      return MockProfitLossRepository.withDefaults(
        performanceMode: demoMode,
        cacheTableName: 'mock_${cacheTableName}_${demoMode.name}',
        sdk: sdk,
      );
    }

    return ProfitLossRepository(
      transactionHistoryRepo: transactionHistoryRepo,
      profitLossCacheProvider:
          HiveLazyBoxProvider<String, ProfitLossCache>(name: cacheTableName),
      cexRepository: cexRepository,
      profitLossCalculator: RealisedProfitLossCalculator(cexRepository),
      sdk: sdk,
    );
  }

  final PersistenceProvider<String, ProfitLossCache> _profitLossCacheProvider;
  final cex.CexRepository _cexRepository;
  final TransactionHistoryRepo _transactionHistoryRepo;
  final ProfitLossCalculator _profitLossCalculator;
  final KomodoDefiSdk _sdk;

  final _log = Logger('profit-loss-repository');

  static Future<void> ensureInitialized() async {
    Hive
      ..registerAdapter(FiatValueAdapter())
      ..registerAdapter(ProfitLossAdapter())
      ..registerAdapter(ProfitLossCacheAdapter());
  }

  Future<void> clearCache() async {
    final stopwatch = Stopwatch()..start();
    _log.fine('Clearing profit/loss cache');

    await _profitLossCacheProvider.deleteAll();

    stopwatch.stop();
    _log.fine(
      'Profit/loss cache cleared in ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  /// Check if the coin is supported by the CEX API for charting.
  /// This is used to filter out unsupported coins from the chart.
  ///
  /// [coinId] is the coin to check.
  /// [fiatCoinId] is the fiat coin id to convert the coin to.
  /// [allowFiatAsBase] is a flag to allow fiat coins as the base coin,
  /// without checking if they are supported by the CEX API.
  ///
  /// Returns `true` if the coin is supported by the CEX API for charting.
  /// Returns `false` if the coin is not supported by the CEX API for charting.
  Future<bool> isCoinChartSupported(
    AssetId coinId,
    String fiatCoinId, {
    bool allowFiatAsBase = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final coinTicker = coinId.symbol.configSymbol.toUpperCase();
    _log.fine(
      'Checking if coin $coinTicker is supported for profit/loss calculation',
    );

    final supportedCoinsStopwatch = Stopwatch()..start();
    final supportedCoins = await _cexRepository.getCoinList();
    supportedCoinsStopwatch.stop();
    _log.fine(
      'Fetched ${supportedCoins.length} supported coins in '
      '${supportedCoinsStopwatch.elapsedMilliseconds}ms',
    );

    // Allow fiat coins through, as they are represented by a constant value,
    // 1, in the repository layer and are not supported by the CEX API
    if (allowFiatAsBase && coinId.id == fiatCoinId.toUpperCase()) {
      stopwatch.stop();
      _log.fine(
        'Coin $coinTicker is a fiat coin, supported: true '
        '(total: ${stopwatch.elapsedMilliseconds}ms)',
      );
      return true;
    }

    final coinPair = CexCoinPair(
      baseCoinTicker: coinTicker,
      relCoinTicker: fiatCoinId.toUpperCase(),
    );
    final isSupported = coinPair.isCoinSupported(supportedCoins);

    stopwatch.stop();
    _log.fine(
      'Coin $coinTicker support check completed in '
      '${stopwatch.elapsedMilliseconds}ms, supported: $isSupported',
    );

    return isSupported;
  }

  /// Get the profit/loss data for a coin based on the transactions
  /// and the spot price of the coin in the fiat currency.
  ///
  /// [coinId] is the id of the coin. E.g. 'BTC'. This is generally the coin
  /// ticker from the komodo coins repository.
  /// [fiatCoinId] is id of the stablecoin to convert the [coinId] to get the
  /// fiat-equivalent price of the coin. This can be any supported coin id, but
  /// the idea is to convert the coin to a fiat currency to calculate the
  /// profit/loss in fiat.
  /// [walletId] is the wallet ID associated with the profit/loss data.
  ///
  /// Returns the list of [ProfitLoss] for the coin.
  Future<List<ProfitLoss>> getProfitLoss(
    AssetId coinId,
    String fiatCoinId,
    String walletId, {
    bool useCache = true,
  }) async {
    final methodStopwatch = Stopwatch()..start();
    _log.fine(
      'Getting profit/loss for ${coinId.id} in $fiatCoinId for wallet $walletId, '
      'useCache: $useCache',
    );

    final userStopwatch = Stopwatch()..start();
    final currentUser = await _sdk.auth.currentUser;
    userStopwatch.stop();

    if (currentUser == null) {
      _log.warning('No current user found when fetching profit/loss');
      methodStopwatch.stop();
      return <ProfitLoss>[];
    }
    _log.fine(
      'Current user fetched in ${userStopwatch.elapsedMilliseconds}ms, '
      'isHd: ${currentUser.isHd}',
    );

    if (useCache) {
      final cacheStopwatch = Stopwatch()..start();
      final String compoundKey = ProfitLossCache.getPrimaryKey(
        coinId: coinId.id,
        fiatCurrency: fiatCoinId,
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      );
      final ProfitLossCache? profitLossCache =
          await _profitLossCacheProvider.get(compoundKey);
      final bool cacheExists = profitLossCache != null;
      cacheStopwatch.stop();

      if (cacheExists) {
        _log.fine(
          'ProfitLossCache hit for ${coinId.id} in $fiatCoinId for wallet $walletId '
          'in ${cacheStopwatch.elapsedMilliseconds}ms, '
          'entries: ${profitLossCache.profitLosses.length}',
        );
        methodStopwatch.stop();
        return profitLossCache.profitLosses;
      }
      _log.fine(
        'ProfitLossCache miss for ${coinId.id} in $fiatCoinId for wallet $walletId '
        'in ${cacheStopwatch.elapsedMilliseconds}ms',
      );
    }

    final supportCheckStopwatch = Stopwatch()..start();
    final isCoinSupported = await isCoinChartSupported(
      coinId,
      fiatCoinId,
    );
    supportCheckStopwatch.stop();

    if (!isCoinSupported) {
      _log.fine(
        'Coin ${coinId.id} is not supported for profit/loss calculation '
        '(checked in ${supportCheckStopwatch.elapsedMilliseconds}ms)',
      );
      methodStopwatch.stop();
      return <ProfitLoss>[];
    }

    final txStopwatch = Stopwatch()..start();
    _log.fine('Fetching transactions for ${coinId.id}');
    final transactions =
        await _transactionHistoryRepo.fetchCompletedTransactions(coinId);
    txStopwatch.stop();
    _log.fine(
      'Fetched ${transactions.length} transactions for ${coinId.id} '
      'in ${txStopwatch.elapsedMilliseconds}ms',
    );

    if (transactions.isEmpty) {
      _log.fine('No transactions found for ${coinId.id}, caching empty result');

      final cacheInsertStopwatch = Stopwatch()..start();
      await _profitLossCacheProvider.insert(
        ProfitLossCache(
          coinId: coinId.id,
          profitLosses: List.empty(),
          fiatCoinId: fiatCoinId,
          lastUpdated: DateTime.now(),
          walletId: walletId,
          isHdWallet: currentUser.isHd,
        ),
      );
      cacheInsertStopwatch.stop();
      _log.fine(
        'Cached empty profit/loss for ${coinId.id} '
        'in ${cacheInsertStopwatch.elapsedMilliseconds}ms',
      );
      methodStopwatch.stop();
      return <ProfitLoss>[];
    }

    final calcStopwatch = Stopwatch()..start();
    _log.fine(
      'Calculating profit/loss for ${coinId.id} with ${transactions.length} transactions',
    );
    final List<ProfitLoss> profitLosses =
        await _profitLossCalculator.getProfitFromTransactions(
      transactions,
      coinId: coinId.id,
      fiatCoinId: fiatCoinId,
    );
    calcStopwatch.stop();
    _log.fine(
      'Calculated ${profitLosses.length} profit/loss entries for ${coinId.id} '
      'in ${calcStopwatch.elapsedMilliseconds}ms',
    );

    final cacheInsertStopwatch = Stopwatch()..start();
    await _profitLossCacheProvider.insert(
      ProfitLossCache(
        coinId: coinId.id,
        profitLosses: profitLosses,
        fiatCoinId: fiatCoinId,
        lastUpdated: DateTime.now(),
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      ),
    );
    cacheInsertStopwatch.stop();
    _log.fine(
      'Cached ${profitLosses.length} profit/loss entries for ${coinId.id} '
      'in ${cacheInsertStopwatch.elapsedMilliseconds}ms',
    );
    methodStopwatch.stop();
    return profitLosses;
  }
}

extension ProfitLossExtension on List<ProfitLoss> {
  ChartData toChartData() {
    return map((ProfitLoss profitLoss) {
      return Point<double>(
        profitLoss.timestamp.millisecondsSinceEpoch.toDouble(),
        profitLoss.profitLoss,
      );
    }).toList();
  }
}
