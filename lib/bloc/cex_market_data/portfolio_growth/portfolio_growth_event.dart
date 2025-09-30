part of 'portfolio_growth_bloc.dart';

sealed class PortfolioGrowthEvent extends Equatable {
  const PortfolioGrowthEvent();

  @override
  List<Object> get props => [];
}

class PortfolioGrowthClearRequested extends PortfolioGrowthEvent {
  const PortfolioGrowthClearRequested();
}

class PortfolioGrowthLoadRequested extends PortfolioGrowthEvent {
  const PortfolioGrowthLoadRequested({
    required this.coins,
    required this.fiatCoinId,
    required this.selectedPeriod,
    required this.walletId,
    this.updateFrequency = const Duration(minutes: 2),
  });

  final List<Coin> coins;
  final String fiatCoinId;
  final Duration selectedPeriod;
  final String walletId;
  final Duration updateFrequency;

  @override
  List<Object> get props => [
        coins,
        fiatCoinId,
        selectedPeriod,
        walletId,
        updateFrequency,
      ];
}

class PortfolioGrowthPeriodChanged extends PortfolioGrowthEvent {
  const PortfolioGrowthPeriodChanged({
    required this.selectedPeriod,
    required this.coins,
    required this.walletId,
    this.updateFrequency = const Duration(minutes: 2),
  });

  final Duration selectedPeriod;
  final List<Coin> coins;
  final String walletId;
  final Duration updateFrequency;

  @override
  List<Object> get props => [selectedPeriod, coins, walletId, updateFrequency];
}
