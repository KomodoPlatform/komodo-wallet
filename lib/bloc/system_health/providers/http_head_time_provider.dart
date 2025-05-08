import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider.dart';

/// A time provider that fetches time from server 'Date' headers via HEAD requests
class HttpHeadTimeProvider extends TimeProvider {
  HttpHeadTimeProvider({
    this.servers = const [
      'https://www.google.com/',
      'https://www.alibaba.com/',
      'https://www.vk.com/',
      'https://www.cloudflare.com/',
      'https://www.microsoft.com/',
    ],
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 2),
    this.maxRetries = 2,
    Logger? logger,
  })  : _httpClient = httpClient ?? http.Client(),
        _logger = logger ?? Logger('HttpHeadTimeProvider');

  /// The name of the provider (for logging and identification)
  final Logger _logger;

  /// List of servers to query via HEAD requests
  final List<String> servers;

  /// Timeout for HTTP requests
  final Duration timeout;

  /// Maximum retries per server
  final int maxRetries;

  final http.Client _httpClient;

  @override
  String get name => 'HttpHead';

  @override
  Future<DateTime?> getCurrentUtcTime() async {
    for (final server in servers) {
      int retries = 0;

      while (retries < maxRetries) {
        try {
          final serverTime = await _fetchServerTime(server);
          if (serverTime != null) {
            _logger.fine('Successfully retrieved time from $server');
            return serverTime;
          }
        } on Exception catch (e) {
          _logger.severe('Error with $server: $e');
        }
        retries++;
      }
    }

    _logger
        .severe('Failed to get time from any server after $maxRetries retries');
    return null;
  }

  /// Fetches server time from the 'date' header of an HTTP HEAD response
  Future<DateTime?> _fetchServerTime(String url) async {
    try {
      final response = await _httpClient.head(
        Uri.parse(url),
        headers: {
          HttpHeaders.userAgentHeader: 'Komodo-Wallet/1.0',
        },
      ).timeout(timeout);

      if (response.statusCode != 200) {
        _logger.warning('HTTP error from $url: ${response.statusCode}');
        return null;
      }

      final dateHeader = response.headers['date'];
      if (dateHeader == null) {
        _logger.warning('No Date header in response from $url');
        return null;
      }

      final parsed = HttpDate.parse(dateHeader);
      return parsed.toUtc(); // Ensure it's UTC
    } on SocketException catch (e) {
      _logger.warning('Socket error with $url: ${e.message}');
      return null;
    } on TimeoutException catch (e) {
      _logger.warning('Timeout with $url: ${e.message}');
      return null;
    } on FormatException catch (e) {
      _logger.severe('Failed to parse Date header from $url: $e');
      return null;
    } on Exception catch (e) {
      _logger.severe('Error fetching time from $url: $e');
      return null;
    }
  }

  /// Disposes the HTTP client when done
  @override
  void dispose() {
    _httpClient.close();
  }
}
