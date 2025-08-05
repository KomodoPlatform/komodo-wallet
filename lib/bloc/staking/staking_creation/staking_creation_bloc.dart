import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/staking/staking_repository.dart';

import 'staking_creation_event.dart';
import 'staking_creation_state.dart';

/// BLoC for managing the staking creation flow.
///
/// This BLoC handles the complete process of creating a new stake/delegation:
/// - Asset selection and initialization
/// - Validator loading and selection
/// - Amount input and validation
/// - Transaction submission
///
/// **Architecture**: Follows the BLoC pattern with clear separation of concerns:
/// - Events represent user actions and external triggers
/// - States represent the current status of the staking creation flow
/// - The BLoC processes events and emits appropriate states
///
/// **Usage Example**:
/// ```dart
/// // Initialize with an asset
/// bloc.add(StakingCreationStarted(assetId: AssetId('ATOM')));
///
/// // Load validators
/// bloc.add(const StakingCreationValidatorsRequested());
///
/// // Select validator and amount
/// bloc.add(StakingCreationValidatorSelected(validatorAddress: 'cosmosvaloper1...'));
/// bloc.add(StakingCreationAmountChanged(amount: Decimal.parse('100')));
///
/// // Validate and submit
/// bloc.add(const StakingCreationValidationRequested());
/// bloc.add(const StakingCreationSubmitted());
/// ```
class StakingCreationBloc
    extends Bloc<StakingCreationEvent, StakingCreationState> {
  /// Creates a new StakingCreationBloc.
  ///
  /// Requires a [StakingRepository] for performing staking operations.
  StakingCreationBloc({required StakingRepository repository})
    : _repository = repository,
      super(StakingCreationState.initial()) {
    // Register event handlers
    on<StakingCreationStarted>(_onStarted);
    on<StakingCreationValidatorsRequested>(_onValidatorsRequested);
    on<StakingCreationValidatorSelected>(_onValidatorSelected);
    on<StakingCreationAmountChanged>(_onAmountChanged);
    on<StakingCreationValidationRequested>(_onValidationRequested);
    on<StakingCreationSubmitted>(_onSubmitted);
    on<StakingCreationReset>(_onReset);
    on<StakingCreationRecommendedValidatorsRequested>(
      _onRecommendedValidatorsRequested,
    );
  }

  final StakingRepository _repository;
  final _log = Logger('StakingCreationBloc');

  /// Handles the StakingCreationStarted event.
  ///
  /// Initializes the bloc with the selected asset and prepares
  /// for the staking creation flow.
  Future<void> _onStarted(
    StakingCreationStarted event,
    Emitter<StakingCreationState> emit,
  ) async {
    try {
      _log.info('Starting staking creation for asset: ${event.assetId}');

      emit(
        state.copyWith(
          status: StakingCreationStatus.initial,
          assetId: event.assetId,
          validators: [],
          recommendedValidators: [],
          selectedValidatorAddress: null,
          amount: null,
          validationResult: null,
          transactionHash: null,
          errorMessage: null,
        ),
      );

      // Automatically load validators for the asset
      add(const StakingCreationValidatorsRequested());

      _log.info('Staking creation initialized for ${event.assetId}');
    } catch (e, stackTrace) {
      _log.severe('Failed to start staking creation', e, stackTrace);
      emit(state.failure('Failed to initialize staking: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationValidatorsRequested event.
  ///
  /// Fetches the list of available validators for the selected asset.
  Future<void> _onValidatorsRequested(
    StakingCreationValidatorsRequested event,
    Emitter<StakingCreationState> emit,
  ) async {
    if (state.assetId == null) {
      emit(state.failure('No asset selected'));
      return;
    }

    try {
      _log.info('Loading validators for asset: ${state.assetId}');
      emit(state.loading());

      final validators = await _repository.getValidators(state.assetId!);

      _log.info('Loaded ${validators.length} validators');
      emit(state.success(validators: validators));
    } catch (e, stackTrace) {
      _log.severe('Failed to load validators', e, stackTrace);
      emit(state.failure('Failed to load validators: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationValidatorSelected event.
  ///
  /// Sets the selected validator for the staking operation.
  Future<void> _onValidatorSelected(
    StakingCreationValidatorSelected event,
    Emitter<StakingCreationState> emit,
  ) async {
    try {
      _log.info('Selected validator: ${event.validatorAddress}');

      emit(
        state.copyWith(
          selectedValidatorAddress: event.validatorAddress,
          validationResult: null, // Clear previous validation
        ),
      );

      // Automatically validate if amount is already set
      if (state.amount != null) {
        add(const StakingCreationValidationRequested());
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to select validator', e, stackTrace);
      emit(state.failure('Failed to select validator: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationAmountChanged event.
  ///
  /// Sets the amount to stake and triggers validation if a validator is selected.
  Future<void> _onAmountChanged(
    StakingCreationAmountChanged event,
    Emitter<StakingCreationState> emit,
  ) async {
    try {
      _log.info('Amount changed to: ${event.amount}');

      emit(
        state.copyWith(
          amount: event.amount,
          validationResult: null, // Clear previous validation
        ),
      );

      // Automatically validate if validator is already selected
      if (state.selectedValidatorAddress != null) {
        add(const StakingCreationValidationRequested());
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to update amount', e, stackTrace);
      emit(state.failure('Failed to update amount: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationValidationRequested event.
  ///
  /// Validates the current staking configuration before submission.
  Future<void> _onValidationRequested(
    StakingCreationValidationRequested event,
    Emitter<StakingCreationState> emit,
  ) async {
    if (state.assetId == null ||
        state.amount == null ||
        state.selectedValidatorAddress == null) {
      emit(
        state.copyWith(
          validationResult: {
            'isValid': false,
            'error': 'Please select asset, validator, and amount',
          },
        ),
      );
      return;
    }

    try {
      _log.info('Validating staking configuration');
      emit(state.copyWith(isValidationInProgress: true));

      final validationResult = await _repository.validateStaking(
        assetId: state.assetId!,
        amount: state.amount!,
        validatorAddress: state.selectedValidatorAddress!,
      );

      _log.info('Validation result: $validationResult');
      emit(
        state.copyWith(
          validationResult: validationResult,
          isValidationInProgress: false,
        ),
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to validate staking', e, stackTrace);
      emit(
        state.copyWith(
          validationResult: {
            'isValid': false,
            'error': 'Validation failed: ${e.toString()}',
          },
          isValidationInProgress: false,
        ),
      );
    }
  }

  /// Handles the StakingCreationSubmitted event.
  ///
  /// Submits the staking transaction with the configured parameters.
  Future<void> _onSubmitted(
    StakingCreationSubmitted event,
    Emitter<StakingCreationState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.failure('Invalid configuration. Please check all fields.'));
      return;
    }

    try {
      _log.info('Submitting staking transaction');
      emit(state.submitting());

      final txHash = await _repository.delegateToValidator(
        assetId: state.assetId!,
        amount: state.amount!,
        validatorAddress: state.selectedValidatorAddress!,
      );

      _log.info('Staking transaction submitted: $txHash');
      emit(state.submitted(txHash));
    } catch (e, stackTrace) {
      _log.severe('Failed to submit staking transaction', e, stackTrace);
      emit(state.failure('Failed to submit transaction: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationReset event.
  ///
  /// Resets the staking creation form to the initial state.
  Future<void> _onReset(
    StakingCreationReset event,
    Emitter<StakingCreationState> emit,
  ) async {
    try {
      _log.info('Resetting staking creation form');
      emit(StakingCreationState.initial());
    } catch (e, stackTrace) {
      _log.severe('Failed to reset form', e, stackTrace);
      emit(state.failure('Failed to reset form: ${e.toString()}'));
    }
  }

  /// Handles the StakingCreationRecommendedValidatorsRequested event.
  ///
  /// Fetches validators that match the specified criteria.
  Future<void> _onRecommendedValidatorsRequested(
    StakingCreationRecommendedValidatorsRequested event,
    Emitter<StakingCreationState> emit,
  ) async {
    if (state.assetId == null) {
      emit(state.failure('No asset selected'));
      return;
    }

    try {
      _log.info(
        'Loading recommended validators with criteria: ${event.maxCommission}',
      );
      emit(state.loading());

      final recommendedValidators = await _repository.getRecommendedValidators(
        assetId: state.assetId!,
        maxCommission: event.maxCommission,
      );

      _log.info(
        'Loaded ${recommendedValidators.length} recommended validators',
      );
      emit(state.success(recommendedValidators: recommendedValidators));
    } catch (e, stackTrace) {
      _log.severe('Failed to load recommended validators', e, stackTrace);
      emit(
        state.failure('Failed to load recommended validators: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> close() {
    _log.info('Closing StakingCreationBloc');
    return super.close();
  }
}
