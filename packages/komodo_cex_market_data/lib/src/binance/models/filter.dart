/// Represents a filter applied to a symbol.
class Filter {
  /// Creates a new instance of [Filter].
  Filter({
    required this.filterType,
    this.minPrice,
    this.maxPrice,
    this.tickSize,
    this.minQty,
    this.maxQty,
    this.stepSize,
    this.limit,
    this.minNotional,
    this.applyMinToMarket,
    this.maxNotional,
    this.applyMaxToMarket,
    this.avgPriceMins,
    this.maxNumOrders,
    this.maxNumAlgoOrders,
  });

  /// Creates a new instance of [Filter] from a JSON map.
  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      filterType: json['filterType'] as String,
      minPrice: json['minPrice'] as String?,
      maxPrice: json['maxPrice'] as String?,
      tickSize: json['tickSize'] as String?,
      minQty: json['minQty'] as String?,
      maxQty: json['maxQty'] as String?,
      stepSize: json['stepSize'] as String?,
      limit: json['limit'] as int?,
      minNotional: json['minNotional'] as String?,
      applyMinToMarket: json['applyMinToMarket'] as bool?,
      maxNotional: json['maxNotional'] as String?,
      applyMaxToMarket: json['applyMaxToMarket'] as bool?,
      avgPriceMins: json['avgPriceMins'] as int?,
      maxNumOrders: json['maxNumOrders'] as int?,
      maxNumAlgoOrders: json['maxNumAlgoOrders'] as int?,
    );
  }

  /// The type of filter.
  String filterType;

  /// The minimum price allowed for the symbol.
  String? minPrice;

  /// The maximum price allowed for the symbol.
  String? maxPrice;

  /// The tick size for the symbol.
  String? tickSize;

  /// The minimum quantity allowed for the symbol.
  String? minQty;

  /// The maximum quantity allowed for the symbol.
  String? maxQty;

  /// The step size for the symbol.
  String? stepSize;

  /// The maximum number of orders allowed for the symbol.
  int? limit;

  /// The minimum notional value allowed for the symbol.
  String? minNotional;

  /// Whether the minimum notional value applies to market orders.
  bool? applyMinToMarket;

  /// The maximum notional value allowed for the symbol.
  String? maxNotional;

  /// Whether the maximum notional value applies to market orders.
  bool? applyMaxToMarket;

  /// The number of minutes required to calculate the average price.
  int? avgPriceMins;

  /// The maximum number of orders allowed for the symbol.
  int? maxNumOrders;

  /// The maximum number of algorithmic orders allowed for the symbol.
  int? maxNumAlgoOrders;
}
