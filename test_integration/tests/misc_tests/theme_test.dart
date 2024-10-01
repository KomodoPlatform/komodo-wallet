// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/goto.dart' as goto;
import '../../helpers/accept_alpha_warning.dart';

Future<void> testThemeSwitcher(WidgetTester tester) async {
  final themeSwitcherFinder = find.byKey(const Key('theme-switcher'));
  final themeSettingsSwitcherLight =
      find.byKey(const Key('theme-settings-switcher-Light'));
  final themeSettingsSwitcherDark =
      find.byKey(const Key('theme-settings-switcher-Dark'));

  print(
    'brightness: ${Theme.of(tester.element(themeSwitcherFinder)).brightness}, '
    'expected: ${Brightness.dark}',
  );
  // Check default theme (dark)
  expect(
    Theme.of(tester.element(themeSwitcherFinder)).brightness,
    equals(Brightness.dark),
    reason: 'Default theme should be dark theme',
  );

  // await tester.tap(themeSwitcherFinder);
  // await tester.pumpAndSettle();
  // expect(
  //   Theme.of(tester.element(themeSwitcherFinder)).brightness,
  //   equals(Brightness.light),
  //   reason: 'Current theme should be light theme',
  // );

  await goto.settingsPage(tester);
  await tester.tap(themeSettingsSwitcherDark);
  await tester.pumpAndSettle();
  expect(
    Theme.of(tester.element(themeSwitcherFinder)).brightness,
    equals(Brightness.dark),
    reason: 'Current theme should be dark theme',
  );

  await tester.pumpAndSettle();
  await tester.tap(themeSettingsSwitcherLight);
  await tester.pumpAndSettle();
  expect(
    Theme.of(tester.element(themeSwitcherFinder)).brightness,
    equals(Brightness.light),
    reason: 'Current theme should be light theme',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Run design tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      await acceptAlphaWarning(tester);
      print('ACCEPT ALPHA WARNING');
      await tester.pumpAndSettle();
      await testThemeSwitcher(tester);

      print('END THEME SWITCH TESTS');
    },
    semanticsEnabled: false,
  );
}
