part of 'onboarding_bloc.dart';

/// Base class for all onboarding events.
abstract class OnboardingEvent {
  const OnboardingEvent();
}

/// Event to start the onboarding flow.
class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted({this.isImport = false});

  final bool isImport;
}

/// Event when passcode is created.
class OnboardingPasscodeCreated extends OnboardingEvent {
  const OnboardingPasscodeCreated(this.passcode);

  final String passcode;
}

/// Event when passcode is confirmed.
class OnboardingPasscodeConfirmed extends OnboardingEvent {
  const OnboardingPasscodeConfirmed(this.passcode);

  final String passcode;
}

/// Event when wallet is created and seed needs to be backed up.
class OnboardingWalletCreated extends OnboardingEvent {
  const OnboardingWalletCreated({
    required this.walletName,
    required this.password,
    required this.seedPhrase,
  });

  final String walletName;
  final String password;
  final String seedPhrase;
}

/// Event when user continues from seed backup warning.
class OnboardingSeedWarningAcknowledged extends OnboardingEvent {
  const OnboardingSeedWarningAcknowledged();
}

/// Event when user continues from seed display.
class OnboardingSeedDisplayed extends OnboardingEvent {
  const OnboardingSeedDisplayed();
}

/// Event when user successfully confirms seed backup.
class OnboardingSeedBackupConfirmed extends OnboardingEvent {
  const OnboardingSeedBackupConfirmed();
}

/// Event when user skips or completes biometric setup.
class OnboardingBiometricSetupCompleted extends OnboardingEvent {
  const OnboardingBiometricSetupCompleted({this.enabled = false});

  final bool enabled;
}

/// Event when onboarding is complete.
class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

/// Event to reset onboarding to initial state.
class OnboardingReset extends OnboardingEvent {
  const OnboardingReset();
}

/// Event when user cancels wallet creation during onboarding.
class OnboardingCancelled extends OnboardingEvent {
  const OnboardingCancelled();
}

/// Event to go back to previous step.
class OnboardingStepBack extends OnboardingEvent {
  const OnboardingStepBack();
}
