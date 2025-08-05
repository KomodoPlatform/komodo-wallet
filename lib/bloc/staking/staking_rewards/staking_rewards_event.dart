import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Base class for all StakingRewards events.
///
/// Events represent user actions and external triggers that cause
/// state changes in the staking rewards flow.
abstract class StakingRewardsEvent extends Equatable {
  const StakingRewardsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the staking rewards process for a specific asset.
///
/// This event initializes the bloc with the selected asset and
/// loads current delegations and pending rewards.
class StakingRewardsStarted extends StakingRewardsEvent {
  const StakingRewardsStarted({required this.assetId});

  /// The asset to check rewards for.
  final AssetId assetId;

  @override
  List<Object?> get props => [assetId];
}

/// Event to refresh rewards data.
///
/// This event fetches the latest delegation information and
/// reward amounts from the blockchain.
class StakingRewardsRefreshRequested extends StakingRewardsEvent {
  const StakingRewardsRefreshRequested();
}

/// Event to claim rewards from a specific validator.
///
/// This event initiates the claim transaction for rewards
/// accumulated from a particular validator.
class StakingRewardsClaimRequested extends StakingRewardsEvent {
  const StakingRewardsClaimRequested({required this.validatorAddress});

  /// The validator to claim rewards from.
  final String validatorAddress;

  @override
  List<Object?> get props => [validatorAddress];
}

/// Event to claim all available rewards.
///
/// This event claims rewards from all validators that have
/// accumulated rewards for the user.
class StakingRewardsClaimAllRequested extends StakingRewardsEvent {
  const StakingRewardsClaimAllRequested();
}

/// Event to reset the rewards view.
///
/// This event clears all loaded data and returns to the initial state.
class StakingRewardsReset extends StakingRewardsEvent {
  const StakingRewardsReset();
}
