import 'dart:convert';
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/firebase_options.dart';

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

class FirebaseAnalyticsRepo implements AnalyticsRepo {
  FirebaseAnalyticsRepo(AnalyticsSettings settings) {
    _initializeWithRetry(settings);
  }

  late FirebaseAnalytics _instance;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isInitialized = false;
  bool _isEnabled = false;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;
  static const String _persistedQueueKey = 'analytics_persisted_queue';

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
      final repo = FirebaseAnalyticsRepo(settings);
      GetIt.I.registerSingleton<AnalyticsRepo>(repo);

      if (kDebugMode) {
        log(
          'AnalyticsRepo registered with GetIt',
          path: 'analytics -> FirebaseAnalyticsService -> register',
        );
      }
    } else if (kDebugMode) {
      log(
        'AnalyticsRepo already registered with GetIt',
        path: 'analytics -> FirebaseAnalyticsService -> register',
      );
    }
  }

  /// Initialize with retry mechanism
  Future<void> _initializeWithRetry(AnalyticsSettings settings) async {
    // Firebase is not supported on Linux
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      _isInitialized = false;
      _isEnabled = false;
      _initCompleter.completeError(UnsupportedError);
      return;
    }

    try {
      if (kDebugMode) {
        log(
          'Initializing Firebase Analytics with settings: isSendAllowed=${settings.isSendAllowed}',
          path: 'analytics -> FirebaseAnalyticsService -> _initialize',
        );
      }

      // Setup queue persistence timer
      _queuePersistenceTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => persistQueue(),
      );

      // Load any previously saved events
      await loadPersistedQueue();

      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on UnsupportedError {
        _isInitialized = false;
        _isEnabled = false;
        if (kDebugMode) {
          log('Firebase Analytics initializeApp failed with UnsupportedError');
        }
        _initCompleter.completeError(UnsupportedError);
        return;
      }
      _instance = FirebaseAnalytics.instance;

      _isInitialized = true;
      _isEnabled = settings.isSendAllowed;

      if (kDebugMode) {
        log(
          'Firebase Analytics initialized: _isInitialized=$_isInitialized, _isEnabled=$_isEnabled',
          path: 'analytics -> FirebaseAnalyticsService -> _initialize',
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
          'Error initializing Firebase Analytics: $e',
          path: 'analytics -> FirebaseAnalyticsService -> _initialize',
          isError: true,
        );
      }

      // Try to initialize again if we haven't exceeded max retries
      if (_initRetryCount < _maxInitRetries) {
        _initRetryCount++;

        if (kDebugMode) {
          log(
            'Retrying analytics initialization (attempt $_initRetryCount of $_maxInitRetries)',
            path: 'analytics -> FirebaseAnalyticsService -> _initialize',
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
        path: 'analytics -> FirebaseAnalyticsService -> sendData',
      );
    }

    try {
      await _instance.logEvent(
        name: event.name,
        parameters: sanitizedParameters,
      );
    } catch (e, s) {
      log(
        e.toString(),
        path: 'analytics -> FirebaseAnalyticsService -> logEvent',
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
        path: 'analytics -> FirebaseAnalyticsService -> queueEvent',
      );
    }

    if (!_isInitialized) {
      _eventQueue.add(data);
      if (kDebugMode) {
        log(
          'Analytics not initialized, added to queue (${_eventQueue.length} events queued)',
          path: 'analytics -> FirebaseAnalyticsService -> queueEvent',
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
          path: 'analytics -> FirebaseAnalyticsService -> queueEvent',
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
    await _instance.setAnalyticsCollectionEnabled(true);

    // Process any queued events
    if (_eventQueue.isNotEmpty) {
      if (kDebugMode) {
        log(
          'Processing ${_eventQueue.length} queued analytics events',
          path: 'analytics -> FirebaseAnalyticsService -> activate',
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
          path: 'analytics -> FirebaseAnalyticsService -> activate',
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
        path: 'analytics -> FirebaseAnalyticsService -> deactivate',
      );
    }

    _isEnabled = false;
    await _instance.setAnalyticsCollectionEnabled(false);
  }

  @override
  Future<void> persistQueue() async {
    if (_eventQueue.isEmpty) {
      if (kDebugMode) {
        log(
          'No events to persist (queue empty)',
          path: 'analytics -> FirebaseAnalyticsService -> persistQueue',
        );
      }
      return;
    }

    try {
      if (kDebugMode) {
        log(
          'Persisting ${_eventQueue.length} queued analytics events',
          path: 'analytics -> FirebaseAnalyticsService -> persistQueue',
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
          path: 'analytics -> FirebaseAnalyticsService -> persistQueue',
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error persisting analytics queue: $e',
          path: 'analytics -> FirebaseAnalyticsService -> persistQueue',
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
          path: 'analytics -> FirebaseAnalyticsService -> loadPersistedQueue',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(_persistedQueueKey);

      if (serialized == null || serialized.isEmpty) {
        if (kDebugMode) {
          log(
            'No persisted analytics events found',
            path: 'analytics -> FirebaseAnalyticsService -> loadPersistedQueue',
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
          path: 'analytics -> FirebaseAnalyticsService -> loadPersistedQueue',
        );
      }

      // Clear the persisted data after loading
      await prefs.remove(_persistedQueueKey);
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Error loading persisted analytics queue: $e',
          path: 'analytics -> FirebaseAnalyticsService -> loadPersistedQueue',
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
          path: 'analytics -> FirebaseAnalyticsService -> dispose',
        );
      }
    }

    // Persist any remaining events before disposing
    persistQueue();
  }
}
