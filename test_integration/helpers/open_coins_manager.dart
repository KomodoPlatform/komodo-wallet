import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openAddAssetsView(WidgetTester tester) async {
  await tester.pumpAndSettle();

  final Finder addAssetsButton = find.byKey(const Key('add-assets-button'));
  await tester.tap(addAssetsButton);
  await tester.pumpAndSettle();

  final Finder searchCoinsField =
      find.byKey(const Key('coins-manager-search-field'));
  expect(
    searchCoinsField,
    findsOneWidget,
    reason:
        'Test error: \'Add assets\' button pressed, but coins manager didn\'t open',
  );
}

Future<void> openRemoveAssetsView(WidgetTester tester) async {
  await tester.pumpAndSettle();

  final Finder removeAssetsButton =
      find.byKey(const Key('remove-assets-button'));
  await tester.tap(removeAssetsButton);
  await tester.pumpAndSettle();

  final Finder searchCoinsField =
      find.byKey(const Key('coins-manager-search-field'));
  expect(
    searchCoinsField,
    findsOneWidget,
    reason:
        'Test error: \'Remove assets\' button pressed, but coins manager didn\'t open',
  );
}
