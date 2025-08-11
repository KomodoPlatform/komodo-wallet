import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class FiatPriceInfo extends Equatable {
  const FiatPriceInfo({
    required this.fiatAmount,
    required this.coinAmount,
    required this.fiatCode,
    required this.coinCode,
    required this.spotPriceIncludingFee,
  });

  factory FiatPriceInfo.fromJson(JsonMap json) {
    return FiatPriceInfo(
      fiatAmount: json.valueOrNull<Decimal>('fiat_amount') ?? Decimal.zero,
      coinAmount: json.valueOrNull<Decimal>('coin_amount') ?? Decimal.zero,
      fiatCode: json.valueOrNull<String>('fiat_code') ?? '',
      coinCode: json.valueOrNull<String>('coin_code') ?? '',
      spotPriceIncludingFee:
          json.valueOrNull<Decimal>('spot_price_including_fee') ?? Decimal.zero,
    );
  }

  static final zero = FiatPriceInfo(
    fiatAmount: Decimal.zero,
    coinAmount: Decimal.zero,
    fiatCode: '',
    coinCode: '',
    spotPriceIncludingFee: Decimal.zero,
  );

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

  JsonMap toJson() {
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
