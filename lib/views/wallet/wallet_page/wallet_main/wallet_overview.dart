import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:komodo_wallet/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:komodo_wallet/bloc/cex_market_data/price_chart/models/time_period.dart';
import 'package:komodo_wallet/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/bloc/analytics/analytics_bloc.dart';
import 'package:komodo_wallet/analytics/events/portfolio_events.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

// TODO(@takenagain): Please clean up the widget structure and bloc usage for
// the wallet overview. It may be better to split this into a separate bloc
// instead of the changes we've made to the existing PortfolioGrowthBloc since
// that bloc is primarily focused on chart data.
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

        // Get total balance from the PortfolioGrowthBloc if available, otherwise calculate
        final double totalBalance =
            portfolioGrowthState is PortfolioGrowthChartLoadSuccess
                ? portfolioGrowthState.totalBalance
                : _getTotalBalance(state.walletCoins.values, context);

        final stateWithData = portfolioAssetsOverviewBloc.state
                is PortfolioAssetsOverviewLoadSuccess
            ? portfolioAssetsOverviewBloc.state
                as PortfolioAssetsOverviewLoadSuccess
            : null;
        if (!_logged && stateWithData != null) {
          context.read<AnalyticsBloc>().logEvent(
                PortfolioViewedEventData(
                  totalCoins: assetCount,
                  totalValueUsd: stateWithData.totalValue.value,
                ),
              );
          _logged = true;
        }

        // Create the statistic cards
        final List<Widget> statisticCards = [
          StatisticCard(
            key: const Key('overview-current-value'),
            caption: Text(LocaleKeys.yourBalance.tr()),
            value: totalBalance,
            actionIcon: const Icon(Icons.copy),
            onPressed: () {
              final formattedValue =
                  NumberFormat.currency(symbol: '\$').format(totalBalance);
              copyToClipBoard(context, formattedValue);
            },
            footer: BlocBuilder<PortfolioGrowthBloc, PortfolioGrowthState>(
              builder: (context, state) {
                final double totalChange =
                    state is PortfolioGrowthChartLoadSuccess
                        ? state.percentageChange24h
                        : 0.0;

                return Chip(
                  visualDensity: const VisualDensity(vertical: -4),
                  label: TrendPercentageText(
                    percentage: totalChange,
                    suffix: Text(TimePeriod.oneDay.formatted()),
                    precision: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
          StatisticCard(
            key: const Key('overview-all-time-investment'),
            caption: Text(LocaleKeys.allTimeInvestment.tr()),
            value: stateWithData?.totalInvestment.value ?? 0,
            actionIcon: const Icon(CustomIcons.fiatIconCircle),
            onPressed: widget.onPortfolioGrowthPressed,
            footer: ActionChip(
              avatar: Icon(
                Icons.pie_chart,
              ),
              onPressed: widget.onAssetsPressed,
              visualDensity: const VisualDensity(vertical: -4),
              label: Text(
                LocaleKeys.assetNumber.plural(assetCount),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          StatisticCard(
            key: const Key('overview-all-time-profit'),
            caption: Text(LocaleKeys.allTimeProfit.tr()),
            value: stateWithData?.profitAmount.value ?? 0,
            footer: Chip(
              visualDensity: const VisualDensity(vertical: -4),
              label: TrendPercentageText(
                percentage: stateWithData?.profitIncreasePercentage ?? 0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            actionIcon: const Icon(Icons.trending_up),
            onPressed: widget.onPortfolioProfitLossPressed,
          ),
        ];

        // Use carousel for mobile and wrap for desktop
        // TODO: `Wrap` is currently redundant. Enforce a minimum width for
        // the cards instead.
        if (isMobile) {
          return StatisticsCarousel(cards: statisticCards);
        } else {
          return Wrap(
            runSpacing: 16,
            children: statisticCards.map((card) {
              return FractionallySizedBox(
                widthFactor: 1 / 3,
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
