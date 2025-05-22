import '../bloc/analytics/analytics_repo.dart';

// E07: Portfolio overview opened
// ------------------------------------------

/// E07: Portfolio overview opened
/// Measures when the portfolio overview is viewed. Business category: Portfolio.
/// Provides insights on balance-check engagement.
class PortfolioViewedEventData implements AnalyticsEventData {
  const PortfolioViewedEventData({
    required this.totalCoins,
    required this.totalValueUsd,
  });

  final int totalCoins;
  final double totalValueUsd;

  @override
  String get name => 'portfolio_viewed';

  @override
  JsonMap get parameters => {
        'total_coins': totalCoins,
        'total_value_usd': totalValueUsd,
      };
}

/// E07: Portfolio overview opened
class AnalyticsPortfolioViewedEvent extends AnalyticsSendDataEvent {
  AnalyticsPortfolioViewedEvent({
    required int totalCoins,
    required double totalValueUsd,
  }) : super(
          PortfolioViewedEventData(
            totalCoins: totalCoins,
            totalValueUsd: totalValueUsd,
          ),
        );
}

// E08: Growth chart opened
// ------------------------------------------

/// E08: Growth chart opened
/// Measures when a user opens the growth chart. Business category: Portfolio.
/// Provides insights on long-term performance interest.
class PortfolioGrowthViewedEventData implements AnalyticsEventData {
  const PortfolioGrowthViewedEventData({
    required this.period,
    required this.growthPct,
  });

  final String period;
  final double growthPct;

  @override
  String get name => 'portfolio_growth_viewed';

  @override
  JsonMap get parameters => {
        'period': period,
        'growth_pct': growthPct,
      };
}

/// E08: Growth chart opened
class AnalyticsPortfolioGrowthViewedEvent extends AnalyticsSendDataEvent {
  AnalyticsPortfolioGrowthViewedEvent({
    required String period,
    required double growthPct,
  }) : super(
          PortfolioGrowthViewedEventData(
            period: period,
            growthPct: growthPct,
          ),
        );
}

// E09: P&L breakdown viewed
// ------------------------------------------

/// E09: P&L breakdown viewed
/// Measures when a user views the P&L breakdown. Business category: Portfolio.
/// Provides insights on trading insight demand and upsell cues.
class PortfolioPnlViewedEventData implements AnalyticsEventData {
  const PortfolioPnlViewedEventData({
    required this.timeframe,
    required this.realizedPnl,
    required this.unrealizedPnl,
  });

  final String timeframe;
  final double realizedPnl;
  final double unrealizedPnl;

  @override
  String get name => 'portfolio_pnl_viewed';

  @override
  JsonMap get parameters => {
        'timeframe': timeframe,
        'realized_pnl': realizedPnl,
        'unrealized_pnl': unrealizedPnl,
      };
}

/// E09: P&L breakdown viewed
class AnalyticsPortfolioPnlViewedEvent extends AnalyticsSendDataEvent {
  AnalyticsPortfolioPnlViewedEvent({
    required String timeframe,
    required double realizedPnl,
    required double unrealizedPnl,
  }) : super(
          PortfolioPnlViewedEventData(
            timeframe: timeframe,
            realizedPnl: realizedPnl,
            unrealizedPnl: unrealizedPnl,
          ),
        );
}

// E10: Custom token added
// ------------------------------------------

/// E10: Custom token added
/// Measures when a user adds a custom token. Business category: Asset Management.
/// Provides insights on token diversity and network popularity.
class AssetAddedEventData implements AnalyticsEventData {
  const AssetAddedEventData({
    required this.assetSymbol,
    required this.assetNetwork,
    required this.walletType,
  });

  final String assetSymbol;
  final String assetNetwork;
  final String walletType;

  @override
  String get name => 'add_asset';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'asset_network': assetNetwork,
        'wallet_type': walletType,
      };
}

/// E10: Custom token added
class AnalyticsAssetAddedEvent extends AnalyticsSendDataEvent {
  AnalyticsAssetAddedEvent({
    required String assetSymbol,
    required String assetNetwork,
    required String walletType,
  }) : super(
          AssetAddedEventData(
            assetSymbol: assetSymbol,
            assetNetwork: assetNetwork,
            walletType: walletType,
          ),
        );
}

// E11: Asset detail viewed
// ------------------------------------------

/// E11: Asset detail viewed
/// Measures when a user views the detailed information of an asset. Business category: Asset Management.
/// Provides insights on asset popularity and research depth.
class AssetViewedEventData implements AnalyticsEventData {
  const AssetViewedEventData({
    required this.assetSymbol,
    required this.assetNetwork,
    required this.walletType,
  });

  final String assetSymbol;
  final String assetNetwork;
  final String walletType;

  @override
  String get name => 'view_asset';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'asset_network': assetNetwork,
        'wallet_type': walletType,
      };
}

/// E11: Asset detail viewed
class AnalyticsAssetViewedEvent extends AnalyticsSendDataEvent {
  AnalyticsAssetViewedEvent({
    required String assetSymbol,
    required String assetNetwork,
    required String walletType,
  }) : super(
          AssetViewedEventData(
            assetSymbol: assetSymbol,
            assetNetwork: assetNetwork,
            walletType: walletType,
          ),
        );
}

// E12: Existing asset toggled on / made visible
// ------------------------------------------

/// E12: Existing asset toggled on / made visible
/// Measures when a user enables an existing asset. Business category: Asset Management.
/// Provides insights on which assets users want on dashboard and feature adoption.
class AssetEnabledEventData implements AnalyticsEventData {
  const AssetEnabledEventData({
    required this.assetSymbol,
    required this.assetNetwork,
    required this.walletType,
  });

  final String assetSymbol;
  final String assetNetwork;
  final String walletType;

  @override
  String get name => 'asset_enabled';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'asset_network': assetNetwork,
        'wallet_type': walletType,
      };
}

/// E12: Existing asset toggled on / made visible
class AnalyticsAssetEnabledEvent extends AnalyticsSendDataEvent {
  AnalyticsAssetEnabledEvent({
    required String assetSymbol,
    required String assetNetwork,
    required String walletType,
  }) : super(
          AssetEnabledEventData(
            assetSymbol: assetSymbol,
            assetNetwork: assetNetwork,
            walletType: walletType,
          ),
        );
}

// E13: Token toggled off / hidden
// ------------------------------------------

/// E13: Token toggled off / hidden
/// Measures when a user disables or hides a token. Business category: Asset Management.
/// Provides insights on portfolio-cleanup behavior and waning asset interest.
class AssetDisabledEventData implements AnalyticsEventData {
  const AssetDisabledEventData({
    required this.assetSymbol,
    required this.assetNetwork,
    required this.walletType,
  });

  final String assetSymbol;
  final String assetNetwork;
  final String walletType;

  @override
  String get name => 'asset_disabled';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'asset_network': assetNetwork,
        'wallet_type': walletType,
      };
}

/// E13: Token toggled off / hidden
class AnalyticsAssetDisabledEvent extends AnalyticsSendDataEvent {
  AnalyticsAssetDisabledEvent({
    required String assetSymbol,
    required String assetNetwork,
    required String walletType,
  }) : super(
          AssetDisabledEventData(
            assetSymbol: assetSymbol,
            assetNetwork: assetNetwork,
            walletType: walletType,
          ),
        );
}
