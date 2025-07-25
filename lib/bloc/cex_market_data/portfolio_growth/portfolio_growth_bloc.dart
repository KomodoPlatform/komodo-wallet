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
import 'package:web_dex/shared/utils/extensions/legacy_coin_migration_extensions.dart';

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
    final currentState = state;
    if (currentState is PortfolioGrowthChartLoadSuccess) {
      emit(
        PortfolioGrowthChartLoadSuccess(
          portfolioGrowth: currentState.portfolioGrowth,
          percentageIncrease: currentState.percentageIncrease,
          selectedPeriod: event.selectedPeriod,
          totalBalance: currentState.totalBalance,
          totalChange24h: currentState.totalChange24h,
          percentageChange24h: currentState.percentageChange24h,
          isUpdating: true,
        ),
      );
    } else if (currentState is GrowthChartLoadFailure) {
      emit(
        GrowthChartLoadFailure(
          error: currentState.error,
          selectedPeriod: event.selectedPeriod,
        ),
      );
    } else if (currentState is PortfolioGrowthChartUnsupported) {
      emit(
        PortfolioGrowthChartUnsupported(selectedPeriod: event.selectedPeriod),
      );
    } else {
      emit(const PortfolioGrowthInitial());
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

      await _loadChart(
        coins,
        event,
        useCache: true,
      ).then(emit.call).catchError((Object error, StackTrace stackTrace) {
        const errorMessage = 'Failed to load cached chart';
        _log.warning(errorMessage, error, stackTrace);
        // ignore cached errors, as the periodic refresh attempts should recover
        // at the cost of a longer first loading time.
      });

      // In case most coins are activating on wallet startup, wait for at least
      // 50% of the coins to be enabled before attempting to load the uncached
      // chart.
      await sdk.waitForEnabledCoinsToPassThreshold(event.coins);

      // Only remove inactivate/activating coins after an attempt to load the
      // cached chart, as the cached chart may contain inactive coins.
      final activeCoins = await _removeInactiveCoins(coins);
      if (activeCoins.isNotEmpty) {
        await _loadChart(
          activeCoins,
          event,
          useCache: false,
        ).then(emit.call).catchError((Object error, StackTrace stackTrace) {
          _log.shout('Failed to load chart', error, stackTrace);
          // Don't emit an error state here. If cached and uncached attempts
          // both fail, the periodic refresh attempts should recovery
          // at the cost of a longer first loading time.
        });
      }
    } catch (error, stackTrace) {
      _log.shout('Failed to load portfolio growth', error, stackTrace);
      // Don't emit an error state here, as the periodic refresh attempts should
      // recover at the cost of a longer first loading time.
    }

    await emit.forEach(
      // computation is omitted, so null-valued events are emitted on a set
      // interval.
      Stream<Object?>.periodic(event.updateFrequency).asyncMap((_) async {
        // Update prices before fetching chart data
        await portfolioGrowthRepository.updatePrices();
        return _fetchPortfolioGrowthChart(event);
      }),
      onData: (data) =>
          _handlePortfolioGrowthUpdate(data, event.selectedPeriod, event.coins),
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
    final chart = await portfolioGrowthRepository.getPortfolioGrowthChart(
      coins,
      fiatCoinId: event.fiatCoinId,
      walletId: event.walletId,
      useCache: useCache,
    );

    if (useCache && chart.isEmpty) {
      return state;
    }

    // Fetch prices before calculating total change
    // This ensures we have the latest prices in the cache
    await portfolioGrowthRepository.updatePrices();

    final totalBalance = _calculateTotalBalance(coins);
    final totalChange24h = _calculateTotalChange24h(coins);
    final percentageChange24h = _calculatePercentageChange24h(coins);

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: chart,
      percentageIncrease: chart.percentageIncrease,
      selectedPeriod: event.selectedPeriod,
      totalBalance: totalBalance,
      totalChange24h: totalChange24h,
      percentageChange24h: percentageChange24h,
      isUpdating: false,
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
    List<Coin> coins,
  ) {
    if (growthChart.isEmpty && state is PortfolioGrowthChartLoadSuccess) {
      return state;
    }

    final percentageIncrease = growthChart.percentageIncrease;
    final totalBalance = _calculateTotalBalance(coins);
    final totalChange24h = _calculateTotalChange24h(coins);
    final percentageChange24h = _calculatePercentageChange24h(coins);

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: growthChart,
      percentageIncrease: percentageIncrease,
      selectedPeriod: selectedPeriod,
      totalBalance: totalBalance,
      totalChange24h: totalChange24h,
      percentageChange24h: percentageChange24h,
      isUpdating: false,
    );
  }

  /// Calculate the total balance of all coins in USD
  double _calculateTotalBalance(List<Coin> coins) {
    double total = coins.fold(
      0,
      (prev, coin) => prev + (coin.lastKnownUsdBalance(sdk) ?? 0),
    );

    // Return at least 0.01 if total is positive but very small
    if (total > 0 && total < 0.01) {
      return 0.01;
    }

    return total;
  }

  /// Calculate the total 24h change in USD value
  double _calculateTotalChange24h(List<Coin> coins) {
    // Calculate the 24h change by summing the change percentage of each coin
    // multiplied by its USD balance and divided by 100 (to convert percentage to decimal)
    return coins.fold(0.0, (sum, coin) {
      // Use the price change from the CexPrice if available
      final usdBalance = coin.lastKnownUsdBalance(sdk) ?? 0.0;
      // Get the coin price from the repository's prices cache
      final price = portfolioGrowthRepository.getCachedPrice(
        coin.id.symbol.configSymbol.toUpperCase(),
      );
      final change24h = price?.change24h ?? 0.0;
      return sum + (change24h * usdBalance / 100);
    });
  }

  /// Calculate the percentage change over 24h for the entire portfolio
  double _calculatePercentageChange24h(List<Coin> coins) {
    final double totalBalance = _calculateTotalBalance(coins);
    final double totalChange = _calculateTotalChange24h(coins);

    // Avoid division by zero or very small balances
    if (totalBalance <= 0.01) {
      return 0.0;
    }

    // Return the percentage change
    return (totalChange / totalBalance) * 100;
  }
}
