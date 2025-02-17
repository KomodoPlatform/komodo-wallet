import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'portfolio_growth_event.dart';
part 'portfolio_growth_state.dart';

class PortfolioGrowthBloc
    extends Bloc<PortfolioGrowthEvent, PortfolioGrowthState> {
  PortfolioGrowthBloc({
    required this.portfolioGrowthRepository,
    required this.coinsRepository,
  }) : super(const PortfolioGrowthInitial()) {
    // Use the restartable transformer for period change events to avoid
    // overlapping events if the user rapidly changes the period (i.e. faster
    // than the previous event can complete).
    on<PortfolioGrowthLoadRequested>(
      _onLoadPortfolioGrowth,
      transformer: restartable(),
    );
    on<PortfolioGrowthPeriodChanged>(
      _onPortfolioGrowthPeriodChanged,
      transformer: restartable(),
    );
    on<PortfolioGrowthClearRequested>(_onClearPortfolioGrowth);
  }

  final PortfolioGrowthRepository portfolioGrowthRepository;
  final CoinsRepo coinsRepository;

  void _onClearPortfolioGrowth(
    PortfolioGrowthClearRequested event,
    Emitter<PortfolioGrowthState> emit,
  ) {
    emit(const PortfolioGrowthInitial());
  }

  void _onPortfolioGrowthPeriodChanged(
    PortfolioGrowthPeriodChanged event,
    Emitter<PortfolioGrowthState> emit,
  ) {
    if (state is GrowthChartLoadFailure) {
      emit(
        GrowthChartLoadFailure(
          error: (state as GrowthChartLoadFailure).error,
          selectedPeriod: event.selectedPeriod,
        ),
      );
    }

    add(
      PortfolioGrowthLoadRequested(
        coins: event.coins,
        selectedPeriod: event.selectedPeriod,
        fiatCoinId: 'USDT',
        updateFrequency: event.updateFrequency,
        walletId: event.walletId,
      ),
    );
  }

  Future<void> _onLoadPortfolioGrowth(
    PortfolioGrowthLoadRequested event,
    Emitter<PortfolioGrowthState> emit,
  ) async {
    try {
      final List<Coin> coins = await _removeUnsupportedCoins(event);
      // Charts for individual coins (coin details) are parsed here as well,
      // and should be hidden if not supported.
      if (coins.isEmpty && event.coins.length <= 1) {
        return emit(
          PortfolioGrowthChartUnsupported(selectedPeriod: event.selectedPeriod),
        );
      }

      await _loadChart(coins, event, useCache: true)
          .then(emit.call)
          .catchError((e, _) {
        if (state is! PortfolioGrowthChartLoadSuccess) {
          emit(
            GrowthChartLoadFailure(
              error: TextError(error: e.toString()),
              selectedPeriod: event.selectedPeriod,
            ),
          );
        }
      });

      // Only remove inactivate/activating coins after an attempt to load the
      // cached chart, as the cached chart may contain inactive coins.
      final activeCoins = await _removeInactiveCoins(coins);
      if (activeCoins.isNotEmpty) {
        await _loadChart(activeCoins, event, useCache: false)
            .then(emit.call)
            .catchError((_, __) {
          // Ignore un-cached errors, as a transaction loading exception should not
          // make the graph disappear with a load failure emit, as the cached data
          // is already displayed. The periodic updates will still try to fetch the
          // data and update the graph.
        });
      }
    } catch (e, s) {
      log(
        'Failed to load portfolio growth: $e',
        isError: true,
        trace: s,
        path: 'portfolio_growth_bloc => _onLoadPortfoliowGrowth',
      );
    }

    await emit.forEach(
      Stream.periodic(event.updateFrequency)
          .asyncMap((_) async => await _fetchPortfolioGrowthChart(event)),
      onData: (data) =>
          _handlePortfolioGrowthUpdate(data, event.selectedPeriod),
      onError: (e, _) {
        log(
          'Failed to load portfolio growth: $e',
          isError: true,
        );
        return GrowthChartLoadFailure(
          error: TextError(error: e.toString()),
          selectedPeriod: event.selectedPeriod,
        );
      },
    );
  }

  Future<List<Coin>> _removeUnsupportedCoins(
    PortfolioGrowthLoadRequested event,
  ) async {
    final List<Coin> coins = List.from(event.coins);
    for (final coin in event.coins) {
      final isCoinSupported = await portfolioGrowthRepository
          .isCoinChartSupported(coin.id, event.fiatCoinId);
      if (!isCoinSupported) {
        coins.remove(coin);
      }
    }
    return coins;
  }

  Future<List<Coin>> _removeInactiveCoins(List<Coin> coins) async {
    final List<Coin> coinsCopy = List.from(coins);
    for (final coin in coins) {
      final updatedCoin = await coinsRepository.getEnabledCoin(coin.abbr);
      if (updatedCoin == null ||
          updatedCoin.isActivating ||
          !updatedCoin.isActive) {
        coinsCopy.remove(coin);
      }
    }
    return coinsCopy;
  }

  Future<PortfolioGrowthState> _loadChart(
    List<Coin> coins,
    PortfolioGrowthLoadRequested event, {
    required bool useCache,
  }) async {
    final chart = await portfolioGrowthRepository.getPortfolioGrowthChart(
      coins,
      fiatCoinId: event.fiatCoinId,
      walletId: event.walletId,
      useCache: useCache,
    );

    if (useCache && chart.isEmpty) {
      return state;
    }

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: chart,
      percentageIncrease: chart.percentageIncrease,
      selectedPeriod: event.selectedPeriod,
    );
  }

  Future<ChartData> _fetchPortfolioGrowthChart(
    PortfolioGrowthLoadRequested event,
  ) async {
    // Do not let transaction loading exceptions stop the periodic updates
    try {
      final supportedCoins = await _removeUnsupportedCoins(event);
      final coins = await _removeInactiveCoins(supportedCoins);
      return await portfolioGrowthRepository.getPortfolioGrowthChart(
        coins,
        fiatCoinId: event.fiatCoinId,
        walletId: event.walletId,
        useCache: false,
      );
    } catch (e, s) {
      log(
        'Empty growth chart on periodic update: $e',
        isError: true,
        trace: s,
        path: 'PortfolioGrowthBloc',
      ).ignore();
      return ChartData.empty();
    }
  }

  PortfolioGrowthState _handlePortfolioGrowthUpdate(
    ChartData growthChart,
    Duration selectedPeriod,
  ) {
    if (growthChart.isEmpty && state is PortfolioGrowthChartLoadSuccess) {
      return state;
    }

    final percentageIncrease = growthChart.percentageIncrease;

    // TODO? Include the center value in the bloc state instead of
    // calculating it in the UI

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: growthChart,
      percentageIncrease: percentageIncrease,
      selectedPeriod: selectedPeriod,
    );
  }
}
