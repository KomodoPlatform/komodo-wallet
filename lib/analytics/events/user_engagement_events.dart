import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E01: App launched / foregrounded
/// Measures when the application is opened or returns to foreground.
/// Business category: User Engagement.
class AppOpenedEventData extends AnalyticsEventData {
  const AppOpenedEventData({required this.platform, required this.appVersion});

  final String platform;
  final String appVersion;

  @override
  String get name => 'app_open';

  @override
  JsonMap get parameters => {'platform': platform, 'app_version': appVersion};
}

/// E01: App launched / foregrounded
class AnalyticsAppOpenedEvent extends AnalyticsSendDataEvent {
  AnalyticsAppOpenedEvent({
    required String platform,
    required String appVersion,
  }) : super(AppOpenedEventData(platform: platform, appVersion: appVersion));
}
