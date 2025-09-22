import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/trading_status/app_geo_status.dart';
import 'package:web_dex/bloc/trading_status/disallowed_feature.dart';
import 'package:web_dex/bloc/trading_status/trading_status_api_provider.dart';

class TradingStatusRepository {
  TradingStatusRepository({
    required KomodoDefiSdk sdk,
    TradingStatusApiProvider? apiProvider,
    Duration? pollingInterval,
  }) : _sdk = sdk,
       _apiProvider = apiProvider ?? TradingStatusApiProvider();

  final TradingStatusApiProvider _apiProvider;
  final Logger _log = Logger('TradingStatusRepository');
  final KomodoDefiSdk _sdk;

  /// Fetches geo status and computes trading availability.
  ///
  /// Rules:
  /// - If GEO_BLOCK=disabled, trading is enabled.
  /// - Otherwise, trading is disabled if disallowed_features contains 'TRADING'.
  Future<AppGeoStatus> fetchStatus({bool? forceFail}) async {
    try {
      if (_isGeoBlockDisabled()) {
        _log.info('GEO_BLOCK is disabled. Trading enabled.');
        return const AppGeoStatus();
      }

      final bool shouldFail = forceFail ?? false;
      final String apiKey = _readFeedbackApiKey();

      if (apiKey.isEmpty && !shouldFail) {
        // TODO!: remvoe after testing
        final coinIds = {'KMD', 'ETH', 'BTC-segwit'};
        final assetIds = coinIds.map((e) => _sdk.getSdkAsset(e).id).toSet();
        return AppGeoStatus(
          disallowedAssets: assetIds,
          disallowedFeatures: const {},
        );
        _log.warning('FEEDBACK_API_KEY not found. Trading disabled.');
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      late final JsonMap data;
      if (shouldFail) {
        final res = await _apiProvider.fetchTradingBlacklist();
        return AppGeoStatus(
          disallowedFeatures: res.statusCode == 200
              ? const <DisallowedFeature>{}
              : const <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      data = await _apiProvider.fetchGeoStatus(apiKey: apiKey);

      final featuresParsed = _parseFeatures(data);
      final Set<AssetId> disallowedAssets = _parseAssets(data);

      // If the API omitted the disallowed_features field entirely,
      // block trading by default to be conservative.
      if (!featuresParsed.hasFeatures) {
        _log.warning(
          'disallowed_features missing in response. Blocking trading.',
        );
        return AppGeoStatus(
          disallowedAssets: disallowedAssets,
          disallowedFeatures: const <DisallowedFeature>{
            DisallowedFeature.trading,
          },
        );
      }

      return AppGeoStatus(
        disallowedAssets: disallowedAssets,
        disallowedFeatures: featuresParsed.features,
      );
    } on Exception catch (e, s) {
      _log.severe('Unexpected error during trading status check', e, s);
      return const AppGeoStatus(
        disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
      );
    }
  }

  /// Backward-compatible helper for existing call sites.
  Future<bool> isTradingEnabled({bool? forceFail}) async {
    final status = await fetchStatus(forceFail: forceFail);
    return status.tradingEnabled;
  }

  /// Creates a stream that periodically polls for trading status using the
  /// poll utility function with fault tolerance.
  ///
  /// The stream yields immediately with the first status check, then continues
  /// polling at the configured interval. Default interval is 3 minutes.
  Stream<AppGeoStatus> watchTradingStatus({
    Duration pollingInterval = const Duration(minutes: 3),
    Duration retryInterval = const Duration(seconds: 30),
    bool? forceFail,
  }) async* {
    _log.info('Starting trading status polling stream');

    while (true) {
      try {
        final status = await poll(
          () => fetchStatus(forceFail: forceFail),
          isComplete: (_) => false, // Never complete, keep polling
          maxDuration: pollingInterval,
          backoffStrategy: const ConstantBackoff(delay: Duration(seconds: 30)),
          shouldContinueOnError: (error) {
            _log.warning('Error during status poll, continuing: $error');
            return true;
          },
        );
        yield status;
      } on TimeoutException catch (_) {
        _log.fine('Polling interval completed, waiting for next cycle');
        await Future<void>.delayed(pollingInterval);
      } catch (e) {
        _log.warning('Unexpected error in polling cycle: $e');
        yield const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
        await Future<void>.delayed(retryInterval);
      }
    }
  }

  // --- Configuration helpers -------------------------------------------------
  String _readGeoBlockFlag() => const String.fromEnvironment('GEO_BLOCK');
  String _readFeedbackApiKey() =>
      const String.fromEnvironment('FEEDBACK_API_KEY');
  bool _isGeoBlockDisabled() => _readGeoBlockFlag() == 'disabled';

  // --- Parsing helpers -------------------------------------------------------

  ({Set<DisallowedFeature> features, bool hasFeatures}) _parseFeatures(
    JsonMap data,
  ) {
    final List<String>? raw = data.valueOrNull<List<String>>(
      'disallowed_features',
    );
    final Set<DisallowedFeature> parsed = raw == null
        ? <DisallowedFeature>{}
        : raw.map(DisallowedFeature.parse).toSet();
    return (features: parsed, hasFeatures: raw != null);
  }

  Set<AssetId> _parseAssets(JsonMap data) {
    final List<String>? raw = data.valueOrNull<List<String>>(
      'disallowed_assets',
    );
    if (raw == null) return const <AssetId>{};

    final Set<AssetId> out = <AssetId>{};
    for (final symbol in raw) {
      try {
        final assets = _sdk.assets.findAssetsByConfigId(symbol);
        out.addAll(assets.map((a) => a.id));
      } catch (e) {
        _log.warning('Failed to resolve asset "$symbol": ${e.toString()}');
      }
    }
    return out;
  }

  void dispose() {
    _apiProvider.dispose();
  }
}
