import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/system_health/providers/time_provider_registry.dart';

class SystemClockRepository {
  SystemClockRepository({
    TimeProviderRegistry? providerRegistry,
    http.Client? httpClient,
    Duration? maxAllowedDifference,
    Duration? apiTimeout,
    Logger? logger,
  })  : _maxAllowedDifference =
            maxAllowedDifference ?? const Duration(seconds: 60),
        _httpClient = httpClient ?? http.Client(),
        _providerRegistry = providerRegistry ??
            TimeProviderRegistry(
              httpClient: httpClient,
              apiTimeout: apiTimeout,
            ),
        _logger = logger;

  final Duration _maxAllowedDifference;
  final http.Client _httpClient;
  final TimeProviderRegistry _providerRegistry;
  final Logger? _logger;

  Logger? get logger => _logger;

  /// Queries the available time providers to validate the system clock validity
  /// returning true if the system clock is within allowed difference of the
  /// first provider that responds, false otherwise. Returns true in case of
  /// errors to avoid blocking app usage.
  Future<bool> isSystemClockValid() async {
    try {
      final providers = _providerRegistry.providers;
      bool receivedValidResponse = false;

      for (final provider in providers) {
        try {
          final apiTime = await provider.getCurrentUtcTime();

          if (apiTime != null) {
            receivedValidResponse = true;
            final localTime = DateTime.timestamp();
            final Duration difference = apiTime.difference(localTime).abs();

            final isValid = difference < _maxAllowedDifference;
            if (isValid) {
              await _log('System clock validated by ${provider.name} provider');
            } else {
              await _log(
                  'System clock differs by ${difference.inSeconds}s from '
                  '${provider.name} provider');
            }

            return isValid;
          }
        } on Exception catch (e) {
          await _log('Provider ${provider.name} failed: $e');
        }
      }

      if (!receivedValidResponse) {
        await _log('All time providers failed to provide a time');
      }

      // Default to allowing usage when no provider responded
      return true;
    } on Exception catch (e) {
      await _log('Failed to validate system clock: $e');
      // Don't block usage of dex if the time provider fetch fails
      return true;
    }
  }

  Future<void> _log(String message) async {
    (logger ?? Logger('SystemClockRepository'))
        .info('[SystemClockRepository] $message');
  }

  void dispose() {
    _providerRegistry.dispose();
    _httpClient.close();
  }
}
