// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Activate/deactivate [coins],
/// depending on which coins manager view
/// is currently open (Add assets or Remove assets)
Future<void> switchCoinsActiveState(
  WidgetTester tester,
  List<String> coins,
) async {
  await tester.pumpAndSettle();

  final Finder searchCoinsField =
      find.byKey(const Key('coins-manager-search-field'));

  for (String coin in coins) {
    final List<String> coinData = coin.split(':');
    final String abbr = coinData.first;
    final String searchTerms = coinData.last;

    print('Test: trying to find and select $abbr in coins manager.');

    await tester.enterText(searchCoinsField, searchTerms);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    final Finder inactiveCoinItem =
        find.byKey(Key('coins-manager-list-item-${abbr.toLowerCase()}'));
    expect(
      inactiveCoinItem,
      findsOneWidget,
      reason:
          'Test error: searching coins manager for $abbr, but nothing found',
    );
    await tester.tap(inactiveCoinItem);
    await tester.pumpAndSettle();
  }

  await tester.pumpAndSettle(const Duration(milliseconds: 250));

  final Finder switchButton =
      find.byKey(const Key('back-button'));
  await tester.tap(switchButton);
  await tester.pumpAndSettle();
}
