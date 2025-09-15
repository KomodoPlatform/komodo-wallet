import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterPumpExtension on WidgetTester {
  Future<void> pumpNFrames(
    int frames, {
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    for (int i = 0; i < frames; i++) {
      await pump();
      await Future<void>.delayed(delay);
    }
  }

  Future<void> pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 60),
    bool throwOnError = true,
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await pumpAndSettle();

      if (any(finder)) {
        return;
      }
    }

    if (!throwOnError) {
      return;
    }

    String finderDescription = '';
    try {
      finderDescription = 'Finder: $finder';
      final Widget finderWidget = widget(finder);
      finderDescription += ', Widget: $finderWidget';
    } catch (e) {
      finderDescription += ', unable to retrieve widget information';
    }

    throw TimeoutException('pumpUntilVisible timed out: $finderDescription');
  }

  Future<void> pumpUntilDisappear(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    bool timerDone = false;
    final timer = Timer(
      timeout,
      () => throw TimeoutException('Pump until has timed out'),
    );
    while (timerDone != true) {
      await pumpAndSettle();

      final found = any(finder);
      if (!found) {
        timerDone = true;
      }
    }
    timer.cancel();
  }
}
