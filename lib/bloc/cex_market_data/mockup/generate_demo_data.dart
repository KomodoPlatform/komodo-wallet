import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:uuid/uuid.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';

// similar to generator implementation to allow for const constructor
final _ohlcvCache = <CexCoinPair, List<Ohlc>>{};

/// Generates semi-random transaction data for demo purposes. The transactions
/// are generated based on the historical OHLCV data for the given coin. The
/// transactions are generated in a way that the overall balance of the user
/// will increase or decrease based on the given performance mode.
class DemoDataGenerator {
  final CexRepository _ohlcRepo;
  final int randomSeed;
  final List<CexCoinPair> coinPairs;
  final Map<PerformanceMode, double> transactionsPerMode;
  final Map<PerformanceMode, double> overallReturn;
  final Map<PerformanceMode, List<double>> buyProbabilities;
  final Map<PerformanceMode, List<double>> tradeAmountFactors;
  final double initialBalance;

  const DemoDataGenerator(
    this._ohlcRepo, {
    this.initialBalance = 1000.0,
    this.coinPairs = const [
      CexCoinPair.usdtPrice('KMD'),
      CexCoinPair.usdtPrice('LTC'),
      CexCoinPair.usdtPrice('MATIC'),
      CexCoinPair.usdtPrice('AVAX'),
      CexCoinPair.usdtPrice('FTM'),
      CexCoinPair.usdtPrice('ATOM'),
    ],
    this.transactionsPerMode = const {
      PerformanceMode.good: 28,
      PerformanceMode.mediocre: 52,
      PerformanceMode.veryBad: 34,
    },
    this.overallReturn = const {
      PerformanceMode.good: 2.0,
      PerformanceMode.mediocre: 1.0,
      PerformanceMode.veryBad: 0.05,
    },
    this.buyProbabilities = const {
      PerformanceMode.good: [0.9, 0.7, 0.5, 0.2],
      PerformanceMode.mediocre: [0.6, 0.5, 0.5, 0.4],
      PerformanceMode.veryBad: [0.7, 0.5, 0.3, 0.1],
    },
    this.tradeAmountFactors = const {
      PerformanceMode.good: [0.25, 0.2, 0.15, 0.1],
      PerformanceMode.mediocre: [0.01, 0.01, 0.01, 0.01],
      PerformanceMode.veryBad: [0.1, 0.15, 0.2, 0.25],
    },
    this.randomSeed = 42,
  });

  Future<List<Transaction>> generateTransactions(
    String coinId,
    PerformanceMode mode,
  ) async {
    if (_ohlcvCache.isEmpty) {
      _ohlcvCache.addAll(await fetchOhlcData());
    }

    // Remove segwit suffix for cache key, as the ohlc data from cex providers
    // does not include the segwit suffix
    final cacheKey = coinId.replaceAll('-segwit', '');
    if (!_ohlcvCache.containsKey(CexCoinPair.usdtPrice(cacheKey))) {
      return [];
    }
    final ohlcvData = _ohlcvCache[CexCoinPair.usdtPrice(cacheKey)]!;

    final numTransactions = transactionsPerMode[mode]!;
    final random = Random(randomSeed);
    final buyProbalities = buyProbabilities[mode]!;
    final tradeAmounts = tradeAmountFactors[mode]!;
    double totalBalance = initialBalance / ohlcvData.last.close;
    double targetFinalBalance =
        (initialBalance * overallReturn[mode]!) / ohlcvData.first.close;

    List<Transaction> transactions = [];

    for (int i = 0; i < numTransactions; i++) {
      final int index = (i * ohlcvData.length ~/ numTransactions)
          .clamp(0, ohlcvData.length - 1);
      final Ohlc ohlcv = ohlcvData[index];

      final int quarter = (i * 4 ~/ numTransactions).clamp(0, 3);
      final bool isBuy = random.nextDouble() < buyProbalities[quarter];
      final bool isSameDay = random.nextDouble() < tradeAmounts[quarter];
      final double tradeAmountFactor = tradeAmounts[quarter];

      final double tradeAmount =
          random.nextDouble() * tradeAmountFactor * totalBalance;

      final transaction =
          fromTradeAmount(coinId, tradeAmount, isBuy, ohlcv.closeTime);
      transactions.add(transaction);

      if (isSameDay) {
        final transaction = fromTradeAmount(
          coinId,
          -tradeAmount,
          !isBuy,
          ohlcv.closeTime + 100,
        );
        transactions.add(transaction);
      }

      totalBalance += transaction.balanceChanges.netChange.toDouble();
      if (totalBalance <= 0) {
        totalBalance = targetFinalBalance;
        break;
      }
    }

    List<Transaction> adjustedTransactions = _adjustTransactionsToTargetBalance(
      targetFinalBalance,
      totalBalance,
      transactions,
    );

    return adjustedTransactions;
  }

  List<Transaction> _adjustTransactionsToTargetBalance(
    double targetFinalBalance,
    double totalBalance,
    List<Transaction> transactions,
  ) {
    final Decimal adjustmentFactor =
        Decimal.parse((targetFinalBalance / totalBalance).toString());
    final adjustedTransactions = <Transaction>[];
    for (var transaction in transactions) {
      final netChange = transaction.balanceChanges.netChange;
      final received = transaction.balanceChanges.receivedByMe;
      final spent = transaction.balanceChanges.spentByMe;
      final totalAmount = transaction.balanceChanges.totalAmount;

      adjustedTransactions.add(
        transaction.copyWith(
          balanceChanges: BalanceChanges(
            netChange: netChange * adjustmentFactor,
            receivedByMe: received * adjustmentFactor,
            spentByMe: spent * adjustmentFactor,
            totalAmount: totalAmount * adjustmentFactor,
          ),
        ),
      );
    }
    return adjustedTransactions;
  }

  Future<Map<CexCoinPair, List<Ohlc>>> fetchOhlcData() async {
    final ohlcvData = <CexCoinPair, List<Ohlc>>{};
    final supportedCoins = await _ohlcRepo.getCoinList();
    for (final CexCoinPair coin in coinPairs) {
      final supportedCoin = supportedCoins.where(
        (element) => element.id == coin.baseCoinTicker,
      );
      if (supportedCoin.isEmpty) {
        continue;
      }

      const interval = GraphInterval.oneDay;
      final startAt = DateTime.now().subtract(const Duration(days: 365));

      final data =
          await _ohlcRepo.getCoinOhlc(coin, interval, startAt: startAt);

      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      data.ohlc.addAll(
        await _ohlcRepo
            .getCoinOhlc(coin, GraphInterval.oneHour, startAt: twoWeeksAgo)
            .then((value) => value.ohlc),
      );

      ohlcvData[coin] = data.ohlc;
    }
    return ohlcvData;
  }
}

Transaction fromTradeAmount(
  String coinId,
  double tradeAmount,
  bool isBuy,
  int closeTimestamp,
) {
  const uuid = Uuid();
  final random = Random(42);

  return Transaction(
    id: uuid.v4(),
    blockHeight: random.nextInt(100000) + 100000,
    assetId: AssetId(
      chainId: AssetChainId(chainId: 0),
      derivationPath: '',
      id: coinId,
      name: coinId,
      subClass: CoinSubClass.smartChain,
      symbol: AssetSymbol(assetConfigId: coinId),
    ),
    confirmations: random.nextInt(3) + 1,
    from: const ["address1"],
    internalId: uuid.v4(),
    balanceChanges: BalanceChanges(
      netChange: Decimal.parse(
        isBuy ? tradeAmount.toString() : (-tradeAmount).toString(),
      ),
      receivedByMe: Decimal.parse(!isBuy ? tradeAmount.toString() : '0'),
      spentByMe: Decimal.parse(isBuy ? tradeAmount.toString() : '0'),
      totalAmount: Decimal.parse(tradeAmount.toString()),
    ),
    timestamp: DateTime.fromMillisecondsSinceEpoch(closeTimestamp),
    to: const ["address2"],
    txHash: uuid.v4(),
    memo: "memo",
  );
}
