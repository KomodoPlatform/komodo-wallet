import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';

import '../../bloc/analytics/analytics_repo.dart';

// E14: Send flow started
// ------------------------------------------

/// E14: Send flow started
/// Measures when a user initiates a send transaction. Business category: Transactions.
/// Provides insights on transaction funnel start and popular send assets.
class SendInitiatedEventData extends AnalyticsEventData {
  const SendInitiatedEventData({
    required this.asset,
    required this.network,
    required this.amount,
    required this.hdType,
  });

  final String asset;
  final String network;
  final double amount;
  final String hdType;

  @override
  String get name => 'send_initiated';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'network': network,
    'amount': amount,
    'hd_type': hdType,
  };
}

/// E14: Send flow started
class AnalyticsSendInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendInitiatedEvent({
    required String asset,
    required String network,
    required double amount,
    required String hdType,
  }) : super(
         SendInitiatedEventData(
           asset: asset,
           network: network,
           amount: amount,
           hdType: hdType,
         ),
       );
}

// E15: On-chain send completed
// ------------------------------------------

/// E15: On-chain send completed
/// Measures when an on-chain send transaction is completed successfully. Business category: Transactions.
/// Provides insights on successful sends, volume, and average size.
class SendSucceededEventData extends AnalyticsEventData {
  const SendSucceededEventData({
    required this.asset,
    required this.network,
    required this.amount,
    required this.hdType,
  });

  final String asset;
  final String network;
  final double amount;
  final String hdType;

  @override
  String get name => 'send_success';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'network': network,
    'amount': amount,
    'hd_type': hdType,
  };
}

/// E15: On-chain send completed
class AnalyticsSendSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSendSucceededEvent({
    required String asset,
    required String network,
    required double amount,
    required String hdType,
  }) : super(
         SendSucceededEventData(
           asset: asset,
           network: network,
           amount: amount,
           hdType: hdType,
         ),
       );
}

// E16: Send failed / cancelled
// ------------------------------------------

/// E16: Send failed / cancelled
/// Measures when a send transaction fails or is cancelled. Business category: Transactions.
/// Provides insights on error hotspots and UX/network issues.
class SendFailedEventData extends AnalyticsEventData {
  const SendFailedEventData({
    required this.asset,
    required this.network,
    required this.failureReason,
    required this.hdType,
  });

  final String asset;
  final String network;
  final String failureReason;
  final String hdType;

  @override
  String get name => 'send_failure';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'network': network,
    'failure_reason': _formatFailureReason(reason: failureReason),
    'hd_type': hdType,
  };
}

/// E16: Send failed / cancelled
class AnalyticsSendFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendFailedEvent({
    required String asset,
    required String network,
    required String failureReason,
    required String hdType,
  }) : super(
         SendFailedEventData(
           asset: asset,
           network: network,
           failureReason: failureReason,
           hdType: hdType,
         ),
       );
}

// E17: Swap order submitted
// ------------------------------------------

/// E17: Swap order submitted
/// Measures when a swap order is submitted. Business category: Trading (DEX).
/// Provides insights on DEX funnel start and pair demand.
class SwapInitiatedEventData extends AnalyticsEventData {
  const SwapInitiatedEventData({
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
  String get name => 'swap_initiated';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'secondary_asset': secondaryAsset,
    'network': network,
    'secondary_network': secondaryNetwork,
    'hd_type': hdType,
  };
}

/// E17: Swap order submitted
class AnalyticsSwapInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapInitiatedEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required String hdType,
  }) : super(
         SwapInitiatedEventData(
           asset: asset,
           secondaryAsset: secondaryAsset,
           network: network,
           secondaryNetwork: secondaryNetwork,
           hdType: hdType,
         ),
       );
}

// E18: Atomic swap succeeded
// ------------------------------------------

/// E18: Atomic swap succeeded
/// Measures when an atomic swap is completed successfully. Business category: Trading (DEX).
/// Provides insights on trading volume and fee revenue.
class SwapSucceededEventData extends AnalyticsEventData {
  const SwapSucceededEventData({
    required this.asset,
    required this.secondaryAsset,
    required this.network,
    required this.secondaryNetwork,
    required this.amount,
    required this.fee,
    required this.hdType,
    this.durationMs,
  });

  final String asset;
  final String secondaryAsset;
  final String network;
  final String secondaryNetwork;
  final double amount;
  final double fee;
  final String hdType;
  final int? durationMs;

  @override
  String get name => 'swap_success';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'secondary_asset': secondaryAsset,
    'network': network,
    'secondary_network': secondaryNetwork,
    'amount': amount,
    'fee': fee,
    'hd_type': hdType,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

/// E18: Atomic swap succeeded
class AnalyticsSwapSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapSucceededEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required double amount,
    required double fee,
    required String hdType,
    int? durationMs,
  }) : super(
         SwapSucceededEventData(
           asset: asset,
           secondaryAsset: secondaryAsset,
           network: network,
           secondaryNetwork: secondaryNetwork,
           amount: amount,
           fee: fee,
           hdType: hdType,
           durationMs: durationMs,
         ),
       );
}

// E19: Swap failed
// ------------------------------------------

/// E19: Swap failed
/// Measures when an atomic swap fails. Business category: Trading (DEX).
/// Provides insights on liquidity gaps and technical/UX blockers.
class SwapFailedEventData extends AnalyticsEventData {
  const SwapFailedEventData({
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
  String get name => 'swap_failure';

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

/// E19: Swap failed
class AnalyticsSwapFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapFailedEvent({
    required String asset,
    required String secondaryAsset,
    required String network,
    required String secondaryNetwork,
    required String failureStage,
    String? failureDetail,
    required String hdType,
    int? durationMs,
  }) : super(
         SwapFailedEventData(
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
