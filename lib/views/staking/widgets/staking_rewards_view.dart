import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_bloc.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_event.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_state.dart';

/// Widget for viewing and claiming staking rewards.
///
/// This widget provides a user interface for:
/// - Viewing accumulated rewards
/// - Claiming rewards from specific validators
/// - Claiming all available rewards
/// - Refreshing reward data
class StakingRewardsView extends StatefulWidget {
  const StakingRewardsView({super.key, required this.assetId});

  final AssetId assetId;

  @override
  State<StakingRewardsView> createState() => _StakingRewardsViewState();
}

class _StakingRewardsViewState extends State<StakingRewardsView> {
  @override
  void initState() {
    super.initState();
    // Note: Rewards are automatically loaded when the bloc is initialized with StakingRewardsStarted
    // in the parent StakingPage, so we don't need to manually refresh here.
  }

  void _onClaimRewards(String validatorAddress) {
    context.read<StakingRewardsBloc>().add(
      StakingRewardsClaimRequested(validatorAddress: validatorAddress),
    );
  }

  void _onClaimAllRewards() {
    context.read<StakingRewardsBloc>().add(
      const StakingRewardsClaimAllRequested(),
    );
  }

  void _onRefresh() {
    context.read<StakingRewardsBloc>().add(
      const StakingRewardsRefreshRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StakingRewardsBloc, StakingRewardsState>(
      listener: (context, state) {
        if (state.status == StakingRewardsStatus.success &&
            state.lastClaimTransactionHash != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Rewards claimed successfully!'),
              backgroundColor: theme.currentGlobal.colorScheme.primary,
            ),
          );
        } else if (state.status == StakingRewardsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An unknown error occurred'),
              backgroundColor: theme.currentGlobal.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Gap(24),
            _buildRefreshSection(state),
            const Gap(24),
            _buildOverviewSection(state),
            const Gap(24),
            _buildRewardsListSection(state),
            const Gap(24),
            _buildClaimAllSection(state),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(
            color: theme.currentGlobal.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.monetization_on,
            color: theme.currentGlobal.colorScheme.primary,
            size: 24,
          ),
          const Gap(12),
          Text(
            'Staking Rewards',
            style: theme.currentGlobal.textTheme.headlineSmall?.copyWith(
              color: theme.currentGlobal.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshSection(StakingRewardsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Rewards Data', style: theme.currentGlobal.textTheme.titleMedium),
        UiSecondaryButton(
          onPressed: state.isLoading ? null : _onRefresh,
          text: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildOverviewSection(StakingRewardsState state) {
    if (state.isLoading) {
      return const Center(child: UiSpinner());
    }

    if (state.hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.currentGlobal.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          state.errorMessage ?? 'An unknown error occurred',
          style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
            color: theme.currentGlobal.colorScheme.error,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Delegated',
                style: theme.currentGlobal.textTheme.bodyMedium,
              ),
              Text(
                state.totalDelegated.toString(),
                style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Rewards',
                style: theme.currentGlobal.textTheme.bodyMedium,
              ),
              Text(
                state.totalRewards.toString(),
                style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.currentGlobal.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsListSection(StakingRewardsState state) {
    if (state.validatorRewards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.currentGlobal.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: theme.currentGlobal.colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              'No rewards available',
              style: theme.currentGlobal.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards by Validator',
          style: theme.currentGlobal.textTheme.titleMedium,
        ),
        const Gap(16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.validatorRewards.length,
          separatorBuilder: (context, index) => const Gap(8),
          itemBuilder: (context, index) {
            final validatorReward = state.validatorRewards[index];
            return _buildValidatorRewardTile(validatorReward, state);
          },
        ),
      ],
    );
  }

  Widget _buildValidatorRewardTile(
    ValidatorRewards validatorReward,
    StakingRewardsState state,
  ) {
    final isClaimingFromThisValidator =
        state.claimingFromValidator == validatorReward.validatorAddress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.currentGlobal.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  validatorReward.validatorAddress,
                  style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              UiSecondaryButton(
                onPressed: isClaimingFromThisValidator
                    ? null
                    : () => _onClaimRewards(validatorReward.validatorAddress),
                text: isClaimingFromThisValidator ? 'Claiming...' : 'Claim',
              ),
            ],
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delegated', style: theme.currentGlobal.textTheme.bodySmall),
              Text(
                validatorReward.delegatedAmount.toStringAsFixed(2),
                style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rewards', style: theme.currentGlobal.textTheme.bodySmall),
              Text(
                validatorReward.rewardAmount.toStringAsFixed(2),
                style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.currentGlobal.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimAllSection(StakingRewardsState state) {
    final hasRewards = state.hasRewardsToClaim;
    final isClaiming = state.isClaiming;
    final isClaimingAll = state.status == StakingRewardsStatus.claimingAll;

    return SizedBox(
      width: double.infinity,
      child: UiPrimaryButton(
        onPressed: hasRewards && !isClaiming && !isClaimingAll
            ? _onClaimAllRewards
            : null,
        text: isClaimingAll ? 'Claiming All...' : 'Claim All Rewards',
      ),
    );
  }
}
