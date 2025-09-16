import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/app_config/app_config.dart' show setGeoDisallowedAssets;

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  Future<bool> isTradingEnabled({bool? forceFail}) async {
    try {
      final geoBlock = const String.fromEnvironment('GEO_BLOCK');
      if (geoBlock == 'disabled') {
        debugPrint('GEO_BLOCK is disabled. Trading enabled.');
        // Ensure no geo disallowed assets are set when geo blocking is disabled
        setGeoDisallowedAssets(const []);
        return true;
      }

      final apiKey = const String.fromEnvironment('FEEDBACK_API_KEY');
      final bool shouldFail = forceFail ?? false;

      if (apiKey.isEmpty && !shouldFail) {
        debugPrint('FEEDBACK_API_KEY not found. Trading disabled.');
        return false;
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
        return res.statusCode == 200;
      }

      if (res.statusCode != 200) return false;
      final JsonMap data = jsonFromString(res.body);

      // Update geo-disallowed assets list if provided by the bouncer
      final List<dynamic>? disallowedAssetsDyn =
          data.valueOrNull<List<dynamic>>('disallowed_assets');
      if (disallowedAssetsDyn != null) {
        final assets = disallowedAssetsDyn
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        setGeoDisallowedAssets(assets);
      } else {
        // If the field is missing, reset to an empty list to avoid stale data
        setGeoDisallowedAssets(const []);
      }

      // Prefer disallowed_features to determine trading availability
      final List<dynamic>? disallowedFeaturesDyn =
          data.valueOrNull<List<dynamic>>('disallowed_features');
      if (disallowedFeaturesDyn != null) {
        final features = disallowedFeaturesDyn.whereType<String>().toSet();
        final tradingBlocked = features.contains('TRADING');
        return !tradingBlocked;
      }

      // Fallback to legacy 'blocked' flag if features are not present
      return !(data.valueOrNull<bool>('blocked') ?? true);
    } catch (_) {
      debugPrint('Network error: Trading status check failed');
      // Block trading features on network failure
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
