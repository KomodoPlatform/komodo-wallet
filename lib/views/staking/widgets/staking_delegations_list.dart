import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_bloc.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_event.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_state.dart';

/// Widget for displaying and managing active staking delegations.
///
/// This widget provides a user interface for:
/// - Viewing current delegations to validators
/// - Displaying delegation amounts and rewards
/// - Managing delegations (unstaking, claiming rewards)
class StakingDelegationsList extends StatefulWidget {
  const StakingDelegationsList({super.key, required this.assetId});

  final AssetId assetId;

  @override
  State<StakingDelegationsList> createState() => _StakingDelegationsListState();
}

class _StakingDelegationsListState extends State<StakingDelegationsList> {
  @override
  void initState() {
    super.initState();
    // Load delegations when the widget is initialized
    context.read<StakingRewardsBloc>().add(
      StakingRewardsStarted(assetId: widget.assetId),
    );
  }

  void _onRefresh() {
    context.read<StakingRewardsBloc>().add(
      const StakingRewardsRefreshRequested(),
    );
  }

  void _onClaimRewards(String validatorAddress) {
    context.read<StakingRewardsBloc>().add(
      StakingRewardsClaimRequested(validatorAddress: validatorAddress),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StakingRewardsBloc, StakingRewardsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState();
        }

        if (state.hasError) {
          return _buildErrorState(state.errorMessage ?? 'Unknown error');
        }

        if (state.validatorRewards.isEmpty) {
          return _buildEmptyState();
        }

        return _buildDelegationsList(state);
      },
    );
  }

  Widget _buildLoadingState() {
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
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [UiSpinner(), Gap(16), Text('Loading delegations...')],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.currentGlobal.colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.currentGlobal.colorScheme.error,
          ),
          const Gap(16),
          Text(
            'Failed to Load Delegations',
            style: theme.currentGlobal.textTheme.titleMedium?.copyWith(
              color: theme.currentGlobal.colorScheme.error,
            ),
          ),
          const Gap(8),
          Text(
            errorMessage,
            style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
              color: theme.currentGlobal.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          UiSecondaryButton(onPressed: _onRefresh, text: 'Retry'),
        ],
      ),
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
            color: theme.currentGlobal.colorScheme.onSurfaceVariant,
          ),
          const Gap(16),
          Text(
            'No Active Delegations',
            style: theme.currentGlobal.textTheme.titleMedium,
          ),
          const Gap(8),
          Text(
            'You haven\'t delegated any ${widget.assetId.symbol.assetConfigId} yet. Start by creating your first delegation.',
            style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
              color: theme.currentGlobal.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          UiSecondaryButton(onPressed: _onRefresh, text: 'Refresh'),
        ],
      ),
    );
  }

  Widget _buildDelegationsList(StakingRewardsState state) {
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
              Text(
                'Active Delegations',
                style: theme.currentGlobal.textTheme.titleMedium?.copyWith(
                  color: theme.currentGlobal.colorScheme.onSurface,
                ),
              ),
              UiSecondaryButton(onPressed: _onRefresh, text: 'Refresh'),
            ],
          ),
          const Gap(16),
          if (state.lastUpdated != null) ...[
            Text(
              'Last updated: ${_formatLastUpdated(state.lastUpdated!)}',
              style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
                color: theme.currentGlobal.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(16),
          ],
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.validatorRewards.length,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              final delegation = state.validatorRewards[index];
              return _buildDelegationTile(delegation, state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDelegationTile(
    ValidatorRewards delegation,
    StakingRewardsState state,
  ) {
    final isClaimingFromThisValidator =
        state.claimingFromValidator == delegation.validatorAddress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validator',
                      style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
                        color: theme.currentGlobal.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      delegation.validatorInfo?.description.moniker ??
                          _formatValidatorAddress(delegation.validatorAddress),
                      style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (delegation.hasRewards)
                UiSecondaryButton(
                  onPressed: isClaimingFromThisValidator
                      ? null
                      : () => _onClaimRewards(delegation.validatorAddress),
                  text: isClaimingFromThisValidator ? 'Claiming...' : 'Claim',
                ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  'Delegated Amount',
                  '${delegation.delegatedAmount.toStringAsFixed(6)} ${widget.assetId.symbol.assetConfigId}',
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Pending Rewards',
                  '${delegation.rewardAmount.toStringAsFixed(6)} ${widget.assetId.symbol.assetConfigId}',
                  isHighlighted: delegation.hasRewards,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
            color: theme.currentGlobal.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? theme.currentGlobal.colorScheme.primary
                : theme.currentGlobal.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatValidatorAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
