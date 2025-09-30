import 'dart:async' show TimeoutException;
import 'dart:io';
import 'dart:math' show Random;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider.dart';

/// A time provider that fetches time from server 'Date' headers via HEAD requests
class HttpHeadTimeProvider extends TimeProvider {
  HttpHeadTimeProvider({
    this.servers = const [
      'https://alibaba.com/',
      'https://google.com/',
      'https://cloudflare.com/',
      'https://microsoft.com/',
      'https://github.com/',
    ],
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 2),
    this.maxRetries = 3,
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
  Future<DateTime> getCurrentUtcTime() async {
    // Randomize the order of servers to avoid overloading any single server
    // and to provide a more even distribution of requests.
    // This also avoid a single server being a single point of failure.
    final shuffledServers = List<String>.from(servers)..shuffle(Random());
    _logger.fine('Randomized server order for time retrieval');
    
    for (final serverUrl in shuffledServers) {
      int retries = 0;

      while (retries < maxRetries) {
        try {
          final serverTime = await _fetchServerTime(serverUrl);
          _logger.fine('Successfully retrieved time from $serverUrl');
          return serverTime;
        } on SocketException catch (e, s) {
          _logger.warning('Socket error with $serverUrl', e, s);
        } on TimeoutException catch (e, s) {
          _logger.warning('Timeout with $serverUrl', e, s);
        } on HttpException catch (e, s) {
          _logger.warning('HTTP error with $serverUrl', e, s);
        } on FormatException catch (e, s) {
          _logger.warning('Date header parse error with $serverUrl', e, s);
        } 
        retries++;
      }
    }

    _logger
        .severe('Failed to get time from any server after $maxRetries retries');
    throw TimeoutException(
      'Failed to get time from any server after $maxRetries retries',
    );
  }

  /// Fetches server time from the 'date' header of an HTTP HEAD response
  Future<DateTime> _fetchServerTime(String url) async {
    final response = await _httpClient.head(Uri.parse(url)).timeout(timeout);

    // Treat any successful or redirect status as acceptable.
    if (response.statusCode < 200 || response.statusCode >= 400) {
      _logger.warning('HTTP error from $url: ${response.statusCode}');
      throw HttpException(
        'HTTP error from $url: ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }

    final dateHeader = response.headers['date'];
    if (dateHeader == null) {
      _logger.warning('No Date header in response from $url');
      throw FormatException('No Date header in response from $url');
    }

    final parsed = HttpDate.parse(dateHeader);
    return parsed.toUtc();
  }

  /// Disposes the HTTP client when done
  @override
  void dispose() {
    _httpClient.close();
  }
}
