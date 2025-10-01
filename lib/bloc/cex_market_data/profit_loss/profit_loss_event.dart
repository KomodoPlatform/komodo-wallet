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
  });

  final List<Coin> coins;
  final String fiatCoinId;
  final Duration selectedPeriod;
  final String walletId;

  @override
  List<Object> get props => [
        coins,
        fiatCoinId,
        selectedPeriod,
        walletId,
      ];
}

class ProfitLossPortfolioPeriodChanged extends ProfitLossEvent {
  const ProfitLossPortfolioPeriodChanged({
    required this.selectedPeriod,
  });

  final Duration selectedPeriod;

  @override
  List<Object> get props => [selectedPeriod];
}
