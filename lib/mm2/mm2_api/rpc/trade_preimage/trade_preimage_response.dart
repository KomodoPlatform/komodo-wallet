import 'package:rational/rational.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/trade_preimage_extended_fee_info.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TradePreimageResponse
    implements BaseResponse<TradePreimageResponseResult> {
  TradePreimageResponse({required this.result, required this.mmrpc});
  factory TradePreimageResponse.fromJson(Map<String, dynamic> json) =>
      TradePreimageResponse(
          result: TradePreimageResponseResult.fromJson(json['result']),
          mmrpc: json['mmrpc']);
  @override
  final TradePreimageResponseResult result;
  @override
  final String mmrpc;
}

class TradePreimageResponseResult {
  TradePreimageResponseResult({
    required this.baseCoinFee,
    required this.relCoinFee,
    required this.volume,
    required this.volumeRat,
    required this.volumeFraction,
    required this.takerFee,
    required this.feeToSendTakerFee,
    required this.totalFees,
  });
  factory TradePreimageResponseResult.fromJson(Map<String, dynamic> json) =>
      TradePreimageResponseResult(
        baseCoinFee:
            TradePreimageExtendedFeeInfo.fromJson(json['base_coin_fee']),
        relCoinFee: TradePreimageExtendedFeeInfo.fromJson(json['rel_coin_fee']),
        volume: json['volume'],
        volumeRat: json['volume_rat'] != null
            ? List<List<dynamic>>.from(json['volume_rat'])
            : [],
        volumeFraction: json['volume_fraction'] != null
            ? fract2rat(json['volume_fraction'])
            : null,
        takerFee: json['taker_fee'] != null
            ? TradePreimageExtendedFeeInfo.fromJson(json['taker_fee'])
            : null,
        feeToSendTakerFee: json['fee_to_send_taker_fee'] != null
            ? TradePreimageExtendedFeeInfo.fromJson(
                json['fee_to_send_taker_fee'])
            : null,
        totalFees: (json['total_fees'] as List<dynamic>)
            .map((dynamic json) => TradePreimageExtendedFeeInfo.fromJson(json))
            .toList(),
      );
  final TradePreimageExtendedFeeInfo baseCoinFee;
  final TradePreimageExtendedFeeInfo relCoinFee;
  final String? volume;
  final List<List<dynamic>> volumeRat;
  final Rational? volumeFraction;
  final TradePreimageExtendedFeeInfo? takerFee;
  final TradePreimageExtendedFeeInfo? feeToSendTakerFee;
  final List<TradePreimageExtendedFeeInfo> totalFees;
}
