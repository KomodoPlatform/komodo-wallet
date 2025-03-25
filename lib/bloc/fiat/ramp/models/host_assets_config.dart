import 'package:decimal/decimal.dart';
import 'package:web_dex/bloc/fiat/ramp/models/ramp_asset_info.dart';

class HostAssetsConfig {
  final List<RampAssetInfo> assets;
  final List<String>? enabledFeatures;
  final String currencyCode;
  final Decimal minPurchaseAmount;
  final Decimal maxPurchaseAmount;
  final Decimal minFeeAmount;
  final Decimal minFeePercent;
  final Decimal maxFeePercent;

  HostAssetsConfig({
    required this.assets,
    this.enabledFeatures,
    required this.currencyCode,
    required this.minPurchaseAmount,
    required this.maxPurchaseAmount,
    required this.minFeeAmount,
    required this.minFeePercent,
    required this.maxFeePercent,
  });

  factory HostAssetsConfig.fromJson(Map<String, dynamic> json) {
    return HostAssetsConfig(
      assets: (json['assets'] as List<dynamic>)
          .map((assetJson) =>
              RampAssetInfo.fromJson(assetJson as Map<String, dynamic>))
          .toList(),
      enabledFeatures: json['enabledFeatures'] != null
          ? List<String>.from(json['enabledFeatures'] as List<dynamic>)
          : null,
      currencyCode: json['currencyCode'] as String,
      minPurchaseAmount: Decimal.parse(json['minPurchaseAmount'].toString()),
      maxPurchaseAmount: Decimal.parse(json['maxPurchaseAmount'].toString()),
      minFeeAmount: Decimal.parse(json['minFeeAmount'].toString()),
      minFeePercent: Decimal.parse(json['minFeePercent'].toString()),
      maxFeePercent: Decimal.parse(json['maxFeePercent'].toString()),
    );
  }
}
