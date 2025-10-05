import 'package:web_dex/bloc/analytics/analytics_repo.dart';

// ONBOARDING & AUTHENTICATION FLOW EVENTS
//============================================================

/// Event when passcode is created during onboarding.
class PasscodeCreatedEventData extends AnalyticsEventData {
  const PasscodeCreatedEventData();

  @override
  String get name => 'passcode_created';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when biometric authentication is enabled.
class BiometricEnabledEventData extends AnalyticsEventData {
  const BiometricEnabledEventData({required this.biometricType});

  final String biometricType;

  @override
  String get name => 'biometric_enabled';

  @override
  Map<String, Object> get parameters => {'biometric_type': biometricType};
}

/// Event when biometric setup is skipped.
class BiometricSkippedEventData extends AnalyticsEventData {
  const BiometricSkippedEventData();

  @override
  String get name => 'biometric_skipped';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when seed backup warning is shown.
class SeedBackupWarningShownEventData extends AnalyticsEventData {
  const SeedBackupWarningShownEventData();

  @override
  String get name => 'seed_backup_warning_shown';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when seed phrase is displayed to user.
class SeedDisplayedEventData extends AnalyticsEventData {
  const SeedDisplayedEventData();

  @override
  String get name => 'seed_displayed';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when seed confirmation is started.
class SeedConfirmationStartedEventData extends AnalyticsEventData {
  const SeedConfirmationStartedEventData();

  @override
  String get name => 'seed_confirmation_started';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when seed confirmation fails.
class SeedConfirmationFailedEventData extends AnalyticsEventData {
  const SeedConfirmationFailedEventData({required this.attemptsRemaining});

  final int attemptsRemaining;

  @override
  String get name => 'seed_confirmation_failed';

  @override
  Map<String, Object> get parameters => {
    'attempts_remaining': attemptsRemaining,
  };
}

/// Event when seed confirmation succeeds.
class SeedConfirmationSuccessEventData extends AnalyticsEventData {
  const SeedConfirmationSuccessEventData();

  @override
  String get name => 'seed_confirmation_success';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when backup banner is shown to user.
class BackupBannerShownEventData extends AnalyticsEventData {
  const BackupBannerShownEventData();

  @override
  String get name => 'backup_banner_shown';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when backup banner action is clicked.
class BackupBannerActionClickedEventData extends AnalyticsEventData {
  const BackupBannerActionClickedEventData();

  @override
  String get name => 'backup_banner_action_clicked';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when backup banner is dismissed.
class BackupBannerDismissedEventData extends AnalyticsEventData {
  const BackupBannerDismissedEventData();

  @override
  String get name => 'backup_banner_dismissed';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when start screen is shown.
class StartScreenShownEventData extends AnalyticsEventData {
  const StartScreenShownEventData();

  @override
  String get name => 'start_screen_shown';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when wallet ready screen is shown.
class WalletReadyShownEventData extends AnalyticsEventData {
  const WalletReadyShownEventData();

  @override
  String get name => 'wallet_ready_shown';

  @override
  Map<String, Object> get parameters => {};
}

/// Event when onboarding step is completed.
class OnboardingStepCompletedEventData extends AnalyticsEventData {
  const OnboardingStepCompletedEventData({required this.step});

  final String step;

  @override
  String get name => 'onboarding_step_completed';

  @override
  Map<String, Object> get parameters => {'step': step};
}

/// Event when onboarding is abandoned.
class OnboardingAbandonedEventData extends AnalyticsEventData {
  const OnboardingAbandonedEventData({required this.step});

  final String step;

  @override
  String get name => 'onboarding_abandoned';

  @override
  Map<String, Object> get parameters => {'step': step};
}

/// Event when onboarding is completed.
class OnboardingCompletedEventData extends AnalyticsEventData {
  const OnboardingCompletedEventData({
    required this.method,
    required this.durationMs,
  });

  final String method;
  final int durationMs;

  @override
  String get name => 'onboarding_completed';

  @override
  Map<String, Object> get parameters => {
    'method': method,
    'duration_ms': durationMs,
  };
}
