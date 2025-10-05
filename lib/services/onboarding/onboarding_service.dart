import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing onboarding state and first-launch detection.
///
/// Tracks whether the user has completed onboarding and seen the start screen.
class OnboardingService {
  OnboardingService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _hasSeenStartScreenKey = 'app_has_seen_start_screen';
  static const String _hasCompletedOnboardingKey =
      'app_has_completed_onboarding';
  static const String _firstLaunchDateKey = 'app_first_launch_date';

  /// Checks if the user has seen the start screen.
  Future<bool> hasSeenStartScreen() async {
    try {
      final seen = await _storage.read(key: _hasSeenStartScreenKey);
      return seen == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Marks the start screen as seen.
  Future<void> markStartScreenSeen() async {
    await _storage.write(key: _hasSeenStartScreenKey, value: 'true');

    // Also record first launch date if not set
    final firstLaunch = await _storage.read(key: _firstLaunchDateKey);
    if (firstLaunch == null) {
      await _storage.write(
        key: _firstLaunchDateKey,
        value: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Checks if the user has completed the full onboarding flow.
  Future<bool> hasCompletedOnboarding() async {
    try {
      final completed = await _storage.read(key: _hasCompletedOnboardingKey);
      return completed == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Marks onboarding as complete.
  Future<void> markOnboardingComplete() async {
    await _storage.write(key: _hasCompletedOnboardingKey, value: 'true');
  }

  /// Checks if this is the first app launch.
  ///
  /// Returns true if the user has never seen the start screen or completed onboarding.
  Future<bool> isFirstLaunch() async {
    final seenStart = await hasSeenStartScreen();
    final completedOnboarding = await hasCompletedOnboarding();
    return !seenStart && !completedOnboarding;
  }

  /// Gets the date of first app launch.
  Future<DateTime?> getFirstLaunchDate() async {
    try {
      final dateStr = await _storage.read(key: _firstLaunchDateKey);
      if (dateStr != null) {
        return DateTime.parse(dateStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Resets all onboarding state (for testing/debugging).
  Future<void> resetOnboarding() async {
    await _storage.delete(key: _hasSeenStartScreenKey);
    await _storage.delete(key: _hasCompletedOnboardingKey);
    await _storage.delete(key: _firstLaunchDateKey);
  }

  /// Gets the complete onboarding state.
  Future<OnboardingState> getState() async {
    final seenStart = await hasSeenStartScreen();
    final completed = await hasCompletedOnboarding();
    final firstLaunch = await getFirstLaunchDate();

    return OnboardingState(
      hasSeenStartScreen: seenStart,
      hasCompletedOnboarding: completed,
      firstLaunchDate: firstLaunch,
    );
  }
}

/// State class representing the user's onboarding progress.
class OnboardingState {
  const OnboardingState({
    required this.hasSeenStartScreen,
    required this.hasCompletedOnboarding,
    this.firstLaunchDate,
  });

  final bool hasSeenStartScreen;
  final bool hasCompletedOnboarding;
  final DateTime? firstLaunchDate;

  /// Returns true if the user is a new user (hasn't started onboarding).
  bool get isNewUser => !hasSeenStartScreen && !hasCompletedOnboarding;

  /// Returns true if the user is in the middle of onboarding.
  bool get isOnboarding => hasSeenStartScreen && !hasCompletedOnboarding;

  /// Returns true if the user has completed onboarding.
  bool get isComplete => hasCompletedOnboarding;
}
