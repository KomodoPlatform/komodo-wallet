import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';
import 'analytics_api.dart';
import 'analytics_repo.dart';

class MatomoAnalyticsApi implements AnalyticsApi {
  late MatomoTracker _instance;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isInitialized = false;
  bool _isEnabled = false;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;

  /// Queue to store events when analytics is disabled
  final List<AnalyticsEventData> _eventQueue = [];

  @override
  String get providerName => 'Matomo';

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> initialize(AnalyticsSettings settings) async {
    return _initializeWithRetry(settings);
  }

  /// Initialize with retry mechanism
  Future<void> _initializeWithRetry(AnalyticsSettings settings) async {
    try {
      if (kDebugMode) {
        log(
          'Initializing Matomo Analytics with settings: isSendAllowed=${settings.isSendAllowed}',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
        );
      }

      // Initialize Matomo only if configuration is provided

      final bool hasConfig = matomoUrl.isNotEmpty && matomoSiteId.isNotEmpty;
      if (!hasConfig) {
        if (kDebugMode) {
          log(
            'Matomo configuration missing (MATOMO_URL and/or MATOMO_SITE_ID). Disabling Matomo.',
            path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          );
        }
        _isInitialized = false;
        _isEnabled = false;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        return;
      }

      // Ensure URL has trailing slash as required by matomo_tracker
      final String resolvedUrl = matomoUrl.endsWith('/')
          ? matomoUrl
          : '$matomoUrl/';

      await MatomoTracker.instance.initialize(
        siteId: matomoSiteId,
        url: resolvedUrl,
        dispatchSettings: const DispatchSettings.persistent(),
        // Include backend API key header similarly to feedback feature
        customHeaders: {
          if (const String.fromEnvironment('FEEDBACK_API_KEY').isNotEmpty)
            'X-KW-KEY': const String.fromEnvironment('FEEDBACK_API_KEY'),
        },
      );
      _instance = MatomoTracker.instance;

      _isInitialized = true;
      // Disable analytics in CI or when analyticsDisabled flag is set
      final bool shouldDisable = analyticsDisabled || isCiEnvironment;
      _isEnabled = settings.isSendAllowed && !shouldDisable;

      if (kDebugMode) {
        log(
          'Matomo Analytics initialized: _isInitialized=$_isInitialized, _isEnabled=$_isEnabled',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
        );
      }

      if (_isInitialized && _isEnabled) {
        await activate();
      } else {
        await deactivate();
      }

      // Successfully initialized
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      _isInitialized = false;

      if (kDebugMode) {
        log(
          'Error initializing Matomo Analytics: $e',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          isError: true,
        );
      }

      // Try to initialize again if we haven't exceeded max retries
      if (_initRetryCount < _maxInitRetries) {
        _initRetryCount++;

        if (kDebugMode) {
          log(
            'Retrying Matomo analytics initialization (attempt $_initRetryCount of $_maxInitRetries)',
            path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          );
        }

        // Retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * _initRetryCount));
        await _initializeWithRetry(settings);
      } else {
        // Maximum retries exceeded
        if (!_initCompleter.isCompleted) {
          _initCompleter.completeError(e);
        }
      }
    }
  }

  @override
  Future<void> retryInitialization(AnalyticsSettings settings) async {
    if (!_isInitialized) {
      _initRetryCount = 0;
      return _initializeWithRetry(settings);
    }
  }

  @override
  Future<void> sendEvent(AnalyticsEventData event) async {
    // If not initialized or disabled, enqueue for later
    if (!_isInitialized || !_isEnabled) {
      _eventQueue.add(event);
      return;
    }
    final sanitizedParameters = event.parameters.map((key, value) {
      if (value == null) return MapEntry(key, "null");
      if (value is Map || value is List) {
        return MapEntry(key, jsonEncode(value));
      }
      return MapEntry(key, value.toString());
    });

    // Log the event in debug mode with formatted parameters for better readability
    if (kDebugMode) {
      final formattedParams = const JsonEncoder.withIndent(
        '  ',
      ).convert(sanitizedParameters);
      log(
        'Matomo Analytics Event: ${event.name}; Parameters: $formattedParams',
        path: 'analytics -> MatomoAnalyticsApi -> sendEvent',
      );
    }

    try {
      // Convert to Matomo event format
      _instance.trackEvent(
        eventInfo: EventInfo(
          category: _extractCategory(event.name),
          action: event.name,
          name: event.name,
          value: _extractEventValue(sanitizedParameters),
        ),
      );

      // Note: Custom dimensions should be set separately in Matomo
      // You can extend this implementation to handle custom dimensions if needed
    } catch (e, s) {
      log(
        e.toString(),
        path: 'analytics -> MatomoAnalyticsApi -> sendEvent',
        trace: s,
        isError: true,
      );
    }
  }

  @override
  Future<void> activate() async {
    if (!_isInitialized) {
      return;
    }

    _isEnabled = true;
    // Attach visit-scoped custom dimensions such as platform name
    try {
      if (matomoPlatformDimensionId != null) {
        final platform = PlatformInfo.getInstance().platform;
        final dimensionKey = 'dimension${matomoPlatformDimensionId}';
        MatomoTracker.instance.trackDimensions(
          dimensions: {dimensionKey: platform},
        );
        if (kDebugMode) {
          log(
            'Matomo dimensions set: {$dimensionKey: $platform}',
            path: 'analytics -> MatomoAnalyticsApi -> activate',
          );
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Failed to set Matomo custom dimensions: $e',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
          trace: s,
          isError: true,
        );
      }
    }
    // Matomo doesn't have a direct enable/disable method like Firebase
    // so we handle this by simply processing queued events

    // Process any queued events
    if (_eventQueue.isNotEmpty) {
      if (kDebugMode) {
        log(
          'Processing ${_eventQueue.length} queued Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
        );
      }

      final queuedEvents = List<AnalyticsEventData>.from(_eventQueue);
      _eventQueue.clear();

      int processedCount = 0;
      for (final event in queuedEvents) {
        await sendEvent(event);
        processedCount++;
      }

      if (kDebugMode && processedCount > 0) {
        log(
          'Successfully processed $processedCount queued Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
        );
      }
    }
  }

  @override
  Future<void> deactivate() async {
    if (!_isInitialized) {
      return;
    }

    if (kDebugMode) {
      log(
        'Matomo analytics collection disabled',
        path: 'analytics -> MatomoAnalyticsApi -> deactivate',
      );
    }

    _isEnabled = false;
    // Matomo doesn't have a direct disable method
    // Events will be queued instead of sent when disabled
  }

  /// Extract category from event name (used for Matomo event categorization)
  String _extractCategory(String eventName) {
    // Simple category extraction based on event naming patterns
    if (eventName.startsWith('app_')) return 'App';
    if (eventName.startsWith('onboarding_')) return 'Onboarding';
    if (eventName.startsWith('wallet_')) return 'Wallet';
    if (eventName.startsWith('portfolio_')) return 'Portfolio';
    if (eventName.startsWith('asset_')) return 'Asset';
    if (eventName.startsWith('send_')) return 'Transaction';
    if (eventName.startsWith('swap_')) return 'Trading';
    if (eventName.startsWith('bridge_')) return 'Bridge';
    if (eventName.startsWith('nft_')) return 'NFT';
    if (eventName.startsWith('marketbot_')) return 'Marketbot';
    if (eventName.startsWith('reward_')) return 'Rewards';
    if (eventName.startsWith('dapp_')) return 'DApp';
    if (eventName.startsWith('settings_')) return 'Settings';
    if (eventName.startsWith('error_')) return 'Error';
    if (eventName.startsWith('hd_')) return 'HDWallet';
    if (eventName.startsWith('scroll_')) return 'UI';
    if (eventName.startsWith('searchbar_')) return 'Search';
    if (eventName.startsWith('theme_')) return 'Theme';
    return 'General';
  }

  /// Extract numeric value from parameters for Matomo event value
  double? _extractEventValue(Map<String, dynamic> parameters) {
    // Look for common numeric parameters that could serve as event value
    final potentialValueKeys = [
      'amount',
      'value',
      'count',
      'duration_ms',
      'profit_usd',
      'reward_amount',
      'base_capital',
      'trade_size',
    ];

    for (final key in potentialValueKeys) {
      if (parameters.containsKey(key)) {
        final value = parameters[key];
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    if (kDebugMode) {
      log(
        'MatomoAnalyticsApi disposed',
        path: 'analytics -> MatomoAnalyticsApi -> dispose',
      );
    }
  }
}
