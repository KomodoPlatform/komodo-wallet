import 'dart:async';

/// A utility class that helps to debounce operations by delaying their execution
/// and canceling previous pending operations.
class Debouncer {
  /// Creates a [Debouncer] with the specified [duration].
  Debouncer({this.duration = const Duration(milliseconds: 500)});

  /// The duration to wait before executing the debounced operation.
  final Duration duration;

  Timer? _timer;

  /// Runs the given callback after the specified duration.
  /// If run is called again before the duration has elapsed, the previous
  /// operation is canceled and a new timer is started.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending operations.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
