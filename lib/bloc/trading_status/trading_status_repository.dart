import 'dart:async';
import 'package:http/http.dart' as http;

class TradingStatusRepository {
  TradingStatusRepository({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 4);

  final http.Client _httpClient;
  final Duration _timeout;

  Future<bool> isTradingEnabled() async {
    try {
      final uri =
          Uri.parse('https://defi-stats.komodo.earth/api/v3/utils/bouncer');
      final res = await _httpClient.get(uri).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      // Do not block trading features on network failure
      return true;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
