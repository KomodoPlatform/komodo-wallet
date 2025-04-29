import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/assets_overview/bloc/asset_overview_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class WalletOverview extends StatelessWidget {
  const WalletOverview({
    super.key,
    this.onPortfolioGrowthPressed,
    this.onPortfolioProfitLossPressed,
  });

  final VoidCallback? onPortfolioGrowthPressed;
  final VoidCallback? onPortfolioProfitLossPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        if (state.coins.isEmpty) return _buildSpinner();

        final portfolioAssetsOverviewBloc = context.watch<AssetOverviewBloc>();
        final int assetCount = state.walletCoins.length;
        final stateWithData = portfolioAssetsOverviewBloc.state
                is PortfolioAssetsOverviewLoadSuccess
            ? portfolioAssetsOverviewBloc.state
                as PortfolioAssetsOverviewLoadSuccess
            : null;

        return Wrap(
          runSpacing: 16,
          children: [
            FractionallySizedBox(
              widthFactor: isMobile ? 1 : 0.5,
              child: StatisticCard(
                key: const Key('overview-total-balance'),
                caption: Text(LocaleKeys.allTimeInvestment.tr()),
                value: stateWithData?.totalInvestment.value ?? 0,
                actionIcon: const Icon(CustomIcons.fiatIconCircle),
                onPressed: onPortfolioGrowthPressed,
                footer: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pie_chart,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('$assetCount ${LocaleKeys.assets.tr()}'),
                    ],
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: isMobile ? 1 : 0.5,
              child: StatisticCard(
                caption: Text(LocaleKeys.allTimeProfit.tr()),
                value: stateWithData?.profitAmount.value ?? 0,
                footer: TrendPercentageText(
                  investmentReturnPercentage:
                      stateWithData?.profitIncreasePercentage ?? 0,
                ),
                actionIcon: const Icon(Icons.trending_up),
                onPressed: onPortfolioProfitLossPressed,
              ),
            ),
          ],
        );
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
}
