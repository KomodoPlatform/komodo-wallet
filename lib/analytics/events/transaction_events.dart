import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';

import '../../bloc/analytics/analytics_repo.dart';

// E14: Send flow started
// ------------------------------------------

/// E14: Send flow started
/// Measures when a user initiates a send transaction. Business category: Transactions.
/// Provides insights on transaction funnel start and popular send assets.
class SendInitiatedEventData implements AnalyticsEventData {
  const SendInitiatedEventData({
    required this.assetSymbol,
    required this.network,
    required this.amount,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final double amount;
  final String walletType;

  @override
  String get name => 'send_initiated';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'amount': amount,
        'wallet_type': walletType,
      };
}

/// E14: Send flow started
class AnalyticsSendInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendInitiatedEvent({
    required String assetSymbol,
    required String network,
    required double amount,
    required String walletType,
  }) : super(SendInitiatedEventData(
          assetSymbol: assetSymbol,
          network: network,
          amount: amount,
          walletType: walletType,
        ));
}

// E15: On-chain send completed
// ------------------------------------------

/// E15: On-chain send completed
/// Measures when an on-chain send transaction is completed successfully. Business category: Transactions.
/// Provides insights on successful sends, volume, and average size.
class SendSucceededEventData implements AnalyticsEventData {
  const SendSucceededEventData({
    required this.assetSymbol,
    required this.network,
    required this.amount,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final double amount;
  final String walletType;

  @override
  String get name => 'send_success';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'amount': amount,
        'wallet_type': walletType,
      };
}

/// E15: On-chain send completed
class AnalyticsSendSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSendSucceededEvent({
    required String assetSymbol,
    required String network,
    required double amount,
    required String walletType,
  }) : super(SendSucceededEventData(
          assetSymbol: assetSymbol,
          network: network,
          amount: amount,
          walletType: walletType,
        ));
}

// E16: Send failed / cancelled
// ------------------------------------------

/// E16: Send failed / cancelled
/// Measures when a send transaction fails or is cancelled. Business category: Transactions.
/// Provides insights on error hotspots and UX/network issues.
class SendFailedEventData implements AnalyticsEventData {
  const SendFailedEventData({
    required this.assetSymbol,
    required this.network,
    required this.failReason,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final String failReason;
  final String walletType;

  @override
  String get name => 'send_failure';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'fail_reason': failReason,
        'wallet_type': walletType,
      };
}

/// E16: Send failed / cancelled
class AnalyticsSendFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendFailedEvent({
    required String assetSymbol,
    required String network,
    required String failReason,
    required String walletType,
  }) : super(SendFailedEventData(
          assetSymbol: assetSymbol,
          network: network,
          failReason: failReason,
          walletType: walletType,
        ));
}

// E17: Swap order submitted
// ------------------------------------------

/// E17: Swap order submitted
/// Measures when a swap order is submitted. Business category: Trading (DEX).
/// Provides insights on DEX funnel start and pair demand.
class SwapInitiatedEventData implements AnalyticsEventData {
  const SwapInitiatedEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.networks,
    required this.walletType,
  });

  final String fromAsset;
  final String toAsset;
  final String networks;
  final String walletType;

  @override
  String get name => 'swap_initiated';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'networks': networks,
        'wallet_type': walletType,
      };
}

/// E17: Swap order submitted
class AnalyticsSwapInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapInitiatedEvent({
    required String fromAsset,
    required String toAsset,
    required String networks,
    required String walletType,
  }) : super(SwapInitiatedEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          networks: networks,
          walletType: walletType,
        ));
}

// E18: Atomic swap succeeded
// ------------------------------------------

/// E18: Atomic swap succeeded
/// Measures when an atomic swap is completed successfully. Business category: Trading (DEX).
/// Provides insights on trading volume and fee revenue.
class SwapSucceededEventData implements AnalyticsEventData {
  const SwapSucceededEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.amount,
    required this.fee,
    required this.walletType,
    this.durationMs,
  });

  final String fromAsset;
  final String toAsset;
  final double amount;
  final double fee;
  final String walletType;
  final int? durationMs;

  @override
  String get name => 'swap_success';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'amount': amount,
        'fee': fee,
        'wallet_type': walletType,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

/// E18: Atomic swap succeeded
class AnalyticsSwapSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapSucceededEvent({
    required String fromAsset,
    required String toAsset,
    required double amount,
    required double fee,
    required String walletType,
    int? durationMs,
  }) : super(SwapSucceededEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          amount: amount,
          fee: fee,
          walletType: walletType,
          durationMs: durationMs,
        ));
}

// E19: Swap failed
// ------------------------------------------

/// E19: Swap failed
/// Measures when an atomic swap fails. Business category: Trading (DEX).
/// Provides insights on liquidity gaps and technical/UX blockers.
class SwapFailedEventData implements AnalyticsEventData {
  const SwapFailedEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.failStage,
    required this.walletType,
    this.durationMs,
  });

  final String fromAsset;
  final String toAsset;
  final String failStage;
  final String walletType;
  final int? durationMs;

  @override
  String get name => 'swap_failure';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'fail_stage': failStage,
        'wallet_type': walletType,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

/// E19: Swap failed
class AnalyticsSwapFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapFailedEvent({
    required String fromAsset,
    required String toAsset,
    required String failStage,
    required String walletType,
    int? durationMs,
  }) : super(SwapFailedEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          failStage: failStage,
          walletType: walletType,
          durationMs: durationMs,
        ));
}
