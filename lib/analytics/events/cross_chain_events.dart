import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E20: Bridge transfer started
/// Business category: Cross-Chain.
class BridgeInitiatedEventData extends AnalyticsEventData {
  const BridgeInitiatedEventData({
    required this.asset,
    required this.secondaryAsset,
    required this.network,
    required this.secondaryNetwork,
    required this.hdType,
  });

  final String asset;
  final String secondaryAsset;
  final String network;
  final String secondaryNetwork;
  final String hdType;

  @override
  String get name => 'bridge_initiated';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'secondary_asset': secondaryAsset,
    'network': network,
    'secondary_network': secondaryNetwork,
    'hd_type': hdType,
  };
}

/// E20: Bridge transfer started
class AnalyticsBridgeInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeInitiatedEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required String hdType,
  }) : super(
         BridgeInitiatedEventData(
           asset: asset,
           secondaryAsset: secondaryAsset,
           network: network,
           secondaryNetwork: secondaryNetwork,
           hdType: hdType,
         ),
       );
}

/// E21: Bridge completed
/// Business category: Cross-Chain.
class BridgeSucceededEventData extends AnalyticsEventData {
  const BridgeSucceededEventData({
    required this.asset,
    required this.secondaryAsset,
    required this.network,
    required this.secondaryNetwork,
    required this.amount,
    required this.hdType,
    this.durationMs,
  });

  final String asset;
  final String secondaryAsset;
  final String network;
  final String secondaryNetwork;
  final double amount;
  final String hdType;
  final int? durationMs;

  @override
  String get name => 'bridge_success';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'secondary_asset': secondaryAsset,
    'network': network,
    'secondary_network': secondaryNetwork,
    'amount': amount,
    'hd_type': hdType,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

/// E21: Bridge completed
class AnalyticsBridgeSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeSucceededEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required double amount,
    required String hdType,
    int? durationMs,
  }) : super(
         BridgeSucceededEventData(
           asset: asset,
           secondaryAsset: secondaryAsset,
           network: network,
           secondaryNetwork: secondaryNetwork,
           amount: amount,
           hdType: hdType,
           durationMs: durationMs,
         ),
       );
}

/// E22: Bridge failed
/// Business category: Cross-Chain.
class BridgeFailedEventData extends AnalyticsEventData {
  const BridgeFailedEventData({
    required this.asset,
    required this.secondaryAsset,
    required this.network,
    required this.secondaryNetwork,
    required this.failureStage,
    this.failureDetail,
    required this.hdType,
    this.durationMs,
  });

  final String asset;
  final String secondaryAsset;
  final String network;
  final String secondaryNetwork;
  final String failureStage;
  final String? failureDetail;
  final String hdType;
  final int? durationMs;

  @override
  String get name => 'bridge_failure';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'secondary_asset': secondaryAsset,
    'network': network,
    'secondary_network': secondaryNetwork,
    'failure_reason': _formatFailureReason(
      stage: failureStage,
      reason: failureDetail,
    ),
    'hd_type': hdType,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

/// E22: Bridge failed
class AnalyticsBridgeFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsBridgeFailedEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required String failureStage,
    String? failureDetail,
    required String hdType,
    int? durationMs,
  }) : super(
         BridgeFailedEventData(
           asset: asset,
           secondaryAsset: secondaryAsset,
           network: network,
           secondaryNetwork: secondaryNetwork,
           failureStage: failureStage,
           failureDetail: failureDetail,
           hdType: hdType,
           durationMs: durationMs,
         ),
       );
}

String _formatFailureReason({String? stage, String? reason, String? code}) {
  final parts = <String>[];

  String? sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final sanitizedStage = sanitize(stage);
  final sanitizedReason = sanitize(reason);
  final sanitizedCode = sanitize(code);

  if (sanitizedStage != null) {
    parts.add('stage:$sanitizedStage');
  }
  if (sanitizedReason != null) {
    parts.add('reason:$sanitizedReason');
  }
  if (sanitizedCode != null && sanitizedCode != sanitizedReason) {
    parts.add('code:$sanitizedCode');
  }

  if (parts.isEmpty) {
    return 'reason:unknown';
  }
  return parts.join('|');
}
