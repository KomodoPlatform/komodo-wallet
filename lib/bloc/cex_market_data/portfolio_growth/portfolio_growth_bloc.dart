import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/sdk_auth_activation_extension.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';

part 'portfolio_growth_event.dart';
part 'portfolio_growth_state.dart';

class PortfolioGrowthBloc
    extends Bloc<PortfolioGrowthEvent, PortfolioGrowthState> {
  PortfolioGrowthBloc({
    required this.portfolioGrowthRepository,
    required this.sdk,
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
  final KomodoDefiSdk sdk;
  final _log = Logger('PortfolioGrowthBloc');

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
          .catchError((Object error, StackTrace stackTrace) {
        const errorMessage = 'Failed to load cached chart';
        _log.warning(errorMessage, error, stackTrace);
        if (state is! PortfolioGrowthChartLoadSuccess) {
          emit(
            GrowthChartLoadFailure(
              error: TextError(error: errorMessage),
              selectedPeriod: event.selectedPeriod,
            ),
          );
        }
      });

      // In case most coins are activating on wallet startup, wait for at least
      // 50% of the coins to be enabled before attempting to load the uncached
      // chart. 
      await sdk.waitForEnabledCoinsToPassThreshold(event.coins);

      // Only remove inactivate/activating coins after an attempt to load the
      // cached chart, as the cached chart may contain inactive coins.
      final activeCoins = await _removeInactiveCoins(coins);
      if (activeCoins.isNotEmpty) {
        await _loadChart(activeCoins, event, useCache: false)
            .then(emit.call)
            .catchError((Object error, StackTrace stackTrace) {
          _log.shout('Failed to load chart', error, stackTrace);
          // Don't emit an error state here. If cached and uncached attempts
          // both fail, the periodic refresh attempts should recovery
          // at the cost of a longer first loading time.
        });
      }
    } catch (error, stackTrace) {
      _log.shout('Failed to load CACHED portfolio growth', error, stackTrace);
    }

    await emit.forEach(
      // computation is omitted, so null-valued events are emitted on a set
      // interval.
      Stream<Object?>.periodic(event.updateFrequency)
          .asyncMap((_) async => _fetchPortfolioGrowthChart(event)),
      onData: (data) =>
          _handlePortfolioGrowthUpdate(data, event.selectedPeriod),
      onError: (error, stackTrace) {
        _log.shout('Failed to load portfolio growth', error, stackTrace);
        return GrowthChartLoadFailure(
          error: TextError(error: 'Failed to load portfolio growth'),
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

  Future<PortfolioGrowthState> _loadChart(
    List<Coin> coins,
    PortfolioGrowthLoadRequested event, {
    required bool useCache,
  }) async {
    final currentUser = await sdk.auth.currentUser;
    if (currentUser == null) {
      return state;
    }

    final chart = await portfolioGrowthRepository.getPortfolioGrowthChart(
      coins,
      fiatCoinId: event.fiatCoinId,
      walletId: event.walletId,
      useCache: useCache,
      isHdWallet: currentUser.isHd,
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
      final currentUser = await sdk.auth.currentUser;
      if (currentUser == null) {
        return ChartData.empty();
      }
      return await portfolioGrowthRepository.getPortfolioGrowthChart(
        coins,
        fiatCoinId: event.fiatCoinId,
        walletId: event.walletId,
        useCache: false,
        isHdWallet: currentUser.isHd,
      );
    } catch (error, stackTrace) {
      _log.shout('Empty growth chart on periodic update', error, stackTrace);
      return ChartData.empty();
    }
  }

  Future<List<Coin>> _removeInactiveCoins(List<Coin> coins) async {
    final coinsCopy = List<Coin>.of(coins);
    final activeCoins = await sdk.assets.getActivatedAssets();
    final activeCoinsMap = activeCoins.map((e) => e.id).toSet();
    for (final coin in coins) {
      if (!activeCoinsMap.contains(coin.id)) {
        coinsCopy.remove(coin);
      }
    }
    return coinsCopy;
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
