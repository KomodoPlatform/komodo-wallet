// Analytics event data classes and factory methods

import '../bloc/analytics/analytics_event.dart';
import '../bloc/analytics/analytics_repo.dart';

typedef JsonMap = Map<String, Object?>;

/// E38: Fresh receive address derived
/// Measures when a fresh HD wallet address is generated.
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

/// E40: Time until the top of the coins list crosses 50% of viewport
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

/// E41: Coins config refresh completed on launch
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

/// E44: Delay from page open until interactive (Loading logo hidden)
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

/// Factory for creating analytics events
class AnalyticsEvents {
  /// Fresh HD address generated
  static HdAddressGeneratedEventData hdAddressGenerated({
    required int accountIndex,
    required int addressIndex,
    required String assetSymbol,
  }) {
    return HdAddressGeneratedEventData(
      accountIndex: accountIndex,
      addressIndex: addressIndex,
      assetSymbol: assetSymbol,
    );
  }

  /// Wallet list reached half of the viewport
  static WalletListHalfViewportReachedEventData walletListHalfViewportReached({
    required int timeToHalfMs,
    required int walletSize,
  }) {
    return WalletListHalfViewportReachedEventData(
      timeToHalfMs: timeToHalfMs,
      walletSize: walletSize,
    );
  }

  /// Coins data updated
  static CoinsDataUpdatedEventData coinsDataUpdated({
    required String updateSource,
    required int updateDurationMs,
    required int coinsCount,
  }) {
    return CoinsDataUpdatedEventData(
      updateSource: updateSource,
      updateDurationMs: updateDurationMs,
      coinsCount: coinsCount,
    );
  }

  /// Page interactive delay measured
  static PageInteractiveDelayEventData pageInteractiveDelay({
    required String pageName,
    required int interactiveDelayMs,
    required int spinnerTimeMs,
  }) {
    return PageInteractiveDelayEventData(
      pageName: pageName,
      interactiveDelayMs: interactiveDelayMs,
      spinnerTimeMs: spinnerTimeMs,
    );
  }
}
