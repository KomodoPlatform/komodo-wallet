import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E02: Wallet setup flow begins
/// Measures when the onboarding flow starts.
/// Business category: User Acquisition.
class OnboardingStartedEventData extends AnalyticsEventData {
  const OnboardingStartedEventData({required this.method, this.referralSource});

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
class WalletCreatedEventData extends AnalyticsEventData {
  const WalletCreatedEventData({required this.source, required this.hdType});

  final String source;
  final String hdType;

  @override
  String get name => 'wallet_created';

  @override
  JsonMap get parameters => {'source': source, 'hd_type': hdType};
}

/// E03: New wallet generated
class AnalyticsWalletCreatedEvent extends AnalyticsSendDataEvent {
  AnalyticsWalletCreatedEvent({required String source, required String hdType})
    : super(WalletCreatedEventData(source: source, hdType: hdType));
}

/// E04: Existing wallet imported
/// Business category: User Acquisition.
class WalletImportedEventData extends AnalyticsEventData {
  const WalletImportedEventData({
    required this.source,
    required this.importType,
    required this.hdType,
  });

  final String source;
  final String importType;
  final String hdType;

  @override
  String get name => 'wallet_imported';

  @override
  JsonMap get parameters => {
    'source': source,
    'import_type': importType,
    'hd_type': hdType,
  };
}

/// E04: Existing wallet imported
class AnalyticsWalletImportedEvent extends AnalyticsSendDataEvent {
  AnalyticsWalletImportedEvent({
    required String source,
    required String importType,
    required String hdType,
  }) : super(
         WalletImportedEventData(
           source: source,
           importType: importType,
           hdType: hdType,
         ),
       );
}
