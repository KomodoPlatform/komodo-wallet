import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart' as logger;

part 'profit_loss_event.dart';
part 'profit_loss_state.dart';

class ProfitLossBloc extends Bloc<ProfitLossEvent, ProfitLossState> {
  ProfitLossBloc({
    required ProfitLossRepository profitLossRepository,
  })  : _profitLossRepository = profitLossRepository,
        super(const ProfitLossInitial()) {
    // Use the restartable transformer for load events to avoid overlapping
    // events if the user rapidly changes the period (i.e. faster than the
    // previous event can complete).
    on<ProfitLossPortfolioChartLoadRequested>(
      _onLoadPortfolioProfitLoss,
      transformer: restartable(),
    );

    on<ProfitLossPortfolioPeriodChanged>(_onPortfolioPeriodChanged);
    on<ProfitLossPortfolioChartClearRequested>(_onClearPortfolioProfitLoss);
  }

  final ProfitLossRepository _profitLossRepository;

  void _onClearPortfolioProfitLoss(
    ProfitLossPortfolioChartClearRequested event,
    Emitter<ProfitLossState> emit,
  ) {
    emit(const ProfitLossInitial());
  }

  Future<void> _onLoadPortfolioProfitLoss(
    ProfitLossPortfolioChartLoadRequested event,
    Emitter<ProfitLossState> emit,
  ) async {
    List<Coin> coins = await _removeUnsupportedCons(event);
    // Charts for individual coins (coin details) are parsed here as well,
    // and should be hidden if not supported.
    if (coins.isEmpty && event.coins.length <= 1) {
      return emit(
        PortfolioProfitLossChartUnsupported(
          selectedPeriod: event.selectedPeriod,
        ),
      );
    }

    await _getProfitLossChart(event, coins, useCache: true)
        .then(emit.call)
        .catchError((e, _) {
      logger.log('Failed to load portfolio profit/loss: $e', isError: true);
      if (state is! PortfolioProfitLossChartLoadSuccess) {
        emit(
          ProfitLossLoadFailure(
            error: TextError(error: 'Failed to load portfolio profit/loss: $e'),
            selectedPeriod: event.selectedPeriod,
          ),
        );
      }
    });

    // Fetch the un-cached version of the chart to update the cache.
    coins = await _removeUnsupportedCons(event, allowInactiveCoins: false);
    if (coins.isNotEmpty) {
      await _getProfitLossChart(event, coins, useCache: false)
          .then(emit.call)
          .catchError((e, _) {
        // Ignore un-cached errors, as a transaction loading exception should not
        // make the graph disappear with a load failure emit, as the cached data
        // is already displayed. The periodic updates will still try to fetch the
        // data and update the graph.
      });
    }

    await emit.forEach(
      Stream.periodic(event.updateFrequency).asyncMap((_) async {
        return _getSortedProfitLossChartForCoins(
          event,
          useCache: false,
        );
      }),
      onData: (profitLossChart) {
        if (profitLossChart.isEmpty) {
          return state;
        }

        final unCachedProfitIncrease = profitLossChart.increase;
        final unCachedPercentageIncrease = profitLossChart.percentageIncrease;
        return PortfolioProfitLossChartLoadSuccess(
          profitLossChart: profitLossChart,
          totalValue: unCachedProfitIncrease,
          percentageIncrease: unCachedPercentageIncrease,
          coins: event.coins,
          fiatCurrency: event.fiatCoinId,
          selectedPeriod: event.selectedPeriod,
          walletId: event.walletId,
        );
      },
      onError: (e, s) {
        logger
            .log(
              'Failed to load portfolio profit/loss: $e',
              isError: true,
              trace: s,
            )
            .ignore();
        return ProfitLossLoadFailure(
          error: TextError(error: 'Failed to load portfolio profit/loss: $e'),
          selectedPeriod: event.selectedPeriod,
        );
      },
    );
  }

  Future<ProfitLossState> _getProfitLossChart(
    ProfitLossPortfolioChartLoadRequested event,
    List<Coin> coins, {
    required bool useCache,
  }) async {
    final filteredChart = await _getSortedProfitLossChartForCoins(
      event,
      useCache: useCache,
    );
    final unCachedProfitIncrease = filteredChart.increase;
    final unCachedPercentageIncrease = filteredChart.percentageIncrease;
    return PortfolioProfitLossChartLoadSuccess(
      profitLossChart: filteredChart,
      totalValue: unCachedProfitIncrease,
      percentageIncrease: unCachedPercentageIncrease,
      coins: coins,
      fiatCurrency: event.fiatCoinId,
      selectedPeriod: event.selectedPeriod,
      walletId: event.walletId,
    );
  }

  Future<List<Coin>> _removeUnsupportedCons(
    ProfitLossPortfolioChartLoadRequested event, {
    bool allowInactiveCoins = true,
  }) async {
    final List<Coin> coins = List.from(event.coins);
    for (final coin in event.coins) {
      final isCoinSupported = await _profitLossRepository.isCoinChartSupported(
        coin.id,
        event.fiatCoinId,
        allowInactiveCoins: allowInactiveCoins,
      );
      if (coin.isTestCoin || !isCoinSupported) {
        coins.remove(coin);
      }
    }
    return coins;
  }

  Future<void> _onPortfolioPeriodChanged(
    ProfitLossPortfolioPeriodChanged event,
    Emitter<ProfitLossState> emit,
  ) async {
    final eventState = state;
    if (eventState is! PortfolioProfitLossChartLoadSuccess) {
      emit(
        PortfolioProfitLossChartLoadInProgress(
          selectedPeriod: event.selectedPeriod,
        ),
      );
    }

    assert(
      eventState is PortfolioProfitLossChartLoadSuccess,
      'Selected period can only be changed when '
      'the state is PortfolioProfitLossChartLoadSuccess',
    );

    final successState = eventState as PortfolioProfitLossChartLoadSuccess;
    add(
      ProfitLossPortfolioChartLoadRequested(
        coins: successState.coins,
        fiatCoinId: successState.fiatCurrency,
        selectedPeriod: event.selectedPeriod,
        walletId: successState.walletId,
      ),
    );
  }

  Future<ChartData> _getSortedProfitLossChartForCoins(
    ProfitLossPortfolioChartLoadRequested event, {
    bool useCache = true,
  }) async {
    final chartsList = await Future.wait(
      event.coins.map((coin) async {
        // Catch any errors and return an empty chart to prevent a single coin
        // from breaking the entire portfolio chart.
        try {
          final profitLosses = await _profitLossRepository.getProfitLoss(
            coin.id,
            event.fiatCoinId,
            event.walletId,
            useCache: useCache,
          );

          profitLosses.removeRange(
            0,
            profitLosses.indexOf(
              profitLosses.firstWhere((element) => element.profitLoss != 0),
            ),
          );

          return profitLosses.toChartData();
        } catch (e) {
          logger.log(
            'Failed to load cached profit/loss for coin ${coin.abbr}: $e',
            isError: true,
          );
          return ChartData.empty();
        }
      }),
    );

    chartsList.removeWhere((element) => element.isEmpty);
    return Charts.merge(chartsList)..sort((a, b) => a.x.compareTo(b.x));
  }
}
