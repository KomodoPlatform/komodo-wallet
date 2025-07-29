import 'dart:async';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'analytics_repo.dart';

/// Abstract interface for analytics providers
abstract class AnalyticsApi {
  /// Initialize the analytics provider
  Future<void> initialize(AnalyticsSettings settings);

  /// Send an analytics event
  Future<void> sendEvent(AnalyticsEventData event);

  /// Activate analytics collection
  Future<void> activate();

  /// Deactivate analytics collection
  Future<void> deactivate();

  /// Check if the provider is initialized
  bool get isInitialized;

  /// Check if the provider is enabled
  bool get isEnabled;

  /// Get the provider name
  String get providerName;

  /// Retry initialization if it previously failed
  Future<void> retryInitialization(AnalyticsSettings settings);

  /// Cleanup resources
  void dispose();
}
