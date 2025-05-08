import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:web_dex/bloc/system_health/providers/http_head_time_provider.dart';

void testHttpHeadTimeProvider() {
  group('HttpHeadTimeProvider', () {
    late HttpHeadTimeProvider provider;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      provider = HttpHeadTimeProvider(
        httpClient: mockClient,
        timeout: const Duration(seconds: 1),
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('returns DateTime when header is valid', () async {
      // RFC 1123 date format used in HTTP headers
      const dateHeader = 'Wed, 07 May 2025 12:34:56 GMT';
      final expectedDateTime = HttpDate.parse(dateHeader);

      mockClient.mockResponse = http.Response(
        '',
        200,
        headers: {'date': dateHeader},
      );

      final result = await provider.getCurrentUtcTime();

      expect(result, isNotNull);
      expect(result, equals(expectedDateTime));
    });

    test('returns null when date header is missing', () async {
      mockClient.mockResponse = http.Response('', 200, headers: {});

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });

    test('returns null when response status is not 200', () async {
      mockClient.mockResponse = http.Response('', 404);

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });

    test('returns null when all servers fail', () async {
      mockClient.mockResponse = http.Response('', 500);

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });

    test('handles timeout exceptions', () async {
      mockClient.shouldThrowTimeout = true;

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });

    test('handles socket exceptions', () async {
      mockClient.shouldThrowSocketException = true;

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });

    test('handles format exceptions with invalid date', () async {
      mockClient.mockResponse = http.Response(
        '',
        200,
        headers: {'date': 'invalid-date-format'},
      );

      final result = await provider.getCurrentUtcTime();

      expect(result, isNull);
    });
  });
}

/// Simple mock HTTP client for testing
class MockClient extends http.BaseClient {
  http.Response mockResponse = http.Response('', 200);
  bool shouldThrowTimeout = false;
  bool shouldThrowSocketException = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (shouldThrowTimeout) {
      throw TimeoutException('Timeout');
    }

    if (shouldThrowSocketException) {
      throw const SocketException('Socket error');
    }

    return http.StreamedResponse(
      Stream.value(mockResponse.bodyBytes),
      mockResponse.statusCode,
      headers: mockResponse.headers,
    );
  }
}
