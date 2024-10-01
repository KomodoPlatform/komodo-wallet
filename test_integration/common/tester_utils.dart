import 'package:flutter_test/flutter_test.dart';

import 'pause.dart';
import 'pump_and_settle.dart';

Future<void> testerTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpNFrames(10);
  await pause();
}

Future<bool> isWidgetVisible(WidgetTester tester, Finder finder) async {
  try {
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
    return true;
  } catch (e) {
    return false;
  }
}
