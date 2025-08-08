import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Base class for all StakingCreation events.
///
/// Events represent user actions and external triggers that cause
/// state changes in the staking creation flow.
abstract class StakingCreationEvent extends Equatable {
  const StakingCreationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the staking creation process for a specific asset.
///
/// This event initializes the bloc with the selected asset and
/// loads available validators and basic information.
class StakingCreationStarted extends StakingCreationEvent {
  const StakingCreationStarted({required this.assetId});

  /// The asset to stake.
  final AssetId assetId;

  @override
  List<Object?> get props => [assetId];
}

/// Event to load available validators for the selected asset.
///
/// This event fetches the list of validators and their information
/// to display in the validator selection UI.
class StakingCreationValidatorsRequested extends StakingCreationEvent {
  const StakingCreationValidatorsRequested();
}

/// Event to select a specific validator for delegation.
///
/// This event is triggered when the user selects a validator
/// from the available list.
class StakingCreationValidatorSelected extends StakingCreationEvent {
  const StakingCreationValidatorSelected({required this.validatorAddress});

  /// The address of the selected validator.
  final String validatorAddress;

  @override
  List<Object?> get props => [validatorAddress];
}

/// Event to set the amount to stake.
///
/// This event is triggered when the user enters or modifies
/// the amount they want to stake.
class StakingCreationAmountChanged extends StakingCreationEvent {
  const StakingCreationAmountChanged({required this.amount});

  /// The amount to stake.
  final Decimal amount;

  @override
  List<Object?> get props => [amount];
}

/// Event to validate the current staking configuration.
///
/// This event checks if the current validator selection and
/// amount are valid before allowing submission.
class StakingCreationValidationRequested extends StakingCreationEvent {
  const StakingCreationValidationRequested();
}

/// Event to submit the staking transaction.
///
/// This event initiates the actual delegation transaction
/// with the selected validator and amount.
class StakingCreationSubmitted extends StakingCreationEvent {
  const StakingCreationSubmitted();
}

/// Event to reset the staking creation form.
///
/// This event clears all selections and returns to the initial state.
class StakingCreationReset extends StakingCreationEvent {
  const StakingCreationReset();
}

/// Event to request recommended validators based on user preferences.
///
/// This event fetches validators that match specific criteria
/// like maximum commission rate or minimum uptime.
class StakingCreationRecommendedValidatorsRequested
    extends StakingCreationEvent {
  const StakingCreationRecommendedValidatorsRequested({this.maxCommission});

  /// Optional maximum commission rate filter.
  final Decimal? maxCommission;

  @override
  List<Object?> get props => [maxCommission];
}
