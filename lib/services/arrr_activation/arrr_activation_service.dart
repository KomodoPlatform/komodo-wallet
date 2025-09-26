import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/shared/utils/utils.dart';

import 'arrr_config.dart';

/// Service layer - business logic coordination for ARRR activation
class ArrrActivationService {
  ArrrActivationService(this._sdk)
    : _configService = _sdk.activationConfigService;

  final ActivationConfigService _configService;
  final KomodoDefiSdk _sdk;
  final Logger _log = Logger('ArrrActivationService');

  /// Stream controller for configuration requests
  final StreamController<ZhtlcConfigurationRequest> _configRequestController =
      StreamController<ZhtlcConfigurationRequest>.broadcast();

  /// Completer to wait for configuration when needed
  final Map<AssetId, Completer<ZhtlcUserConfig?>> _configCompleters = {};

  /// Stream of configuration requests that UI can listen to
  Stream<ZhtlcConfigurationRequest> get configurationRequests =>
      _configRequestController.stream;

  /// Future-based activation (for CoinsRepo consumers)
  /// This method will wait for user configuration if needed
  Future<ArrrActivationResult> activateArrr(
    Asset asset, {
    ZhtlcUserConfig? initialConfig,
  }) async {
    var config = initialConfig ?? await _getOrRequestConfiguration(asset.id);

    if (config == null) {
      final requiredSettings = await _getRequiredSettings(asset.id);

      final configRequest = ZhtlcConfigurationRequest(
        asset: asset,
        requiredSettings: requiredSettings,
      );

      final completer = Completer<ZhtlcUserConfig?>();
      _configCompleters[asset.id] = completer;

      _log.info('Requesting configuration for ${asset.id.id}');

      // Check if stream controller is closed
      if (_configRequestController.isClosed) {
        _log.severe(
          'Configuration request controller is closed for ${asset.id.id}',
        );
        return ArrrActivationResultError(
          'Configuration system is not available',
        );
      }

      // Wait for UI listeners to be ready before emitting request
      await _waitForUIListeners(asset.id);

      try {
        _configRequestController.add(configRequest);
        _log.info('Configuration request emitted for ${asset.id.id}');
      } catch (e, stackTrace) {
        _log.severe(
          'Failed to emit configuration request for ${asset.id.id}',
          e,
          stackTrace,
        );
        return ArrrActivationResultError('Failed to request configuration: $e');
      }

      try {
        config = await completer.future.timeout(
          const Duration(minutes: 15),
          onTimeout: () {
            _log.warning('Configuration request timed out for ${asset.id.id}');
            return null;
          },
        );
      } finally {
        _configCompleters.remove(asset.id);
      }

      if (config == null) {
        _log.info('Configuration cancelled/timed out for ${asset.id.id}');
        return ArrrActivationResultError(
          'Configuration cancelled by user or timed out',
        );
      }

      _log.info('Configuration received for ${asset.id.id}');
    }

    _log.info('Starting activation with configuration for ${asset.id.id}');
    return _performActivation(asset, config);
  }

  /// Perform the actual activation with configuration
  Future<ArrrActivationResult> _performActivation(
    Asset asset,
    ZhtlcUserConfig config,
  ) async {
    try {
      _cacheActivationStart(asset.id);

      await for (final progress in _sdk.assets.activateAsset(asset)) {
        _cacheActivationProgress(asset.id, progress);
      }

      _cacheActivationComplete(asset.id);
      return ArrrActivationResultSuccess(
        Stream.value(
          ActivationProgress(
            status: 'Activation completed successfully',
            progressDetails: ActivationProgressDetails(
              currentStep: ActivationStep.complete,
              stepCount: 1,
            ),
          ),
        ),
      );
    } catch (e) {
      _cacheActivationError(asset.id, e.toString());
      return ArrrActivationResultError(e.toString());
    }
  }

  Future<ZhtlcUserConfig?> _getOrRequestConfiguration(AssetId assetId) async {
    final existing = await _configService.getSavedZhtlc(assetId);
    if (existing != null) return existing;

    return null;
  }

  Future<List<ActivationSettingDescriptor>> _getRequiredSettings(
    AssetId assetId,
  ) async {
    return assetId.activationSettings();
  }

  /// Activation status caching for UI display
  final Map<AssetId, ArrrActivationStatus> _activationCache = {};

  void _cacheActivationStart(AssetId assetId) {
    _activationCache[assetId] = ArrrActivationStatusInProgress(
      assetId: assetId,
      startTime: DateTime.now(),
    );
  }

  void _cacheActivationProgress(AssetId assetId, ActivationProgress progress) {
    final current = _activationCache[assetId];
    if (current is ArrrActivationStatusInProgress) {
      _activationCache[assetId] = (current).copyWith(
        progressPercentage: progress.progressPercentage?.toInt(),
        currentStep: progress.progressDetails?.currentStep,
        statusMessage: progress.status,
      );
    }
  }

  void _cacheActivationComplete(AssetId assetId) {
    _activationCache[assetId] = ArrrActivationStatusCompleted(
      assetId: assetId,
      completionTime: DateTime.now(),
    );
  }

  void _cacheActivationError(AssetId assetId, String errorMessage) {
    _activationCache[assetId] = ArrrActivationStatusError(
      assetId: assetId,
      errorMessage: errorMessage,
      errorTime: DateTime.now(),
    );
  }

  // Public method for UI to check activation status
  ArrrActivationStatus? getActivationStatus(AssetId assetId) {
    return _activationCache[assetId];
  }

  // Public method for UI to get all cached activation statuses
  Map<AssetId, ArrrActivationStatus> get activationStatuses =>
      _activationCache.unmodifiable();

  // Clear cached status when no longer needed
  void clearActivationStatus(AssetId assetId) {
    _activationCache.remove(assetId);
  }

  /// Submit configuration for a pending request
  /// Called by UI when user provides configuration
  Future<void> submitConfiguration(
    AssetId assetId,
    ZhtlcUserConfig config,
  ) async {
    _log.info('Submitting configuration for ${assetId.id}');

    // Save configuration to SDK
    final completer = _configCompleters[assetId];
    try {
      await _configService.saveZhtlcConfig(assetId, config);
      _log.info('Configuration saved to SDK for ${assetId.id}');
    } catch (e) {
      _log.severe('Failed to save configuration to SDK for ${assetId.id}: $e');
      completer?.completeError('Failed to save configuration: $e');
    }

    if (completer != null && !completer.isCompleted) {
      completer.complete(config);
    } else {
      _log.warning('No pending completer found for ${assetId.id}');
    }
  }

  /// Cancel configuration for a pending request
  /// Called by UI when user cancels configuration
  void cancelConfiguration(AssetId assetId) {
    _log.info('Cancelling configuration for ${assetId.id}');
    final completer = _configCompleters[assetId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(null);
    } else {
      _log.warning('No pending completer found for ${assetId.id}');
    }
  }

  /// Get diagnostic information about the configuration request system
  Map<String, dynamic> getConfigurationSystemDiagnostics() {
    return {
      'hasListeners': _configRequestController.hasListener,
      'isClosed': _configRequestController.isClosed,
      'pendingCompleters': _configCompleters.keys.map((id) => id.id).toList(),
      'handledConfigurations': _configCompleters.length,
    };
  }

  /// Test method to verify configuration request system is working
  /// This will log diagnostic information
  void diagnoseConfigurationSystem() {
    final diagnostics = getConfigurationSystemDiagnostics();
    _log.info('Configuration system diagnostics: $diagnostics');

    if (!_configRequestController.hasListener) {
      _log.warning(
        'No listeners detected for configuration requests. '
        'Make sure ZhtlcConfigurationHandler is in the widget tree.',
      );
    }

    if (_configRequestController.isClosed) {
      _log.severe('Configuration request controller is closed!');
    }
  }

  /// Wait for UI listeners to be ready before emitting configuration requests
  /// This ensures the ZhtlcConfigurationHandler is properly initialized
  Future<void> _waitForUIListeners(AssetId assetId) async {
    const maxWaitTime = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 100);
    final stopwatch = Stopwatch()..start();

    while (!_configRequestController.hasListener &&
        stopwatch.elapsed < maxWaitTime) {
      _log.info('Waiting for UI listeners to be ready for ${assetId.id}...');
      await Future.delayed(checkInterval);
    }

    if (!_configRequestController.hasListener) {
      _log.warning(
        'No UI listeners detected after ${maxWaitTime.inSeconds} seconds for ${assetId.id}. '
        'Make sure ZhtlcConfigurationHandler is in the widget tree.',
      );
    } else {
      _log.info(
        'UI listeners ready for ${assetId.id} after ${stopwatch.elapsed.inMilliseconds}ms',
      );
    }

    stopwatch.stop();
  }

  /// Dispose resources
  void dispose() {
    // Complete any pending configuration requests
    for (final completer in _configCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _configCompleters.clear();
    _configRequestController.close();
  }
}

/// Configuration request model for UI handling
class ZhtlcConfigurationRequest {
  const ZhtlcConfigurationRequest({
    required this.asset,
    required this.requiredSettings,
  });

  final Asset asset;
  final List<ActivationSettingDescriptor> requiredSettings;
}
