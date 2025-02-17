// lib/repositories/system_clock_repository.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:web_dex/shared/utils/utils.dart';

class SystemClockRepository {
  SystemClockRepository({
    http.Client? httpClient,
    Duration? maxAllowedDifference,
    Duration? apiTimeout,
  })  : _httpClient = httpClient ?? http.Client(),
        _maxAllowedDifference =
            maxAllowedDifference ?? const Duration(seconds: 60),
        _apiTimeout = apiTimeout ?? const Duration(seconds: 2);

  static const _utcWorldTimeApis = [
    'https://worldtimeapi.org/api/timezone/UTC',
    'https://timeapi.io/api/time/current/zone?timeZone=UTC',
    'http://worldclockapi.com/api/json/utc/now',
  ];

  final Duration _maxAllowedDifference;
  final Duration _apiTimeout;
  final http.Client _httpClient;

  /// Queries the available 3rd party APIs to validate the system clock validity
  /// returning true if the system clock is within allowed difference of the API
  /// time, false otherwise. Uses the first successful response
  Future<bool> isSystemClockValid({
    List<String> timeApiUrls = _utcWorldTimeApis,
  }) async {
    try {
      final futures = timeApiUrls.map((url) => _httpGet(url));

      final responses = await Future.wait(
        futures,
        eagerError: false,
      );

      for (final response in responses) {
        if (response.statusCode != 200) {
          continue;
        }

        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final DateTime apiTime = _parseUtcDateTimeString(jsonResponse);
        final localTime = DateTime.timestamp();
        final Duration difference = apiTime.difference(localTime).abs();

        return difference < _maxAllowedDifference;
      }

      // Log error if no successful responses
      log('All time API requests failed').ignore();
      return true;
    } catch (e) {
      log('Failed to validate system clock: $e').ignore();
      return true; // Don't block usage
    }
  }

  Future<http.Response> _httpGet(String url) async {
    try {
      return await _httpClient.get(Uri.parse(url)).timeout(_apiTimeout);
    } catch (e) {
      return http.Response('Error: $e', HttpStatus.internalServerError);
    }
  }

  DateTime _parseUtcDateTimeString(Map<String, dynamic> jsonResponse) {
    dynamic apiTimeStr = jsonResponse['datetime'] ?? // worldtimeapi.org
        jsonResponse['dateTime'] ?? // worldclockapi.com
        jsonResponse['currentDateTime']; // timeapi.io

    if (apiTimeStr == null) {
      throw Exception('API response does not contain datetime field');
    }

    if (apiTimeStr is! String || apiTimeStr.isEmpty) {
      throw const FormatException('API datetime field is not a string');
    }

    // Convert +00:00 format to Z format if needed
    if (apiTimeStr.endsWith('+00:00')) {
      apiTimeStr = apiTimeStr.replaceAll('+00:00', 'Z');
    } else if (!apiTimeStr.endsWith('Z')) {
      apiTimeStr += 'Z'; // Add UTC timezone indicator if missing
    }

    final apiTime = DateTime.parse(apiTimeStr);
    if (!apiTime.isUtc) {
      throw const FormatException('API time is not in UTC');
    }
    return apiTime;
  }

  /// Checks if there are enough active seeders to indicate valid system clock
  Future<bool> hasActiveSeeders() async {
    // TODO: Implement seeder check logic onur suggested - few seeders
    // implies that the user's clock is invalid and being rejected by seeders
    throw UnimplementedError('Not implemented yet');
  }

  /// Combines multiple clock validation methods
  Future<bool> isClockValidWithAllChecks() async {
    final apiCheck = await isSystemClockValid();
    final seederCheck = await hasActiveSeeders();

    return apiCheck && seederCheck;
  }

  void dispose() {
    _httpClient.close();
  }
}
