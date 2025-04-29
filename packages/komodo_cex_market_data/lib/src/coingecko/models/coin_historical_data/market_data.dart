import 'package:equatable/equatable.dart';

import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/current_price.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/market_cap.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/total_volume.dart';

class MarketData extends Equatable {
  const MarketData({this.currentPrice, this.marketCap, this.totalVolume});

  factory MarketData.fromJson(Map<String, dynamic> json) => MarketData(
        currentPrice: json['current_price'] == null
            ? null
            : CurrentPrice.fromJson(
                json['current_price'] as Map<String, dynamic>,
              ),
        marketCap: json['market_cap'] == null
            ? null
            : MarketCap.fromJson(json['market_cap'] as Map<String, dynamic>),
        totalVolume: json['total_volume'] == null
            ? null
            : TotalVolume.fromJson(
                json['total_volume'] as Map<String, dynamic>,
              ),
      );
  final CurrentPrice? currentPrice;
  final MarketCap? marketCap;
  final TotalVolume? totalVolume;

  Map<String, dynamic> toJson() => {
        'current_price': currentPrice?.toJson(),
        'market_cap': marketCap?.toJson(),
        'total_volume': totalVolume?.toJson(),
      };

  MarketData copyWith({
    CurrentPrice? currentPrice,
    MarketCap? marketCap,
    TotalVolume? totalVolume,
  }) {
    return MarketData(
      currentPrice: currentPrice ?? this.currentPrice,
      marketCap: marketCap ?? this.marketCap,
      totalVolume: totalVolume ?? this.totalVolume,
    );
  }

  @override
  List<Object?> get props => [currentPrice, marketCap, totalVolume];
}
