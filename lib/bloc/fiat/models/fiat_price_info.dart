import 'package:equatable/equatable.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FiatPriceInfo extends Equatable {
  const FiatPriceInfo({
    required this.fiatAmount,
    required this.coinAmount,
    required this.fiatCode,
    required this.coinCode,
    required this.spotPriceIncludingFee,
  });

  const FiatPriceInfo.zero()
      : fiatAmount = 0,
        coinAmount = 0,
        fiatCode = '',
        coinCode = '',
        spotPriceIncludingFee = 0;

  factory FiatPriceInfo.fromJson(Map<String, dynamic> json) {
    return FiatPriceInfo(
      fiatAmount: _parseFiatAmount(json),
      coinAmount: _parseCoinAmount(json),
      fiatCode: json['fiat_code'] as String? ?? '',
      coinCode: json['coin_code'] as String? ?? '',
      spotPriceIncludingFee: assertDouble(json['spot_price_including_fee']),
    );
  }

  static double _parseFiatAmount(Map<String, dynamic> json) =>
      double.parse(json['fiat_amount'] as String? ?? '0');

  static double _parseCoinAmount(Map<String, dynamic> json) =>
      double.parse(json['coin_amount'] as String? ?? '0');

  final double fiatAmount;
  final double coinAmount;
  final String fiatCode;
  final String coinCode;
  final double spotPriceIncludingFee;

  FiatPriceInfo copyWith({
    double? fiatAmount,
    double? coinAmount,
    String? fiatCode,
    String? coinCode,
    double? spotPriceIncludingFee,
  }) {
    return FiatPriceInfo(
      fiatAmount: fiatAmount ?? this.fiatAmount,
      coinAmount: coinAmount ?? this.coinAmount,
      fiatCode: fiatCode ?? this.fiatCode,
      coinCode: coinCode ?? this.coinCode,
      spotPriceIncludingFee:
          spotPriceIncludingFee ?? this.spotPriceIncludingFee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fiat_amount': fiatAmount,
      'coin_amount': coinAmount,
      'fiat_code': fiatCode,
      'coin_code': coinCode,
      'spot_price_including_fee': spotPriceIncludingFee,
    };
  }

  @override
  List<Object?> get props => [
        fiatAmount,
        coinAmount,
        fiatCode,
        coinCode,
        spotPriceIncludingFee,
      ];
}
