import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E34: External DApp connection
class DappConnectEventData implements AnalyticsEventData {
  const DappConnectEventData({
    required this.dappName,
    required this.network,
  });

  final String dappName;
  final String network;

  @override
  String get name => 'dapp_connect';

  @override
  JsonMap get parameters => {
        'dapp_name': dappName,
        'network': network,
      };
}

class AnalyticsDappConnectEvent extends AnalyticsSendDataEvent {
  AnalyticsDappConnectEvent({
    required String dappName,
    required String network,
  }) : super(
          DappConnectEventData(
            dappName: dappName,
            network: network,
          ),
        );
}

/// E35: Setting toggled
class SettingsChangeEventData implements AnalyticsEventData {
  const SettingsChangeEventData({
    required this.settingName,
    required this.newValue,
  });

  final String settingName;
  final String newValue;

  @override
  String get name => 'settings_change';

  @override
  JsonMap get parameters => {
        'setting_name': settingName,
        'new_value': newValue,
      };
}

class AnalyticsSettingsChangeEvent extends AnalyticsSendDataEvent {
  AnalyticsSettingsChangeEvent({
    required String settingName,
    required String newValue,
  }) : super(
          SettingsChangeEventData(
            settingName: settingName,
            newValue: newValue,
          ),
        );
}

/// E36: Error dialog shown
class ErrorDisplayedEventData implements AnalyticsEventData {
  const ErrorDisplayedEventData({
    required this.errorCode,
    required this.screenContext,
  });

  final String errorCode;
  final String screenContext;

  @override
  String get name => 'error_displayed';

  @override
  JsonMap get parameters => {
        'error_code': errorCode,
        'screen_context': screenContext,
      };
}

class AnalyticsErrorDisplayedEvent extends AnalyticsSendDataEvent {
  AnalyticsErrorDisplayedEvent({
    required String errorCode,
    required String screenContext,
  }) : super(
          ErrorDisplayedEventData(
            errorCode: errorCode,
            screenContext: screenContext,
          ),
        );
}

/// E37: App / referral shared
class AppShareEventData implements AnalyticsEventData {
  const AppShareEventData({required this.channel});

  final String channel;

  @override
  String get name => 'app_share';

  @override
  JsonMap get parameters => {
        'channel': channel,
      };
}

class AnalyticsAppShareEvent extends AnalyticsSendDataEvent {
  AnalyticsAppShareEvent({required String channel})
      : super(
          AppShareEventData(channel: channel),
        );
}

/// E40: User scroll attempt outside content
class ScrollAttemptOutsideContentEventData implements AnalyticsEventData {
  const ScrollAttemptOutsideContentEventData({
    required this.screenContext,
    required this.scrollDelta,
  });

  final String screenContext;
  final double scrollDelta;

  @override
  String get name => 'scroll_attempt_outside_content';

  @override
  JsonMap get parameters => {
        'screen_context': screenContext,
        'scroll_delta': scrollDelta,
      };
}

class AnalyticsScrollAttemptOutsideContentEvent extends AnalyticsSendDataEvent {
  AnalyticsScrollAttemptOutsideContentEvent({
    required String screenContext,
    required double scrollDelta,
  }) : super(
          ScrollAttemptOutsideContentEventData(
            screenContext: screenContext,
            scrollDelta: scrollDelta,
          ),
        );
}

/// E42: Searchbar input submitted
class SearchbarInputEventData implements AnalyticsEventData {
  const SearchbarInputEventData({
    required this.queryLength,
    this.assetSymbol,
  });

  final int queryLength;
  final String? assetSymbol;

  @override
  String get name => 'searchbar_input';

  @override
  JsonMap get parameters => {
        'query_length': queryLength,
        if (assetSymbol != null) 'asset_symbol': assetSymbol!,
      };
}

class AnalyticsSearchbarInputEvent extends AnalyticsSendDataEvent {
  AnalyticsSearchbarInputEvent({
    required int queryLength,
    String? assetSymbol,
  }) : super(
          SearchbarInputEventData(
            queryLength: queryLength,
            assetSymbol: assetSymbol,
          ),
        );
}

/// E43: Theme selected
class ThemeSelectedEventData implements AnalyticsEventData {
  const ThemeSelectedEventData({required this.themeName});

  final String themeName;

  @override
  String get name => 'theme_selected';

  @override
  JsonMap get parameters => {
        'theme_name': themeName,
      };
}

class AnalyticsThemeSelectedEvent extends AnalyticsSendDataEvent {
  AnalyticsThemeSelectedEvent({required String themeName})
      : super(
          ThemeSelectedEventData(themeName: themeName),
        );
}
