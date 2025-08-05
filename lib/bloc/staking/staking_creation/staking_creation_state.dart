import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Represents the status of the staking creation flow.
enum StakingCreationStatus {
  /// Initial state - no operations performed yet.
  initial,

  /// Loading validators or performing validation.
  loading,

  /// Successfully loaded data or completed validation.
  success,

  /// An error occurred during the process.
  failure,

  /// Submitting the staking transaction.
  submitting,

  /// Staking transaction completed successfully.
  submitted,
}

/// State for the StakingCreation BLoC.
///
/// This state manages the entire staking creation flow including
/// asset selection, validator selection, amount input, validation,
/// and transaction submission.
class StakingCreationState extends Equatable {
  const StakingCreationState({
    this.status = StakingCreationStatus.initial,
    this.assetId,
    this.validators = const [],
    this.recommendedValidators = const [],
    this.selectedValidatorAddress,
    this.amount,
    this.validationResult,
    this.transactionHash,
    this.errorMessage,
    this.isValidationInProgress = false,
  });

  /// Current status of the staking creation flow.
  final StakingCreationStatus status;

  /// The asset being staked.
  final AssetId? assetId;

  /// List of all available validators for the selected asset.
  final List<ValidatorInfo> validators;

  /// List of recommended validators based on user criteria.
  final List<ValidatorInfo> recommendedValidators;

  /// Address of the currently selected validator.
  final String? selectedValidatorAddress;

  /// Amount to stake.
  final Decimal? amount;

  /// Result of the latest validation check.
  final Map<String, dynamic>? validationResult;

  /// Transaction hash of the submitted staking transaction.
  final String? transactionHash;

  /// Error message if an error occurred.
  final String? errorMessage;

  /// Whether validation is currently in progress.
  final bool isValidationInProgress;

  /// Creates an initial state.
  factory StakingCreationState.initial() => const StakingCreationState();

  /// Creates a loading state.
  StakingCreationState loading() =>
      copyWith(status: StakingCreationStatus.loading);

  /// Creates a success state with optional data.
  StakingCreationState success({
    List<ValidatorInfo>? validators,
    List<ValidatorInfo>? recommendedValidators,
    Map<String, dynamic>? validationResult,
  }) => copyWith(
    status: StakingCreationStatus.success,
    validators: validators,
    recommendedValidators: recommendedValidators,
    validationResult: validationResult,
    errorMessage: null,
  );

  /// Creates a failure state with an error message.
  StakingCreationState failure(String message) =>
      copyWith(status: StakingCreationStatus.failure, errorMessage: message);

  /// Creates a submitting state.
  StakingCreationState submitting() =>
      copyWith(status: StakingCreationStatus.submitting, errorMessage: null);

  /// Creates a submitted state with transaction hash.
  StakingCreationState submitted(String txHash) => copyWith(
    status: StakingCreationStatus.submitted,
    transactionHash: txHash,
    errorMessage: null,
  );

  /// Whether the current configuration is valid for submission.
  bool get canSubmit {
    return assetId != null &&
        selectedValidatorAddress != null &&
        amount != null &&
        amount! > Decimal.zero &&
        validationResult?['isValid'] == true &&
        status != StakingCreationStatus.submitting;
  }

  /// Whether validators are currently being loaded.
  bool get isLoadingValidators =>
      status == StakingCreationStatus.loading && validators.isEmpty;

  /// Whether the form has been completed successfully.
  bool get isCompleted => status == StakingCreationStatus.submitted;

  /// Whether an error occurred.
  bool get hasError => status == StakingCreationStatus.failure;

  /// Gets the selected validator info if available.
  ValidatorInfo? get selectedValidator {
    if (selectedValidatorAddress == null) return null;
    try {
      return validators.firstWhere(
        (v) => v.operatorAddress == selectedValidatorAddress,
      );
    } catch (e) {
      return null;
    }
  }

  /// Creates a copy of this state with updated fields.
  StakingCreationState copyWith({
    StakingCreationStatus? status,
    AssetId? assetId,
    List<ValidatorInfo>? validators,
    List<ValidatorInfo>? recommendedValidators,
    String? selectedValidatorAddress,
    Decimal? amount,
    Map<String, dynamic>? validationResult,
    String? transactionHash,
    String? errorMessage,
    bool? isValidationInProgress,
  }) {
    return StakingCreationState(
      status: status ?? this.status,
      assetId: assetId ?? this.assetId,
      validators: validators ?? this.validators,
      recommendedValidators:
          recommendedValidators ?? this.recommendedValidators,
      selectedValidatorAddress:
          selectedValidatorAddress ?? this.selectedValidatorAddress,
      amount: amount ?? this.amount,
      validationResult: validationResult ?? this.validationResult,
      transactionHash: transactionHash ?? this.transactionHash,
      errorMessage: errorMessage ?? this.errorMessage,
      isValidationInProgress:
          isValidationInProgress ?? this.isValidationInProgress,
    );
  }

  @override
  List<Object?> get props => [
    status,
    assetId,
    validators,
    recommendedValidators,
    selectedValidatorAddress,
    amount,
    validationResult,
    transactionHash,
    errorMessage,
    isValidationInProgress,
  ];
}
