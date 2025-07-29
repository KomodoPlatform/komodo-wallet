// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_dex/app_config/app_config.dart';

PerformanceAnalytics get performance => PerformanceAnalytics._instance;

class PerformanceAnalytics {
  PerformanceAnalytics._();

  static final PerformanceAnalytics _instance = PerformanceAnalytics._();

  Timer? _summaryTimer;
  final Map<String, int> _timerCounts = {};
  final Map<String, Duration> _operationDurations = {};
  int _memoryUsage = 0;
  int _totalApiCalls = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  bool get _isInitialized => _summaryTimer != null;

  static void init() {
    if (_instance._isInitialized) {
      throw Exception('PerformanceAnalytics already initialized');
    }
    if (!kDebugMode) return;

    _instance._start();

    print('PerformanceAnalytics initialized');
  }

  void _start() {
    _summaryTimer = Timer.periodic(
      kPerformanceLogInterval,
      (timer) {
        final summary = _metricsSummary();
        print(summary);
      },
    );
  }

  String _metricsSummary() {
    final summary = StringBuffer();
    summary.writeln('=-' * 20);

    summary.writeln('Performance summary:');
    summary.writeln('  - Total log events: $_logEventsCount');
    summary.writeln('  - Active timers: ${_timerCounts.length}');
    summary.writeln('  - Total API calls: $_totalApiCalls');
    summary.writeln('  - Cache hit rate: ${_cacheHits > 0 ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1) : 0}%');
    summary.writeln('  - Memory usage: ${(_memoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');
    
    if (_timerCounts.isNotEmpty) {
      summary.writeln('  - Timer breakdown:');
      _timerCounts.forEach((name, count) {
        summary.writeln('    * $name: $count');
      });
    }
    
    summary.writeln('=-' * 20);

    return summary.toString();
  }

  int _logEventsCount = 0;

  void logTimeWritingLogs(int milliSeconds) {
    if (!_isInitialized) return;

    if (milliSeconds < 0) {
      throw Exception('Log execution time milliSeconds must be >= 0');
    }

    _logEventsCount++;
  }

  void trackTimer(String name) {
    _timerCounts[name] = (_timerCounts[name] ?? 0) + 1;
  }

  void trackOperation(String name, Duration duration) {
    _operationDurations[name] = duration;
  }

  void trackApiCall() {
    _totalApiCalls++;
  }

  void trackCacheHit() {
    _cacheHits++;
  }

  void trackCacheMiss() {
    _cacheMisses++;
  }

  void updateMemoryUsage(int bytes) {
    _memoryUsage = bytes;
  }

  static void stop() {
    _instance._summaryTimer?.cancel();
    _instance._summaryTimer = null;

    print('PerformanceAnalytics stopped');
  }
}
