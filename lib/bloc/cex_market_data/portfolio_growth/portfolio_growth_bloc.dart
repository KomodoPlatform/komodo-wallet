import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:logging/logging.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/common/update_frequency_backoff_strategy.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/cex_market_data/sdk_auth_activation_extension.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/extensions/legacy_coin_migration_extensions.dart';

part 'portfolio_growth_event.dart';
part 'portfolio_growth_state.dart';

class PortfolioGrowthBloc
    extends Bloc<PortfolioGrowthEvent, PortfolioGrowthState> {
  PortfolioGrowthBloc({
    required PortfolioGrowthRepository portfolioGrowthRepository,
    required KomodoDefiSdk sdk,
  }) : _sdk = sdk,
       _portfolioGrowthRepository = portfolioGrowthRepository,
       super(const PortfolioGrowthInitial()) {
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

  final PortfolioGrowthRepository _portfolioGrowthRepository;
  final KomodoDefiSdk _sdk;
  final _log = Logger('PortfolioGrowthBloc');
  final UpdateFrequencyBackoffStrategy _backoffStrategy = UpdateFrequencyBackoffStrategy();

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
    final (
      int totalCoins,
      int coinsWithKnownBalance,
      int coinsWithKnownBalanceAndFiat,
    ) = _calculateCoinProgressCounters(
      event.coins,
    );
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
          totalCoins: totalCoins,
          coinsWithKnownBalance: coinsWithKnownBalance,
          coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
          isUpdating: true,
        ),
      );
    } else if (currentState is GrowthChartLoadFailure) {
      emit(
        GrowthChartLoadFailure(
          error: currentState.error,
          selectedPeriod: event.selectedPeriod,
          totalCoins: totalCoins,
          coinsWithKnownBalance: coinsWithKnownBalance,
          coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
        ),
      );
    } else if (currentState is PortfolioGrowthChartUnsupported) {
      emit(
        PortfolioGrowthChartUnsupported(
          selectedPeriod: event.selectedPeriod,
          totalCoins: totalCoins,
          coinsWithKnownBalance: coinsWithKnownBalance,
          coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
        ),
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
        final (
          int totalCoins,
          int coinsWithKnownBalance,
          int coinsWithKnownBalanceAndFiat,
        ) = _calculateCoinProgressCounters(
          event.coins,
        );
        return emit(
          PortfolioGrowthChartUnsupported(
            selectedPeriod: event.selectedPeriod,
            totalCoins: totalCoins,
            coinsWithKnownBalance: coinsWithKnownBalance,
            coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
          ),
        );
      }

      final initialActiveCoins = await coins.removeInactiveCoins(_sdk);
      await _loadChart(
        initialActiveCoins,
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
      await _sdk.waitForEnabledCoinsToPassThreshold(event.coins);

      // Only remove inactivate/activating coins after an attempt to load the
      // cached chart, as the cached chart may contain inactive coins.
      final activeCoins = await coins.removeInactiveCoins(_sdk);
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

    // Reset backoff strategy for new load request
    _backoffStrategy.reset();
    
    // Create periodic update stream with dynamic intervals
    await _runPeriodicUpdates(event, emit);
  }

  Future<List<Coin>> _removeUnsupportedCoins(
    PortfolioGrowthLoadRequested event,
  ) async {
    final List<Coin> coins = List.from(event.coins);
    for (final coin in event.coins) {
      final isCoinSupported = await _portfolioGrowthRepository
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
    final chart = await _portfolioGrowthRepository.getPortfolioGrowthChart(
      coins,
      fiatCoinId: event.fiatCoinId,
      walletId: event.walletId,
      useCache: useCache,
    );

    if (useCache && chart.isEmpty) {
      return state;
    }

    final totalBalance = _calculateTotalBalance(coins);
    final totalChange24h = await _calculateTotalChange24h(coins);
    final percentageChange24h = await _calculatePercentageChange24h(coins);

    final (
      int totalCoins,
      int coinsWithKnownBalance,
      int coinsWithKnownBalanceAndFiat,
    ) = _calculateCoinProgressCounters(
      event.coins,
    );

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: chart,
      percentageIncrease: chart.percentageIncrease,
      selectedPeriod: event.selectedPeriod,
      totalBalance: totalBalance,
      totalChange24h: totalChange24h.toDouble(),
      percentageChange24h: percentageChange24h.toDouble(),
      totalCoins: totalCoins,
      coinsWithKnownBalance: coinsWithKnownBalance,
      coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
      isUpdating: false,
    );
  }

  Future<ChartData> _fetchPortfolioGrowthChart(
    PortfolioGrowthLoadRequested event,
  ) async {
    // Do not let transaction loading exceptions stop the periodic updates
    try {
      final supportedCoins = await _removeUnsupportedCoins(event);
      final coins = await supportedCoins.removeInactiveCoins(_sdk);
      return await _portfolioGrowthRepository.getPortfolioGrowthChart(
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

  Future<PortfolioGrowthState> _handlePortfolioGrowthUpdate(
    ChartData growthChart,
    Duration selectedPeriod,
    List<Coin> coins,
  ) async {
    if (growthChart.isEmpty && state is PortfolioGrowthChartLoadSuccess) {
      return state;
    }

    final percentageIncrease = growthChart.percentageIncrease;
    final totalBalance = _calculateTotalBalance(coins);
    final totalChange24h = await _calculateTotalChange24h(coins);
    final percentageChange24h = await _calculatePercentageChange24h(coins);

    final (
      int totalCoins,
      int coinsWithKnownBalance,
      int coinsWithKnownBalanceAndFiat,
    ) = _calculateCoinProgressCounters(
      coins,
    );

    return PortfolioGrowthChartLoadSuccess(
      portfolioGrowth: growthChart,
      percentageIncrease: percentageIncrease,
      selectedPeriod: selectedPeriod,
      totalBalance: totalBalance,
      totalChange24h: totalChange24h.toDouble(),
      percentageChange24h: percentageChange24h.toDouble(),
      totalCoins: totalCoins,
      coinsWithKnownBalance: coinsWithKnownBalance,
      coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
      isUpdating: false,
    );
  }

  /// Calculate the total balance of all coins in USD
  double _calculateTotalBalance(List<Coin> coins) {
    double total = coins.fold(
      0,
      (prev, coin) => prev + (coin.lastKnownUsdBalance(_sdk) ?? 0),
    );

    // Return at least 0.01 if total is positive but very small
    if (total > 0 && total < 0.01) {
      return 0.01;
    }

    return total;
  }

  /// Calculate the total 24h change in USD value
  /// TODO: look into avoiding zero default values here if no data is available
  Future<Rational> _calculateTotalChange24h(List<Coin> coins) async {
    Rational totalChange = Rational.zero;
    for (final coin in coins) {
      final double usdBalance = coin.lastKnownUsdBalance(_sdk) ?? 0.0;
      final usdBalanceDecimal = Decimal.parse(usdBalance.toString());
      final change24h =
          await _sdk.marketData.priceChange24h(coin.id) ?? Decimal.zero;
      totalChange += change24h * usdBalanceDecimal / Decimal.fromInt(100);
    }
    return totalChange;
  }

  /// Calculate the percentage change over 24h for the entire portfolio
  Future<Rational> _calculatePercentageChange24h(List<Coin> coins) async {
    final double totalBalance = _calculateTotalBalance(coins);
    final Rational totalBalanceRational = Rational.parse(
      totalBalance.toString(),
    );
    final Rational totalChange = await _calculateTotalChange24h(coins);

    // Avoid division by zero or very small balances
    if (totalBalanceRational <= Rational.fromInt(1, 100)) {
      return Rational.zero;
    }

    // Return the percentage change
    return (totalChange / totalBalanceRational) * Rational.fromInt(100);
  }

  /// Calculate progress counters for balances and fiat prices
  /// - totalCoins: total coins being considered (input list length)
  /// - coinsWithKnownBalance: number of coins with a known last balance
  /// - coinsWithKnownBalanceAndFiat: number of coins with a known last balance and known fiat price
  (int, int, int) _calculateCoinProgressCounters(List<Coin> coins) {
    int totalCoins = coins.length;
    int withBalance = 0;
    int withBalanceAndFiat = 0;
    for (final coin in coins) {
      final balanceKnown = _sdk.balances.lastKnown(coin.id) != null;
      if (balanceKnown) {
        withBalance++;
        final priceKnown = _sdk.marketData.priceIfKnown(coin.id) != null;
        if (priceKnown) {
          withBalanceAndFiat++;
        }
      }
    }
    return (totalCoins, withBalance, withBalanceAndFiat);
  }

  /// Run periodic updates with exponential backoff strategy
  Future<void> _runPeriodicUpdates(
    PortfolioGrowthLoadRequested event,
    Emitter<PortfolioGrowthState> emit,
  ) async {
    while (true) {
      try {
        await Future.delayed(_backoffStrategy.getNextInterval());
        
        final data = await _fetchPortfolioGrowthChart(event);
        emit(
          await _handlePortfolioGrowthUpdate(
            data,
            event.selectedPeriod,
            event.coins,
          ),
        );
      } catch (error, stackTrace) {
        _log.shout('Failed to load portfolio growth', error, stackTrace);
        final (
          int totalCoins,
          int coinsWithKnownBalance,
          int coinsWithKnownBalanceAndFiat,
        ) = _calculateCoinProgressCounters(event.coins);
        emit(
          GrowthChartLoadFailure(
            error: TextError(error: 'Failed to load portfolio growth'),
            selectedPeriod: event.selectedPeriod,
            totalCoins: totalCoins,
            coinsWithKnownBalance: coinsWithKnownBalance,
            coinsWithKnownBalanceAndFiat: coinsWithKnownBalanceAndFiat,
          ),
        );
      }
    }
  }
}
