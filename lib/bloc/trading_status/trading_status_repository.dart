import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _httpClient;
  final Duration _timeout;

  Future<bool> isTradingEnabled({bool? forceFail}) async {
    try {
      final uri = Uri.parse(
        (forceFail ?? false)
            ? 'https://defi-stats.komodo.earth/api/v3/utils/blacklist'
            : 'https://defi-stats.komodo.earth/api/v3/utils/bouncer',
      );
      final res = await _httpClient.get(uri).timeout(_timeout);
      return res.statusCode == 200;
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
