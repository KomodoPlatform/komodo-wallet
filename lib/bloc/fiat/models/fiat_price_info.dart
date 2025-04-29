import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class FiatPriceInfo extends Equatable {
  const FiatPriceInfo({
    required this.fiatAmount,
    required this.coinAmount,
    required this.fiatCode,
    required this.coinCode,
    required this.spotPriceIncludingFee,
  });

  static final zero = FiatPriceInfo(
    fiatAmount: Decimal.zero,
    coinAmount: Decimal.zero,
    fiatCode: '',
    coinCode: '',
    spotPriceIncludingFee: Decimal.zero,
  );

  factory FiatPriceInfo.fromJson(Map<String, dynamic> json) {
    return FiatPriceInfo(
      fiatAmount: Decimal.parse(json['fiat_amount']?.toString() ?? '0'),
      coinAmount: Decimal.parse(json['coin_amount']?.toString() ?? '0'),
      fiatCode: json['fiat_code'] as String? ?? '',
      coinCode: json['coin_code'] as String? ?? '',
      spotPriceIncludingFee:
          Decimal.parse(json['spot_price_including_fee']?.toString() ?? '0'),
    );
  }

  final Decimal fiatAmount;
  final Decimal coinAmount;
  final String fiatCode;
  final String coinCode;
  final Decimal spotPriceIncludingFee;

  FiatPriceInfo copyWith({
    Decimal? fiatAmount,
    Decimal? coinAmount,
    String? fiatCode,
    String? coinCode,
    Decimal? spotPriceIncludingFee,
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
      'fiat_amount': fiatAmount.toString(),
      'coin_amount': coinAmount.toString(),
      'fiat_code': fiatCode,
      'coin_code': coinCode,
      'spot_price_including_fee': spotPriceIncludingFee.toString(),
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
