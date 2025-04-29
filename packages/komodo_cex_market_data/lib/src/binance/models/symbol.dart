import 'package:komodo_cex_market_data/src/binance/models/filter.dart';

/// Represents a symbol on the exchange.
class Symbol {
  /// Creates a new instance of [Symbol].
  Symbol({
    required this.symbol,
    required this.status,
    required this.baseAsset,
    required this.baseAssetPrecision,
    required this.quoteAsset,
    required this.quotePrecision,
    required this.quoteAssetPrecision,
    required this.baseCommissionPrecision,
    required this.quoteCommissionPrecision,
    required this.orderTypes,
    required this.icebergAllowed,
    required this.ocoAllowed,
    required this.quoteOrderQtyMarketAllowed,
    required this.allowTrailingStop,
    required this.cancelReplaceAllowed,
    required this.isSpotTradingAllowed,
    required this.isMarginTradingAllowed,
    required this.filters,
    required this.permissions,
    required this.defaultSelfTradePreventionMode,
    required this.allowedSelfTradePreventionModes,
  });

  /// Creates a new instance of [Symbol] from a JSON map.
  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      symbol: json['symbol'] as String,
      status: json['status'] as String,
      baseAsset: json['baseAsset'] as String,
      baseAssetPrecision: json['baseAssetPrecision'] as int,
      quoteAsset: json['quoteAsset'] as String,
      quotePrecision: json['quotePrecision'] as int,
      quoteAssetPrecision: json['quoteAssetPrecision'] as int,
      baseCommissionPrecision: json['baseCommissionPrecision'] as int,
      quoteCommissionPrecision: json['quoteCommissionPrecision'] as int,
      orderTypes: (json['orderTypes'] as List<dynamic>)
          .map((dynamic v) => v as String)
          .toList(),
      icebergAllowed: json['icebergAllowed'] as bool,
      ocoAllowed: json['ocoAllowed'] as bool,
      quoteOrderQtyMarketAllowed: json['quoteOrderQtyMarketAllowed'] as bool,
      allowTrailingStop: json['allowTrailingStop'] as bool,
      cancelReplaceAllowed: json['cancelReplaceAllowed'] as bool,
      isSpotTradingAllowed: json['isSpotTradingAllowed'] as bool,
      isMarginTradingAllowed: json['isMarginTradingAllowed'] as bool,
      filters: (json['filters'] as List<dynamic>)
          .map((dynamic v) => Filter.fromJson(v as Map<String, dynamic>))
          .toList(),
      permissions: (json['permissions'] as List<dynamic>)
          .map((dynamic v) => v as String)
          .toList(),
      defaultSelfTradePreventionMode:
          json['defaultSelfTradePreventionMode'] as String,
      allowedSelfTradePreventionModes:
          (json['allowedSelfTradePreventionModes'] as List<dynamic>)
              .map((dynamic v) => v as String)
              .toList(),
    );
  }

  /// The symbol name.
  String symbol;

  /// The status of the symbol.
  String status;

  /// The base asset of the symbol.
  String baseAsset;

  /// The precision of the base asset.
  int baseAssetPrecision;

  /// The quote asset of the symbol.
  String quoteAsset;

  /// The precision of the quote asset.
  int quotePrecision;

  /// The precision of the quote asset for commission calculations.
  int quoteAssetPrecision;

  /// The precision of the base asset for commission calculations.
  int baseCommissionPrecision;

  /// The precision of the quote asset for commission calculations.
  int quoteCommissionPrecision;

  /// The types of orders supported for the symbol.
  List<String> orderTypes;

  /// Whether iceberg orders are allowed for the symbol.
  bool icebergAllowed;

  /// Whether OCO (One-Cancels-the-Other) orders are allowed for the symbol.
  bool ocoAllowed;

  /// Whether quote order quantity market orders are allowed for the symbol.
  bool quoteOrderQtyMarketAllowed;

  /// Whether trailing stop orders are allowed for the symbol.
  bool allowTrailingStop;

  /// Whether cancel/replace orders are allowed for the symbol.
  bool cancelReplaceAllowed;

  /// Whether spot trading is allowed for the symbol.
  bool isSpotTradingAllowed;

  /// Whether margin trading is allowed for the symbol.
  bool isMarginTradingAllowed;

  /// The filters applied to the symbol.
  List<Filter> filters;

  /// The permissions required to trade the symbol.
  List<String> permissions;

  /// The default self-trade prevention mode for the symbol.
  String defaultSelfTradePreventionMode;

  /// The allowed self-trade prevention modes for the symbol.
  List<String> allowedSelfTradePreventionModes;
}
