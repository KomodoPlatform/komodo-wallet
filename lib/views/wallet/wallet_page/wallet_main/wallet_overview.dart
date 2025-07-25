import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/portfolio_events.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/balance_summary_widget.dart';

// TODO(@takenagain): Please clean up the widget structure and bloc usage for
// the wallet overview. It may be better to split this into a separate bloc
// instead of the changes we've made to the existing PortfolioGrowthBloc since
// that bloc is primarily focused on chart data.
//
// IMPLEMENTATION NOTES:
// - Current Balance: Uses PortfolioGrowthBloc.totalBalance with fallback to calculated balance
// - 24h Change: Uses PortfolioGrowthBloc.percentageChange24h and totalChange24h
// - All-time Investment: Uses AssetOverviewBloc.totalInvestment
// - All-time Profit: Uses AssetOverviewBloc.profitAmount and profitIncreasePercentage

class WalletOverview extends StatefulWidget {
  const WalletOverview({
    super.key,
    this.onPortfolioGrowthPressed,
    this.onPortfolioProfitLossPressed,
    this.onAssetsPressed,
  });

  final VoidCallback? onPortfolioGrowthPressed;
  final VoidCallback? onPortfolioProfitLossPressed;
  final VoidCallback? onAssetsPressed;

  @override
  State<WalletOverview> createState() => _WalletOverviewState();
}

class _WalletOverviewState extends State<WalletOverview> {
  bool _logged = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        if (state.coins.isEmpty) return _buildSpinner();
        final portfolioAssetsOverviewBloc = context.watch<AssetOverviewBloc>();
        final int assetCount = state.walletCoins.length;

        // Get the portfolio growth bloc to access balance and 24h change
        final portfolioGrowthBloc = context.watch<PortfolioGrowthBloc>();
        final portfolioGrowthState = portfolioGrowthBloc.state;

        // Get asset overview state data
        final stateWithData = portfolioAssetsOverviewBloc.state
                is PortfolioAssetsOverviewLoadSuccess
            ? portfolioAssetsOverviewBloc.state
                as PortfolioAssetsOverviewLoadSuccess
            : null;

        // Get total balance from the PortfolioGrowthBloc if available, otherwise calculate
        final double totalBalance =
            portfolioGrowthState is PortfolioGrowthChartLoadSuccess
                ? portfolioGrowthState.totalBalance
                : stateWithData?.totalValue.value ??
                    _getTotalBalance(state.walletCoins.values, context);

        if (!_logged && stateWithData != null) {
          context.read<AnalyticsBloc>().logEvent(
                PortfolioViewedEventData(
                  totalCoins: assetCount,
                  totalValueUsd: stateWithData.totalValue.value,
                ),
              );
          _logged = true;
        }

        // Create the statistic cards - replace first card with BalanceSummaryWidget for mobile
        final List<Widget> statisticCards = [
          // For mobile, use BalanceSummaryWidget; for desktop, use StatisticCard
          if (isMobile) ...[
            // Get 24h change data from the PortfolioGrowthBloc
            BlocBuilder<PortfolioGrowthBloc, PortfolioGrowthState>(
              builder: (context, state) {
                final double totalChange24h =
                    state is PortfolioGrowthChartLoadSuccess
                        ? state.totalChange24h
                        : 0.0;
                final double percentageChange24h =
                    state is PortfolioGrowthChartLoadSuccess
                        ? state.percentageChange24h
                        : 0.0;

                return BalanceSummaryWidget(
                  totalBalance: totalBalance,
                  changeAmount: totalChange24h,
                  changePercentage: percentageChange24h,
                  onTap: widget.onAssetsPressed,
                  onLongPress: () {
                    final formattedValue = NumberFormat.currency(symbol: '\$')
                        .format(totalBalance);
                    copyToClipBoard(context, formattedValue);
                  },
                );
              },
            ),
          ] else ...[
            StatisticCard(
              key: const Key('overview-current-value'),
              caption: Text(LocaleKeys.yourBalance.tr()),
              value: totalBalance,
              onTap: widget.onAssetsPressed,
              onLongPress: () {
                final formattedValue =
                    NumberFormat.currency(symbol: '\$').format(totalBalance);
                copyToClipBoard(context, formattedValue);
              },
              trendWidget:
                  BlocBuilder<PortfolioGrowthBloc, PortfolioGrowthState>(
                builder: (context, state) {
                  final double totalChange =
                      state is PortfolioGrowthChartLoadSuccess
                          ? state.percentageChange24h
                          : 0.0;
                  final double totalChange24h =
                      state is PortfolioGrowthChartLoadSuccess
                          ? state.totalChange24h
                          : 0.0;

                  return TrendPercentageText(
                    percentage: totalChange,
                    upColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .extension<ThemeCustomDark>()!
                            .increaseColor
                        : Theme.of(context)
                            .extension<ThemeCustomLight>()!
                            .increaseColor,
                    downColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .extension<ThemeCustomDark>()!
                            .decreaseColor
                        : Theme.of(context)
                            .extension<ThemeCustomLight>()!
                            .decreaseColor,
                    value: totalChange24h,
                    valueFormatter: NumberFormat.currency(symbol: '\$').format,
                  );
                },
              ),
            ),
          ],
          StatisticCard(
            key: const Key('overview-all-time-investment'),
            caption: Text(LocaleKeys.allTimeInvestment.tr()),
            value: stateWithData?.totalInvestment.value ?? 0,
            onTap: widget.onPortfolioGrowthPressed,
            onLongPress: () {
              final formattedValue = NumberFormat.currency(symbol: '\$')
                  .format(stateWithData?.totalInvestment.value ?? 0);
              copyToClipBoard(context, formattedValue);
            },
            trendWidget: ActionChip(
              avatar: Icon(
                Icons.pie_chart,
                size: 16,
              ),
              onPressed: widget.onAssetsPressed,
              visualDensity: const VisualDensity(vertical: -4),
              label: Text(
                LocaleKeys.assetNumber.plural(assetCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          StatisticCard(
            key: const Key('overview-all-time-profit'),
            caption: Text(LocaleKeys.allTimeProfit.tr()),
            value: stateWithData?.profitAmount.value ?? 0,
            onTap: widget.onPortfolioProfitLossPressed,
            onLongPress: () {
              final formattedValue = NumberFormat.currency(symbol: '\$')
                  .format(stateWithData?.profitAmount.value ?? 0);
              copyToClipBoard(context, formattedValue);
            },
            trendWidget: stateWithData != null
                ? TrendPercentageText(
                    percentage: stateWithData.profitIncreasePercentage,
                    upColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .extension<ThemeCustomDark>()!
                            .increaseColor
                        : Theme.of(context)
                            .extension<ThemeCustomLight>()!
                            .increaseColor,
                    downColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .extension<ThemeCustomDark>()!
                            .decreaseColor
                        : Theme.of(context)
                            .extension<ThemeCustomLight>()!
                            .decreaseColor,
                    // Show the total profit amount as the value
                    value: stateWithData.profitAmount.value,
                    valueFormatter: NumberFormat.currency(symbol: '\$').format,
                  )
                : const SizedBox.shrink(),
          ),
        ];

        if (isMobile) {
          return StatisticsCarousel(cards: statisticCards);
        } else {
          return Row(
            spacing: 24,
            children: statisticCards.map((card) {
              return Expanded(
                child: card,
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildSpinner() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(20.0),
          child: UiSpinner(),
        ),
      ],
    );
  }

  // TODO: Migrate these values to a new/existing bloc e.g. PortfolioGrowthBloc
  double _getTotalBalance(Iterable<Coin> coins, BuildContext context) {
    double total = coins.fold(
        0, (prev, coin) => prev + (coin.usdBalance(context.sdk) ?? 0));

    if (total > 0.01) {
      return total;
    }

    return total != 0 ? 0.01 : 0;
  }
}

/// A carousel widget that displays statistics cards with page indicators
class StatisticsCarousel extends StatefulWidget {
  final List<Widget> cards;

  const StatisticsCarousel({
    super.key,
    required this.cards,
  });

  @override
  State<StatisticsCarousel> createState() => _StatisticsCarouselState();
}

// TODO: Refactor into a generic card carousel widget and move to `komodo_ui`
class _StatisticsCarouselState extends State<StatisticsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: widget.cards[index],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.cards.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
