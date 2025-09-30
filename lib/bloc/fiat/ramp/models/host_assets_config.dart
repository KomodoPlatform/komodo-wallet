import 'package:decimal/decimal.dart';
import 'package:web_dex/bloc/fiat/ramp/models/ramp_asset_info.dart';
import 'package:web_dex/bloc/fiat/ramp/ramp_api_utils.dart';

/// Configuration for on/off ramp provider assets and fees
///
/// Contains information about supported assets, purchase limits,
/// fee structures, and enabled features for a ramp provider.
class HostAssetsConfig {
  /// List of assets supported by the ramp provider
  final List<RampAssetInfo> assets;

  /// Optional list of enabled features for the ramp provider
  final List<String>? enabledFeatures;

  /// Currency code (e.g., 'USD', 'EUR') for transactions
  final String currencyCode;

  /// Minimum purchase amount allowed
  final Decimal minPurchaseAmount;

  /// Maximum purchase amount allowed
  final Decimal maxPurchaseAmount;

  /// Minimum fee amount applied to transactions
  final Decimal minFeeAmount;

  /// Minimum fee percentage applied to transactions
  final Decimal minFeePercent;

  /// Maximum fee percentage applied to transactions
  final Decimal maxFeePercent;

  /// Creates a new [HostAssetsConfig] instance
  HostAssetsConfig({
    required this.assets,
    required this.currencyCode,
    required this.minPurchaseAmount,
    required this.maxPurchaseAmount,
    required this.minFeeAmount,
    required this.minFeePercent,
    required this.maxFeePercent,
    this.enabledFeatures,
  });

  /// Creates a [HostAssetsConfig] from a JSON map
  ///
  /// Throws [FormatException] if required fields are missing or have invalid format
  factory HostAssetsConfig.fromJson(Map<String, dynamic> json) {
    RampApiUtils.validateResponse<Map<String, dynamic>>(
      json,
      context: 'HostAssetsConfig.fromJson',
    );

    // Validate required fields
    _validateRequiredField(json, 'assets');
    _validateRequiredField(json, 'currencyCode');
    _validateRequiredField(json, 'minPurchaseAmount');
    _validateRequiredField(json, 'maxPurchaseAmount');
    _validateRequiredField(json, 'minFeeAmount');
    _validateRequiredField(json, 'minFeePercent');
    _validateRequiredField(json, 'maxFeePercent');

    // Validate assets is a list
    if (json['assets'] is! List) {
      throw const FormatException('Field "assets" must be a list');
    }

    return HostAssetsConfig(
      assets: (json['assets'] as List<dynamic>).map((assetJson) {
        if (assetJson is! Map<String, dynamic>) {
          throw const FormatException('Each asset must be a valid JSON object');
        }
        return RampAssetInfo.fromJson(assetJson);
      }).toList(),
      enabledFeatures: json['enabledFeatures'] != null
          ? List<String>.from(json['enabledFeatures'] as List<dynamic>)
          : null,
      currencyCode: json['currencyCode'] as String,
      minPurchaseAmount: _parseDecimal(json, 'minPurchaseAmount'),
      maxPurchaseAmount: _parseDecimal(json, 'maxPurchaseAmount'),
      minFeeAmount: _parseDecimal(json, 'minFeeAmount'),
      minFeePercent: _parseDecimal(json, 'minFeePercent'),
      maxFeePercent: _parseDecimal(json, 'maxFeePercent'),
    );
  }

  /// Helper method to validate required fields in JSON
  static void _validateRequiredField(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    if (!json.containsKey(fieldName) || json[fieldName] == null) {
      throw FormatException('Required field "$fieldName" is missing or null');
    }
  }

  /// Helper method to safely parse Decimal values
  static Decimal _parseDecimal(Map<String, dynamic> json, String fieldName) {
    final value = json[fieldName];
    if (value == null) {
      throw FormatException('Field "$fieldName" is missing');
    }

    try {
      return Decimal.parse(value.toString());
    } catch (e) {
      throw FormatException(
        'Field "$fieldName" has invalid decimal format: $value',
      );
    }
  }
}
