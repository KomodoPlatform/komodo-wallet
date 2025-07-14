import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E20: Bridge transfer started
/// Business category: Cross-Chain.
class BridgeInitiatedEventData implements AnalyticsEventData {
  const BridgeInitiatedEventData({
    required this.fromChain,
    required this.toChain,
    required this.asset,
    required this.walletType,
  });

  final String fromChain;
  final String toChain;
  final String asset;
  final String walletType;

  @override
  String get name => 'bridge_initiated';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
        'wallet_type': walletType,
      };
}

/// E20: Bridge transfer started
class AnalyticsBridgeInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeInitiatedEvent({
    required String fromChain,
    required String toChain,
    required String asset,
    required String walletType,
  }) : super(
          BridgeInitiatedEventData(
            fromChain: fromChain,
            toChain: toChain,
            asset: asset,
            walletType: walletType,
          ),
        );
}

/// E21: Bridge completed
/// Business category: Cross-Chain.
class BridgeSucceededEventData implements AnalyticsEventData {
  const BridgeSucceededEventData({
    required this.fromChain,
    required this.toChain,
    required this.asset,
    required this.amount,
    required this.walletType,
    required this.durationMs,
  });

  final String fromChain;
  final String toChain;
  final String asset;
  final double amount;
  final String walletType;
  final int durationMs;

  @override
  String get name => 'bridge_success';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
        'amount': amount,
        'wallet_type': walletType,
        'duration_ms': durationMs,
      };
}

/// E21: Bridge completed
class AnalyticsBridgeSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeSucceededEvent({
    required String fromChain,
    required String toChain,
    required String asset,
    required double amount,
    required String walletType,
    required int durationMs,
  }) : super(
          BridgeSucceededEventData(
            fromChain: fromChain,
            toChain: toChain,
            asset: asset,
            amount: amount,
            walletType: walletType,
            durationMs: durationMs,
          ),
        );
}

/// E22: Bridge failed
/// Business category: Cross-Chain.
class BridgeFailedEventData implements AnalyticsEventData {
  const BridgeFailedEventData({
    required this.fromChain,
    required this.toChain,
    required this.failError,
    required this.walletType,
    required this.durationMs,
  });

  final String fromChain;
  final String toChain;
  final String failError;
  final String walletType;
  final int durationMs;

  @override
  String get name => 'bridge_failure';

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'fail_error': failError,
        'wallet_type': walletType,
        'duration_ms': durationMs,
      };
}

/// E22: Bridge failed
class AnalyticsBridgeFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeFailedEvent({
    required String fromChain,
    required String toChain,
    required String failError,
    required String walletType,
    required int durationMs,
  }) : super(
          BridgeFailedEventData(
            fromChain: fromChain,
            toChain: toChain,
            failError: failError,
            walletType: walletType,
            durationMs: durationMs,
          ),
        );
}
