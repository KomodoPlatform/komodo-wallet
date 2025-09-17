import 'package:flutter/foundation.dart';
import 'package:web_dex/bloc/system_health/providers/binance_time_provider.dart';
import 'package:web_dex/bloc/system_health/providers/http_head_time_provider.dart';
import 'package:web_dex/bloc/system_health/providers/http_time_provider.dart';
import 'package:web_dex/bloc/system_health/providers/ntp_time_provider.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider.dart';

/// Registry of all available time providers
class TimeProviderRegistry {
  TimeProviderRegistry({List<TimeProvider>? providers, Duration? apiTimeout})
    : _apiTimeout = apiTimeout ?? const Duration(seconds: 2) {
    _providers = providers ?? _createDefaultProviders();
  }

  final Duration _apiTimeout;
  late final List<TimeProvider> _providers;

  /// Returns all registered time providers
  List<TimeProvider> get providers => _providers;

  /// Creates the default time providers
  List<TimeProvider> _createDefaultProviders() {
    return [
      // NTP is not supported on web with the existing flutter packages,
      // so we use HTTP time providers instead via REST APIs that correctly
      // configure the CORS headers to allow all origins
      if (!kIsWeb && !kIsWasm) NtpTimeProvider(),

      // CORS errors on web block head requests to external servers, so HTTP
      // header time providers are not available. We use REST APIs instead.
      if (!kIsWeb && !kIsWasm) HttpHeadTimeProvider(timeout: _apiTimeout),

      // Web fallback to NTP and HTTP head providers before trying the REST APIs
      BinanceTimeProvider(timeout: _apiTimeout),

      // REST APIs that return the current UTC time
      // NOTE: these are prone to change, outages, and rate limits.
      HttpTimeProvider(
        url: 'https://timeapi.io/api/time/current/zone?timeZone=UTC',
        timeFieldPath: 'currentDateTime',
        timeFormat: TimeFormat.iso8601,
        providerName: 'TimeAPI',
        apiTimeout: _apiTimeout,
      ),
      HttpTimeProvider(
        url: 'https://worldtimeapi.org/api/timezone/Etc/UTC',
        timeFieldPath: 'utc_datetime',
        timeFormat: TimeFormat.iso8601,
        providerName: 'WorldTimeAPI',
        apiTimeout: _apiTimeout,
      ),
    ];
  }

  /// Disposes all providers that need cleanup
  /// Necessary for providers that manage resources like sockets or streams
  void dispose() {
    for (final provider in _providers) {
      provider.dispose();
    }
  }
}
