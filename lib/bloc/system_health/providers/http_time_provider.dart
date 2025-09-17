import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider.dart';

/// A time provider that fetches time from an HTTP API
class HttpTimeProvider extends TimeProvider {
  HttpTimeProvider({
    required this.url,
    required this.timeFieldPath,
    required this.timeFormat,
    required String providerName,
    http.Client? httpClient,
    Duration? apiTimeout,
    Logger? logger,
  }) : _httpClient = httpClient ?? http.Client(),
       _apiTimeout = apiTimeout ?? const Duration(seconds: 2),
       name = providerName,
       _logger = logger ?? Logger(providerName);

  /// The URL of the time API
  final String url;

  /// The field path in the JSON response that contains the time.
  ///
  /// Separate nested fields with dots (e.g., "time.current")
  final String timeFieldPath;

  /// The format of the time string in the response
  final TimeFormat timeFormat;

  /// The name of the provider (for logging and identification)
  @override
  final String name;

  final Logger _logger;

  final http.Client _httpClient;
  final Duration _apiTimeout;

  @override
  Future<DateTime> getCurrentUtcTime() async {
    final response = await _httpClient.get(Uri.parse(url)).timeout(_apiTimeout);

    if (response.statusCode != 200) {
      _logger.warning('API request failed with status ${response.statusCode}');
      throw HttpException(
        'API request failed with status ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      _logger.warning(
        'Expected top-level JSON object, got ${decoded.runtimeType}',
      );
      throw const FormatException('Invalid JSON structure – object expected');
    }
    final Map<String, dynamic> jsonResponse = decoded;
    final parsedTime = await _parseTimeFromJson(jsonResponse);

    return parsedTime;
  }

  Future<DateTime> _parseTimeFromJson(Map<String, dynamic> jsonResponse) async {
    final fieldParts = timeFieldPath.split('.');
    dynamic value = jsonResponse;

    for (final part in fieldParts) {
      if (value is! Map<String, dynamic>) {
        _logger.warning('JSON path error: expected Map at $part');
        throw FormatException('JSON path error: expected Map at $part');
      }
      value = value[part];
      if (value == null) {
        _logger.warning('JSON path error: null value at $part');
        throw FormatException('JSON path error: null value at $part');
      }
    }

    final timeStr = value.toString();
    if (timeStr.isEmpty) {
      _logger.warning('Empty time string');
      throw const FormatException('Empty time string');
    }

    return _parseDateTime(timeStr);
  }

  DateTime _parseDateTime(String timeStr) {
    switch (timeFormat) {
      case TimeFormat.iso8601:
        return DateTime.parse(timeStr).toUtc();
      case TimeFormat.custom:
        throw const FormatException('Custom time format not supported');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}

/// Enum representing the format of time returned by the API
enum TimeFormat {
  /// ISO8601 format (e.g. "2023-05-07T12:34:56Z")
  iso8601,

  /// Custom format that may require special parsing
  custom,
}
