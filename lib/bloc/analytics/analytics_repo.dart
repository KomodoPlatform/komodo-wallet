import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/firebase_options.dart';

abstract class AnalyticsEventData {
  late String name;
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

  Future<void> _initialize(AnalyticsSettings settings) async {
    try {
      if (!settings.isSendAllowed) return;

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
    if (!_isInitialized) {
      return;
    }

    final sanitizedParameters = event.parameters.map((key, value) {
      return MapEntry(key, value is Object ? value : value.toString());
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
