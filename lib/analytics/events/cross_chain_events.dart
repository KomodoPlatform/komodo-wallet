import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E20: Bridge transfer started
class BridgeInitiatedEventData implements AnalyticsEventData {
  const BridgeInitiatedEventData({
    required this.fromChain,
    required this.toChain,
    required this.asset,
  });

  final String fromChain;
  final String toChain;
  final String asset;

  @override
  String get name => 'bridge_initiated';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
      };
}

class AnalyticsBridgeInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeInitiatedEvent({
    required String fromChain,
    required String toChain,
    required String asset,
  }) : super(
          BridgeInitiatedEventData(
            fromChain: fromChain,
            toChain: toChain,
            asset: asset,
          ),
        );
}

/// E21: Bridge completed
class BridgeSuccessEventData implements AnalyticsEventData {
  const BridgeSuccessEventData({
    required this.fromChain,
    required this.toChain,
    required this.asset,
    required this.amount,
  });

  final String fromChain;
  final String toChain;
  final String asset;
  final double amount;

  @override
  String get name => 'bridge_success';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
        'amount': amount,
      };
}

class AnalyticsBridgeSuccessEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeSuccessEvent({
    required String fromChain,
    required String toChain,
    required String asset,
    required double amount,
  }) : super(
          BridgeSuccessEventData(
            fromChain: fromChain,
            toChain: toChain,
            asset: asset,
            amount: amount,
          ),
        );
}

/// E22: Bridge failed
class BridgeFailureEventData implements AnalyticsEventData {
  const BridgeFailureEventData({
    required this.fromChain,
    required this.toChain,
    required this.failError,
  });

  final String fromChain;
  final String toChain;
  final String failError;

  @override
  String get name => 'bridge_failure';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'fail_error': failError,
      };
}

class AnalyticsBridgeFailureEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeFailureEvent({
    required String fromChain,
    required String toChain,
    required String failError,
  }) : super(
          BridgeFailureEventData(
            fromChain: fromChain,
            toChain: toChain,
            failError: failError,
          ),
        );
}
