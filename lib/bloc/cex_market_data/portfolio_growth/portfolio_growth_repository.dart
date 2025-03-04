import 'dart:math';

import 'package:hive/hive.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart' as cex;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/mock_portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/models/graph_type.dart';
import 'package:web_dex/bloc/cex_market_data/models/models.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/model/coin.dart';

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

  final CoinsRepo _coinsRepository;
  final KomodoDefiSdk _sdk;

  static Future<void> ensureInitialized() async {
    Hive
      ..registerAdapter(GraphCacheAdapter())
      ..registerAdapter(PointAdapter());
  }

  /// Get the growth chart for a coin based on the transactions
  /// and the spot price of the coin in the fiat currency.
  ///
  /// NOTE: On a cache miss, an [Exception] is thrown. The assumption is that
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
  /// exists, otherwise an [Exception] is thrown.
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
    final currentUser = await _sdk.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    if (useCache) {
      final String compoundKey = GraphCache.getPrimaryKey(
        coinId: coinId.id,
        fiatCoinId: fiatCoinId,
        graphType: GraphType.balanceGrowth,
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      );
      final GraphCache? cachedGraph = await _graphCache.get(compoundKey);
      final cacheExists = cachedGraph != null;
      if (cacheExists) {
        return cachedGraph.graph;
      } else {
        throw Exception('Cache miss for $compoundKey');
      }
    }

    // TODO: Refactor referenced coinsBloc method to a repository.
    // NB: Even though the class is called [CoinsBloc], it is not a Bloc.
    final Coin coin = _coinsRepository.getCoinFromId(coinId)!;
    final List<Transaction> transactions = await _transactionHistoryRepository
        .fetchCompletedTransactions(coin.id)
        .then((value) => value.toList())
        .catchError((Object e) {
      if (ignoreTransactionFetchErrors) {
        return List<Transaction>.empty();
      } else {
        throw e;
      }
    });

    if (transactions.isEmpty) {
      // Insert an empty chart into the cache to avoid fetching transactions
      // again for each invocation. The assumption is that this function is
      // called later with useCache set to false to fetch the transactions again
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
      return List.empty();
    }

    // Continue to cache an empty chart rather than trying to fetch transactions
    // again for each invocation.
    startAt ??= transactions.first.timestamp;
    endAt ??= DateTime.now();

    final String baseCoinId = coin.abbr.split('-').first;
    final cex.GraphInterval interval = _getOhlcInterval(
      startAt,
      endDate: endAt,
    );

    cex.CoinOhlc ohlcData;
    // if the base coin is the same as the fiat coin, return a chart with a
    // constant value of 1.0
    if (baseCoinId.toLowerCase() == fiatCoinId.toLowerCase()) {
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

    final List<Point<double>> portfolowGrowthChart =
        _mergeTransactionsWithOhlc(ohlcData, transactions);

    await _graphCache.insert(
      GraphCache(
        coinId: coin.abbr,
        fiatCoinId: fiatCoinId,
        lastUpdated: DateTime.now(),
        graph: portfolowGrowthChart,
        graphType: GraphType.balanceGrowth,
        walletId: walletId,
        isHdWallet: currentUser.isHd,
      ),
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
    required bool isHdWallet,
    bool useCache = true,
    DateTime? startAt,
    DateTime? endAt,
    bool ignoreTransactionFetchErrors = true,
  }) async {
    if (coins.isEmpty) {
      assert(coins.isNotEmpty, 'The list of coins should not empty.');
      return ChartData.empty();
    }

    final chartDataFutures = coins.map((coin) async {
      try {
        return await getCoinGrowthChart(
          coin.id,
          fiatCoinId: fiatCoinId,
          useCache: useCache,
          walletId: walletId,
          ignoreTransactionFetchErrors: ignoreTransactionFetchErrors,
        );
      } on TransactionFetchException {
        if (ignoreTransactionFetchErrors) {
          return Future.value(ChartData.empty());
        } else {
          rethrow;
        }
      } on Exception {
        // Exception primarily thrown for cache misses
        // TODO: create a custom exception for cache misses to avoid catching
        // this broad exception type
        return Future.value(ChartData.empty());
      }
    });
    final charts = await Future.wait(chartDataFutures);

    charts.removeWhere((element) => element.isEmpty);
    if (charts.isEmpty) {
      return ChartData.empty();
    }

    final mergedChart = Charts.merge(charts, mergeType: MergeType.leftJoin);
    // Add the current USD balance to the end of the chart to ensure that the
    // chart matches the current prices and ends at the current time.
    final double totalUsdBalance =
        coins.fold(0, (prev, coin) => prev + (coin.usdBalance ?? 0));
    if (totalUsdBalance <= 0) {
      return mergedChart;
    }

    final currentDate = DateTime.now();
    mergedChart.add(
      Point<double>(
        currentDate.millisecondsSinceEpoch.toDouble(),
        totalUsdBalance,
      ),
    );

    return mergedChart.filterDomain(startAt: startAt, endAt: endAt);
  }

  ChartData _mergeTransactionsWithOhlc(
    cex.CoinOhlc ohlcData,
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty || ohlcData.ohlc.isEmpty) {
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
    final coinTicker = coin.abbr.split('-').firstOrNull?.toUpperCase() ?? '';
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
}
