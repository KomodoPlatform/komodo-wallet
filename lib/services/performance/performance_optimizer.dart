import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._();
  static PerformanceOptimizer get instance => _instance;

  PerformanceOptimizer._();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, DateTime> _lastOperationTimes = {};
  final Map<String, dynamic> _cache = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  // Debounce configuration
  static const Duration _defaultDebounceTime = Duration(milliseconds: 300);
  static const Duration _defaultThrottleTime = Duration(milliseconds: 1000);

  /// Creates a debounced timer that only executes after the specified delay
  /// has passed without any new calls
  Timer createDebouncedTimer(
    String name,
    VoidCallback callback, {
    Duration debounceTime = _defaultDebounceTime,
  }) {
    _activeTimers[name]?.cancel();
    
    final timer = Timer(debounceTime, () {
      performance.trackTimer(name);
      callback();
      _activeTimers.remove(name);
    });
    
    _activeTimers[name] = timer;
    return timer;
  }

  /// Creates a throttled timer that executes at most once per specified interval
  Timer createThrottledTimer(
    String name,
    VoidCallback callback, {
    Duration throttleTime = _defaultThrottleTime,
  }) {
    final now = DateTime.now();
    final lastTime = _lastOperationTimes[name];
    
    if (lastTime != null && now.difference(lastTime) < throttleTime) {
      return Timer.periodic(throttleTime, (_) {
        performance.trackTimer(name);
        callback();
        _lastOperationTimes[name] = DateTime.now();
      });
    }
    
    _lastOperationTimes[name] = now;
    performance.trackTimer(name);
    callback();
    
    return Timer.periodic(throttleTime, (_) {
      performance.trackTimer(name);
      callback();
      _lastOperationTimes[name] = DateTime.now();
    });
  }

  /// Smart caching with TTL (Time To Live)
  T? getCached<T>(String key, {Duration? ttl}) {
    final cacheEntry = _cache[key];
    if (cacheEntry == null) {
      _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
      performance.trackCacheMiss();
      return null;
    }

    if (cacheEntry is _CacheEntry<T>) {
      if (ttl != null && DateTime.now().difference(cacheEntry.timestamp) > ttl) {
        _cache.remove(key);
        _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
        performance.trackCacheMiss();
        return null;
      }
      
      _cacheHits[key] = (_cacheHits[key] ?? 0) + 1;
      performance.trackCacheHit();
      return cacheEntry.value;
    }
    
    return null;
  }

  void setCached<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry<T>(
      value: value,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Batch operations to reduce individual calls
  Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int maxConcurrent = 3,
  }) async {
    final results = <T>[];
    final queue = Queue<Future<T> Function()>.from(operations);
    final active = <Future<T>>[];

    while (queue.isNotEmpty || active.isNotEmpty) {
      // Start new operations if we have capacity
      while (active.length < maxConcurrent && queue.isNotEmpty) {
        final operation = queue.removeFirst();
        active.add(operation());
      }

      // Wait for at least one operation to complete
      if (active.isNotEmpty) {
        final completed = await Future.any(active);
        active.removeWhere((future) => future == completed);
        results.add(await completed);
      }
    }

    return results;
  }

  /// Memory management
  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  void cancelAllTimers() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void cancelTimer(String name) {
    _activeTimers[name]?.cancel();
    _activeTimers.remove(name);
  }

  /// Performance metrics
  Map<String, dynamic> getMetrics() {
    return {
      'activeTimers': _activeTimers.length,
      'cacheSize': _cache.length,
      'cacheHits': _cacheHits.values.fold(0, (sum, hits) => sum + hits),
      'cacheMisses': _cacheMisses.values.fold(0, (sum, misses) => sum + misses),
    };
  }

  void dispose() {
    cancelAllTimers();
    clearCache();
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  final Duration? ttl;

  _CacheEntry({
    required this.value,
    required this.timestamp,
    this.ttl,
  });
}