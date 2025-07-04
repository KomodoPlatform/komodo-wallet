import 'package:komodo_wallet/bloc/analytics/analytics_repo.dart';

abstract class AnalyticsEvent {
  const AnalyticsEvent();
}

class AnalyticsActivateEvent extends AnalyticsEvent {
  const AnalyticsActivateEvent();
}

class AnalyticsDeactivateEvent extends AnalyticsEvent {
  const AnalyticsDeactivateEvent();
}

class AnalyticsSendDataEvent extends AnalyticsEvent {
  const AnalyticsSendDataEvent(this.data);
  final AnalyticsEventData data;
}
