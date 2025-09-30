import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';
import 'analytics_api.dart';
import 'analytics_repo.dart';

class MatomoAnalyticsApi implements AnalyticsApi {
  late MatomoTracker _instance;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isInitialized = false;
  bool _isEnabled = false;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;

  /// SYNC NOTE:
  /// The event-to-category mapping and numeric value extraction keys below must
  /// stay in sync with `lib/analytics/required_analytics_events.csv`.
  /// Ideally these would not be hard-coded and should be generated from a
  /// shared analytics metadata source.

  /// Explicit mapping of GA4 event names to Business Categories as defined in
  /// `lib/analytics/required_analytics_events.csv`.
  static const Map<String, String> _eventCategoryMap = {
    // User Engagement
    'app_open': 'User Engagement',

    // User Acquisition
    'onboarding_start': 'User Acquisition',
    'wallet_created': 'User Acquisition',
    'wallet_imported': 'User Acquisition',

    // Security
    'backup_complete': 'Security Adoption',
    'backup_skipped': 'Security Risk',

    // Portfolio
    'portfolio_viewed': 'Portfolio',
    'portfolio_growth_viewed': 'Portfolio',
    'portfolio_pnl_viewed': 'Portfolio',

    // Asset Mgmt
    'add_asset': 'Asset Mgmt',
    'view_asset': 'Asset Mgmt',
    'asset_enabled': 'Asset Mgmt',
    'asset_disabled': 'Asset Mgmt',

    // Transactions
    'send_initiated': 'Transactions',
    'send_success': 'Transactions',
    'send_failure': 'Transactions',

    // Trading (DEX)
    'swap_initiated': 'Trading (DEX)',
    'swap_success': 'Trading (DEX)',
    'swap_failure': 'Trading (DEX)',

    // Cross-Chain
    'bridge_initiated': 'Cross-Chain',
    'bridge_success': 'Cross-Chain',
    'bridge_failure': 'Cross-Chain',

    // NFT Wallet
    'nft_gallery_opened': 'NFT Wallet',
    'nft_transfer_initiated': 'NFT Wallet',
    'nft_transfer_success': 'NFT Wallet',
    'nft_transfer_failure': 'NFT Wallet',

    // Market Bot
    'marketbot_setup_start': 'Market Bot',
    'marketbot_setup_complete': 'Market Bot',
    'marketbot_trade_executed': 'Market Bot',
    'marketbot_error': 'Market Bot',

    // Rewards
    'reward_claim_initiated': 'Rewards',
    'reward_claim_success': 'Rewards',
    'reward_claim_failure': 'Rewards',

    // Ecosystem
    'dapp_connect': 'Ecosystem',

    // Preferences
    'settings_change': 'Preferences',
    'theme_selected': 'Preferences',

    // Stability
    'error_displayed': 'Stability',

    // Growth
    'app_share': 'Growth',

    // HD Wallet Ops
    'hd_address_generated': 'HD Wallet Ops',

    // UX & UI
    'scroll_attempt_outside_content': 'UX Interaction',
    'wallet_list_half_viewport': 'UI Usability',

    // Data Sync
    'coins_data_updated': 'Data Sync',

    // Search
    'searchbar_input': 'Search',

    // Performance
    'page_interactive_delay': 'Performance',
  };

  /// Queue to store events when analytics is disabled
  final List<AnalyticsEventData> _eventQueue = [];

  @override
  String get providerName => 'Matomo';

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> initialize(AnalyticsSettings settings) async {
    return _initializeWithRetry(settings);
  }

  /// Initialize with retry mechanism
  Future<void> _initializeWithRetry(AnalyticsSettings settings) async {
    try {
      if (kDebugMode) {
        log(
          'Initializing Matomo Analytics with settings: isSendAllowed=${settings.isSendAllowed}',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
        );
      }

      // Initialize Matomo only if configuration is provided

      final bool hasConfig = matomoUrl.isNotEmpty && matomoSiteId.isNotEmpty;
      if (!hasConfig) {
        if (kDebugMode) {
          log(
            'Matomo configuration missing (MATOMO_URL and/or MATOMO_SITE_ID). Disabling Matomo.',
            path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          );
        }
        _isInitialized = false;
        _isEnabled = false;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        return;
      }

      await MatomoTracker.instance.initialize(
        siteId: matomoSiteId,
        url: matomoUrl,
        dispatchSettings: const DispatchSettings.persistent(),
        // Include backend API key header similarly to feedback feature
        customHeaders: {
          if (const String.fromEnvironment('FEEDBACK_API_KEY').isNotEmpty)
            'X-KW-KEY': const String.fromEnvironment('FEEDBACK_API_KEY'),
        },
      );
      _instance = MatomoTracker.instance;

      _isInitialized = true;
      // Disable analytics in CI or when analyticsDisabled flag is set
      final bool shouldDisable = analyticsDisabled || isCiEnvironment;
      _isEnabled = settings.isSendAllowed && !shouldDisable;

      if (kDebugMode) {
        log(
          'Matomo Analytics initialized: _isInitialized=$_isInitialized, _isEnabled=$_isEnabled',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
        );
      }

      if (_isInitialized && _isEnabled) {
        await activate();
      } else {
        await deactivate();
      }

      // Successfully initialized
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      _isInitialized = false;

      if (kDebugMode) {
        log(
          'Error initializing Matomo Analytics: $e',
          path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          isError: true,
        );
      }

      // Try to initialize again if we haven't exceeded max retries
      if (_initRetryCount < _maxInitRetries) {
        _initRetryCount++;

        if (kDebugMode) {
          log(
            'Retrying Matomo analytics initialization (attempt $_initRetryCount of $_maxInitRetries)',
            path: 'analytics -> MatomoAnalyticsApi -> _initialize',
          );
        }

        // Retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * _initRetryCount));
        await _initializeWithRetry(settings);
      } else {
        // Maximum retries exceeded
        if (!_initCompleter.isCompleted) {
          _initCompleter.completeError(e);
        }
      }
    }
  }

  @override
  Future<void> retryInitialization(AnalyticsSettings settings) async {
    if (!_isInitialized) {
      _initRetryCount = 0;
      return _initializeWithRetry(settings);
    }
  }

  @override
  Future<void> sendEvent(AnalyticsEventData event) async {
    // If not initialized or disabled, enqueue for later
    if (!_isInitialized || !_isEnabled) {
      _eventQueue.add(event);
      return;
    }
    final sanitizedParameters = event.parameters.map((key, value) {
      if (value == null) return MapEntry(key, "null");
      if (value is Map || value is List) {
        return MapEntry(key, jsonEncode(value));
      }
      return MapEntry(key, value.toString());
    });

    // Log the event in debug mode with formatted parameters for better readability
    if (kDebugMode) {
      final formattedParams = const JsonEncoder.withIndent(
        '  ',
      ).convert(sanitizedParameters);
      log(
        'Matomo Analytics Event: ${event.name}; Parameters: $formattedParams',
        path: 'analytics -> MatomoAnalyticsApi -> sendEvent',
      );
    }

    try {
      // Convert to Matomo event format
      _instance.trackEvent(
        eventInfo: EventInfo(
          category: _extractCategory(event.name),
          action: event.name,
          name: event.name,
          value: _extractEventValue(sanitizedParameters),
        ),
        dimensions: event.parameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      // Note: Custom dimensions should be set separately in Matomo
      // You can extend this implementation to handle custom dimensions if needed
    } catch (e, s) {
      log(
        e.toString(),
        path: 'analytics -> MatomoAnalyticsApi -> sendEvent',
        trace: s,
        isError: true,
      );
    }
  }

  @override
  Future<void> activate() async {
    if (!_isInitialized) {
      return;
    }

    _isEnabled = true;
    // Attach visit-scoped custom dimensions such as platform name
    try {
      if (matomoPlatformDimensionId != null) {
        final platform = PlatformInfo.getInstance().platform;
        final dimensionKey = 'dimension$matomoPlatformDimensionId';
        MatomoTracker.instance.trackDimensions(
          dimensions: {dimensionKey: platform},
        );
        if (kDebugMode) {
          log(
            'Matomo dimensions set: {$dimensionKey: $platform}',
            path: 'analytics -> MatomoAnalyticsApi -> activate',
          );
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        log(
          'Failed to set Matomo custom dimensions: $e',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
          trace: s,
          isError: true,
        );
      }
    }
    // Matomo doesn't have a direct enable/disable method like Firebase
    // so we handle this by simply processing queued events

    // Process any queued events
    if (_eventQueue.isNotEmpty) {
      if (kDebugMode) {
        log(
          'Processing ${_eventQueue.length} queued Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
        );
      }

      final queuedEvents = List<AnalyticsEventData>.from(_eventQueue);
      _eventQueue.clear();

      int processedCount = 0;
      for (final event in queuedEvents) {
        await sendEvent(event);
        processedCount++;
      }

      if (kDebugMode && processedCount > 0) {
        log(
          'Successfully processed $processedCount queued Matomo analytics events',
          path: 'analytics -> MatomoAnalyticsApi -> activate',
        );
      }
    }
  }

  @override
  Future<void> deactivate() async {
    if (!_isInitialized) {
      return;
    }

    if (kDebugMode) {
      log(
        'Matomo analytics collection disabled',
        path: 'analytics -> MatomoAnalyticsApi -> deactivate',
      );
    }

    _isEnabled = false;
    // Matomo doesn't have a direct disable method
    // Events will be queued instead of sent when disabled
  }

  /// Extract category from event name (used for Matomo event categorization)
  String _extractCategory(String eventName) {
    // 1) Exact mapping from CSV
    final mapped = _eventCategoryMap[eventName];
    if (mapped != null) return mapped;

    // 2) Fallback by prefix → Business Category (keep in sync with CSV semantics)
    if (eventName.startsWith('onboarding_')) return 'User Acquisition';
    if (eventName.startsWith('wallet_')) return 'User Acquisition';
    if (eventName.startsWith('app_')) return 'User Engagement';
    if (eventName.startsWith('portfolio_')) return 'Portfolio';
    if (eventName.startsWith('asset_')) return 'Asset Mgmt';
    if (eventName.startsWith('send_')) return 'Transactions';
    if (eventName.startsWith('swap_')) return 'Trading (DEX)';
    if (eventName.startsWith('bridge_')) return 'Cross-Chain';
    if (eventName.startsWith('nft_')) return 'NFT Wallet';
    if (eventName.startsWith('marketbot_')) return 'Market Bot';
    if (eventName.startsWith('reward_')) return 'Rewards';
    if (eventName.startsWith('dapp_')) return 'Ecosystem';
    if (eventName.startsWith('settings_')) return 'Preferences';
    if (eventName.startsWith('error_')) return 'Stability';
    if (eventName.startsWith('hd_')) return 'HD Wallet Ops';
    if (eventName.startsWith('scroll_')) return 'UX Interaction';
    if (eventName.startsWith('searchbar_')) return 'Search';
    if (eventName.startsWith('theme_')) return 'Preferences';
    if (eventName.startsWith('coins_')) return 'Data Sync';
    if (eventName.startsWith('page_')) return 'Performance';

    return 'General';
  }

  /// Extract numeric value from parameters for Matomo event value
  double? _extractEventValue(Map<String, dynamic> parameters) {
    // Look for common numeric parameters that could serve as event value
    final potentialValueKeys = [
      'amount',
      'value',
      'count',
      'duration_ms',
      'profit_usd',
      'reward_amount',
      'base_capital',
      'trade_size',
      // From required_analytics_events.csv (keep in sync)
      'backup_time',
      'total_coins',
      'total_value_usd',
      'growth_pct',
      'realized_pnl',
      'unrealized_pnl',
      'fee',
      'load_time_ms',
      'nft_count',
      'pairs_count',
      'expected_reward_amount',
      'account_index',
      'address_index',
      'scroll_delta',
      'time_to_half_ms',
      'wallet_size',
      'coins_count',
      'update_duration_ms',
      'query_length',
      'interactive_delay_ms',
      'spinner_time_ms',
    ];

    for (final key in potentialValueKeys) {
      if (parameters.containsKey(key)) {
        final value = parameters[key];
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    if (kDebugMode) {
      log(
        'MatomoAnalyticsApi disposed',
        path: 'analytics -> MatomoAnalyticsApi -> dispose',
      );
    }
  }
}
