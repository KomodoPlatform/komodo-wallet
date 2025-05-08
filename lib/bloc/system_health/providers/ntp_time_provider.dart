import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:ntp/ntp.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider.dart';

/// A time provider that fetches accurate time from NTP servers
class NtpTimeProvider extends TimeProvider {
  NtpTimeProvider({
    this.ntpServers = const [
      'pool.ntp.org',
      'time.google.com',
      'time.cloudflare.com',
      'time.apple.com',
    ],
    this.lookupTimeout = const Duration(seconds: 1),
    this.maxRetries = 3,
    Logger? logger,
  }) : _logger = logger ?? Logger('NtpTimeProvider');

  /// The name of the provider (for logging and identification)
  final Logger _logger;

  /// List of NTP servers to query
  final List<String> ntpServers;

  /// Timeout for NTP lookup
  final Duration lookupTimeout;

  /// Maximum number of retries per server
  final int maxRetries;

  @override
  String get name => 'NTP';

  @override
  Future<DateTime> getCurrentUtcTime() async {
    for (final server in ntpServers) {
      DateTime? time;
      int retries = 0;

      while (time == null && retries < maxRetries) {
        try {
          final localNow = DateTime.now();
          final int offset = await NTP.getNtpOffset(
            localTime: localNow,
            lookUpAddress: server,
            timeout: lookupTimeout,
          );

          time = localNow.add(Duration(milliseconds: offset));
          final utcTime = time.toUtc();

          _logger.fine('Successfully retrieved time from $server');
          return utcTime;
        } on SocketException catch (e) {
          _logger.warning('Socket error with $server: ${e.message}');
          retries++;
        } on TimeoutException catch (e) {
          _logger.warning('Timeout with $server: ${e.message}');
          retries++;
        } on Exception catch (e) {
          _logger.severe('Error with $server: $e');
          retries++;
        }
      }
    }

    _logger.severe(
      'Failed to get time from any NTP server after $maxRetries retries',
    );
    throw TimeoutException(
      'Failed to get time from any NTP server after $maxRetries retries',
    );
  }
}
