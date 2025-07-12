import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/extensions/profit_loss_transaction_extension.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/price_stamped_transaction.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss.dart';

class ProfitLossCalculator {
  ProfitLossCalculator(this._cexRepository);
  final CexRepository _cexRepository;

  /// Get the running profit/loss for a coin based on the transactions.
  /// ProfitLoss = Proceeds - CostBasis
  /// CostBasis = Sum of the fiat price of the coin amount received (bought)
  /// Proceeds = Sum of the fiat price of the coin amount spent (sold)
  ///
  /// [transactions] is the list of transactions.
  /// [coinId] is the id of the coin, generally the coin ticker. Eg: 'BTC'.
  /// [fiatCoinId] is id of the fiat currency tether to convert the [coinId] to.
  /// E.g. 'USDT'. This can be any supported coin id, but the idea is to convert
  /// the coin to a fiat currency to calculate the profit/loss in fiat.
  ///
  /// Returns the list of [ProfitLoss] for the coin.
  Future<List<ProfitLoss>> getProfitFromTransactions(
    List<Transaction> transactions, {
    required String coinId,
    required String fiatCoinId,
  }) async {
    if (transactions.isEmpty) {
      return <ProfitLoss>[];
    }

    transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final todayAtMidnight = _getDateAtMidnight(DateTime.now());
    final transactionDates = _getTransactionDates(transactions);
    final coinUsdPrices =
        await _getTimestampedUsdPrices(coinId, transactionDates);
    final currentPrice =
        coinUsdPrices[todayAtMidnight] ?? coinUsdPrices.values.last;
    final priceStampedTransactions =
        _priceStampTransactions(transactions, coinUsdPrices);

    return _calculateProfitLosses(priceStampedTransactions, currentPrice);
  }

  List<UsdPriceStampedTransaction> _priceStampTransactions(
    List<Transaction> transactions,
    Map<DateTime, double> usdPrices,
  ) {
    return transactions.map((transaction) {
      final usdPrice = usdPrices[_getDateAtMidnight(transaction.timestamp)]!;
      return UsdPriceStampedTransaction(transaction, usdPrice);
    }).toList();
  }

  List<DateTime> _getTransactionDates(List<Transaction> transactions) {
    return transactions.map((tx) => tx.timestamp).toList()..add(DateTime.now());
  }

  DateTime _getDateAtMidnight(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<Map<DateTime, double>> _getTimestampedUsdPrices(
    String coinId,
    List<DateTime> dates,
  ) async {
    final cleanCoinId = coinId.split('-').firstOrNull?.toUpperCase() ?? '';
    return _cexRepository.getCoinFiatPrices(cleanCoinId, dates);
  }

  List<ProfitLoss> _calculateProfitLosses(
    List<UsdPriceStampedTransaction> transactions,
    double currentPrice,
  ) {
    var state = _ProfitLossState();
    final profitLosses = <ProfitLoss>[];

    for (final transaction in transactions) {
      if (transaction.totalAmountAsDouble == 0) continue;

      if (transaction.amount.toDouble() > 0) {
        state = _processBuyTransaction(state, transaction);
      } else {
        state = _processSellTransaction(state, transaction);
      }

      final runningProfitLoss = _calculateProfitLoss(state, currentPrice);
      profitLosses.add(
        ProfitLoss.fromTransaction(
          transaction,
          transaction.fiatValue,
          runningProfitLoss,
        ),
      );
    }

    return profitLosses;
  }

  _ProfitLossState _processBuyTransaction(
    _ProfitLossState state,
    UsdPriceStampedTransaction transaction,
  ) {
    final newHolding =
        (holdings: transaction.amount.toDouble(), price: transaction.priceUsd);
    return _ProfitLossState(
      holdings: [...state.holdings, newHolding],
      realizedProfitLoss: state.realizedProfitLoss,
      totalInvestment: state.totalInvestment + transaction.balanceChangeUsd,
      currentHoldings: state.currentHoldings + transaction.amount.toDouble(),
    );
  }

  _ProfitLossState _processSellTransaction(
    _ProfitLossState state,
    UsdPriceStampedTransaction transaction,
  ) {
    if (state.currentHoldings < transaction.amount.toDouble()) {
      throw Exception('Attempting to sell more than currently held');
    }

    // Balance change is negative for sales, so we use the abs value to
    // calculate the cost basis (formula assumes positive "total" value).
    var remainingToSell = transaction.amount.toDouble().abs();
    var costBasis = 0.0;
    final newHoldings =
        List<({double holdings, double price})>.from(state.holdings);

    while (remainingToSell > 0) {
      final oldestBuy = newHoldings.first.holdings;
      if (oldestBuy <= remainingToSell) {
        newHoldings.removeAt(0);
        costBasis += oldestBuy * state.holdings.first.price;
        remainingToSell -= oldestBuy;
      } else {
        newHoldings[0] = (
          holdings: newHoldings[0].holdings - remainingToSell,
          price: newHoldings[0].price
        );
        costBasis += remainingToSell * state.holdings.first.price;
        remainingToSell = 0;
      }
    }

    final double saleProceeds = transaction.balanceChangeUsd.abs();
    final double newRealizedProfitLoss =
        state.realizedProfitLoss + (saleProceeds - costBasis);

    // Balance change is negative for a sale, so subtract the abs value (
    // or add the positive value) to get the new holdings.
    final double newCurrentHoldings =
        state.currentHoldings - transaction.amount.toDouble().abs();
    final double newTotalInvestment = state.totalInvestment - costBasis;

    return _ProfitLossState(
      holdings: newHoldings,
      realizedProfitLoss: newRealizedProfitLoss,
      totalInvestment: newTotalInvestment,
      currentHoldings: newCurrentHoldings,
    );
  }

  double _calculateProfitLoss(
    _ProfitLossState state,
    double currentPrice,
  ) {
    final currentValue = state.currentHoldings * currentPrice;
    final unrealizedProfitLoss = currentValue - state.totalInvestment;
    return state.realizedProfitLoss + unrealizedProfitLoss;
  }
}

class RealisedProfitLossCalculator extends ProfitLossCalculator {
  RealisedProfitLossCalculator(super.cexRepository);

  @override
  double _calculateProfitLoss(
    _ProfitLossState state,
    double currentPrice,
  ) {
    return state.realizedProfitLoss;
  }
}

class UnRealisedProfitLossCalculator extends ProfitLossCalculator {
  UnRealisedProfitLossCalculator(super.cexRepository);

  @override
  double _calculateProfitLoss(
    _ProfitLossState state,
    double currentPrice,
  ) {
    final currentValue = state.currentHoldings * currentPrice;
    final unrealizedProfitLoss = currentValue - state.totalInvestment;
    return unrealizedProfitLoss;
  }
}

class _ProfitLossState {
  _ProfitLossState({
    List<({double holdings, double price})>? holdings,
    this.realizedProfitLoss = 0.0,
    this.totalInvestment = 0.0,
    this.currentHoldings = 0.0,
  }) : holdings = holdings ?? [];
  final List<({double holdings, double price})> holdings;
  final double realizedProfitLoss;
  final double totalInvestment;
  final double currentHoldings;
}
