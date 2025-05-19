// filepath: /Users/charl/Code/UTXO/komodo-wallet/lib/analytics/analytics_events.dart
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

/// Base interface for all analytics event data
abstract class AnalyticsEventData {
  const AnalyticsEventData();

  String get name;
  JsonMap get parameters;
}

// Event class for dispatching events
class AnalyticsEvent {
  const AnalyticsEvent();
}

/// Event wrapper class for sending analytics data
class AnalyticsSendDataEvent extends AnalyticsEvent {
  const AnalyticsSendDataEvent(this.data);
  final AnalyticsEventData data;
}

// E01: App launched / foregrounded
// ------------------------------------------

/// E01: App launched / foregrounded
/// Measures app launches and foregrounds. Business category: User Engagement.
/// Provides insights on DAU / MAU, usage frequency, platform mix.
class AppOpenedEventData implements AnalyticsEventData {
  const AppOpenedEventData({
    required this.platform,
    required this.appVersion,
  });

  final String platform;
  final String appVersion;

  @override
  String get name => 'app_open';

  @override
  JsonMap get parameters => {
        'platform': platform,
        'app_version': appVersion,
      };
}

/// E01: App launched / foregrounded
class AnalyticsAppOpenedEvent extends AnalyticsSendDataEvent {
  AnalyticsAppOpenedEvent({
    required String platform,
    required String appVersion,
  }) : super(AppOpenedEventData(platform: platform, appVersion: appVersion));
}

// E02: Wallet setup flow begins
// ------------------------------------------

/// E02: Wallet setup flow begins
/// Measures when a user starts the wallet setup process. Business category: User Acquisition.
/// Provides insights on funnel start and referral impact.
class OnboardingStartedEventData implements AnalyticsEventData {
  const OnboardingStartedEventData({
    required this.method,
    this.referralSource,
  });

  final String method;
  final String? referralSource;

  @override
  String get name => 'onboarding_start';

  @override
  JsonMap get parameters => {
        'method': method,
        if (referralSource != null) 'referral_source': referralSource,
      };
}

/// E02: Wallet setup flow begins
class AnalyticsOnboardingStartedEvent extends AnalyticsSendDataEvent {
  AnalyticsOnboardingStartedEvent({
    required String method,
    String? referralSource,
  }) : super(OnboardingStartedEventData(
          method: method,
          referralSource: referralSource,
        ));
}

// E03: New wallet generated
// ------------------------------------------

/// E03: New wallet generated
/// Measures when a new wallet is created. Business category: User Acquisition.
/// Provides insights on new-user conversion and platform preference.
class WalletCreatedEventData implements AnalyticsEventData {
  const WalletCreatedEventData({
    required this.source,
    required this.walletType,
  });

  final String source;
  final String walletType;

  @override
  String get name => 'wallet_created';

  @override
  JsonMap get parameters => {
        'source': source,
        'wallet_type': walletType,
      };
}

/// E03: New wallet generated
class AnalyticsWalletCreatedEvent extends AnalyticsSendDataEvent {
  AnalyticsWalletCreatedEvent({
    required String source,
    required String walletType,
  }) : super(WalletCreatedEventData(
          source: source,
          walletType: walletType,
        ));
}

// E04: Existing wallet imported
// ------------------------------------------

/// E04: Existing wallet imported
/// Measures when an existing wallet is imported. Business category: User Acquisition.
/// Provides insights on power-user acquisition and migration rate.
class WalletImportedEventData implements AnalyticsEventData {
  const WalletImportedEventData({
    required this.source,
    required this.importType,
    required this.walletType,
  });

  final String source;
  final String importType;
  final String walletType;

  @override
  String get name => 'wallet_imported';

  @override
  JsonMap get parameters => {
        'source': source,
        'import_type': importType,
        'wallet_type': walletType,
      };
}

/// E04: Existing wallet imported
class AnalyticsWalletImportedEvent extends AnalyticsSendDataEvent {
  AnalyticsWalletImportedEvent({
    required String source,
    required String importType,
    required String walletType,
  }) : super(WalletImportedEventData(
          source: source,
          importType: importType,
          walletType: walletType,
        ));
}

// E05: Seed backup finished
// ------------------------------------------

/// E05: Seed backup finished
/// Measures when a seed backup is completed. Business category: Security Adoption.
/// Provides insights on security uptake and UX health.
class BackupCompletedEventData implements AnalyticsEventData {
  const BackupCompletedEventData({
    required this.backupTime,
    required this.method,
    required this.walletType,
  });

  final int backupTime;
  final String method;
  final String walletType;

  @override
  String get name => 'backup_complete';

  @override
  JsonMap get parameters => {
        'backup_time': backupTime,
        'method': method,
        'wallet_type': walletType,
      };
}

/// E05: Seed backup finished
class AnalyticsBackupCompletedEvent extends AnalyticsSendDataEvent {
  AnalyticsBackupCompletedEvent({
    required int backupTime,
    required String method,
    required String walletType,
  }) : super(BackupCompletedEventData(
          backupTime: backupTime,
          method: method,
          walletType: walletType,
        ));
}

// E06: Backup skipped / postponed
// ------------------------------------------

/// E06: Backup skipped / postponed
/// Measures when a user skips or postpones the backup process. Business category: Security Risk.
/// Provides insights on at-risk cohort size and friction stage.
class BackupSkippedEventData implements AnalyticsEventData {
  const BackupSkippedEventData({
    required this.stageSkipped,
    required this.walletType,
  });

  final String stageSkipped;
  final String walletType;

  @override
  String get name => 'backup_skipped';

  @override
  JsonMap get parameters => {
        'stage_skipped': stageSkipped,
        'wallet_type': walletType,
      };
}

/// E06: Backup skipped / postponed
class AnalyticsBackupSkippedEvent extends AnalyticsSendDataEvent {
  AnalyticsBackupSkippedEvent({
    required String stageSkipped,
    required String walletType,
  }) : super(BackupSkippedEventData(
          stageSkipped: stageSkipped,
          walletType: walletType,
        ));
}

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
  }) : super(PortfolioViewedEventData(
          totalCoins: totalCoins,
          totalValueUsd: totalValueUsd,
        ));
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
  }) : super(PortfolioGrowthViewedEventData(
          period: period,
          growthPct: growthPct,
        ));
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
  }) : super(PortfolioPnlViewedEventData(
          timeframe: timeframe,
          realizedPnl: realizedPnl,
          unrealizedPnl: unrealizedPnl,
        ));
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
  }) : super(AssetAddedEventData(
          assetSymbol: assetSymbol,
          assetNetwork: assetNetwork,
          walletType: walletType,
        ));
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
  }) : super(AssetViewedEventData(
          assetSymbol: assetSymbol,
          assetNetwork: assetNetwork,
          walletType: walletType,
        ));
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
  }) : super(AssetEnabledEventData(
          assetSymbol: assetSymbol,
          assetNetwork: assetNetwork,
          walletType: walletType,
        ));
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
  }) : super(AssetDisabledEventData(
          assetSymbol: assetSymbol,
          assetNetwork: assetNetwork,
          walletType: walletType,
        ));
}

// E14: Send flow started
// ------------------------------------------

/// E14: Send flow started
/// Measures when a user initiates a send transaction. Business category: Transactions.
/// Provides insights on transaction funnel start and popular send assets.
class SendInitiatedEventData implements AnalyticsEventData {
  const SendInitiatedEventData({
    required this.assetSymbol,
    required this.network,
    required this.amount,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final double amount;
  final String walletType;

  @override
  String get name => 'send_initiated';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'amount': amount,
        'wallet_type': walletType,
      };
}

/// E14: Send flow started
class AnalyticsSendInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendInitiatedEvent({
    required String assetSymbol,
    required String network,
    required double amount,
    required String walletType,
  }) : super(SendInitiatedEventData(
          assetSymbol: assetSymbol,
          network: network,
          amount: amount,
          walletType: walletType,
        ));
}

// E15: On-chain send completed
// ------------------------------------------

/// E15: On-chain send completed
/// Measures when an on-chain send transaction is completed successfully. Business category: Transactions.
/// Provides insights on successful sends, volume, and average size.
class SendSucceededEventData implements AnalyticsEventData {
  const SendSucceededEventData({
    required this.assetSymbol,
    required this.network,
    required this.amount,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final double amount;
  final String walletType;

  @override
  String get name => 'send_success';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'amount': amount,
        'wallet_type': walletType,
      };
}

/// E15: On-chain send completed
class AnalyticsSendSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSendSucceededEvent({
    required String assetSymbol,
    required String network,
    required double amount,
    required String walletType,
  }) : super(SendSucceededEventData(
          assetSymbol: assetSymbol,
          network: network,
          amount: amount,
          walletType: walletType,
        ));
}

// E16: Send failed / cancelled
// ------------------------------------------

/// E16: Send failed / cancelled
/// Measures when a send transaction fails or is cancelled. Business category: Transactions.
/// Provides insights on error hotspots and UX/network issues.
class SendFailedEventData implements AnalyticsEventData {
  const SendFailedEventData({
    required this.assetSymbol,
    required this.network,
    required this.failReason,
    required this.walletType,
  });

  final String assetSymbol;
  final String network;
  final String failReason;
  final String walletType;

  @override
  String get name => 'send_failure';

  @override
  JsonMap get parameters => {
        'asset_symbol': assetSymbol,
        'network': network,
        'fail_reason': failReason,
        'wallet_type': walletType,
      };
}

/// E16: Send failed / cancelled
class AnalyticsSendFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSendFailedEvent({
    required String assetSymbol,
    required String network,
    required String failReason,
    required String walletType,
  }) : super(SendFailedEventData(
          assetSymbol: assetSymbol,
          network: network,
          failReason: failReason,
          walletType: walletType,
        ));
}

// E17: Swap order submitted
// ------------------------------------------

/// E17: Swap order submitted
/// Measures when a swap order is submitted. Business category: Trading (DEX).
/// Provides insights on DEX funnel start and pair demand.
class SwapInitiatedEventData implements AnalyticsEventData {
  const SwapInitiatedEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.networks,
    required this.walletType,
  });

  final String fromAsset;
  final String toAsset;
  final String networks;
  final String walletType;

  @override
  String get name => 'swap_initiated';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'networks': networks,
        'wallet_type': walletType,
      };
}

/// E17: Swap order submitted
class AnalyticsSwapInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapInitiatedEvent({
    required String fromAsset,
    required String toAsset,
    required String networks,
    required String walletType,
  }) : super(SwapInitiatedEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          networks: networks,
          walletType: walletType,
        ));
}

// E18: Atomic swap succeeded
// ------------------------------------------

/// E18: Atomic swap succeeded
/// Measures when an atomic swap is completed successfully. Business category: Trading (DEX).
/// Provides insights on trading volume and fee revenue.
class SwapSucceededEventData implements AnalyticsEventData {
  const SwapSucceededEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.amount,
    required this.fee,
    required this.walletType,
  });

  final String fromAsset;
  final String toAsset;
  final double amount;
  final double fee;
  final String walletType;

  @override
  String get name => 'swap_success';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'amount': amount,
        'fee': fee,
        'wallet_type': walletType,
      };
}

/// E18: Atomic swap succeeded
class AnalyticsSwapSucceededEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapSucceededEvent({
    required String fromAsset,
    required String toAsset,
    required double amount,
    required double fee,
    required String walletType,
  }) : super(SwapSucceededEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          amount: amount,
          fee: fee,
          walletType: walletType,
        ));
}

// E19: Swap failed
// ------------------------------------------

/// E19: Swap failed
/// Measures when an atomic swap fails. Business category: Trading (DEX).
/// Provides insights on liquidity gaps and technical/UX blockers.
class SwapFailedEventData implements AnalyticsEventData {
  const SwapFailedEventData({
    required this.fromAsset,
    required this.toAsset,
    required this.failStage,
    required this.walletType,
  });

  final String fromAsset;
  final String toAsset;
  final String failStage;
  final String walletType;

  @override
  String get name => 'swap_failure';

  @override
  JsonMap get parameters => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'fail_stage': failStage,
        'wallet_type': walletType,
      };
}

/// E19: Swap failed
class AnalyticsSwapFailedEvent extends AnalyticsSendDataEvent {
  AnalyticsSwapFailedEvent({
    required String fromAsset,
    required String toAsset,
    required String failStage,
    required String walletType,
  }) : super(SwapFailedEventData(
          fromAsset: fromAsset,
          toAsset: toAsset,
          failStage: failStage,
          walletType: walletType,
        ));
}

// E38: Fresh receive address derived
// ------------------------------------------

/// E38: Fresh receive address derived
/// Measures when a fresh HD wallet address is generated. Business category: HD Wallet Operations.
/// Provides insights on address-reuse risk and payment UX.
class HdAddressGeneratedEventData implements AnalyticsEventData {
  const HdAddressGeneratedEventData({
    required this.accountIndex,
    required this.addressIndex,
    required this.assetSymbol,
  });

  final int accountIndex;
  final int addressIndex;
  final String assetSymbol;

  @override
  String get name => 'hd_address_generated';

  @override
  JsonMap get parameters => {
        'account_index': accountIndex,
        'address_index': addressIndex,
        'asset_symbol': assetSymbol,
      };
}

/// E38: Fresh receive address derived
class AnalyticsHdAddressGeneratedEvent extends AnalyticsSendDataEvent {
  AnalyticsHdAddressGeneratedEvent({
    required int accountIndex,
    required int addressIndex,
    required String assetSymbol,
  }) : super(HdAddressGeneratedEventData(
          accountIndex: accountIndex,
          addressIndex: addressIndex,
          assetSymbol: assetSymbol,
        ));
}

// E40: Time until the top of the coins list crosses 50% of viewport
// ------------------------------------------

/// E40: Time until the top of the coins list crosses 50% of viewport
/// Measures the time it takes for the coins list to reach halfway through the viewport. Business category: UI Usability.
/// Provides insights on whether users struggle to reach balances and helps optimize list layout.
class WalletListHalfViewportReachedEventData implements AnalyticsEventData {
  const WalletListHalfViewportReachedEventData({
    required this.timeToHalfMs,
    required this.walletSize,
  });

  final int timeToHalfMs;
  final int walletSize;

  @override
  String get name => 'wallet_list_half_viewport';

  @override
  JsonMap get parameters => {
        'time_to_half_ms': timeToHalfMs,
        'wallet_size': walletSize,
      };
}

/// E40: Time until the top of the coins list crosses 50% of viewport
class AnalyticsWalletListHalfViewportReachedEvent
    extends AnalyticsSendDataEvent {
  AnalyticsWalletListHalfViewportReachedEvent({
    required int timeToHalfMs,
    required int walletSize,
  }) : super(WalletListHalfViewportReachedEventData(
          timeToHalfMs: timeToHalfMs,
          walletSize: walletSize,
        ));
}

// E41: Coins config refresh completed on launch
// ------------------------------------------

/// E41: Coins config refresh completed on launch
/// Measures when coins configuration data is refreshed upon app launch. Business category: Data Sync.
/// Provides insights on data freshness and helps monitor failed or slow syncs.
class CoinsDataUpdatedEventData implements AnalyticsEventData {
  const CoinsDataUpdatedEventData({
    required this.coinsCount,
    required this.updateSource,
    required this.updateDurationMs,
  });

  final int coinsCount;
  final String updateSource;
  final int updateDurationMs;

  @override
  String get name => 'coins_data_updated';

  @override
  JsonMap get parameters => {
        'coins_count': coinsCount,
        'update_source': updateSource,
        'update_duration_ms': updateDurationMs,
      };
}

/// E41: Coins config refresh completed on launch
class AnalyticsCoinsDataUpdatedEvent extends AnalyticsSendDataEvent {
  AnalyticsCoinsDataUpdatedEvent({
    required String updateSource,
    required int updateDurationMs,
    required int coinsCount,
  }) : super(CoinsDataUpdatedEventData(
          updateSource: updateSource,
          updateDurationMs: updateDurationMs,
          coinsCount: coinsCount,
        ));
}

// E44: Delay from page open until interactive
// ------------------------------------------

/// E44: Delay from page open until interactive (Loading logo hidden)
/// Measures the delay between opening a page and when it becomes interactive. Business category: Performance.
/// Provides insights on performance bottlenecks that impact user experience.
class PageInteractiveDelayEventData implements AnalyticsEventData {
  const PageInteractiveDelayEventData({
    required this.pageName,
    required this.interactiveDelayMs,
    required this.spinnerTimeMs,
  });

  final String pageName;
  final int interactiveDelayMs;
  final int spinnerTimeMs;

  @override
  String get name => 'page_interactive_delay';

  @override
  JsonMap get parameters => {
        'page_name': pageName,
        'interactive_delay_ms': interactiveDelayMs,
        'spinner_time_ms': spinnerTimeMs,
      };
}

/// E44: Delay from page open until interactive (Loading logo hidden)
class AnalyticsPageInteractiveDelayEvent extends AnalyticsSendDataEvent {
  AnalyticsPageInteractiveDelayEvent({
    required String pageName,
    required int interactiveDelayMs,
    required int spinnerTimeMs,
  }) : super(PageInteractiveDelayEventData(
          pageName: pageName,
          interactiveDelayMs: interactiveDelayMs,
          spinnerTimeMs: spinnerTimeMs,
        ));
}
