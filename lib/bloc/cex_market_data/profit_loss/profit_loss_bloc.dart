import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';
import 'package:web_dex/bloc/cex_market_data/sdk_auth_activation_extension.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';

part 'profit_loss_event.dart';
part 'profit_loss_state.dart';

class ProfitLossBloc extends Bloc<ProfitLossEvent, ProfitLossState> {
  ProfitLossBloc(this._profitLossRepository, this._sdk)
      : super(const ProfitLossInitial()) {
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
  final KomodoDefiSdk _sdk;

  final _log = Logger('ProfitLossBloc');

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
    try {
      final supportedCoins =
          await _removeUnsupportedCons(event.coins, event.fiatCoinId);
      // Charts for individual coins (coin details) are parsed here as well,
      // and should be hidden if not supported.
      if (supportedCoins.isEmpty && event.coins.length <= 1) {
        return emit(
          PortfolioProfitLossChartUnsupported(
            selectedPeriod: event.selectedPeriod,
          ),
        );
      }

      await _getProfitLossChart(event, supportedCoins, useCache: true)
          .then(emit.call)
          .catchError((Object error, StackTrace stackTrace) {
        const errorMessage = 'Failed to load CACHED portfolio profit/loss';
        _log.warning(errorMessage, error, stackTrace);
        if (state is! PortfolioProfitLossChartLoadSuccess) {
          emit(
            ProfitLossLoadFailure(
              error: TextError(error: errorMessage),
              selectedPeriod: event.selectedPeriod,
            ),
          );
        }
      });

      // Fetch the un-cached version of the chart to update the cache.
      await _sdk.waitForEnabledCoinsToPassThreshold(supportedCoins);
      final activeCoins = await _removeInactiveCoins(supportedCoins);
      if (activeCoins.isNotEmpty) {
        await _getProfitLossChart(event, activeCoins, useCache: false)
            .then(emit.call)
            .catchError((e, _) {
          // Ignore un-cached errors, as a transaction loading exception should not
          // make the graph disappear with a load failure emit, as the cached data
          // is already displayed. The periodic updates will still try to fetch the
          // data and update the graph.
        });
      }
    } catch (error, stackTrace) {
      _log.shout('Failed to load portfolio profit/loss', e, stackTrace);
      emit(
        ProfitLossLoadFailure(
          error: TextError(error: 'Failed to load portfolio profit/loss'),
          selectedPeriod: event.selectedPeriod,
        ),
      );
    }

    await emit.forEach(
      // computation is omitted, so null-valued events are emitted on a set
      // interval.
      Stream<Object?>.periodic(event.updateFrequency).asyncMap((_) async {
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
        _log.shout('Failed to load portfolio profit/loss', e, s);
        return ProfitLossLoadFailure(
          error: TextError(error: 'Failed to load portfolio profit/loss'),
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
    List<Coin> walletCoins,
    String fiatCoinId,
  ) async {
    final coins = List<Coin>.of(walletCoins);
    for (final coin in coins) {
      final isCoinSupported = await _profitLossRepository.isCoinChartSupported(
        coin.id,
        fiatCoinId,
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
      return emit(
        PortfolioProfitLossChartLoadInProgress(
          selectedPeriod: event.selectedPeriod,
        ),
      );
    }
    add(
      ProfitLossPortfolioChartLoadRequested(
        coins: eventState.coins,
        fiatCoinId: eventState.fiatCurrency,
        selectedPeriod: event.selectedPeriod,
        walletId: eventState.walletId,
      ),
    );
  }

  Future<ChartData> _getSortedProfitLossChartForCoins(
    ProfitLossPortfolioChartLoadRequested event, {
    bool useCache = true,
  }) async {
    final currentWallet = await _sdk.auth.currentUser;
    if (currentWallet == null) {
      throw Exception('No wallet found');
    }

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

          final firstNonZeroProfitLossIndex =
              profitLosses.indexWhere((element) => element.profitLoss != 0);
          if (firstNonZeroProfitLossIndex == -1) {
            _log.info(
              'No non-zero profit/loss data found for coin ${coin.abbr}',
            );
            return ChartData.empty();
          }

          final nonZeroProfitLosses =
              profitLosses.sublist(firstNonZeroProfitLossIndex);
          return nonZeroProfitLosses.toChartData();
        } catch (e, s) {
          _log.severe(
            'Failed to load cached profit/loss for coin ${coin.abbr}',
            e,
            s,
          );
          return ChartData.empty();
        }
      }),
    );

    chartsList.removeWhere((element) => element.isEmpty);
    return Charts.merge(chartsList)..sort((a, b) => a.x.compareTo(b.x));
  }

  Future<List<Coin>> _removeInactiveCoins(List<Coin> coins) async {
    final coinsCopy = List<Coin>.of(coins);
    final activeCoins = await _sdk.assets.getActivatedAssets();
    final activeCoinsMap = activeCoins.map((e) => e.id).toSet();
    for (final coin in coins) {
      if (!activeCoinsMap.contains(coin.id)) {
        coinsCopy.remove(coin);
      }
    }
    return coinsCopy;
  }
}
