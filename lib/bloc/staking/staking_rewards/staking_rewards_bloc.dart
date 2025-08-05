import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/staking/staking_repository.dart';

import 'staking_rewards_event.dart';
import 'staking_rewards_state.dart';

/// BLoC for managing staking rewards viewing and claiming.
///
/// This BLoC handles the complete process of viewing and claiming staking rewards:
/// - Loading delegation information and reward amounts
/// - Displaying rewards breakdown by validator
/// - Claiming rewards from specific validators
/// - Claiming all available rewards
///
/// **Architecture**: Follows the BLoC pattern with clear separation of concerns:
/// - Events represent user actions like viewing rewards or claiming
/// - States represent the current status of rewards and claiming operations
/// - The BLoC processes events and emits appropriate states
///
/// **Usage Example**:
/// ```dart
/// // Initialize with an asset
/// bloc.add(StakingRewardsStarted(assetId: AssetId('ATOM')));
///
/// // Refresh rewards data
/// bloc.add(const StakingRewardsRefreshRequested());
///
/// // Claim from specific validator
/// bloc.add(StakingRewardsClaimRequested(validatorAddress: 'cosmosvaloper1...'));
///
/// // Claim all rewards
/// bloc.add(const StakingRewardsClaimAllRequested());
/// ```
class StakingRewardsBloc
    extends Bloc<StakingRewardsEvent, StakingRewardsState> {
  /// Creates a new StakingRewardsBloc.
  ///
  /// Requires a [StakingRepository] for performing rewards operations.
  StakingRewardsBloc({required StakingRepository repository})
    : _repository = repository,
      super(StakingRewardsState.initial()) {
    // Register event handlers
    on<StakingRewardsStarted>(_onStarted);
    on<StakingRewardsRefreshRequested>(_onRefreshRequested);
    on<StakingRewardsClaimRequested>(_onClaimRequested);
    on<StakingRewardsClaimAllRequested>(_onClaimAllRequested);
    on<StakingRewardsReset>(_onReset);
  }

  final StakingRepository _repository;
  final _log = Logger('StakingRewardsBloc');

  /// Handles the StakingRewardsStarted event.
  ///
  /// Initializes the bloc with the selected asset and loads
  /// current delegations and rewards.
  Future<void> _onStarted(
    StakingRewardsStarted event,
    Emitter<StakingRewardsState> emit,
  ) async {
    try {
      _log.info('Starting staking rewards for asset: ${event.assetId}');

      emit(
        state.copyWith(
          status: StakingRewardsStatus.initial,
          assetId: event.assetId,
          validatorRewards: [],
          totalDelegated: Decimal.zero,
          totalRewards: Decimal.zero,
          errorMessage: null,
        ),
      );

      // Automatically load rewards data
      add(const StakingRewardsRefreshRequested());

      _log.info('Staking rewards initialized for ${event.assetId}');
    } catch (e, stackTrace) {
      _log.severe('Failed to start staking rewards', e, stackTrace);
      emit(state.failure('Failed to initialize rewards: ${e.toString()}'));
    }
  }

  /// Handles the StakingRewardsRefreshRequested event.
  ///
  /// Fetches the latest delegation information and reward amounts.
  Future<void> _onRefreshRequested(
    StakingRewardsRefreshRequested event,
    Emitter<StakingRewardsState> emit,
  ) async {
    if (state.assetId == null) {
      emit(state.failure('No asset selected'));
      return;
    }

    try {
      _log.info('Refreshing rewards for asset: ${state.assetId}');
      emit(state.loading());

      // Get delegation information which includes rewards
      final delegations = await _repository.getDelegations(state.assetId!);

      // Convert delegations to validator rewards
      final validatorRewards = delegations.map((delegation) {
        return ValidatorRewards(
          validatorAddress: delegation.validatorAddress,
          delegatedAmount: Decimal.parse(delegation.delegatedAmount),
          rewardAmount: Decimal.parse(delegation.rewardAmount),
        );
      }).toList();

      // Calculate totals
      final totalDelegated = validatorRewards.fold<Decimal>(
        Decimal.zero,
        (total, reward) => total + reward.delegatedAmount,
      );

      final totalRewards = validatorRewards.fold<Decimal>(
        Decimal.zero,
        (total, reward) => total + reward.rewardAmount,
      );

      _log.info(
        'Loaded rewards: ${validatorRewards.length} validators, '
        'total delegated: $totalDelegated, total rewards: $totalRewards',
      );

      emit(
        state.success(
          validatorRewards: validatorRewards,
          totalDelegated: totalDelegated,
          totalRewards: totalRewards,
        ),
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to refresh rewards', e, stackTrace);
      emit(state.failure('Failed to load rewards: ${e.toString()}'));
    }
  }

  /// Handles the StakingRewardsClaimRequested event.
  ///
  /// Claims rewards from a specific validator.
  Future<void> _onClaimRequested(
    StakingRewardsClaimRequested event,
    Emitter<StakingRewardsState> emit,
  ) async {
    if (state.assetId == null) {
      emit(state.failure('No asset selected'));
      return;
    }

    // Check if this validator has rewards to claim
    final validatorReward = state.validatorRewards.firstWhere(
      (reward) => reward.validatorAddress == event.validatorAddress,
      orElse: () => throw Exception('Validator not found in rewards list'),
    );

    if (!validatorReward.hasRewards) {
      emit(state.failure('No rewards available for this validator'));
      return;
    }

    try {
      _log.info('Claiming rewards from validator: ${event.validatorAddress}');
      emit(state.claiming(event.validatorAddress));

      final txHash = await _repository.claimRewardsFromValidator(
        assetId: state.assetId!,
        validatorAddress: event.validatorAddress,
      );

      _log.info('Rewards claimed successfully: $txHash');
      emit(state.claimed(txHash));

      // Refresh rewards data after successful claim
      add(const StakingRewardsRefreshRequested());
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to claim rewards from ${event.validatorAddress}',
        e,
        stackTrace,
      );
      emit(state.failure('Failed to claim rewards: ${e.toString()}'));
    }
  }

  /// Handles the StakingRewardsClaimAllRequested event.
  ///
  /// Claims all available rewards from all validators.
  Future<void> _onClaimAllRequested(
    StakingRewardsClaimAllRequested event,
    Emitter<StakingRewardsState> emit,
  ) async {
    if (state.assetId == null) {
      emit(state.failure('No asset selected'));
      return;
    }

    if (!state.hasRewardsToClaim) {
      emit(state.failure('No rewards available to claim'));
      return;
    }

    try {
      _log.info('Claiming all rewards for asset: ${state.assetId}');
      emit(state.claimingAll());

      final claimableRewards = state.claimableRewards;
      String? lastTxHash;

      // Claim from each validator with rewards
      for (final validatorReward in claimableRewards) {
        try {
          final txHash = await _repository.claimRewardsFromValidator(
            assetId: state.assetId!,
            validatorAddress: validatorReward.validatorAddress,
          );
          lastTxHash = txHash;
          _log.info(
            'Claimed from ${validatorReward.validatorAddress}: $txHash',
          );
        } catch (e) {
          _log.warning(
            'Failed to claim from ${validatorReward.validatorAddress}: $e',
          );
          // Continue with other validators even if one fails
        }
      }

      if (lastTxHash != null) {
        _log.info('All rewards claimed successfully');
        emit(state.claimed(lastTxHash));

        // Refresh rewards data after successful claims
        add(const StakingRewardsRefreshRequested());
      } else {
        emit(state.failure('Failed to claim rewards from any validator'));
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to claim all rewards', e, stackTrace);
      emit(state.failure('Failed to claim all rewards: ${e.toString()}'));
    }
  }

  /// Handles the StakingRewardsReset event.
  ///
  /// Resets the rewards view to the initial state.
  Future<void> _onReset(
    StakingRewardsReset event,
    Emitter<StakingRewardsState> emit,
  ) async {
    try {
      _log.info('Resetting staking rewards');
      emit(StakingRewardsState.initial());
    } catch (e, stackTrace) {
      _log.severe('Failed to reset rewards', e, stackTrace);
      emit(state.failure('Failed to reset: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _log.info('Closing StakingRewardsBloc');
    return super.close();
  }
}
