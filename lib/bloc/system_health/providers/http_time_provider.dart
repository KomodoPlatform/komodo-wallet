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
  })  : _httpClient = httpClient ?? http.Client(),
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
  Future<DateTime?> getCurrentUtcTime() async {
    try {
      final response = await _httpGet(url);

      if (response.statusCode != 200) {
        _logger
            .warning('API request failed with status ${response.statusCode}');
        return null;
      }

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      final DateTime? parsedTime = await _parseTimeFromJson(jsonResponse);

      if (parsedTime == null) {
        _logger.warning('Failed to parse time from response');
        return null;
      }

      return parsedTime;
    } on Exception catch (e) {
      _logger.severe('Error fetching time: $e');
      return null;
    }
  }

  Future<http.Response> _httpGet(String url) async {
    try {
      return await _httpClient.get(Uri.parse(url)).timeout(_apiTimeout);
    } on Exception catch (e) {
      return http.Response('Error: $e', HttpStatus.internalServerError);
    }
  }

  Future<DateTime?> _parseTimeFromJson(
      Map<String, dynamic> jsonResponse) async {
    try {
      final fieldParts = timeFieldPath.split('.');
      dynamic value = jsonResponse;

      for (final part in fieldParts) {
        if (value is! Map<String, dynamic>) {
          _logger.warning('JSON path error: expected Map at $part');
          return null;
        }
        value = value[part];
        if (value == null) {
          _logger.warning('JSON path error: null value at $part');
          return null;
        }
      }

      final timeStr = value.toString();
      if (timeStr.isEmpty) {
        _logger.warning('Empty time string');
        return null;
      }

      return await _parseDateTime(timeStr);
    } on Exception catch (e) {
      _logger.severe('JSON parsing error: $e');
      return null;
    }
  }

  Future<DateTime?> _parseDateTime(String timeStr) async {
    try {
      String formattedTime = timeStr;

      switch (timeFormat) {
        case TimeFormat.iso8601:
          if (formattedTime.endsWith('+00:00')) {
            formattedTime = formattedTime.replaceAll('+00:00', 'Z');
          } else if (!formattedTime.endsWith('Z')) {
            formattedTime += 'Z';
          }

        case TimeFormat.custom:
          throw const FormatException('Custom time format not supported');
      }

      final dateTime = DateTime.parse(formattedTime);
      if (!dateTime.isUtc) {
        throw const FormatException('Time is not in UTC');
      }

      return dateTime;
    } on Exception catch (e) {
      _logger.severe('Date parsing error: $e');
      return null;
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
  custom
}
