import 'package:equatable/equatable.dart';

/// Represents the market data of a coin.
class CoinMarketData extends Equatable {
  const CoinMarketData({
    this.id,
    this.symbol,
    this.name,
    this.image,
    this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.fullyDilutedValuation,
    this.totalVolume,
    this.high24h,
    this.low24h,
    this.priceChange24h,
    this.priceChangePercentage24h,
    this.marketCapChange24h,
    this.marketCapChangePercentage24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.ath,
    this.athChangePercentage,
    this.athDate,
    this.atl,
    this.atlChangePercentage,
    this.atlDate,
    this.roi,
    this.lastUpdated,
  });

  factory CoinMarketData.fromJson(Map<String, dynamic> json) {
    return CoinMarketData(
      id: json['id'] as String?,
      symbol: json['symbol'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapRank: (json['market_cap_rank'] as num?)?.toDouble(),
      fullyDilutedValuation:
          (json['fully_diluted_valuation'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      high24h: (json['high_24h'] as num?)?.toDouble(),
      low24h: (json['low_24h'] as num?)?.toDouble(),
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      marketCapChange24h: (json['market_cap_change_24h'] as num?)?.toDouble(),
      marketCapChangePercentage24h:
          (json['market_cap_change_percentage_24h'] as num?)?.toDouble(),
      circulatingSupply: (json['circulating_supply'] as num?)?.toDouble(),
      totalSupply: (json['total_supply'] as num?)?.toDouble(),
      maxSupply: (json['max_supply'] as num?)?.toDouble(),
      ath: (json['ath'] as num?)?.toDouble(),
      athChangePercentage: (json['ath_change_percentage'] as num?)?.toDouble(),
      athDate: json['ath_date'] == null
          ? null
          : DateTime.parse(json['ath_date'] as String),
      atl: (json['atl'] as num?)?.toDouble(),
      atlChangePercentage: (json['atl_change_percentage'] as num?)?.toDouble(),
      atlDate: json['atl_date'] == null
          ? null
          : DateTime.parse(json['atl_date'] as String),
      roi: json['roi'] as dynamic,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );
  }

  /// The unique identifier of the coin.
  final String? id;

  /// The symbol of the coin.
  final String? symbol;

  /// The name of the coin.
  final String? name;

  /// The URL of the coin's image.
  final String? image;

  /// The current price of the coin.
  final double? currentPrice;

  /// The market capitalization of the coin.
  final double? marketCap;

  /// The rank of the coin based on market capitalization.
  final double? marketCapRank;

  /// The fully diluted valuation of the coin.
  final double? fullyDilutedValuation;

  /// The total trading volume of the coin in the last 24 hours.
  final double? totalVolume;

  /// The highest price of the coin in the last 24 hours.
  final double? high24h;

  /// The lowest price of the coin in the last 24 hours.
  final double? low24h;

  /// The price change of the coin in the last 24 hours.
  final double? priceChange24h;

  /// The percentage price change of the coin in the last 24 hours.
  final double? priceChangePercentage24h;

  /// The market capitalization change of the coin in the last 24 hours.
  final double? marketCapChange24h;

  /// The percentage market capitalization change of the coin in the last 24 hours.
  final double? marketCapChangePercentage24h;

  /// The circulating supply of the coin.
  final double? circulatingSupply;

  /// The total supply of the coin.
  final double? totalSupply;

  /// The maximum supply of the coin.
  final double? maxSupply;

  /// The all-time high price of the coin.
  final double? ath;

  /// The percentage change from the all-time high price of the coin.
  final double? athChangePercentage;

  /// The date when the all-time high price of the coin was reached.
  final DateTime? athDate;

  /// The all-time low price of the coin.
  final double? atl;

  /// The percentage change from the all-time low price of the coin.
  final double? atlChangePercentage;

  /// The date when the all-time low price of the coin was reached.
  final DateTime? atlDate;

  /// The return on investment (ROI) of the coin.
  final dynamic roi;

  /// The date and time when the market data was last updated.
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'symbol': symbol,
        'name': name,
        'image': image,
        'current_price': currentPrice,
        'market_cap': marketCap,
        'market_cap_rank': marketCapRank,
        'fully_diluted_valuation': fullyDilutedValuation,
        'total_volume': totalVolume,
        'high_24h': high24h,
        'low_24h': low24h,
        'price_change_24h': priceChange24h,
        'price_change_percentage_24h': priceChangePercentage24h,
        'market_cap_change_24h': marketCapChange24h,
        'market_cap_change_percentage_24h': marketCapChangePercentage24h,
        'circulating_supply': circulatingSupply,
        'total_supply': totalSupply,
        'max_supply': maxSupply,
        'ath': ath,
        'ath_change_percentage': athChangePercentage,
        'ath_date': athDate?.toIso8601String(),
        'atl': atl,
        'atl_change_percentage': atlChangePercentage,
        'atl_date': atlDate?.toIso8601String(),
        'roi': roi,
        'last_updated': lastUpdated?.toIso8601String(),
      };

  @override
  List<Object?> get props {
    return <Object?>[
      id,
      symbol,
      name,
      image,
      currentPrice,
      marketCap,
      marketCapRank,
      fullyDilutedValuation,
      totalVolume,
      high24h,
      low24h,
      priceChange24h,
      priceChangePercentage24h,
      marketCapChange24h,
      marketCapChangePercentage24h,
      circulatingSupply,
      totalSupply,
      maxSupply,
      ath,
      athChangePercentage,
      athDate,
      atl,
      atlChangePercentage,
      atlDate,
      roi,
      lastUpdated,
    ];
  }
}
