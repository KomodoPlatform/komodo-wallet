import 'package:rational/rational.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/trade_preimage/trade_preimage_request.dart';
import 'package:komodo_wallet/model/trade_preimage_extended_fee_info.dart';

class TradePreimage {
  TradePreimage({
    required this.baseCoinFee,
    required this.relCoinFee,
    required this.volume,
    required this.volumeFract,
    required this.takerFee,
    required this.totalFees,
    required this.feeToSendTakerFee,
    required this.request,
  });

  final TradePreimageExtendedFeeInfo baseCoinFee;
  final TradePreimageExtendedFeeInfo relCoinFee;
  final String? volume;
  final Rational? volumeFract;
  final TradePreimageExtendedFeeInfo? takerFee;
  final TradePreimageExtendedFeeInfo? feeToSendTakerFee;
  final List<TradePreimageExtendedFeeInfo> totalFees;
  final TradePreimageRequest request;
}
