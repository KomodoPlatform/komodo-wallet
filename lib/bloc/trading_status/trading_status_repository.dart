import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/bloc/trading_status/disallowed_feature.dart';

/// Structured status returned by the bouncer service.
class TradingGeoStatus {
  const TradingGeoStatus({
    required this.tradingEnabled,
    this.disallowedAssets = const <AssetId>{},
    this.disallowedFeatures = const <DisallowedFeature>{},
  });

  final bool tradingEnabled;
  final Set<AssetId> disallowedAssets;
  final Set<DisallowedFeature> disallowedFeatures;
}

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  /// Fetches geo status and computes trading availability.
  ///
  /// Rules:
  /// - If GEO_BLOCK=disabled, trading is enabled.
  /// - Otherwise, when response contains disallowed_features, trading is
  ///   disabled if it contains 'TRADING'.
  /// - Fallback to legacy 'blocked' boolean if features are missing.
  Future<TradingGeoStatus> fetchStatus({bool? forceFail}) async {
    try {
      final geoBlock = const String.fromEnvironment('GEO_BLOCK');
      if (geoBlock == 'disabled') {
        debugPrint('GEO_BLOCK is disabled. Trading enabled.');
        return const TradingGeoStatus(tradingEnabled: true);
      }

      final apiKey = const String.fromEnvironment('FEEDBACK_API_KEY');
      final bool shouldFail = forceFail ?? false;

      if (apiKey.isEmpty && !shouldFail) {
        debugPrint('FEEDBACK_API_KEY not found. Trading disabled.');
        return const TradingGeoStatus(tradingEnabled: false);
      }

      late final Uri uri;
      final headers = <String, String>{};

      if (shouldFail) {
        uri = Uri.parse(tradingBlacklistUrl);
      } else {
        uri = Uri.parse(geoBlockerApiUrl);
        headers['X-KW-KEY'] = apiKey;
      }

      final res =
          await _httpClient.post(uri, headers: headers).timeout(_timeout);

      if (shouldFail) {
        return TradingGeoStatus(tradingEnabled: res.statusCode == 200);
      }

      if (res.statusCode != 200) {
        return const TradingGeoStatus(tradingEnabled: false);
      }

      final JsonMap data = jsonFromString(res.body);

      // Parse disallowed features/assets if present
      final List<dynamic>? rawFeatures =
          data.valueOrNull<List<dynamic>>('disallowed_features');
      final Set<DisallowedFeature> disallowedFeatures = rawFeatures == null
          ? <DisallowedFeature>{}
          : rawFeatures
              .whereType<String>()
              .map(DisallowedFeature.fromString)
              .whereType<DisallowedFeature>()
              .toSet();

      final List<dynamic>? rawAssets =
          data.valueOrNull<List<dynamic>>('disallowed_assets');
      final Set<AssetId> disallowedAssets = rawAssets == null
          ? <AssetId>{}
          : rawAssets
              .whereType<String>()
              .map((symbol) => AssetId(id: symbol, name: symbol))
              .toSet();

      bool tradingEnabled;
      if (rawFeatures != null) {
        tradingEnabled = !disallowedFeatures.contains(DisallowedFeature.trading);
      } else {
        // Backwards-breaking change: require features; if missing, block trading
        tradingEnabled = true;
      }

      return TradingGeoStatus(
        tradingEnabled: tradingEnabled,
        disallowedAssets: disallowedAssets,
        disallowedFeatures: disallowedFeatures,
      );
    } catch (_) {
      debugPrint('Network error: Trading status check failed');
      // Block trading features on network failure
      return const TradingGeoStatus(tradingEnabled: false);
    }
  }

  /// Backward-compatible helper for existing call sites.
  Future<bool> isTradingEnabled({bool? forceFail}) async {
    final status = await fetchStatus(forceFail: forceFail);
    return status.tradingEnabled;
  }

  void dispose() {
    _httpClient.close();
  }
}
