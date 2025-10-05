part of 'onboarding_bloc.dart';

/// Represents the different steps in the onboarding flow.
enum OnboardingStep {
  /// Initial state - show start screen.
  start,

  /// Create 6-digit passcode.
  createPasscode,

  /// Confirm passcode.
  confirmPasscode,

  /// Show seed backup warning.
  seedBackupWarning,

  /// Display seed phrase.
  seedDisplay,

  /// Confirm seed backup with quiz.
  seedConfirmation,

  /// Optional biometric setup.
  biometricSetup,

  /// Wallet is ready - success screen.
  walletReady,

  /// Onboarding complete, ready to enter wallet.
  complete,
}

/// Represents the state of the onboarding flow.
class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.start,
    this.passcode,
    this.walletName,
    this.password,
    this.seedPhrase,
    this.isImport = false,
    this.error,
  });

  /// The current step in the onboarding flow.
  final OnboardingStep currentStep;

  /// The passcode entered by the user (stored temporarily).
  final String? passcode;

  /// The wallet name (stored temporarily during creation).
  final String? walletName;

  /// The wallet password (stored temporarily during creation).
  final String? password;

  /// The seed phrase (stored temporarily during backup flow).
  final String? seedPhrase;

  /// Whether this is an import flow vs create flow.
  final bool isImport;

  /// Error message if any.
  final String? error;

  /// Creates a copy of this state with updated values.
  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? passcode,
    String? walletName,
    String? password,
    String? seedPhrase,
    bool? isImport,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      passcode: passcode ?? this.passcode,
      walletName: walletName ?? this.walletName,
      password: password ?? this.password,
      seedPhrase: seedPhrase ?? this.seedPhrase,
      isImport: isImport ?? this.isImport,
      error: error,
    );
  }

  /// Resets to initial state, clearing all temporary data.
  OnboardingState reset() {
    return const OnboardingState();
  }

  /// Returns true if the current step is after passcode confirmation.
  bool get isPasscodeSet => passcode != null;

  /// Returns true if the current step is during seed backup flow.
  bool get isInSeedBackupFlow =>
      currentStep == OnboardingStep.seedBackupWarning ||
      currentStep == OnboardingStep.seedDisplay ||
      currentStep == OnboardingStep.seedConfirmation;

  @override
  String toString() {
    return 'OnboardingState(currentStep: $currentStep, '
        'hasPasscode: ${passcode != null}, '
        'hasWalletData: ${walletName != null}, '
        'hasSeed: ${seedPhrase != null}, '
        'isImport: $isImport, '
        'error: $error)';
  }
}
