import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/firebase_options.dart';

abstract class AnalyticsEventData {
  String get name;
  Map<String, dynamic> get parameters;
}

abstract class AnalyticsRepo {
  Future<void> sendData(AnalyticsEventData data);
  Future<void> activate();
  Future<void> deactivate();
}

class FirebaseAnalyticsRepo implements AnalyticsRepo {
  FirebaseAnalyticsRepo(AnalyticsSettings settings) {
    _initialize(settings);
  }

  late FirebaseAnalytics _instance;

  bool _isInitialized = false;

  /// Registers the AnalyticsRepo instance with GetIt for dependency injection
  static void register(AnalyticsSettings settings) {
    if (!GetIt.I.isRegistered<AnalyticsRepo>()) {
      final repo = FirebaseAnalyticsRepo(settings);
      GetIt.I.registerSingleton<AnalyticsRepo>(repo);
    }
  }

  Future<void> _initialize(AnalyticsSettings settings) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _instance = FirebaseAnalytics.instance;

      _isInitialized = true;
      if (_isInitialized && settings.isSendAllowed) {
        await activate();
      } else {
        await deactivate();
      }
    } catch (e) {
      _isInitialized = false;
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
  Future<void> activate() async {
    if (!_isInitialized) {
      return;
    }
    await _instance.setAnalyticsCollectionEnabled(true);
  }

  @override
  Future<void> deactivate() async {
    if (!_isInitialized) {
      return;
    }
    await _instance.setAnalyticsCollectionEnabled(false);
  }
}
