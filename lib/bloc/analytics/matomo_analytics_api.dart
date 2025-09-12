import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'analytics_api.dart';
import 'analytics_repo.dart';

class MatomoAnalyticsApi implements AnalyticsApi {
  late MatomoTracker _instance;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isInitialized = false;
  bool _isEnabled = false;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;
  static const String _persistedQueueKey = 'matomo_analytics_persisted_queue';

  /// Queue to store events when analytics is disabled
  final List<AnalyticsEventData> _eventQueue = [];

  /// Timer for periodic queue persistence
  Timer? _queuePersistenceTimer;

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

      // Setup queue persistence timer
      _queuePersistenceTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _persistQueue(),
      );

      // Load any previously saved events
      await _loadPersistedQueue();

      // Initialize Matomo (only if enabled and configuration provided)
      if (!matomoEnabled) {
        if (kDebugMode) {
          log(
            'Matomo disabled by MATOMO_ENABLED=false',
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

      final bool hasConfig = matomoUrl.isNotEmpty && matomoSiteId.isNotEmpty;
      if (!hasConfig && !kDebugMode) {
        // In non-debug builds, do not initialize Matomo without explicit configuration
        if (kDebugMode) {
          log(
            'Matomo configuration missing in non-debug build. Disabling Matomo.',
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
      final String resolvedUrl = hasConfig
          ? (matomoUrl.endsWith('/') ? matomoUrl : '${matomoUrl}/')
          : 'https://demo.matomo.cloud/';

      await MatomoTracker.instance.initialize(
        siteId: hasConfig ? matomoSiteId : '1',
        url: resolvedUrl,
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

  Future<void> _persistQueue() async {
    if (_eventQueue.isEmpty) {
      if (kDebugMode) {
        log(
          'No Matomo events to persist (queue empty)',
          path: 'analytics -> MatomoAnalyticsApi -> _persistQueue',
        );
      }
      return;
    }

    try {
      if (kDebugMode) {
        log(
          'Persisting ${_eventQueue.length} queued Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> _persistQueue',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Convert events to a serializable format
      final serializedEvents = _eventQueue.map((event) {
        return {'name': event.name, 'parameters': event.parameters};
      }).toList();

      // Serialize and store
      final serialized = jsonEncode(serializedEvents);
      await prefs.setString(_persistedQueueKey, serialized);

      if (kDebugMode) {
        log(
          'Successfully persisted ${_eventQueue.length} Matomo events to SharedPreferences',
          path: 'analytics -> MatomoAnalyticsApi -> _persistQueue',
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error persisting Matomo analytics queue: $e',
          path: 'analytics -> MatomoAnalyticsApi -> _persistQueue',
          trace: s,
          isError: true,
        );
      }
    }
  }

  Future<void> _loadPersistedQueue() async {
    try {
      if (kDebugMode) {
        log(
          'Loading persisted Matomo analytics events from SharedPreferences',
          path: 'analytics -> MatomoAnalyticsApi -> _loadPersistedQueue',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(_persistedQueueKey);

      if (serialized == null || serialized.isEmpty) {
        if (kDebugMode) {
          log(
            'No persisted Matomo analytics events found',
            path: 'analytics -> MatomoAnalyticsApi -> _loadPersistedQueue',
          );
        }
        return;
      }

      // Deserialize the data
      final List<dynamic> decodedList = jsonDecode(serialized);

      // Create PersistedAnalyticsEventData instances
      for (final eventMap in decodedList) {
        _eventQueue.add(
          PersistedAnalyticsEventData(
            name: eventMap['name'],
            parameters: Map<String, dynamic>.from(eventMap['parameters']),
          ),
        );
      }

      if (kDebugMode) {
        log(
          'Loaded ${_eventQueue.length} persisted Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> _loadPersistedQueue',
        );
      }

      // Clear the persisted data after loading
      await prefs.remove(_persistedQueueKey);
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error loading persisted Matomo analytics queue: $e',
          path: 'analytics -> MatomoAnalyticsApi -> _loadPersistedQueue',
          trace: s,
          isError: true,
        );
      }
    }
  }

  @override
  @override
  Future<void> dispose() async {
    if (_queuePersistenceTimer != null) {
      _queuePersistenceTimer!.cancel();
      _queuePersistenceTimer = null;

      if (kDebugMode) {
        log(
          'Cancelled Matomo queue persistence timer',
          path: 'analytics -> MatomoAnalyticsApi -> dispose',
        );
      }
    }

    // Persist any remaining events before disposing
    await _persistQueue();
  }
}
