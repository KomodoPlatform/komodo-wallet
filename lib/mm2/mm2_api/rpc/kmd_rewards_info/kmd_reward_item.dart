import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class KmdRewardItem {
  KmdRewardItem({
    required this.txHash,
    required this.height,
    required this.outputIndex,
    required this.amount,
    required this.lockTime,
    required this.reward,
    required this.accrueStartAt,
    required this.accrueStopAt,
    String? error,
  }) {
    _error = error != null && error.isNotEmpty ? _getError(error) : null;
  }

  factory KmdRewardItem.fromJson(Map<String, dynamic> json) {
    final double? reward = json['accrued_rewards']?['Accrued'] != null
        ? double.tryParse(json['accrued_rewards']['Accrued'])
        : null;
    final String? error = json['accrued_rewards']?['NotAccruedReason'];

    return KmdRewardItem(
      txHash: json['tx_hash'],
      height: json['height'],
      outputIndex: json['output_index'],
      amount: json['amount'],
      lockTime: json['locktime'],
      reward: reward,
      accrueStartAt: json['accrue_start_at'],
      accrueStopAt: json['accrue_stop_at'],
      error: error,
    );
  }

  final String txHash;
  final String amount;
  final int? outputIndex;
  final int? lockTime;
  final double? reward;
  final int? height;
  final int? accrueStartAt;
  final int? accrueStopAt;
  RewardItemError? _error;

  Duration? get timeLeft {
    if (accrueStopAt == null) {
      return null;
    }
    return Duration(
        milliseconds:
            accrueStopAt! * 1000 - DateTime.now().millisecondsSinceEpoch);
  }

  RewardItemError? get error {
    return _error;
  }
}

class RewardItemError {
  RewardItemError({required this.short, required this.long});

  final String short;
  final String long;
}

RewardItemError _getError(String errorKey) {
  switch (errorKey) {
    case 'UtxoAmountLessThanTen':
      return RewardItemError(
        short: '<10 KMD',
        long: LocaleKeys.rewardLessThanTenLong.tr(),
      );
    case 'TransactionInMempool':
      return RewardItemError(
          short: LocaleKeys.rewardProcessingShort.tr().toLowerCase(),
          long: LocaleKeys.rewardProcessingLong.tr());
    case 'OneHourNotPassedYet':
      return RewardItemError(
          short: LocaleKeys.rewardOneHourNotPassedShort.tr(),
          long: LocaleKeys.rewardOneHourNotPassedLong.tr());
    default:
      return RewardItemError(short: '?', long: '');
  }
}
