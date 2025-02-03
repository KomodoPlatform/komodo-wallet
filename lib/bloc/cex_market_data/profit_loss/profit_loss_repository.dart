import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart' as cex;
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/demo_profit_loss_repository.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/adapters/adapters.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss_cache.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_calculator.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/shared/utils/utils.dart';

class ProfitLossRepository {
  ProfitLossRepository({
    required PersistenceProvider<String, ProfitLossCache>
        profitLossCacheProvider,
    required cex.CexRepository cexRepository,
    required TransactionHistoryRepo transactionHistoryRepo,
    required ProfitLossCalculator profitLossCalculator,
    required CoinsRepo coinsRepository,
  })  : _transactionHistoryRepo = transactionHistoryRepo,
        _cexRepository = cexRepository,
        _profitLossCacheProvider = profitLossCacheProvider,
        _profitLossCalculator = profitLossCalculator,
        _coinsRepository = coinsRepository;

  final PersistenceProvider<String, ProfitLossCache> _profitLossCacheProvider;
  final cex.CexRepository _cexRepository;
  final TransactionHistoryRepo _transactionHistoryRepo;
  final ProfitLossCalculator _profitLossCalculator;
  final CoinsRepo _coinsRepository;

  static Future<void> ensureInitialized() async {
    Hive
      ..registerAdapter(FiatValueAdapter())
      ..registerAdapter(ProfitLossAdapter())
      ..registerAdapter(ProfitLossCacheAdapter());
  }

  Future<void> clearCache() async {
    await _profitLossCacheProvider.deleteAll();
  }

  /// Return a new instance of [ProfitLossRepository] with default values.
  ///
  /// If [demoMode] is provided, it will return a [MockProfitLossRepository].
  factory ProfitLossRepository.withDefaults({
    String cacheTableName = 'profit_loss',
    required TransactionHistoryRepo transactionHistoryRepo,
    required cex.CexRepository cexRepository,
    required CoinsRepo coinsRepository,
    required Mm2Api mm2Api,
    required KomodoDefiSdk sdk,
    PerformanceMode? demoMode,
  }) {
    if (demoMode != null) {
      return MockProfitLossRepository.withDefaults(
        performanceMode: demoMode,
        coinsRepository: coinsRepository,
        cacheTableName: 'mock_${cacheTableName}_${demoMode.name}',
        mm2Api: mm2Api,
        sdk: sdk,
      );
    }

    return ProfitLossRepository(
      transactionHistoryRepo: transactionHistoryRepo,
      profitLossCacheProvider:
          HiveLazyBoxProvider<String, ProfitLossCache>(name: cacheTableName),
      cexRepository: cexRepository,
      profitLossCalculator: RealisedProfitLossCalculator(cexRepository),
      coinsRepository: coinsRepository,
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
    String coinId,
    String fiatCoinId, {
    bool allowFiatAsBase = false,
    bool allowInactiveCoins = false,
  }) async {
    if (!allowInactiveCoins) {
      final coin = await _coinsRepository.getEnabledCoin(coinId);
      if (coin == null || coin.isActivating || !coin.isActive) {
        return false;
      }
    }

    final supportedCoins = await _cexRepository.getCoinList();
    final coinTicker = abbr2Ticker(coinId).toUpperCase();
    // Allow fiat coins through, as they are represented by a constant value,
    // 1, in the repository layer and are not supported by the CEX API
    if (allowFiatAsBase && coinId == fiatCoinId.toUpperCase()) {
      return true;
    }

    final coinPair = CexCoinPair(
      baseCoinTicker: coinTicker,
      relCoinTicker: fiatCoinId.toUpperCase(),
    );
    return coinPair.isCoinSupported(supportedCoins);
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
    String coinId,
    String fiatCoinId,
    String walletId, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final String compoundKey = ProfitLossCache.getPrimaryKey(
        coinId,
        fiatCoinId,
        walletId,
      );
      final ProfitLossCache? profitLossCache =
          await _profitLossCacheProvider.get(compoundKey);
      final bool cacheExists = profitLossCache != null;

      if (cacheExists) {
        return profitLossCache.profitLosses;
      }
    }

    final isCoinSupported = await isCoinChartSupported(
      coinId,
      fiatCoinId,
    );
    if (!isCoinSupported) {
      return <ProfitLoss>[];
    }

    final transactions =
        await _transactionHistoryRepo.fetchCompletedTransactions(
      // TODO: Refactor referenced coinsBloc method to a repository.
      // NB: Even though the class is called [CoinsBloc], it is not a Bloc.
      _coinsRepository.getCoin(coinId)!,
    );

    if (transactions.isEmpty) {
      await _profitLossCacheProvider.insert(
        ProfitLossCache(
          coinId: coinId,
          profitLosses: List.empty(),
          fiatCoinId: fiatCoinId,
          lastUpdated: DateTime.now(),
          walletId: walletId,
        ),
      );
      return <ProfitLoss>[];
    }

    final List<ProfitLoss> profitLosses =
        await _profitLossCalculator.getProfitFromTransactions(
      transactions,
      coinId: coinId,
      fiatCoinId: fiatCoinId,
    );

    await _profitLossCacheProvider.insert(
      ProfitLossCache(
        coinId: coinId,
        profitLosses: profitLosses,
        fiatCoinId: fiatCoinId,
        lastUpdated: DateTime.now(),
        walletId: walletId,
      ),
    );

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
