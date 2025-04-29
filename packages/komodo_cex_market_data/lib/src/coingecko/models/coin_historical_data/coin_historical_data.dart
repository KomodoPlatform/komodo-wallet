import 'package:equatable/equatable.dart';

import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/community_data.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/developer_data.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/image.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/localization.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/market_data.dart';
import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/public_interest_stats.dart';

class CoinHistoricalData extends Equatable {
  const CoinHistoricalData({
    this.id,
    this.symbol,
    this.name,
    this.localization,
    this.image,
    this.marketData,
    this.communityData,
    this.developerData,
    this.publicInterestStats,
  });

  factory CoinHistoricalData.fromJson(Map<String, dynamic> json) {
    return CoinHistoricalData(
      id: json['id'] as String?,
      symbol: json['symbol'] as String?,
      name: json['name'] as String?,
      localization: json['localization'] == null
          ? null
          : Localization.fromJson(json['localization'] as Map<String, dynamic>),
      image: json['image'] == null
          ? null
          : Image.fromJson(json['image'] as Map<String, dynamic>),
      marketData: json['market_data'] == null
          ? null
          : MarketData.fromJson(json['market_data'] as Map<String, dynamic>),
      communityData: json['community_data'] == null
          ? null
          : CommunityData.fromJson(
              json['community_data'] as Map<String, dynamic>,
            ),
      developerData: json['developer_data'] == null
          ? null
          : DeveloperData.fromJson(
              json['developer_data'] as Map<String, dynamic>,
            ),
      publicInterestStats: json['public_interest_stats'] == null
          ? null
          : PublicInterestStats.fromJson(
              json['public_interest_stats'] as Map<String, dynamic>,
            ),
    );
  }
  final String? id;
  final String? symbol;
  final String? name;
  final Localization? localization;
  final Image? image;
  final MarketData? marketData;
  final CommunityData? communityData;
  final DeveloperData? developerData;
  final PublicInterestStats? publicInterestStats;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'localization': localization?.toJson(),
        'image': image?.toJson(),
        'market_data': marketData?.toJson(),
        'community_data': communityData?.toJson(),
        'developer_data': developerData?.toJson(),
        'public_interest_stats': publicInterestStats?.toJson(),
      };

  CoinHistoricalData copyWith({
    String? id,
    String? symbol,
    String? name,
    Localization? localization,
    Image? image,
    MarketData? marketData,
    CommunityData? communityData,
    DeveloperData? developerData,
    PublicInterestStats? publicInterestStats,
  }) {
    return CoinHistoricalData(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      localization: localization ?? this.localization,
      image: image ?? this.image,
      marketData: marketData ?? this.marketData,
      communityData: communityData ?? this.communityData,
      developerData: developerData ?? this.developerData,
      publicInterestStats: publicInterestStats ?? this.publicInterestStats,
    );
  }

  @override
  List<Object?> get props {
    return [
      id,
      symbol,
      name,
      localization,
      image,
      marketData,
      communityData,
      developerData,
      publicInterestStats,
    ];
  }
}
