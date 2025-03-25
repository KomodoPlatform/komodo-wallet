import 'package:web_dex/bloc/fiat/ramp/models/models.dart';

class RampQuoteResult {
  final RampAssetInfo asset;
  final Map<String, RampQuoteResultForPaymentMethod> paymentMethods;

  RampQuoteResult({
    required this.asset,
    required this.paymentMethods,
  });

  factory RampQuoteResult.fromJson(Map<String, dynamic> json) {
    final paymentMethods = <String, RampQuoteResultForPaymentMethod>{};
    final assetJson = json['asset'] as Map<String, dynamic>;
    final asset = RampAssetInfo.fromJson(assetJson);

    json.forEach((key, value) {
      if (key != 'asset' && value is Map<String, dynamic>) {
        paymentMethods[key] = RampQuoteResultForPaymentMethod.fromJson(value);
      }
    });

    return RampQuoteResult(
      asset: asset,
      paymentMethods: paymentMethods,
    );
  }

  RampQuoteResultForPaymentMethod? getPaymentMethod(String methodId) {
    return paymentMethods[methodId];
  }
}
