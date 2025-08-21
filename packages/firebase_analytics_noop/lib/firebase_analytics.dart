library firebase_analytics;

class FirebaseAnalytics {
  FirebaseAnalytics._();
  static final FirebaseAnalytics instance = FirebaseAnalytics._();

  Future<void> logEvent({required String name, Map<String, Object?>? parameters}) async {}
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}
  Future<void> setUserId({String? id}) async {}
  Future<void> setUserProperty({required String name, String? value}) async {}
  Future<void> resetAnalyticsData() async {}
}
