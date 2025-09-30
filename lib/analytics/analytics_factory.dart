import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

import '../bloc/analytics/analytics_repo.dart';

class PortfolioPnlViewedEvent extends AnalyticsEventData {
  PortfolioPnlViewedEvent({
    required this.timeframe,
    required this.realizedPnl,
    required this.unrealizedPnl,
  });

  @override
  String get name => 'portfolio_pnl_viewed';

  final String timeframe;
  final double realizedPnl;
  final double unrealizedPnl;

  @override
  Map<String, Object> get parameters => {
        'timeframe': timeframe,
        'realized_pnl': realizedPnl,
        'unrealized_pnl': unrealizedPnl,
      };
}

class AppOpenedEvent extends AnalyticsEventData {
  AppOpenedEvent({required this.platform, required this.appVersion});

  @override
  String get name => 'app_open';

  final String platform;
  final String appVersion;

  @override
  JsonMap get parameters => {
        'platform': platform,
        'app_version': appVersion,
      };
}

class OnboardingStartedEvent extends AnalyticsEventData {
  OnboardingStartedEvent({required this.method, this.referralSource});

  @override
  String get name => 'onboarding_start';

  final String method;
  final String? referralSource;

  @override
  JsonMap get parameters => {
        'method': method,
        if (referralSource != null) 'referral_source': referralSource!,
      };
}

class WalletCreatedEvent extends AnalyticsEventData {
  WalletCreatedEvent({required this.source, required this.walletType});

  @override
  String get name => 'wallet_created';

  final String source;
  final String walletType;

  @override
  JsonMap get parameters => {
        'source': source,
        'wallet_type': walletType,
      };
}

class WalletImportedEvent extends AnalyticsEventData {
  WalletImportedEvent({
    required this.source,
    required this.importType,
    required this.walletType,
  });

  @override
  String get name => 'wallet_imported';

  final String source;
  final String importType;
  final String walletType;

  @override
  JsonMap get parameters => {
        'source': source,
        'import_type': importType,
        'wallet_type': walletType,
      };
}

class BackupCompletedEvent extends AnalyticsEventData {
  BackupCompletedEvent({
    required this.backupTime,
    required this.method,
    required this.walletType,
  });

  @override
  String get name => 'backup_complete';

  final int backupTime;
  final String method;
  final String walletType;

  @override
  JsonMap get parameters => {
        'backup_time': backupTime,
        'method': method,
        'wallet_type': walletType,
      };
}

class BackupSkippedEvent extends AnalyticsEventData {
  BackupSkippedEvent({required this.stageSkipped, required this.walletType});

  @override
  String get name => 'backup_skipped';

  final String stageSkipped;
  final String walletType;

  @override
  JsonMap get parameters => {
        'stage_skipped': stageSkipped,
        'wallet_type': walletType,
      };
}

class AnalyticsEvents {
  const AnalyticsEvents._();

  /// Portfolio P&L viewed event
  static PortfolioPnlViewedEvent portfolioPnlViewed({
    required String timeframe,
    required double realizedPnl,
    required double unrealizedPnl,
  }) {
    return PortfolioPnlViewedEvent(
      timeframe: timeframe,
      realizedPnl: realizedPnl,
      unrealizedPnl: unrealizedPnl,
    );
  }

  /// App opened / foregrounded event
  static AppOpenedEvent appOpened({
    required String platform,
    required String appVersion,
  }) {
    return AppOpenedEvent(platform: platform, appVersion: appVersion);
  }

  /// Onboarding started event
  static OnboardingStartedEvent onboardingStarted({
    required String method,
    String? referralSource,
  }) {
    return OnboardingStartedEvent(
      method: method,
      referralSource: referralSource,
    );
  }

  /// Wallet created event
  static WalletCreatedEvent walletCreated({
    required String source,
    required String walletType,
  }) {
    return WalletCreatedEvent(source: source, walletType: walletType);
  }

  /// Wallet imported event
  static WalletImportedEvent walletImported({
    required String source,
    required String importType,
    required String walletType,
  }) {
    return WalletImportedEvent(
      source: source,
      importType: importType,
      walletType: walletType,
    );
  }

  /// Seed backup completed event
  static BackupCompletedEvent backupCompleted({
    required int backupTime,
    required String method,
    required String walletType,
  }) {
    return BackupCompletedEvent(
      backupTime: backupTime,
      method: method,
      walletType: walletType,
    );
  }

  /// Backup skipped event
  static BackupSkippedEvent backupSkipped({
    required String stageSkipped,
    required String walletType,
  }) {
    return BackupSkippedEvent(
      stageSkipped: stageSkipped,
      walletType: walletType,
    );
  }

  /// Bridge initiated event
  static BridgeInitiatedEvent bridgeInitiated({
    required String fromChain,
    required String toChain,
    required String asset,
  }) {
    return BridgeInitiatedEvent(
      fromChain: fromChain,
      toChain: toChain,
      asset: asset,
    );
  }

  /// Bridge success event
  static BridgeSuccessEvent bridgeSuccess({
    required String fromChain,
    required String toChain,
    required String asset,
    required double amount,
    int? durationMs,
  }) {
    return BridgeSuccessEvent(
      fromChain: fromChain,
      toChain: toChain,
      asset: asset,
      amount: amount,
      durationMs: durationMs,
    );
  }

  /// Bridge failure event
  static BridgeFailureEvent bridgeFailure({
    required String fromChain,
    required String toChain,
    required String failError,
    int? durationMs,
  }) {
    return BridgeFailureEvent(
      fromChain: fromChain,
      toChain: toChain,
      failError: failError,
      durationMs: durationMs,
    );
  }

  /// NFT gallery opened event
  static NftGalleryOpenedEvent nftGalleryOpened({
    required int nftCount,
    required int loadTimeMs,
  }) {
    return NftGalleryOpenedEvent(
      nftCount: nftCount,
      loadTimeMs: loadTimeMs,
    );
  }

  /// NFT transfer initiated
  static NftTransferInitiatedEvent nftTransferInitiated({
    required String collectionName,
    required String tokenId,
    required String hdType,
  }) {
    return NftTransferInitiatedEvent(
      collectionName: collectionName,
      tokenId: tokenId,
      hdType: hdType,
    );
  }

  /// NFT transfer success
  static NftTransferSuccessEvent nftTransferSuccess({
    required String collectionName,
    required String tokenId,
    required double fee,
    required String hdType,
  }) {
    return NftTransferSuccessEvent(
      collectionName: collectionName,
      tokenId: tokenId,
      fee: fee,
      hdType: hdType,
    );
  }

  /// NFT transfer failure
  static NftTransferFailureEvent nftTransferFailure({
    required String collectionName,
    required String failReason,
    required String hdType,
  }) {
    return NftTransferFailureEvent(
      collectionName: collectionName,
      failReason: failReason,
      hdType: hdType,
    );
  }

  /// Marketbot setup started
  static MarketbotSetupStartEvent marketbotSetupStart({
    required String strategyType,
    required int pairsCount,
  }) {
    return MarketbotSetupStartEvent(
      strategyType: strategyType,
      pairsCount: pairsCount,
    );
  }

  /// Marketbot setup complete
  static MarketbotSetupCompleteEvent marketbotSetupComplete({
    required String strategyType,
    required double baseCapital,
  }) {
    return MarketbotSetupCompleteEvent(
      strategyType: strategyType,
      baseCapital: baseCapital,
    );
  }

  /// Marketbot trade executed
  static MarketbotTradeExecutedEvent marketbotTradeExecuted({
    required String pair,
    required double tradeSize,
    required double profitUsd,
  }) {
    return MarketbotTradeExecutedEvent(
      pair: pair,
      tradeSize: tradeSize,
      profitUsd: profitUsd,
    );
  }

  /// Marketbot error
  static MarketbotErrorEvent marketbotError({
    required String errorCode,
    required String strategyType,
  }) {
    return MarketbotErrorEvent(
      errorCode: errorCode,
      strategyType: strategyType,
    );
  }

  /// Reward claim initiated
  static RewardClaimInitiatedEvent rewardClaimInitiated({
    required String asset,
    required double expectedRewardAmount,
  }) {
    return RewardClaimInitiatedEvent(
      asset: asset,
      expectedRewardAmount: expectedRewardAmount,
    );
  }

  /// Reward claim success
  static RewardClaimSuccessEvent rewardClaimSuccess({
    required String asset,
    required double rewardAmount,
  }) {
    return RewardClaimSuccessEvent(
      asset: asset,
      rewardAmount: rewardAmount,
    );
  }

  /// Reward claim failure
  static RewardClaimFailureEvent rewardClaimFailure({
    required String asset,
    required String failReason,
  }) {
    return RewardClaimFailureEvent(
      asset: asset,
      failReason: failReason,
    );
  }

  /// DApp connected
  static DappConnectEvent dappConnect({
    required String dappName,
    required String network,
  }) {
    return DappConnectEvent(
      dappName: dappName,
      network: network,
    );
  }

  /// Settings change
  static SettingsChangeEvent settingsChange({
    required String settingName,
    required String newValue,
  }) {
    return SettingsChangeEvent(
      settingName: settingName,
      newValue: newValue,
    );
  }

  /// Error displayed
  static ErrorDisplayedEvent errorDisplayed({
    required String errorCode,
    required String screenContext,
  }) {
    return ErrorDisplayedEvent(
      errorCode: errorCode,
      screenContext: screenContext,
    );
  }

  /// App shared
  static AppShareEvent appShare({
    required String channel,
  }) {
    return AppShareEvent(channel: channel);
  }

  /// Scroll attempt outside content
  static ScrollAttemptOutsideContentEvent scrollAttemptOutsideContent({
    required String screenContext,
    required double scrollDelta,
  }) {
    return ScrollAttemptOutsideContentEvent(
      screenContext: screenContext,
      scrollDelta: scrollDelta,
    );
  }

  /// Searchbar input
  static SearchbarInputEvent searchbarInput({
    required int queryLength,
    String? assetSymbol,
  }) {
    return SearchbarInputEvent(
      queryLength: queryLength,
      assetSymbol: assetSymbol,
    );
  }

  /// Theme selected
  static ThemeSelectedEvent themeSelected({
    required String themeName,
  }) {
    return ThemeSelectedEvent(themeName: themeName);
  }
}

class BridgeInitiatedEvent extends AnalyticsEventData {
  BridgeInitiatedEvent({
    required this.fromChain,
    required this.toChain,
    required this.asset,
  });

  @override
  String get name => 'bridge_initiated';

  final String fromChain;
  final String toChain;
  final String asset;

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
      };
}

class BridgeSuccessEvent extends AnalyticsEventData {
  BridgeSuccessEvent({
    required this.fromChain,
    required this.toChain,
    required this.asset,
    required this.amount,
    this.durationMs,
  });

  @override
  String get name => 'bridge_success';

  final String fromChain;
  final String toChain;
  final String asset;
  final double amount;
  final int? durationMs;

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'asset': asset,
        'amount': amount,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

class BridgeFailureEvent extends AnalyticsEventData {
  BridgeFailureEvent({
    required this.fromChain,
    required this.toChain,
    required this.failError,
    this.durationMs,
  });

  @override
  String get name => 'bridge_failure';

  final String fromChain;
  final String toChain;
  final String failError;
  final int? durationMs;

  @override
  JsonMap get parameters => {
        'from_chain': fromChain,
        'to_chain': toChain,
        'fail_error': failError,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

class NftGalleryOpenedEvent extends AnalyticsEventData {
  NftGalleryOpenedEvent({
    required this.nftCount,
    required this.loadTimeMs,
  });

  @override
  String get name => 'nft_gallery_opened';

  final int nftCount;
  final int loadTimeMs;

  @override
  JsonMap get parameters => {
        'nft_count': nftCount,
        'load_time_ms': loadTimeMs,
      };
}

class NftTransferInitiatedEvent extends AnalyticsEventData {
  NftTransferInitiatedEvent({
    required this.collectionName,
    required this.tokenId,
    required this.hdType,
  });

  @override
  String get name => 'nft_transfer_initiated';

  final String collectionName;
  final String tokenId;
  final String hdType;

  @override
  JsonMap get parameters => {
        'collection_name': collectionName,
        'token_id': tokenId,
        'hd_type': hdType,
      };
}

class NftTransferSuccessEvent extends AnalyticsEventData {
  NftTransferSuccessEvent({
    required this.collectionName,
    required this.tokenId,
    required this.fee,
    required this.hdType,
  });

  @override
  String get name => 'nft_transfer_success';

  final String collectionName;
  final String tokenId;
  final double fee;
  final String hdType;

  @override
  JsonMap get parameters => {
        'collection_name': collectionName,
        'token_id': tokenId,
        'fee': fee,
        'hd_type': hdType,
      };
}

class NftTransferFailureEvent extends AnalyticsEventData {
  NftTransferFailureEvent({
    required this.collectionName,
    required this.failReason,
    required this.hdType,
  });

  @override
  String get name => 'nft_transfer_failure';

  final String collectionName;
  final String failReason;
  final String hdType;

  @override
  JsonMap get parameters => {
        'collection_name': collectionName,
        'fail_reason': failReason,
        'hd_type': hdType,
      };
}

class MarketbotSetupStartEvent extends AnalyticsEventData {
  MarketbotSetupStartEvent({
    required this.strategyType,
    required this.pairsCount,
  });

  @override
  String get name => 'marketbot_setup_start';

  final String strategyType;
  final int pairsCount;

  @override
  JsonMap get parameters => {
        'strategy_type': strategyType,
        'pairs_count': pairsCount,
      };
}

class MarketbotSetupCompleteEvent extends AnalyticsEventData {
  MarketbotSetupCompleteEvent({
    required this.strategyType,
    required this.baseCapital,
  });

  @override
  String get name => 'marketbot_setup_complete';

  final String strategyType;
  final double baseCapital;

  @override
  JsonMap get parameters => {
        'strategy_type': strategyType,
        'base_capital': baseCapital,
      };
}

class MarketbotTradeExecutedEvent extends AnalyticsEventData {
  MarketbotTradeExecutedEvent({
    required this.pair,
    required this.tradeSize,
    required this.profitUsd,
  });

  @override
  String get name => 'marketbot_trade_executed';

  final String pair;
  final double tradeSize;
  final double profitUsd;

  @override
  JsonMap get parameters => {
        'pair': pair,
        'trade_size': tradeSize,
        'profit_usd': profitUsd,
      };
}

class MarketbotErrorEvent extends AnalyticsEventData {
  MarketbotErrorEvent({
    required this.errorCode,
    required this.strategyType,
  });

  @override
  String get name => 'marketbot_error';

  final String errorCode;
  final String strategyType;

  @override
  JsonMap get parameters => {
        'error_code': errorCode,
        'strategy_type': strategyType,
      };
}

class RewardClaimInitiatedEvent extends AnalyticsEventData {
  RewardClaimInitiatedEvent({
    required this.asset,
    required this.expectedRewardAmount,
  });

  @override
  String get name => 'reward_claim_initiated';

  final String asset;
  final double expectedRewardAmount;

  @override
  JsonMap get parameters => {
        'asset': asset,
        'expected_reward_amount': expectedRewardAmount,
      };
}

class RewardClaimSuccessEvent extends AnalyticsEventData {
  RewardClaimSuccessEvent({
    required this.asset,
    required this.rewardAmount,
  });

  @override
  String get name => 'reward_claim_success';

  final String asset;
  final double rewardAmount;

  @override
  JsonMap get parameters => {
        'asset': asset,
        'reward_amount': rewardAmount,
      };
}

class RewardClaimFailureEvent extends AnalyticsEventData {
  RewardClaimFailureEvent({
    required this.asset,
    required this.failReason,
  });

  @override
  String get name => 'reward_claim_failure';

  final String asset;
  final String failReason;

  @override
  JsonMap get parameters => {
        'asset': asset,
        'fail_reason': failReason,
      };
}

class DappConnectEvent extends AnalyticsEventData {
  DappConnectEvent({
    required this.dappName,
    required this.network,
  });

  @override
  String get name => 'dapp_connect';

  final String dappName;
  final String network;

  @override
  JsonMap get parameters => {
        'dapp_name': dappName,
        'network': network,
      };
}

class SettingsChangeEvent extends AnalyticsEventData {
  SettingsChangeEvent({
    required this.settingName,
    required this.newValue,
  });

  @override
  String get name => 'settings_change';

  final String settingName;
  final String newValue;

  @override
  JsonMap get parameters => {
        'setting_name': settingName,
        'new_value': newValue,
      };
}

class ErrorDisplayedEvent extends AnalyticsEventData {
  ErrorDisplayedEvent({
    required this.errorCode,
    required this.screenContext,
  });

  @override
  String get name => 'error_displayed';

  final String errorCode;
  final String screenContext;

  @override
  JsonMap get parameters => {
        'error_code': errorCode,
        'screen_context': screenContext,
      };
}

class AppShareEvent extends AnalyticsEventData {
  AppShareEvent({required this.channel});

  @override
  String get name => 'app_share';

  final String channel;

  @override
  JsonMap get parameters => {
        'channel': channel,
      };
}

class ScrollAttemptOutsideContentEvent extends AnalyticsEventData {
  ScrollAttemptOutsideContentEvent({
    required this.screenContext,
    required this.scrollDelta,
  });

  @override
  String get name => 'scroll_attempt_outside_content';

  final String screenContext;
  final double scrollDelta;

  @override
  JsonMap get parameters => {
        'screen_context': screenContext,
        'scroll_delta': scrollDelta,
      };
}

class SearchbarInputEvent extends AnalyticsEventData {
  SearchbarInputEvent({
    required this.queryLength,
    this.assetSymbol,
  });

  @override
  String get name => 'searchbar_input';

  final int queryLength;
  final String? assetSymbol;

  @override
  JsonMap get parameters => {
        'query_length': queryLength,
        if (assetSymbol != null) 'asset_symbol': assetSymbol!,
      };
}

class ThemeSelectedEvent extends AnalyticsEventData {
  ThemeSelectedEvent({required this.themeName});

  @override
  String get name => 'theme_selected';

  final String themeName;

  @override
  JsonMap get parameters => {
        'theme_name': themeName,
      };
}
