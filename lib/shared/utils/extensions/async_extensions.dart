// Extension to wait all futures in a list

extension WaitAllFutures<T> on List<Future<T>> {
  /// Wait all futures in a list.
  ///
  /// See Dart docs on error handling in lists of futures: [Future.wait]
  Future<List<T>> awaitAll() => Future.wait<T>(this);
}
