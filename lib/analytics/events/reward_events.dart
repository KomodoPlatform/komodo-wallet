import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E31: KMD reward claim started
class RewardClaimInitiatedEventData extends AnalyticsEventData {
  const RewardClaimInitiatedEventData({
    required this.asset,
    required this.expectedRewardAmount,
  });

  final String asset;
  final double expectedRewardAmount;

  @override
  String get name => 'reward_claim_initiated';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'expected_reward_amount': expectedRewardAmount,
  };
}

class AnalyticsRewardClaimInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsRewardClaimInitiatedEvent({
    required String asset,
    required double expectedRewardAmount,
  }) : super(
         RewardClaimInitiatedEventData(
           asset: asset,
           expectedRewardAmount: expectedRewardAmount,
         ),
       );
}

/// E32: KMD reward claim succeeded
class RewardClaimSuccessEventData extends AnalyticsEventData {
  const RewardClaimSuccessEventData({
    required this.asset,
    required this.rewardAmount,
  });

  final String asset;
  final double rewardAmount;

  @override
  String get name => 'reward_claim_success';

  @override
  JsonMap get parameters => {'asset': asset, 'amount': rewardAmount};
}

class AnalyticsRewardClaimSuccessEvent extends AnalyticsSendDataEvent {
  AnalyticsRewardClaimSuccessEvent({
    required String asset,
    required double rewardAmount,
  }) : super(
         RewardClaimSuccessEventData(asset: asset, rewardAmount: rewardAmount),
       );
}

/// E33: Reward claim failed
class RewardClaimFailureEventData extends AnalyticsEventData {
  const RewardClaimFailureEventData({
    required this.asset,
    required this.failReason,
  });

  final String asset;
  final String failReason;

  @override
  String get name => 'reward_claim_failure';

  @override
  JsonMap get parameters => {
    'asset': asset,
    'failure_reason': _formatFailureReason(reason: failReason),
  };
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

class AnalyticsRewardClaimFailureEvent extends AnalyticsSendDataEvent {
  AnalyticsRewardClaimFailureEvent({
    required String asset,
    required String failReason,
  }) : super(RewardClaimFailureEventData(asset: asset, failReason: failReason));
}
