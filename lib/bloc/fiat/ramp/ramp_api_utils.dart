import 'package:logging/logging.dart';

/// Utility for validating Ramp API responses.
class RampApiUtils {
  static final Logger _log = Logger('RampApiUtils');

  /// Validates [response] for standard Ramp API errors and ensures it is of
  /// the expected type [T].
  ///
  /// Throws a [FormatException] if the response indicates a validation error
  /// or if it is not of type [T].
  static T validateResponse<T>(dynamic response, {String? context}) {
    if (response is Map<String, dynamic>) {
      final name = response['name'];
      final status = response['status'];
      if (name == 'ValidationException' || status == 400) {
        final message = response['response'] ?? response['message'];
        throw FormatException('Ramp validation error: $message');
      }
    }

    if (response is! T) {
      _log.warning(
          'Unexpected response${context != null ? ' for $context' : ''}: $response');
      final contextInfo = context != null ? ' for $context' : '';
      throw FormatException('Unexpected response type$contextInfo from Ramp');
    }
    return response;
  }
}
