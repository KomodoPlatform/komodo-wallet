import 'package:web_dex/bloc/fiat/ramp/models/models.dart';

/// Represents a complete quote result from a ramp service provider.
///
/// This class combines asset information with available payment method options
/// and their respective quotation details.
class RampQuoteResult {
  /// Information about the cryptocurrency asset being purchased.
  final RampAssetInfo asset;

  /// Available payment methods mapped by their unique identifiers.
  /// Each payment method contains specific quote details like fees and amounts.
  final Map<String, RampQuoteResultForPaymentMethod> paymentMethods;

  RampQuoteResult({
    required this.asset,
    required this.paymentMethods,
  });

  /// Creates a [RampQuoteResult] from a JSON object.
  ///
  /// Extracts the asset information and processes all payment methods in the response.
  ///
  /// Throws [ArgumentError] if required fields are missing or of incorrect type.
  /// Throws [FormatException] if parsing of nested objects fails.
  factory RampQuoteResult.fromJson(Map<String, dynamic> json) {
    // Validate 'asset' field exists
    if (json['asset'] == null) {
      throw ArgumentError.notNull('asset');
    }

    final assetJson = json['asset'];
    if (assetJson is! Map<String, dynamic>) {
      throw ArgumentError.value(assetJson, 'asset', 'Must be a JSON object');
    }

    final paymentMethods = <String, RampQuoteResultForPaymentMethod>{};
    final asset = RampAssetInfo.fromJson(assetJson);

    json.forEach((key, value) {
      if (key != 'asset' && value is Map<String, dynamic>) {
        paymentMethods[key] = RampQuoteResultForPaymentMethod.fromJson(value);
      }
    });

    // Ensure we have at least one payment method
    if (paymentMethods.isEmpty) {
      throw ArgumentError('No payment methods found in the response');
    }

    return RampQuoteResult(
      asset: asset,
      paymentMethods: paymentMethods,
    );
  }

  /// Retrieves quote information for a specific payment method by its ID.
  ///
  /// Returns null if the requested payment method is not available.
  ///
  /// [methodId] The unique identifier of the payment method to retrieve.
  RampQuoteResultForPaymentMethod? getPaymentMethod(String methodId) {
    return paymentMethods[methodId];
  }
}
