import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show JsonMap;

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  /// Returns the set of disallowed feature identifiers reported by the
  /// bouncer service. Empty set means no feature is blocked.
  ///
  /// Recognized features include (but are not limited to):
  /// - 'TRADING'
  /// - 'PRIVACY_COINS'
  Future<Set<String>> fetchDisallowedFeatures({bool? forceFail}) async {
    try {
      final geoBlock = const String.fromEnvironment('GEO_BLOCK');
      if (geoBlock == 'disabled') {
        debugPrint('GEO_BLOCK is disabled. No features are disallowed.');
        return <String>{};
      }

      final apiKey = const String.fromEnvironment('FEEDBACK_API_KEY');
      final bool shouldFail = forceFail ?? false;

      if (apiKey.isEmpty && !shouldFail) {
        debugPrint('FEEDBACK_API_KEY not found. Assuming TRADING disallowed.');
        return {'TRADING'};
      }

      late final Uri uri;
      final headers = <String, String>{};

      if (shouldFail) {
        uri = Uri.parse(tradingBlacklistUrl);
      } else {
        uri = Uri.parse(geoBlockerApiUrl);
        headers['X-KW-KEY'] = apiKey;
      }

      final res = await _httpClient
          .post(uri, headers: headers)
          .timeout(_timeout);

      if (shouldFail) {
        // Fallback behavior for tests: non-200 => treat as trading blocked
        return res.statusCode == 200 ? <String>{} : {'TRADING'};
      }

      if (res.statusCode != 200) return {'TRADING'};

      final JsonMap root = jsonFromString(res.body);
      // Support both top-level and nested under 'data'
      final JsonMap payload =
          (root.valueOrNull<JsonMap>('data') ?? root) as JsonMap;

      final List<dynamic> disallowed =
          (payload['disallowed_features'] as List<dynamic>?) ?? const [];
      final Set<String> features = disallowed
          .map((e) => e.toString().toUpperCase())
          .toSet();

      // Backward compatibility: if new field is absent, fall back to 'blocked'
      if (features.isEmpty) {
        final bool? blocked = payload.valueOrNull<bool>('blocked');
        if (blocked == true) return {'TRADING'};
      }

      return features;
    } catch (_) {
      debugPrint('Network error: Feature gating check failed');
      // Block trading features on network failure (conservative)
      return {'TRADING'};
    }
  }

  /// Backward-compatible method. Prefer [fetchDisallowedFeatures].
  Future<bool> isTradingEnabled({bool? forceFail}) async {
    final features = await fetchDisallowedFeatures(forceFail: forceFail);
    return !features.contains('TRADING');
  }

  void dispose() {
    _httpClient.close();
  }
}
