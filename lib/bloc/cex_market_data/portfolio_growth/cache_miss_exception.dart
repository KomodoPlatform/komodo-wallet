/// Exception thrown when a cache miss occurs in the portfolio growth repository.
class CacheMissException implements Exception {
  /// Creates a new [CacheMissException] with the provided cache key.
  const CacheMissException(this.cacheKey);

  /// The cache key that was not found.
  final String cacheKey;

  @override
  String toString() => 'Cache miss for key: $cacheKey';
}
