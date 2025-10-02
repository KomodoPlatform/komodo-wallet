import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';

void main() {
  group('AnalyticsRepository Tests', () {
    late AnalyticsSettings testSettings;

    setUp(() {
      testSettings = const AnalyticsSettings(isSendAllowed: true);
    });

    test('AnalyticsRepository implements AnalyticsRepo', () {
      final repo = AnalyticsRepository(testSettings);
      expect(repo, isA<AnalyticsRepo>());
    });

    test('AnalyticsRepository has correct initialization state', () {
      final repo = AnalyticsRepository(testSettings);

      // Initially should not be initialized (async initialization)
      expect(repo.isInitialized, false);
      expect(repo.isEnabled, false);
    });

    testWidgets('AnalyticsRepository can send test event', (
      WidgetTester tester,
    ) async {
      final repo = AnalyticsRepository(testSettings);

      // Create a test event
      final testEvent = TestAnalyticsEvent();

      // This should not throw an exception
      expect(() => repo.queueEvent(testEvent), returnsNormally);
    });
  });
}

class TestAnalyticsEvent extends AnalyticsEventData {
  @override
  String get name => 'test_event';

  @override
  Map<String, dynamic> get parameters => {
    'test_parameter': 'test_value',
    'timestamp': DateTime.now().toIso8601String(),
  };
}
