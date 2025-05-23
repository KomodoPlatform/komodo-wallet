import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E02: Wallet setup flow begins
/// Measures when the onboarding flow starts.
/// Business category: User Acquisition.
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
        if (referralSource != null) 'referral_source': referralSource!,
      };
}

/// E02: Wallet setup flow begins
class AnalyticsOnboardingStartedEvent extends AnalyticsSendDataEvent {
  AnalyticsOnboardingStartedEvent({
    required String method,
    String? referralSource,
  }) : super(
          OnboardingStartedEventData(
            method: method,
            referralSource: referralSource,
          ),
        );
}

/// E03: New wallet generated
/// Business category: User Acquisition.
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
  }) : super(
          WalletCreatedEventData(
            source: source,
            walletType: walletType,
          ),
        );
}

/// E04: Existing wallet imported
/// Business category: User Acquisition.
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
  }) : super(
          WalletImportedEventData(
            source: source,
            importType: importType,
            walletType: walletType,
          ),
        );
}
