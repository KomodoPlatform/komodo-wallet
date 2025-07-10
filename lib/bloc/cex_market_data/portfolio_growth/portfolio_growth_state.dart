part of 'portfolio_growth_bloc.dart';

sealed class PortfolioGrowthState extends Equatable {
  const PortfolioGrowthState({required this.selectedPeriod});

  final Duration selectedPeriod;

  @override
  List<Object> get props => <Object>[selectedPeriod];
}

final class PortfolioGrowthInitial extends PortfolioGrowthState {
  const PortfolioGrowthInitial()
      : super(selectedPeriod: const Duration(hours: 1));
}

final class PortfolioGrowthChartLoadSuccess extends PortfolioGrowthState {
  const PortfolioGrowthChartLoadSuccess({
    required this.portfolioGrowth,
    required this.percentageIncrease,
    required super.selectedPeriod,
    required this.totalBalance,
    required this.totalChange24h,
    required this.percentageChange24h,
    this.isUpdating = false,
  });

  final ChartData portfolioGrowth;
  final double percentageIncrease;
  final double totalBalance;
  final double totalChange24h;
  final double percentageChange24h;
  final bool isUpdating;

  @override
  List<Object> get props => <Object>[
        portfolioGrowth,
        percentageIncrease,
        selectedPeriod,
        totalBalance,
        totalChange24h,
        percentageChange24h,
        isUpdating,
      ];
}

final class GrowthChartLoadFailure extends PortfolioGrowthState {
  const GrowthChartLoadFailure({
    required this.error,
    required super.selectedPeriod,
  });

  final BaseError error;

  @override
  List<Object> get props => <Object>[error, selectedPeriod];
}

final class PortfolioGrowthChartUnsupported extends PortfolioGrowthState {
  const PortfolioGrowthChartUnsupported({required Duration selectedPeriod})
      : super(selectedPeriod: selectedPeriod);
}
