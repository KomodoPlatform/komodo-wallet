/// A reduced version of [Symbol] with the bare minimum required fields.
/// This class is used to reduce the amount of data fetched parsed from the
/// Binance API response to reduce memory and CPU usage.
class SymbolReduced {
  /// Creates a new instance of [SymbolReduced].
  SymbolReduced({
    required this.symbol,
    required this.status,
    required this.baseAsset,
    required this.baseAssetPrecision,
    required this.quoteAsset,
    required this.quotePrecision,
    required this.quoteAssetPrecision,
    required this.isSpotTradingAllowed,
  });

  /// Creates a new instance of [SymbolReduced] from a JSON map.
  factory SymbolReduced.fromJson(Map<String, dynamic> json) {
    return SymbolReduced(
      symbol: json['symbol'] as String,
      status: json['status'] as String,
      baseAsset: json['baseAsset'] as String,
      baseAssetPrecision: json['baseAssetPrecision'] as int,
      quoteAsset: json['quoteAsset'] as String,
      quotePrecision: json['quotePrecision'] as int,
      quoteAssetPrecision: json['quoteAssetPrecision'] as int,
      isSpotTradingAllowed: json['isSpotTradingAllowed'] as bool,
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

  /// Whether spot trading is allowed for the symbol.
  bool isSpotTradingAllowed;
}
