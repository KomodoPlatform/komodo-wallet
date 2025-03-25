import 'package:decimal/decimal.dart';

class RampQuoteResultForPaymentMethod {
  final String fiatCurrency;
  final Decimal cryptoAmount;
  final Decimal fiatValue;
  final Decimal baseRampFee;
  final Decimal appliedFee;
  final Decimal? hostFeeCut;

  RampQuoteResultForPaymentMethod({
    required this.fiatCurrency,
    required this.cryptoAmount,
    required this.fiatValue,
    required this.baseRampFee,
    required this.appliedFee,
    this.hostFeeCut,
  });

  factory RampQuoteResultForPaymentMethod.fromJson(Map<String, dynamic> json) {
    return RampQuoteResultForPaymentMethod(
      fiatCurrency: json['fiatCurrency'] as String,
      cryptoAmount: Decimal.parse(json['cryptoAmount'] as String),
      fiatValue: Decimal.parse(json['fiatValue'].toString()),
      baseRampFee: Decimal.parse(json['baseRampFee'].toString()),
      appliedFee: Decimal.parse(json['appliedFee'].toString()),
      hostFeeCut: json['hostFeeCut'] != null
          ? Decimal.parse(json['hostFeeCut'].toString())
          : null,
    );
  }
}
