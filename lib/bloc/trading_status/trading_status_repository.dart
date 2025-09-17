import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/bloc/trading_status/disallowed_feature.dart';

/// Structured status returned by the bouncer service.
class AppGeoStatus {
  const AppGeoStatus({
    this.disallowedAssets = const <AssetId>{},
    this.disallowedFeatures = const <DisallowedFeature>{},
  });

  final Set<AssetId> disallowedAssets;
  final Set<DisallowedFeature> disallowedFeatures;

  bool get tradingEnabled =>
      !disallowedFeatures.contains(DisallowedFeature.trading);
}

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
    : _httpClient = httpClient ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  KomodoDefiSdk get _sdk => GetIt.I<KomodoDefiSdk>();

  /// Fetches geo status and computes trading availability.
  ///
  /// Rules:
  /// - If GEO_BLOCK=disabled, trading is enabled.
  /// - Otherwise, trading is disabled if disallowed_features contains 'TRADING'.
  Future<AppGeoStatus> fetchStatus({bool? forceFail}) async {
    try {
      if (_isGeoBlockDisabled()) {
        debugPrint('GEO_BLOCK is disabled. Trading enabled.');
        return const AppGeoStatus();
      }

      final bool shouldFail = forceFail ?? false;
      final String apiKey = _readFeedbackApiKey();

      if (apiKey.isEmpty && !shouldFail) {
        debugPrint('FEEDBACK_API_KEY not found. Trading disabled.');
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      final _RequestConfig request = _buildRequestConfig(
        shouldFail: shouldFail,
        apiKey: apiKey,
      );

      late final http.Response res;
      try {
        res = await _postJson(request);
      } on TimeoutException catch (_) {
        debugPrint('Trading status request timed out');
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      } on http.ClientException catch (e) {
        debugPrint(
          'HTTP client error when fetching trading status: ${e.message}',
        );
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      if (shouldFail) {
        return AppGeoStatus(
          disallowedFeatures: res.statusCode == 200
              ? const <DisallowedFeature>{}
              : const <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      if (res.statusCode != 200) {
        debugPrint('Trading status request failed with code ${res.statusCode}');
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      }

      late final JsonMap data;
      try {
        data = _decodeBody(res.body);
      } catch (e) {
        debugPrint('Failed to parse trading status response: ${e.toString()}');
        return const AppGeoStatus(
          disallowedFeatures: <DisallowedFeature>{DisallowedFeature.trading},
        );
      }
      final featuresParsed = _parseFeatures(data);
      final Set<AssetId> disallowedAssets = _parseAssets(data);

      // If the API omitted the disallowed_features field entirely,
      // block trading by default to be conservative.
      if (!featuresParsed.hasFeatures) {
        debugPrint(
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
    } catch (_) {
      debugPrint('Unexpected error: Trading status check failed');
      // Block trading features on network failure
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

  // --- Configuration helpers -------------------------------------------------
  String _readGeoBlockFlag() => const String.fromEnvironment('GEO_BLOCK');
  String _readFeedbackApiKey() =>
      const String.fromEnvironment('FEEDBACK_API_KEY');
  bool _isGeoBlockDisabled() => _readGeoBlockFlag() == 'disabled';

  // --- HTTP helpers ----------------------------------------------------------
  static const String _apiKeyHeader = 'X-KW-KEY';

  _RequestConfig _buildRequestConfig({
    required bool shouldFail,
    required String apiKey,
  }) {
    if (shouldFail) {
      return _RequestConfig(
        uri: Uri.parse(tradingBlacklistUrl),
        headers: const <String, String>{},
      );
    }
    return _RequestConfig(
      uri: Uri.parse(geoBlockerApiUrl),
      headers: <String, String>{_apiKeyHeader: apiKey},
    );
  }

  Future<http.Response> _postJson(_RequestConfig request) {
    return _httpClient
        .post(request.uri, headers: request.headers)
        .timeout(_timeout);
  }

  // --- Parsing helpers -------------------------------------------------------
  JsonMap _decodeBody(String body) => jsonFromString(body);

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
        debugPrint('Failed to resolve asset "$symbol": ${e.toString()}');
      }
    }
    return out;
  }

  void dispose() {
    _httpClient.close();
  }
}

class _RequestConfig {
  const _RequestConfig({required this.uri, required this.headers});
  final Uri uri;
  final Map<String, String> headers;
}
