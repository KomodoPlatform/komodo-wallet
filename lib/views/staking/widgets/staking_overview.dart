import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_bloc.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_state.dart';
import 'package:web_dex/common/screen.dart';

/// Overview widget for staking that displays key metrics and actions.
///
/// This widget provides a high-level view of the user's staking portfolio
/// including total staked amounts, pending rewards, and quick action buttons.
/// Similar to the WalletOverview widget but focused on staking data.
class StakingOverview extends StatelessWidget {
  const StakingOverview({
    super.key,
    this.selectedAssetId,
    this.onStakePressed,
    this.onRewardsPressed,
    this.onDelegationsPressed,
    this.onAssetChanged,
  });

  /// Currently selected asset for staking operations.
  final AssetId? selectedAssetId;

  /// Callback when the stake button is pressed.
  final VoidCallback? onStakePressed;

  /// Callback when the rewards button is pressed.
  final VoidCallback? onRewardsPressed;

  /// Callback when the delegations button is pressed.
  final VoidCallback? onDelegationsPressed;

  /// Callback when the asset selection changes.
  final ValueChanged<AssetId>? onAssetChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedAssetId == null) {
      return _buildEmptyState();
    }

    return BlocBuilder<StakingRewardsBloc, StakingRewardsState>(
      builder: (context, state) {
        return _buildStakingMetrics(state);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.currentGlobal.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance,
            size: 48,
            color: theme.currentGlobal.colorScheme.primary,
          ),
          const Gap(16),
          Text(
            'Staking Overview',
            style: theme.currentGlobal.textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            'Select an asset to view staking information',
            style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
              color: theme.currentGlobal.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStakingMetrics(StakingRewardsState state) {
    final statisticCards = [
      _buildTotalStakedCard(state),
      _buildPendingRewardsCard(state),
      _buildEstimatedAPYCard(state),
    ];

    if (isMobile) {
      return StatisticsCarousel(cards: statisticCards);
    } else {
      return Row(
        children: [
          for (int i = 0; i < statisticCards.length; i++) ...[
            Expanded(child: statisticCards[i]),
            if (i < statisticCards.length - 1) const SizedBox(width: 24),
          ],
        ],
      );
    }
  }

  Widget _buildTotalStakedCard(StakingRewardsState state) {
    final totalStaked = state.totalDelegated.toDouble();

    return StatisticCard(
      value: totalStaked,
      caption: const Text('Total Staked'),
      onTap: onStakePressed,
    );
  }

  Widget _buildPendingRewardsCard(StakingRewardsState state) {
    final pendingRewards = state.totalRewards.toDouble();

    return StatisticCard(
      value: pendingRewards,
      caption: const Text('Pending Rewards'),
      onTap: onRewardsPressed,
    );
  }

  Widget _buildEstimatedAPYCard(StakingRewardsState state) {
    // Mock data for now - would come from actual staking data
    const estimatedAPY = 12.5;

    return StatisticCard(
      value: estimatedAPY,
      caption: const Text('Estimated APY %'),
      onTap: onDelegationsPressed,
      valueFormatter: NumberFormat.decimalPercentPattern(),
    );
  }
}

/// A carousel widget that displays statistics cards with page indicators
/// Copied from wallet_overview.dart for consistency
class StatisticsCarousel extends StatefulWidget {
  final List<Widget> cards;

  const StatisticsCarousel({super.key, required this.cards});

  @override
  State<StatisticsCarousel> createState() => _StatisticsCarouselState();
}

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
