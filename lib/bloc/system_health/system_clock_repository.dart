import 'package:logging/logging.dart';
import 'package:komodo_wallet/bloc/system_health/providers/time_provider_registry.dart';

class SystemClockRepository {
  SystemClockRepository({
    TimeProviderRegistry? providerRegistry,
    Duration? maxAllowedDifference,
    Duration? apiTimeout,
    Logger? logger,
  })  : _maxAllowedDifference =
            maxAllowedDifference ?? const Duration(seconds: 60),
        _providerRegistry = providerRegistry ??
            TimeProviderRegistry(
              apiTimeout: apiTimeout,
            ),
        _logger = logger ?? Logger('SystemClockRepository');

  final Duration _maxAllowedDifference;
  final TimeProviderRegistry _providerRegistry;
  final Logger _logger;

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
          receivedValidResponse = true;

          final localTime = DateTime.timestamp();
          final Duration difference = apiTime.difference(localTime).abs();

          final isValid = difference < _maxAllowedDifference;
          if (isValid) {
            _logger.info('System clock validated by ${provider.name} provider');
          } else {
            _logger.warning(
                'System clock differs by ${difference.inSeconds}s from '
                '${provider.name} provider');
          }

          return isValid;
        } on Exception catch (e, s) {
          _logger.severe('Provider ${provider.name} failed', e, s);
        }
      }

      if (!receivedValidResponse) {
        _logger.warning('All time providers failed to provide a time');
      }

      // Default to allowing usage when no provider responded
      return true;
    } on Exception catch (e, s) {
      _logger.shout('Failed to validate system clock', e, s);
      // Don't block usage of dex if the time provider fetch fails
      return true;
    }
  }

  void dispose() {
    _providerRegistry.dispose();
  }
}
