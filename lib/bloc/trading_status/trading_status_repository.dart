import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/shared/constants.dart';

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  Future<bool> isTradingEnabled({bool? forceFail}) async {
    try {
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
