import 'package:flutter_bloc/flutter_bloc.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// BLoC that manages the onboarding flow state and navigation.
///
/// This BLoC coordinates the multi-step onboarding process including:
/// - Start screen
/// - Passcode creation and confirmation
/// - Seed backup (warning, display, confirmation)
/// - Biometric setup
/// - Wallet ready screen
///
/// It stores temporary state data during the onboarding flow and emits
/// state changes to update the UI accordingly.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingPasscodeCreated>(_onPasscodeCreated);
    on<OnboardingPasscodeConfirmed>(_onPasscodeConfirmed);
    on<OnboardingWalletCreated>(_onWalletCreated);
    on<OnboardingSeedWarningAcknowledged>(_onSeedWarningAcknowledged);
    on<OnboardingSeedDisplayed>(_onSeedDisplayed);
    on<OnboardingSeedBackupConfirmed>(_onSeedBackupConfirmed);
    on<OnboardingBiometricSetupCompleted>(_onBiometricSetupCompleted);
    on<OnboardingCompleted>(_onCompleted);
    on<OnboardingReset>(_onReset);
    on<OnboardingCancelled>(_onCancelled);
    on<OnboardingStepBack>(_onStepBack);
  }

  void _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) {
    emit(
      state.copyWith(
        currentStep: event.isImport
            ? OnboardingStep
                  .complete // Import goes directly to wallet creation
            : OnboardingStep.createPasscode,
        isImport: event.isImport,
      ),
    );
  }

  void _onPasscodeCreated(
    OnboardingPasscodeCreated event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        currentStep: OnboardingStep.confirmPasscode,
        passcode: event.passcode,
      ),
    );
  }

  void _onPasscodeConfirmed(
    OnboardingPasscodeConfirmed event,
    Emitter<OnboardingState> emit,
  ) {
    // After passcode confirmation, proceed to wallet creation form
    // The actual wallet creation happens in iguana_wallets_manager
    emit(
      state.copyWith(
        currentStep: OnboardingStep.complete, // Let wallet manager take over
      ),
    );
  }

  void _onWalletCreated(
    OnboardingWalletCreated event,
    Emitter<OnboardingState> emit,
  ) {
    // Wallet has been created, now start seed backup flow
    emit(
      state.copyWith(
        currentStep: OnboardingStep.seedBackupWarning,
        walletName: event.walletName,
        password: event.password,
        seedPhrase: event.seedPhrase,
      ),
    );
  }

  void _onSeedWarningAcknowledged(
    OnboardingSeedWarningAcknowledged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(currentStep: OnboardingStep.seedDisplay));
  }

  void _onSeedDisplayed(
    OnboardingSeedDisplayed event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(currentStep: OnboardingStep.seedConfirmation));
  }

  void _onSeedBackupConfirmed(
    OnboardingSeedBackupConfirmed event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        currentStep: OnboardingStep.biometricSetup,
        // Clear seed phrase from memory after confirmation
        seedPhrase: null,
        password: null,
      ),
    );
  }

  void _onBiometricSetupCompleted(
    OnboardingBiometricSetupCompleted event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(currentStep: OnboardingStep.walletReady));
  }

  void _onCompleted(OnboardingCompleted event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(currentStep: OnboardingStep.complete));
  }

  void _onReset(OnboardingReset event, Emitter<OnboardingState> emit) {
    emit(state.reset());
  }

  void _onCancelled(OnboardingCancelled event, Emitter<OnboardingState> emit) {
    // Clear sensitive data
    emit(state.reset());
  }

  void _onStepBack(OnboardingStepBack event, Emitter<OnboardingState> emit) {
    // Navigate back to previous step based on current step
    OnboardingStep? previousStep;

    switch (state.currentStep) {
      case OnboardingStep.confirmPasscode:
        previousStep = OnboardingStep.createPasscode;
        break;
      case OnboardingStep.seedDisplay:
        previousStep = OnboardingStep.seedBackupWarning;
        break;
      case OnboardingStep.seedConfirmation:
        previousStep = OnboardingStep.seedDisplay;
        break;
      case OnboardingStep.biometricSetup:
        // Cannot go back after seed confirmation
        previousStep = null;
        break;
      case OnboardingStep.walletReady:
        // Cannot go back from success screen
        previousStep = null;
        break;
      default:
        previousStep = null;
    }

    if (previousStep != null) {
      emit(state.copyWith(currentStep: previousStep));
    }
  }
}
