import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/assets_overview/investment_repository.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/fiat_value.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart' as logger;

part 'asset_overview_event.dart';
part 'asset_overview_state.dart';

class AssetOverviewBloc extends Bloc<AssetOverviewEvent, AssetOverviewState> {
  AssetOverviewBloc({
    required this.profitLossRepository,
    required this.investmentRepository,
  }) : super(const AssetOverviewInitial()) {
    on<AssetOverviewLoadRequested>(_onLoad);
    on<AssetOverviewClearRequested>(_onClear);
    on<PortfolioAssetsOverviewLoadRequested>(_onLoadPortfolio);
    on<AssetOverviewSubscriptionRequested>(_onSubscribe);
    on<PortfolioAssetsOverviewSubscriptionRequested>(_onSubscribePortfolio);
    on<AssetOverviewUnsubscriptionRequested>(_onUnsubscribe);
    on<PortfolioAssetsOverviewUnsubscriptionRequested>(_onUnsubscribePortfolio);
  }

  final ProfitLossRepository profitLossRepository;
  final InvestmentRepository investmentRepository;

  Timer? _updateTimer;

  Future<void> _onLoad(
    AssetOverviewLoadRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    emit(const AssetOverviewLoadInProgress());

    try {
      final profitLosses = await profitLossRepository.getProfitLoss(
        event.coin.id,
        'USDT',
        event.walletId,
      );

      final totalInvestment =
          await investmentRepository.calculateTotalInvestment(
        event.walletId,
        [event.coin],
      );

      final profitAmount = profitLosses.lastOrNull?.profitLoss ?? 0.0;
      // The percent which the user has gained or lost on their investment
      final investmentReturnPercentage =
          (profitAmount / totalInvestment.value) * 100;

      emit(
        AssetOverviewLoadSuccess(
          totalInvestment: totalInvestment,
          // TODO! Get current coin value
          // totalValue: profitAmount,
          totalValue: totalInvestment,
          profitAmount: FiatValue.usd(profitAmount),
          investmentReturnPercentage: investmentReturnPercentage,
        ),
      );
    } catch (e) {
      logger.log('Failed to load asset overview: $e', isError: true);
      if (state is! AssetOverviewLoadSuccess) {
        emit(AssetOverviewLoadFailure(error: e.toString()));
      }
    }
  }

  Future<void> _onClear(
    AssetOverviewClearRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    emit(const AssetOverviewInitial());
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _onLoadPortfolio(
    PortfolioAssetsOverviewLoadRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    // nothing listens to this. The UI just resets to default values, i.e. 0
    // emit(const AssetOverviewLoadInProgress());

    try {
      final profitLossesFutures = event.coins.map((coin) async {
        // Catch errors that occur for single coins and exclude them from the
        // total so that transaction fetching errors for a single coin do not
        // affect the total investment calculation.
        try {
          return await profitLossRepository.getProfitLoss(
            coin.id,
            'USDT',
            event.walletId,
          );
        } catch (e) {
          return Future.value(<ProfitLoss>[]);
        }
      });

      final profitLosses = await Future.wait(profitLossesFutures);

      final totalInvestment =
          await investmentRepository.calculateTotalInvestment(
        event.walletId,
        event.coins,
      );

      final profitAmount = profitLosses.fold(0.0, (sum, item) {
        return sum + (item.lastOrNull?.profitLoss ?? 0.0);
      });

      final double portfolioInvestmentReturnPercentage =
          _calculateInvestmentReturnPercentage(profitAmount, totalInvestment);
      // Total profit / total purchase amount
      final assetPortionPercentages =
          _calculateAssetPortionPercentages(profitLosses, profitAmount);

      emit(
        PortfolioAssetsOverviewLoadSuccess(
          selectedAssetIds: event.coins.map((coin) => coin.abbr).toList(),
          assetPortionPercentages: assetPortionPercentages,
          totalInvestment: totalInvestment,
          totalValue: FiatValue.usd(profitAmount),
          profitAmount: FiatValue.usd(profitAmount),
          profitIncreasePercentage: portfolioInvestmentReturnPercentage,
        ),
      );
    } catch (e) {
      logger.log('Failed to load portfolio assets overview: $e', isError: true);
      if (state is! PortfolioAssetsOverviewLoadSuccess) {
        emit(AssetOverviewLoadFailure(error: e.toString()));
      }
    }
  }

  double _calculateInvestmentReturnPercentage(
    double profitAmount,
    FiatValue totalInvestment,
  ) {
    if (totalInvestment.value == 0) return 0.0;

    final portfolioInvestmentReturnPercentage =
        (profitAmount / totalInvestment.value) * 100;
    return portfolioInvestmentReturnPercentage;
  }

  Future<void> _onSubscribe(
    AssetOverviewSubscriptionRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    add(
      AssetOverviewLoadRequested(
        coin: event.coin,
        walletId: event.walletId,
      ),
    );

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(event.updateFrequency, (_) {
      add(
        AssetOverviewLoadRequested(
          coin: event.coin,
          walletId: event.walletId,
        ),
      );
    });
  }

  Future<void> _onSubscribePortfolio(
    PortfolioAssetsOverviewSubscriptionRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    add(
      PortfolioAssetsOverviewLoadRequested(
        coins: event.coins,
        walletId: event.walletId,
      ),
    );

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(event.updateFrequency, (_) {
      add(
        PortfolioAssetsOverviewLoadRequested(
          coins: event.coins,
          walletId: event.walletId,
        ),
      );
    });
  }

  Future<void> _onUnsubscribe(
    AssetOverviewUnsubscriptionRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _onUnsubscribePortfolio(
    PortfolioAssetsOverviewUnsubscriptionRequested event,
    Emitter<AssetOverviewState> emit,
  ) async {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  double _calculatePercentageIncrease(List<ProfitLoss> profitLosses) {
    if (profitLosses.length < 2) return 0.0;

    final oldestValue = profitLosses.first.fiatPrice.value;
    final newestValue = profitLosses.last.fiatPrice.value;

    if (oldestValue < 0 && newestValue >= 0) {
      final double totalChange = newestValue + oldestValue.abs();
      return (totalChange / oldestValue.abs()) * 100;
    } else {
      return ((newestValue - oldestValue) / oldestValue.abs()) * 100;
    }
  }

  Map<String, double> _calculateAssetPortionPercentages(
    List<List<ProfitLoss>> profitLosses,
    double totalProfit,
  ) {
    final Map<String, double> assetPortionPercentages = {};

    for (final coinProfitLosses in profitLosses) {
      if (coinProfitLosses.isNotEmpty) {
        final coinId = coinProfitLosses.first.coin;
        final coinTotalProfit = _calculatePercentageIncrease(coinProfitLosses);
        assetPortionPercentages[coinId] = (coinTotalProfit / totalProfit) * 100;
      }
    }

    return assetPortionPercentages;
  }

  @override
  Future<void> close() {
    _updateTimer?.cancel();
    return super.close();
  }
}
