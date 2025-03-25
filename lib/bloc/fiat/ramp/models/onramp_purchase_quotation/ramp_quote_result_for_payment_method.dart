import 'package:decimal/decimal.dart';

/// Represents a quotation result for a specific payment method in a ramp transaction.
///
/// This class contains all the financial details related to a crypto purchase
/// through a ramp service, including fees and currency information.
class RampQuoteResultForPaymentMethod {
  /// The currency code for the fiat currency being used in the transaction.
  final String fiatCurrency;

  /// The amount of cryptocurrency that will be received.
  final Decimal cryptoAmount;

  /// The fiat value being exchanged in the transaction.
  final Decimal fiatValue;

  /// The base fee charged by the ramp service.
  final Decimal baseRampFee;

  /// The actual fee applied to this specific transaction.
  final Decimal appliedFee;

  /// Optional fee cut taken by the host platform, if applicable.
  final Decimal? hostFeeCut;

  RampQuoteResultForPaymentMethod({
    required this.fiatCurrency,
    required this.cryptoAmount,
    required this.fiatValue,
    required this.baseRampFee,
    required this.appliedFee,
    this.hostFeeCut,
  });

  /// Creates a [RampQuoteResultForPaymentMethod] from a JSON object.
  ///
  /// Validates essential fields and parses decimal values appropriately.
  ///
  /// Throws [FormatException] if decimal parsing fails.
  /// Throws [ArgumentError] if required fields are missing or of incorrect type.
  factory RampQuoteResultForPaymentMethod.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['fiatCurrency'] == null) {
      throw ArgumentError.notNull('fiatCurrency');
    }
    if (json['cryptoAmount'] == null) {
      throw ArgumentError.notNull('cryptoAmount');
    }
    if (json['fiatValue'] == null) {
      throw ArgumentError.notNull('fiatValue');
    }
    if (json['baseRampFee'] == null) {
      throw ArgumentError.notNull('baseRampFee');
    }
    if (json['appliedFee'] == null) {
      throw ArgumentError.notNull('appliedFee');
    }

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
