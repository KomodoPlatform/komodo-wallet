import 'dart:async';

import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/trading_status/app_geo_status.dart';
import 'package:web_dex/bloc/trading_status/disallowed_feature.dart';
import 'package:web_dex/bloc/trading_status/trading_status_repository.dart';

/// Service class that manages trading status state and provides cached access
/// to trading restrictions. This service watches the trading status stream
/// and maintains the current state for efficient lookups.
class TradingStatusService {
  TradingStatusService(this._repository);

  final TradingStatusRepository _repository;
  final Logger _log = Logger('TradingStatusService');

  /// Current cached trading status
  /// Starts with a restrictive state to prevent race conditions during app startup
  AppGeoStatus _currentStatus = const AppGeoStatus(
    disallowedFeatures: {DisallowedFeature.trading},
  );

  /// Stream subscription for trading status updates
  StreamSubscription<AppGeoStatus>? _statusSubscription;

  /// Stream controller for broadcasting status changes
  final StreamController<AppGeoStatus> _statusController =
      StreamController<AppGeoStatus>.broadcast();

  /// Track whether initialize has been called
  bool _isInitialized = false;

  /// Track whether we've received the initial status from the API
  bool _hasInitialStatus = false;

  /// Completer to track when initial status is ready
  final Completer<void> _initialStatusCompleter = Completer<void>();

  /// Future that completes when the initial status has been received
  Future<void> get initialStatusReady => _initialStatusCompleter.future;

  /// Stream of trading status updates
  Stream<AppGeoStatus> get statusStream => _statusController.stream;

  /// Current trading status (cached)
  AppGeoStatus get currentStatus {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    return _currentStatus;
  }

  /// Whether trading is currently enabled
  bool get isTradingEnabled {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    return _currentStatus.tradingEnabled;
  }

  /// Set of currently blocked asset IDs
  Set<AssetId> get blockedAssets {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    return _currentStatus.disallowedAssets;
  }

  /// Initialize the service by starting to watch trading status
  /// Must be called after constructing the service
  Future<void> initialize() async {
    assert(
      !_isInitialized,
      'TradingStatusService.initialize() can only be called once',
    );
    _isInitialized = true;
    _log.info('Initializing trading status service');

    try {
      final initialStatus = await _repository.fetchStatus();
      _updateStatus(initialStatus);
    } catch (error, stackTrace) {
      _log.severe(
        'Failed to fetch initial trading status, defaulting to blocked',
        error,
        stackTrace,
      );
      _updateStatus(
        const AppGeoStatus(disallowedFeatures: {DisallowedFeature.trading}),
      );
    }

    _startWatching();
  }

  /// Start watching trading status updates from the repository
  void _startWatching() {
    _statusSubscription?.cancel();

    _statusSubscription = _repository.watchTradingStatus().listen(
      _updateStatus,
      onError: (error, stackTrace) {
        _log.severe('Error in trading status stream', error, stackTrace);
        // On error, assume trading is disabled for safety
        _updateStatus(
          const AppGeoStatus(disallowedFeatures: {DisallowedFeature.trading}),
        );
      },
    );
  }

  /// Update the current status and broadcast changes
  void _updateStatus(AppGeoStatus newStatus) {
    final previousStatus = _currentStatus;
    _currentStatus = newStatus;

    // Mark that we've received the initial status
    if (!_hasInitialStatus) {
      _hasInitialStatus = true;
      if (!_initialStatusCompleter.isCompleted) {
        _initialStatusCompleter.complete();
      }
      _log.info('Initial trading status received');
    }

    if (previousStatus.tradingEnabled != newStatus.tradingEnabled) {
      _log.info(
        'Trading status changed: '
        '${newStatus.tradingEnabled ? 'enabled' : 'disabled'}',
      );
    }

    if (previousStatus.disallowedAssets.length !=
        newStatus.disallowedAssets.length) {
      _log.info(
        'Blocked assets count changed: '
        '${previousStatus.disallowedAssets.length} -> '
        '${newStatus.disallowedAssets.length}',
      );
    }

    _statusController.add(newStatus);
  }

  /// Check if a specific asset is currently blocked
  bool isAssetBlocked(AssetId assetId) {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    return _currentStatus.isAssetBlocked(assetId);
  }

  /// Filter a list of assets to remove blocked ones
  List<Asset> filterAllowedAssets(List<Asset> assets) {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    if (_currentStatus.tradingEnabled &&
        _currentStatus.disallowedAssets.isEmpty) {
      return assets;
    }

    return assets.where((asset) => !isAssetBlocked(asset.id)).toList();
  }

  /// Filter a map of assets to remove blocked ones
  Map<String, T> filterAllowedAssetsMap<T>(
    Map<String, T> assetsMap,
    AssetId Function(T) getAssetId,
  ) {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );
    if (_currentStatus.tradingEnabled &&
        _currentStatus.disallowedAssets.isEmpty) {
      return assetsMap; // No filtering needed
    }

    return Map.fromEntries(
      assetsMap.entries.where(
        (entry) => !isAssetBlocked(getAssetId(entry.value)),
      ),
    );
  }

  /// Immediately refresh the trading status by fetching from the repository
  /// Returns the fresh status and updates the cached status
  Future<AppGeoStatus> refreshStatus({bool? forceFail}) async {
    assert(
      _isInitialized,
      'TradingStatusService must be initialized before use. Call initialize() first.',
    );

    _log.info('Refreshing trading status immediately');

    try {
      final freshStatus = await _repository.fetchStatus(forceFail: forceFail);
      _updateStatus(freshStatus);
      return freshStatus;
    } catch (error, stackTrace) {
      _log.severe('Error refreshing trading status', error, stackTrace);
      // On error, assume trading is disabled for safety
      const errorStatus = AppGeoStatus(
        disallowedFeatures: {DisallowedFeature.trading},
      );
      _updateStatus(errorStatus);
      rethrow;
    }
  }

  void dispose() {
    _log.info('Disposing trading status service');
    _statusSubscription?.cancel();
    _statusController.close();
  }
}
