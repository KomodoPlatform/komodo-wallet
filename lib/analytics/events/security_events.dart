import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E05: Seed backup finished
/// Business category: Security.
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
  }) : super(
          BackupCompletedEventData(
            backupTime: backupTime,
            method: method,
            walletType: walletType,
          ),
        );
}

/// E06: Backup skipped / postponed
/// Business category: Security.
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
  }) : super(
          BackupSkippedEventData(
            stageSkipped: stageSkipped,
            walletType: walletType,
          ),
        );
}
