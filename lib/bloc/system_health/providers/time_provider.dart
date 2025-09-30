/// Base interface for all time providers
abstract class TimeProvider {
  /// Returns the current UTC time from an external source
  Future<DateTime> getCurrentUtcTime();

  /// Returns a descriptive name for the provider
  String get name;

  /// Dispose of any resources used by the provider
  void dispose() {
    // Default implementation does nothing
  }
}
