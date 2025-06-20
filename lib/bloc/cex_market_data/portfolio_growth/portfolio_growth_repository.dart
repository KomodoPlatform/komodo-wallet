import 'dart:math' show Point;

import 'package:hive/hive.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart' as cex;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/mock_portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/models/graph_type.dart';
import 'package:web_dex/bloc/cex_market_data/models/models.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/cache_miss_exception.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/extensions/legacy_coin_migration_extensions.dart';

/// A repository for fetching the growth chart for the portfolio and coins.
class PortfolioGrowthRepository {
  /// Create a new instance of the repository with the provided dependencies.
  PortfolioGrowthRepository({
    required cex.CexRepository cexRepository,
    required TransactionHistoryRepo transactionHistoryRepo,
    required PersistenceProvider<String, GraphCache> cacheProvider,
    required CoinsRepo coinsRepository,
    required KomodoDefiSdk sdk,
  })  : _transactionHistoryRepository = transactionHistoryRepo,
        _cexRepository = cexRepository,
        _graphCache = cacheProvider,
        _coinsRepository = coinsRepository,
        _sdk = sdk;

  /// Create a new instance of the repository with default dependencies.
  /// The default dependencies are the [BinanceRepository] and the
  /// [TransactionHistoryRepo].
  factory PortfolioGrowthRepository.withDefaults({
    required TransactionHistoryRepo transactionHistoryRepo,
    required cex.CexRepository cexRepository,
    required CoinsRepo coinsRepository,
    required KomodoDefiSdk sdk,
    PerformanceMode? demoMode,
  }) {
    if (demoMode != null) {
      return MockPortfolioGrowthRepository.withDefaults(
        performanceMode: demoMode,
        coinsRepository: coinsRepository,
        sdk: sdk,
      );
    }

    return PortfolioGrowthRepository(
      cexRepository: cexRepository,
      transactionHistoryRepo: transactionHistoryRepo,
      cacheProvider: HiveLazyBoxProvider<String, GraphCache>(
        name: GraphType.balanceGrowth.tableName,
      ),
      coinsRepository: coinsRepository,
      sdk: sdk,
    );
  }

  /// The CEX repository to fetch the spot price of the coins.
  final cex.CexRepository _cexRepository;

  /// The transaction history repository to fetch the transactions.
  final TransactionHistoryRepo _transactionHistoryRepository;

  /// The graph cache provider to store the portfolio growth graph data.
  final PersistenceProvider<String, GraphCache> _graphCache;

  /// The SDK needed for connecting to blockchain nodes
  final KomodoDefiSdk _sdk;

  /// The coins repository for detailed coin info
  final CoinsRepo _coinsRepository;

  final _log = Logger('PortfolioGrowthRepository');

  static Future<void> ensureInitialized() async {
    Hive
      ..registerAdapter(GraphCacheAdapter())
      ..registerAdapter(PointAdapter());
  }

  /// Get the growth chart for a coin based on the transactions
  /// and the spot price of the coin in the fiat currency.
  ///
  /// NOTE: On a cache miss, a [CacheMissException] is thrown. The assumption is that
  /// the function is called with useCache set to false to fetch the
  /// transactions again.
  /// NOTE: If the transactions are empty, an empty chart is stored in the
  /// cache. This is to avoid fetching transactions again for each invocation.
  ///
  /// [coinId] is the coin to get the growth chart for.
  /// [fiatCoinId] is the fiat currency to convert the coin to.
  /// [walletId] is the id of the current wallet of the user.
  /// [startAt] is the start time of the chart.
  /// [endAt] is the end time of the chart.
  /// [useCache] is a flag to indicate whether to use the cache when fetching
  /// the chart. If set to `true`, the chart is fetched from the cache if it
  /// exists, otherwise a [CacheMissException] is thrown.
  ///
  /// Returns the growth [ChartData] for the coin ([List] of [Point]).
  Future<ChartData> getCoinGrowthChart(
    AssetId coinId, {
    required String fiatCoinId,
    required String walletId,
    DateTime? startAt,
    DateTime? endAt,
    bool useCache = true,
    bool ignoreTransactionFetchErrors = true,
  }) async {
    final methodStopwatch = Stopwatch()..start();
    _log.fine('Getting growth chart for coin: ${coinId.id}');

    final currentUser = await _sdk.auth.currentUser;
    if (currentUser == null) {
      _log.warning('User is not logged in when fetching growth chart');
      throw Exception('User is not logged in');
    }

    if (useCache) {
      final cacheStopwatch = Stopwatch()..start();
      final String compoundKey = GraphCache.getPrimaryKey(
        coinId: coinId.id,
        fiatCoinId: fiatCoinId,
        graphType: GraphType.balanceGrowth,
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      );
      final GraphCache? cachedGraph = await _graphCache.get(compoundKey);
      final cacheExists = cachedGraph != null;
      cacheStopwatch.stop();

      if (cacheExists) {
        _log.fine(
          'Cache hit for ${coinId.id}: ${cacheStopwatch.elapsedMilliseconds}ms',
        );
        methodStopwatch.stop();
        _log.fine(
          'getCoinGrowthChart completed in '
          '${methodStopwatch.elapsedMilliseconds}ms (cached)',
        );
        return cachedGraph.graph;
      } else {
        _log.fine(
          'Cache miss ${coinId.id}: ${cacheStopwatch.elapsedMilliseconds}ms',
        );
        throw CacheMissException(compoundKey);
      }
    }

    final Coin coin = _coinsRepository.getCoinFromId(coinId)!;

    final txStopwatch = Stopwatch()..start();
    _log.fine('Fetching transactions for ${coin.id}');
    final List<Transaction> transactions = await _transactionHistoryRepository
        .fetchCompletedTransactions(coin.id)
        .then((value) => value.toList())
        .catchError((Object e) {
      txStopwatch.stop();
      _log.warning(
        'Error fetching transactions for ${coin.id} '
        'in ${txStopwatch.elapsedMilliseconds}ms: $e',
      );
      if (ignoreTransactionFetchErrors) {
        return List<Transaction>.empty();
      } else {
        throw e;
      }
    });
    txStopwatch.stop();
    _log.fine(
      'Fetched ${transactions.length} transactions for ${coin.id} '
      'in ${txStopwatch.elapsedMilliseconds}ms',
    );

    if (transactions.isEmpty) {
      _log.fine('No transactions found for ${coin.id}, caching empty chart');
      // Insert an empty chart into the cache to avoid fetching transactions
      // again for each invocation. The assumption is that this function is
      // called later with useCache set to false to fetch the transactions again
      final cacheInsertStopwatch = Stopwatch()..start();
      await _graphCache.insert(
        GraphCache(
          coinId: coinId.id,
          fiatCoinId: fiatCoinId,
          lastUpdated: DateTime.now(),
          graph: List.empty(),
          graphType: GraphType.balanceGrowth,
          walletId: walletId,
          isHdWallet: currentUser.isHd,
        ),
      );
      cacheInsertStopwatch.stop();
      _log.fine(
        'Cached empty chart for ${coin.id} '
        'in ${cacheInsertStopwatch.elapsedMilliseconds}ms',
      );

      methodStopwatch.stop();
      _log.fine(
        'getCoinGrowthChart for ${coin.id.id} completed in '
        '${methodStopwatch.elapsedMilliseconds}ms (empty)',
      );
      return List.empty();
    }

    // Continue to cache an empty chart rather than trying to fetch transactions
    // again for each invocation.
    startAt ??= transactions.first.timestamp;
    endAt ??= DateTime.now();

    final String baseCoinId = coin.id.symbol.configSymbol.toUpperCase();
    final cex.GraphInterval interval = _getOhlcInterval(
      startAt,
      endDate: endAt,
    );

    _log.fine(
      'Fetching OHLC data for $baseCoinId/$fiatCoinId '
      'with interval: $interval',
    );

    final ohlcStopwatch = Stopwatch()..start();
    cex.CoinOhlc ohlcData;
    // if the base coin is the same as the fiat coin, return a chart with a
    // constant value of 1.0
    if (baseCoinId.toLowerCase() == fiatCoinId.toLowerCase()) {
      _log.fine('Using constant price for fiat coin: $baseCoinId');
      ohlcData = cex.CoinOhlc.fromConstantPrice(
        startAt: startAt,
        endAt: endAt,
        intervalSeconds: interval.toSeconds(),
      );
    } else {
      ohlcData = await _cexRepository.getCoinOhlc(
        cex.CexCoinPair(baseCoinTicker: baseCoinId, relCoinTicker: fiatCoinId),
        interval,
        startAt: startAt,
        endAt: endAt,
      );
    }
    ohlcStopwatch.stop();
    _log.fine(
      'Fetched ${ohlcData.ohlc.length} OHLC data points '
      'in ${ohlcStopwatch.elapsedMilliseconds}ms',
    );

    final List<Point<double>> portfolowGrowthChart =
        _mergeTransactionsWithOhlc(ohlcData, transactions);
    final cacheInsertStopwatch = Stopwatch()..start();
    await _graphCache.insert(
      GraphCache(
        coinId: coin.id.id,
        fiatCoinId: fiatCoinId,
        lastUpdated: DateTime.now(),
        graph: portfolowGrowthChart,
        graphType: GraphType.balanceGrowth,
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      ),
    );
    cacheInsertStopwatch.stop();
    _log.fine(
      'Cached chart for ${coin.id} in ${cacheInsertStopwatch.elapsedMilliseconds}ms',
    );

    methodStopwatch.stop();
    _log.fine(
      'getCoinGrowthChart completed in ${methodStopwatch.elapsedMilliseconds}ms '
      'with ${portfolowGrowthChart.length} data points',
    );

    return portfolowGrowthChart;
  }

  /// Get the growth chart for the portfolio based on the transactions
  /// and the spot price of the coins in the fiat currency provided.
  ///
  /// [coins] is the list of coins in the portfolio.
  /// [fiatCoinId] is the fiat currency to convert the portfolio to.
  /// [walletId] is the wallet id of the portfolio.
  /// [useCache] is a flag to indicate whether to use the cache.
  /// [startAt] and [endAt] will filter the final chart to the specified range,
  /// and cache the filtered chart.
  /// [ignoreTransactionFetchErrors] is a flag to ignore transaction fetch errors
  /// and return an empty chart instead.
  ///
  /// Returns the growth [ChartData] for the portfolio ([List] of [Point]).
  ///
  /// Example usage:
  /// ```dart
  /// final chartData =
  ///   await getPortfolioGrowthChart(coins, fiatCurrency: 'usdt');
  /// ```
  Future<ChartData> getPortfolioGrowthChart(
    List<Coin> coins, {
    required String fiatCoinId,
    required String walletId,
    bool useCache = true,
    DateTime? startAt,
    DateTime? endAt,
    bool ignoreTransactionFetchErrors = true,
  }) async {
    final methodStopwatch = Stopwatch()..start();
    _log.fine(
      'Getting portfolio growth chart for ${coins.length} coins, '
      'useCache: $useCache',
    );

    if (coins.isEmpty) {
      _log.warning('Empty coins list provided to getPortfolioGrowthChart');
      assert(coins.isNotEmpty, 'The list of coins should not empty.');
      return ChartData.empty();
    }

    final parallelFetchStopwatch = Stopwatch()..start();
    // this is safe because increments are atomic operations, and dart is
    // single-threaded, so no concern over race conditions.
    int successCount = 0;
    int errorCount = 0;

    final chartDataFutures = coins.map((coin) async {
      try {
        final chartData = await getCoinGrowthChart(
          coin.id,
          fiatCoinId: fiatCoinId,
          useCache: useCache,
          walletId: walletId,
          ignoreTransactionFetchErrors: ignoreTransactionFetchErrors,
        );
        successCount++;
        return chartData;
      } on TransactionFetchException {
        errorCount++;
        _log.warning('Failed to fetch transactions for ${coin.id} ');
        if (ignoreTransactionFetchErrors) {
          return Future.value(ChartData.empty());
        } else {
          rethrow;
        }
      } on CacheMissException {
        errorCount++;
        _log.fine('Cache miss for ${coin.id}');
        return Future.value(ChartData.empty());
      } on Exception catch (error, stackTrace) {
        errorCount++;
        _log.severe('Error fetching chart for ${coin.id}', error, stackTrace);
        return Future.value(ChartData.empty());
      }
    });
    final charts = await Future.wait(chartDataFutures);
    parallelFetchStopwatch.stop();

    _log.fine(
      'Parallel fetch completed in ${parallelFetchStopwatch.elapsedMilliseconds}ms, '
      'success: $successCount, errors: $errorCount',
    );

    charts.removeWhere((element) => element.isEmpty);
    if (charts.isEmpty) {
      _log.warning(
          'getPortfolioGrowthChart: No valid charts found after filtering '
          'empty charts in ${methodStopwatch.elapsedMilliseconds}ms');
      return ChartData.empty();
    }

    final mergedChart = Charts.merge(charts, mergeType: MergeType.leftJoin);

    // Add the current USD balance to the end of the chart to ensure that the
    // chart matches the current prices and ends at the current time.
    // TODO: Move to the SDK when portfolio balance is implemented.
    final double totalUsdBalance = coins.fold(
        0, (prev, coin) => prev + (coin.lastKnownUsdBalance(_sdk) ?? 0));
    if (totalUsdBalance <= 0) {
      _log.fine(
        'Total USD balance is zero or negative, skipping balance point addition',
      );
      methodStopwatch.stop();
      _log.fine(
        'getPortfolioGrowthChart completed in ${methodStopwatch.elapsedMilliseconds}ms '
        'with ${mergedChart.length} data points',
      );
      return mergedChart;
    }

    final currentDate = DateTime.now();
    mergedChart.add(
      Point<double>(
        currentDate.millisecondsSinceEpoch.toDouble(),
        totalUsdBalance,
      ),
    );
    _log.fine(
      'Added current balance point: $totalUsdBalance USD at '
      '${currentDate.toIso8601String()}',
    );

    if (startAt != null || endAt != null) {
      _log.fine(
        'Filtering chart domain: startAt: ${startAt?.toIso8601String()}, '
        'endAt: ${endAt?.toIso8601String()}',
      );
    }

    final filteredChart =
        mergedChart.filterDomain(startAt: startAt, endAt: endAt);

    methodStopwatch.stop();
    _log.fine(
      'getPortfolioGrowthChart completed in ${methodStopwatch.elapsedMilliseconds}ms '
      'with ${filteredChart.length} data points',
    );

    return filteredChart;
  }

  ChartData _mergeTransactionsWithOhlc(
    cex.CoinOhlc ohlcData,
    List<Transaction> transactions,
  ) {
    final stopwatch = Stopwatch()..start();
    _log.fine(
      'Merging ${transactions.length} transactions with '
      '${ohlcData.ohlc.length} OHLC data points',
    );

    if (transactions.isEmpty || ohlcData.ohlc.isEmpty) {
      _log.warning('Empty transactions or OHLC data, returning empty chart');
      return List.empty();
    }

    final ChartData spotValues = ohlcData.ohlc.map((cex.Ohlc ohlc) {
      return Point<double>(
        ohlc.closeTime.toDouble(),
        ohlc.close,
      );
    }).toList();

    final portfolowGrowthChart =
        Charts.mergeTransactionsWithPortfolioOHLC(transactions, spotValues);

    stopwatch.stop();
    _log.fine(
      'Merged transactions with OHLC in ${stopwatch.elapsedMilliseconds}ms, '
      'resulting in ${portfolowGrowthChart.length} data points',
    );

    return portfolowGrowthChart;
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
    bool allowFiatAsBase = true,
  }) async {
    final Coin coin = _coinsRepository.getCoinFromId(coinId)!;
    final supportedCoins = await _cexRepository.getCoinList();
    final coinTicker = coin.id.symbol.configSymbol.toUpperCase();
    // Allow fiat coins through, as they are represented by a constant value,
    // 1, in the repository layer and are not supported by the CEX API
    if (allowFiatAsBase && coinTicker == fiatCoinId.toUpperCase()) {
      return true;
    }

    final coinPair = CexCoinPair(
      baseCoinTicker: coinTicker,
      relCoinTicker: fiatCoinId.toUpperCase(),
    );
    final isCoinSupported = coinPair.isCoinSupported(supportedCoins);
    return !coin.isTestCoin && isCoinSupported;
  }

  /// Get the OHLC interval for the chart based on the number of transactions
  /// and the time span of the transactions.
  /// The interval is chosen based on the number of data points
  /// and the time span of the transactions.
  ///
  /// [startDate] is the start date of the transactions.
  /// [endDate] is the end date of the transactions.
  /// [targetLength] is the number of data points to be displayed on the chart.
  ///
  /// Returns the OHLC interval.
  ///
  /// Example usage:
  /// ```dart
  /// final interval
  ///  = _getOhlcInterval(transactions, targetLength: 500);
  /// ```
  cex.GraphInterval _getOhlcInterval(
    DateTime startDate, {
    DateTime? endDate,
    int targetLength = 500,
  }) {
    final DateTime lastDate = endDate ?? DateTime.now();
    final duration = lastDate.difference(startDate);
    final int interval = duration.inSeconds.toDouble() ~/ targetLength;
    final intervalValue = cex.graphIntervalsInSeconds.entries.firstWhere(
      (entry) => entry.value >= interval,
      orElse: () => cex.graphIntervalsInSeconds.entries.last,
    );
    return intervalValue.key;
  }

  Future<void> clearCache() => _graphCache.deleteAll();

  /// Calculate the total 24h change in USD value for a list of coins
  ///
  /// This method fetches the current prices for all coins and calculates
  /// the 24h change by multiplying each coin's percentage change by its USD balance
  Future<double> calculateTotalChange24h(List<Coin> coins) async {
    // Fetch current prices including 24h change data
    final prices = await _coinsRepository.fetchCurrentPrices() ?? {};

    // Calculate the 24h change by summing the change percentage of each coin
    // multiplied by its USD balance and divided by 100 (to convert percentage to decimal)
    double totalChange = 0.0;
    for (final coin in coins) {
      final price = prices[coin.id.symbol.configSymbol.toUpperCase()];
      final change24h = price?.change24h ?? 0.0;
      final usdBalance = coin.lastKnownUsdBalance(_sdk) ?? 0.0;
      totalChange += (change24h * usdBalance / 100);
    }
    return totalChange;
  }

  /// Get the cached price for a given coin symbol
  ///
  /// This is used to avoid fetching prices for every calculation
  CexPrice? getCachedPrice(String symbol) {
    return _coinsRepository.getCachedPrice(symbol);
  }

  /// Update prices for all coins by fetching from market data
  ///
  /// This method ensures we have up-to-date price data before calculations
  Future<void> updatePrices() async {
    await _coinsRepository.fetchCurrentPrices();
  }
}
