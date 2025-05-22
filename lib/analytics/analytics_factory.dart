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
}
