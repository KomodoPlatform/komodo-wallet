import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Represents the status of the staking rewards flow.
enum StakingRewardsStatus {
  /// Initial state - no operations performed yet.
  initial,

  /// Loading delegations or rewards data.
  loading,

  /// Successfully loaded data.
  success,

  /// An error occurred during the process.
  failure,

  /// Claiming rewards from a specific validator.
  claiming,

  /// Claiming rewards from all validators.
  claimingAll,

  /// Rewards claim completed successfully.
  claimed,
}

/// Information about rewards from a specific validator.
class ValidatorRewards extends Equatable {
  const ValidatorRewards({
    required this.validatorAddress,
    required this.delegatedAmount,
    required this.rewardAmount,
    this.validatorInfo,
  });

  /// The validator's operator address.
  final String validatorAddress;

  /// Amount currently delegated to this validator.
  final Decimal delegatedAmount;

  /// Pending reward amount from this validator.
  final Decimal rewardAmount;

  /// Optional validator information for display.
  final ValidatorInfo? validatorInfo;

  /// Whether this validator has claimable rewards.
  bool get hasRewards => rewardAmount > Decimal.zero;

  @override
  List<Object?> get props => [
    validatorAddress,
    delegatedAmount,
    rewardAmount,
    validatorInfo,
  ];
}

/// State for the StakingRewards BLoC.
///
/// This state manages the rewards viewing and claiming flow including
/// delegation information, reward amounts, and claim operations.
class StakingRewardsState extends Equatable {
  const StakingRewardsState({
    this.status = StakingRewardsStatus.initial,
    this.assetId,
    this.validatorRewards = const [],
    required this.totalDelegated,
    required this.totalRewards,
    this.claimingFromValidator,
    this.lastClaimTransactionHash,
    this.errorMessage,
    this.lastUpdated,
  });

  /// Current status of the staking rewards flow.
  final StakingRewardsStatus status;

  /// The asset being viewed.
  final AssetId? assetId;

  /// List of rewards from each validator.
  final List<ValidatorRewards> validatorRewards;

  /// Total amount delegated across all validators.
  final Decimal totalDelegated;

  /// Total pending rewards across all validators.
  final Decimal totalRewards;

  /// Validator address currently being claimed from (if any).
  final String? claimingFromValidator;

  /// Transaction hash of the last successful claim.
  final String? lastClaimTransactionHash;

  /// Error message if an error occurred.
  final String? errorMessage;

  /// When the data was last updated.
  final DateTime? lastUpdated;

  /// Creates an initial state.
  factory StakingRewardsState.initial() => StakingRewardsState(
    status: StakingRewardsStatus.initial,
    totalDelegated: Decimal.zero,
    totalRewards: Decimal.zero,
  );

  /// Creates a loading state.
  StakingRewardsState loading() =>
      copyWith(status: StakingRewardsStatus.loading);

  /// Creates a success state with rewards data.
  StakingRewardsState success({
    required List<ValidatorRewards> validatorRewards,
    required Decimal totalDelegated,
    required Decimal totalRewards,
  }) => copyWith(
    status: StakingRewardsStatus.success,
    validatorRewards: validatorRewards,
    totalDelegated: totalDelegated,
    totalRewards: totalRewards,
    lastUpdated: DateTime.now(),
    errorMessage: null,
  );

  /// Creates a failure state with an error message.
  StakingRewardsState failure(String message) =>
      copyWith(status: StakingRewardsStatus.failure, errorMessage: message);

  /// Creates a claiming state for a specific validator.
  StakingRewardsState claiming(String validatorAddress) => copyWith(
    status: StakingRewardsStatus.claiming,
    claimingFromValidator: validatorAddress,
    errorMessage: null,
  );

  /// Creates a claiming all state.
  StakingRewardsState claimingAll() => copyWith(
    status: StakingRewardsStatus.claimingAll,
    claimingFromValidator: null,
    errorMessage: null,
  );

  /// Creates a claimed state with transaction hash.
  StakingRewardsState claimed(String txHash) => copyWith(
    status: StakingRewardsStatus.claimed,
    lastClaimTransactionHash: txHash,
    claimingFromValidator: null,
    errorMessage: null,
  );

  /// Whether there are any rewards available for claiming.
  bool get hasRewardsToClaim => totalRewards > Decimal.zero;

  /// Whether data is currently being loaded.
  bool get isLoading => status == StakingRewardsStatus.loading;

  /// Whether a claim operation is in progress.
  bool get isClaiming =>
      status == StakingRewardsStatus.claiming ||
      status == StakingRewardsStatus.claimingAll;

  /// Whether the operation completed successfully.
  bool get isSuccess => status == StakingRewardsStatus.success;

  /// Whether an error occurred.
  bool get hasError => status == StakingRewardsStatus.failure;

  /// Whether a claim was just completed.
  bool get justClaimed => status == StakingRewardsStatus.claimed;

  /// Number of validators with pending rewards.
  int get validatorsWithRewards =>
      validatorRewards.where((v) => v.hasRewards).length;

  /// List of validator rewards that have claimable amounts.
  List<ValidatorRewards> get claimableRewards =>
      validatorRewards.where((v) => v.hasRewards).toList();

  /// Creates a copy of this state with updated fields.
  StakingRewardsState copyWith({
    StakingRewardsStatus? status,
    AssetId? assetId,
    List<ValidatorRewards>? validatorRewards,
    Decimal? totalDelegated,
    Decimal? totalRewards,
    String? claimingFromValidator,
    String? lastClaimTransactionHash,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return StakingRewardsState(
      status: status ?? this.status,
      assetId: assetId ?? this.assetId,
      validatorRewards: validatorRewards ?? this.validatorRewards,
      totalDelegated: totalDelegated ?? this.totalDelegated,
      totalRewards: totalRewards ?? this.totalRewards,
      claimingFromValidator:
          claimingFromValidator ?? this.claimingFromValidator,
      lastClaimTransactionHash:
          lastClaimTransactionHash ?? this.lastClaimTransactionHash,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    status,
    assetId,
    validatorRewards,
    totalDelegated,
    totalRewards,
    claimingFromValidator,
    lastClaimTransactionHash,
    errorMessage,
    lastUpdated,
  ];
}
