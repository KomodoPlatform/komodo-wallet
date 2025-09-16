// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_dex/app_config/app_config.dart';

PerformanceAnalytics get performance => PerformanceAnalytics._instance;

class PerformanceAnalytics {
  PerformanceAnalytics._();

  static final PerformanceAnalytics _instance = PerformanceAnalytics._();

  Timer? _summaryTimer;

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
    _summaryTimer = Timer.periodic(kPerformanceLogInterval, (timer) {
      final summary = _metricsSummary();
      print(summary);
    });
  }

  String _metricsSummary() {
    final summary = StringBuffer();
    summary.writeln('=-' * 20);

    summary.writeln('Performance summary:');
    // summary.writeln('  - Total time spent writing logs: $_totalLogTime');
    summary.writeln('  - Total log events: $_logEventsCount');
    // summary.writeln(
    //   '  - Average time spent writing logs: '
    //   '${_totalLogTime.inMilliseconds ~/ _logEventsCount}ms',
    // );
    summary.writeln('=-' * 20);

    return summary.toString();
  }

  // Duration get _totalLogTime => Duration(
  //       milliseconds: _totalMillisecondsWaitingOnLogs,
  //     );

  // int _totalMillisecondsWaitingOnLogs = 0;
  int _logEventsCount = 0;

  void logTimeWritingLogs(int milliSeconds) {
    if (!_isInitialized) return;

    if (milliSeconds < 0) {
      throw Exception('Log execution time milliSeconds must be >= 0');
    }

    // _totalMillisecondsWaitingOnLogs += milliSeconds;
    _logEventsCount++;
  }

  static void stop() {
    _instance._summaryTimer?.cancel();
    _instance._summaryTimer = null;

    print('PerformanceAnalytics stopped');
  }
}
