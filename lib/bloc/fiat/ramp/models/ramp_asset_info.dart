import 'package:decimal/decimal.dart';

class RampAssetInfo {
  final String name;
  final String symbol;
  final int decimals;
  final Map<String, dynamic> price;
  final Decimal? minPurchaseAmount;
  final Decimal? maxPurchaseAmount;
  final String? address;
  final String chain;
  final String currencyCode;
  final bool enabled;
  final bool hidden;
  final String logoUrl;
  final String minPurchaseCryptoAmount;
  final Decimal networkFee;
  final String type;

  RampAssetInfo({
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.price,
    this.minPurchaseAmount,
    this.maxPurchaseAmount,
    this.address,
    required this.chain,
    required this.currencyCode,
    required this.enabled,
    required this.hidden,
    required this.logoUrl,
    required this.minPurchaseCryptoAmount,
    required this.networkFee,
    required this.type,
  });

  /// Returns true if this asset has a valid minimum purchase amount.
  /// A value of -1 indicates no limit.
  bool hasValidMinPurchaseAmount() {
    if (minPurchaseAmount == null) return false;
    return minPurchaseAmount! > Decimal.fromInt(-1);
  }

  /// Returns true if this asset has a valid maximum purchase amount.
  /// A value of -1 indicates no limit.
  bool hasValidMaxPurchaseAmount() {
    if (maxPurchaseAmount == null) return false;
    return maxPurchaseAmount! > Decimal.fromInt(-1);
  }

  factory RampAssetInfo.fromJson(Map<String, dynamic> json) {
    return RampAssetInfo(
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      decimals: json['decimals'] as int,
      price: json['price'] as Map<String, dynamic>,
      minPurchaseAmount: json['minPurchaseAmount'] != null
          ? Decimal.tryParse(json['minPurchaseAmount'].toString())
          : null,
      maxPurchaseAmount: json['maxPurchaseAmount'] != null
          ? Decimal.tryParse(json['maxPurchaseAmount'].toString())
          : null,
      address: json['address'] as String?,
      chain: json['chain'] as String,
      currencyCode: json['currencyCode'] as String,
      enabled: json['enabled'] as bool,
      hidden: json['hidden'] as bool,
      logoUrl: json['logoUrl'] as String,
      minPurchaseCryptoAmount: json['minPurchaseCryptoAmount'] as String,
      networkFee: Decimal.parse(json['networkFee'].toString()),
      type: json['type'] as String,
    );
  }
}
