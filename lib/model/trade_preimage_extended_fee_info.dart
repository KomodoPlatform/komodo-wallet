import 'package:rational/rational.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class TradePreimageExtendedFeeInfo {
  TradePreimageExtendedFeeInfo({
    required this.coin,
    required this.amount,
    required this.amountRational,
    required this.paidFromTradingVol,
  });
  factory TradePreimageExtendedFeeInfo.fromJson(Map<String, dynamic> json) =>
      TradePreimageExtendedFeeInfo(
        coin: json['coin'],
        amount: json['amount'],
        amountRational: fract2rat(json['amount_fraction']) ?? Rational.zero,
        paidFromTradingVol: json['paid_from_trading_vol'] ?? false,
      );

  final String coin;
  final String amount;
  final Rational amountRational;
  final bool paidFromTradingVol;
}
