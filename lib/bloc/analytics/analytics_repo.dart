import 'dart:convert';
import 'dart:async';

import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/utils/utils.dart';

abstract class AnalyticsEventData {
  String get name;
  Map<String, dynamic> get parameters;
}

/// A simple implementation of AnalyticsEventData for persisted events
class PersistedAnalyticsEventData implements AnalyticsEventData {
  PersistedAnalyticsEventData({
    required this.name,
    required this.parameters,
  });

  @override
  final String name;

  @override
  final Map<String, dynamic> parameters;
}

abstract class AnalyticsRepo {
  /// Sends an analytics event immediately
  Future<void> sendData(AnalyticsEventData data);

  /// Activates analytics collection
  Future<void> activate();

  /// Deactivates analytics collection
  Future<void> deactivate();

  /// Queues an event to be sent when possible.
  /// If analytics is enabled, sends immediately.
  /// Otherwise, stores for future sending when enabled.
  Future<void> queueEvent(AnalyticsEventData data);

  /// Check if analytics is initialized
  bool get isInitialized;

  /// Check if analytics is enabled
  bool get isEnabled;

  /// Force a retry of initialization if it previously failed
  Future<void> retryInitialization(AnalyticsSettings settings);

  /// Save the current event queue to persistent storage
  Future<void> persistQueue();

  /// Load any previously persisted events
  Future<void> loadPersistedQueue();

  /// Cleanup resources used by the repository
  void dispose();
}

class MatomoAnalyticsRepo implements AnalyticsRepo {
  MatomoAnalyticsRepo(AnalyticsSettings settings) {
    _initializeWithRetry(settings);
  }

  final Completer<void> _initCompleter = Completer<void>();

  bool _isInitialized = false;
  bool _isEnabled = false;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;
  static const String _persistedQueueKey = 'analytics_persisted_queue';

  // Matomo configuration via compile-time environment variables
  // Provide these with --dart-define=MATOMO_URL=..., --dart-define=MATOMO_SITE_ID=...
  static final String _matomoUrl = const String.fromEnvironment('MATOMO_URL', defaultValue: '');
  static final String _matomoSiteIdStr = const String.fromEnvironment('MATOMO_SITE_ID', defaultValue: '');
  static int? get _matomoSiteId => int.tryParse(_matomoSiteIdStr);

  /// Queue to store events when analytics is disabled
  final List<AnalyticsEventData> _eventQueue = [];

  /// Timer for periodic queue persistence
  Timer? _queuePersistenceTimer;

  /// For checking initialization status
  @override
  bool get isInitialized => _isInitialized;

  /// For checking if analytics is enabled
  @override
  bool get isEnabled => _isEnabled;

  /// Registers the AnalyticsRepo instance with GetIt for dependency injection
  static void register(AnalyticsSettings settings) {
    if (!GetIt.I.isRegistered<AnalyticsRepo>()) {
      final repo = MatomoAnalyticsRepo(settings);
      GetIt.I.registerSingleton<AnalyticsRepo>(repo);

      if (kDebugMode) {
        log(
          'AnalyticsRepo registered with GetIt',
          path: 'analytics -> MatomoAnalyticsService -> register',
        );
      }
    } else if (kDebugMode) {
      log(
        'AnalyticsRepo already registered with GetIt',
        path: 'analytics -> MatomoAnalyticsService -> register',
      );
    }
  }

  /// Initialize with retry mechanism
  Future<void> _initializeWithRetry(AnalyticsSettings settings) async {
    try {
      if (kDebugMode) {
        log(
          'Initializing Matomo Analytics with settings: isSendAllowed=${settings.isSendAllowed}',
          path: 'analytics -> MatomoAnalyticsService -> _initialize',
        );
      }

      // Setup queue persistence timer
      _queuePersistenceTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => persistQueue(),
      );

      // Load any previously saved events
      await loadPersistedQueue();

      // Initialize Matomo if configuration is provided
      if (_matomoUrl.isEmpty || _matomoSiteId == null) {
        _isInitialized = false;
        _isEnabled = false;
        if (kDebugMode) {
          log('Matomo configuration missing: set MATOMO_URL and MATOMO_SITE_ID to enable analytics');
        }
        // Do not throw; allow app to proceed without analytics
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        return;
      }

      await MatomoTracker.instance.initialize(
        siteId: _matomoSiteId!,
        url: _matomoUrl,
      );

      _isInitialized = true;
      _isEnabled = settings.isSendAllowed;

      if (kDebugMode) {
        log(
          'Matomo Analytics initialized: _isInitialized=$_isInitialized, _isEnabled=$_isEnabled',
          path: 'analytics -> MatomoAnalyticsService -> _initialize',
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
          path: 'analytics -> MatomoAnalyticsService -> _initialize',
          isError: true,
        );
      }

      // Try to initialize again if we haven't exceeded max retries
      if (_initRetryCount < _maxInitRetries) {
        _initRetryCount++;

        if (kDebugMode) {
          log(
            'Retrying analytics initialization (attempt $_initRetryCount of $_maxInitRetries)',
            path: 'analytics -> MatomoAnalyticsService -> _initialize',
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

  /// Retry initialization if it previously failed
  @override
  Future<void> retryInitialization(AnalyticsSettings settings) async {
    if (!_isInitialized) {
      _initRetryCount = 0;
      return _initializeWithRetry(settings);
    }
  }

  @override
  Future<void> sendData(AnalyticsEventData event) async {
    final sanitizedParameters = event.parameters.map((key, value) {
      if (value == null) return MapEntry(key, "null");
      if (value is Map || value is List) {
        return MapEntry(key, jsonEncode(value));
      }
      return MapEntry(key, value.toString());
    });

    // Log the event in debug mode with formatted parameters for better readability
    if (kDebugMode) {
      final formattedParams =
          const JsonEncoder.withIndent('  ').convert(sanitizedParameters);
      log(
        'Analytics Event: ${event.name}; Parameters: $formattedParams',
        path: 'analytics -> MatomoAnalyticsService -> sendData',
      );
    }

    try {
      // Map our generic analytics event to Matomo event
      await MatomoTracker.instance.trackEvent(
        eventInfo: EventInfo(
          category: 'app',
          action: event.name,
          name: sanitizedParameters.isEmpty
              ? null
              : jsonEncode(sanitizedParameters),
          value: null,
        ),
      );
    } catch (e, s) {
      log(
        e.toString(),
        path: 'analytics -> MatomoAnalyticsService -> logEvent',
        trace: s,
        isError: true,
      );
    }
  }

  @override
  Future<void> queueEvent(AnalyticsEventData data) async {
    // Log the queued event in debug mode with formatted parameters
    if (kDebugMode) {
      final formattedParams =
          const JsonEncoder.withIndent('  ').convert(data.parameters);
      log(
        'Analytics Event Queued: ${data.name}\nParameters:\n$formattedParams',
        path: 'analytics -> MatomoAnalyticsService -> queueEvent',
      );
    }

    if (!_isInitialized) {
      _eventQueue.add(data);
      if (kDebugMode) {
        log(
          'Analytics not initialized, added to queue (${_eventQueue.length} events queued)',
          path: 'analytics -> MatomoAnalyticsService -> queueEvent',
        );
      }
      return;
    }

    if (_isEnabled) {
      await sendData(data);
    } else {
      _eventQueue.add(data);
      if (kDebugMode) {
        log(
          'Analytics disabled, added to queue (${_eventQueue.length} events queued)',
          path: 'analytics -> MatomoAnalyticsService -> queueEvent',
        );
      }
    }
  }

  @override
  Future<void> activate() async {
    if (!_isInitialized) {
      return;
    }

    _isEnabled = true;

    // Process any queued events
    if (_eventQueue.isNotEmpty) {
      if (kDebugMode) {
        log(
          'Processing ${_eventQueue.length} queued analytics events',
          path: 'analytics -> MatomoAnalyticsService -> activate',
        );
      }

      final queuedEvents = List<AnalyticsEventData>.from(_eventQueue);
      _eventQueue.clear();

      int processedCount = 0;
      for (final event in queuedEvents) {
        await sendData(event);
        processedCount++;
      }

      if (kDebugMode && processedCount > 0) {
        log(
          'Successfully processed $processedCount queued analytics events',
          path: 'analytics -> MatomoAnalyticsService -> activate',
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
        'Analytics collection disabled',
        path: 'analytics -> MatomoAnalyticsService -> deactivate',
      );
    }

    _isEnabled = false;
  }

  @override
  Future<void> persistQueue() async {
    if (_eventQueue.isEmpty) {
      if (kDebugMode) {
        log(
          'No events to persist (queue empty)',
          path: 'analytics -> MatomoAnalyticsService -> persistQueue',
        );
      }
      return;
    }

    try {
      if (kDebugMode) {
        log(
          'Persisting ${_eventQueue.length} queued analytics events',
          path: 'analytics -> MatomoAnalyticsService -> persistQueue',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Convert events to a serializable format
      final serializedEvents = _eventQueue.map((event) {
        return {
          'name': event.name,
          'parameters': event.parameters,
        };
      }).toList();

      // Serialize and store
      final serialized = jsonEncode(serializedEvents);
      await prefs.setString(_persistedQueueKey, serialized);

      if (kDebugMode) {
        log(
          'Successfully persisted ${_eventQueue.length} events to SharedPreferences',
          path: 'analytics -> MatomoAnalyticsService -> persistQueue',
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error persisting analytics queue: $e',
          path: 'analytics -> MatomoAnalyticsService -> persistQueue',
          trace: s,
          isError: true,
        );
      }
    }
  }

  @override
  Future<void> loadPersistedQueue() async {
    try {
      if (kDebugMode) {
        log(
          'Loading persisted analytics events from SharedPreferences',
          path: 'analytics -> MatomoAnalyticsService -> loadPersistedQueue',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(_persistedQueueKey);

      if (serialized == null || serialized.isEmpty) {
        if (kDebugMode) {
          log(
            'No persisted analytics events found',
            path: 'analytics -> MatomoAnalyticsService -> loadPersistedQueue',
          );
        }
        return;
      }

      // Deserialize the data
      final List<dynamic> decodedList = jsonDecode(serialized);

      // Create PersistedAnalyticsEventData instances
      for (final eventMap in decodedList) {
        _eventQueue.add(PersistedAnalyticsEventData(
          name: eventMap['name'],
          parameters: Map<String, dynamic>.from(eventMap['parameters']),
        ));
      }

      if (kDebugMode) {
        log(
          'Loaded ${_eventQueue.length} persisted analytics events',
          path: 'analytics -> MatomoAnalyticsService -> loadPersistedQueue',
        );
      }

      // Clear the persisted data after loading
      await prefs.remove(_persistedQueueKey);
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error loading persisted analytics queue: $e',
          path: 'analytics -> MatomoAnalyticsService -> loadPersistedQueue',
          trace: s,
          isError: true,
        );
      }
    }
  }

  /// Cleanup resources used by the repository
  @override
  void dispose() {
    if (_queuePersistenceTimer != null) {
      _queuePersistenceTimer!.cancel();
      _queuePersistenceTimer = null;

      if (kDebugMode) {
        log(
          'Cancelled queue persistence timer',
          path: 'analytics -> MatomoAnalyticsService -> dispose',
        );
      }
    }

    // Persist any remaining events before disposing
    persistQueue();
  }
}
