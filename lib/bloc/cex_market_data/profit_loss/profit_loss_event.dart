part of 'profit_loss_bloc.dart';

abstract class ProfitLossEvent extends Equatable {
  const ProfitLossEvent();

  @override
  List<Object> get props => [];
}

class ProfitLossPortfolioChartClearRequested extends ProfitLossEvent {
  const ProfitLossPortfolioChartClearRequested();
}

class ProfitLossPortfolioChartLoadRequested extends ProfitLossEvent {
  const ProfitLossPortfolioChartLoadRequested({
    required this.coins,
    required this.fiatCoinId,
    required this.selectedPeriod,
    required this.walletId,
    this.updateFrequency = const Duration(minutes: 2),
  });

  final List<Coin> coins;
  final String fiatCoinId;
  final Duration selectedPeriod;
  final Duration updateFrequency;
  final String walletId;

  @override
  List<Object> get props => [
        coins,
        fiatCoinId,
        selectedPeriod,
        walletId,
        updateFrequency,
      ];
}

class ProfitLossPortfolioPeriodChanged extends ProfitLossEvent {
  const ProfitLossPortfolioPeriodChanged({
    required this.selectedPeriod,
    this.updateFrequency = const Duration(minutes: 2),
  });

  final Duration selectedPeriod;
  final Duration updateFrequency;

  @override
  List<Object> get props => [selectedPeriod, updateFrequency];
}
