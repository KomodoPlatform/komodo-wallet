// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testFilters(WidgetTester tester) async {
  print('🔍 FILTERS: Starting filters test');

  final Finder walletTab = find.byKey(const Key('main-menu-wallet'));
  final Finder addAssetsButton = find.byKey(const Key('add-assets-button'));
  final coinsManagerList = find.byKey(const Key('coins-manager-list'));
  final Finder filtersButton = find.byKey(const Key('filters-dropdown'));
  final Finder utxoFilterItem = find.byKey(const Key('filter-item-utxo'));
  final Finder erc20FilterItem = find.byKey(const Key('filter-item-erc20'));
  final utxoItems = find.descendant(
    of: coinsManagerList,
    matching: find.text('Native'),
  );
  final bep20Items = find.descendant(
    of: coinsManagerList,
    matching: find.text('BEP-20'),
  );
  final erc20Items = find.descendant(
    of: coinsManagerList,
    matching: find.text('ERC-20'),
  );

  await tester.tap(walletTab);
  print('🔍 FILTERS: Tapped wallet tab');
  await tester.pumpAndSettle();

  await tester.tap(addAssetsButton);
  print('🔍 FILTERS: Tapped add assets button');
  await tester.pumpAndSettle();

  await tester.tap(filtersButton);
  print('🔍 FILTERS: Opened filters dropdown');
  await tester.pumpAndSettle();

  await tester.tap(utxoFilterItem);
  print('🔍 FILTERS: Applied UTXO filter');
  await tester.pumpAndSettle();

  expect(bep20Items, findsNothing);
  expect(erc20Items, findsNothing);
  expect(utxoItems, findsWidgets);
  print('🔍 FILTERS: Verified UTXO filter results');

  await tester.tap(utxoFilterItem);
  print('🔍 FILTERS: Removed UTXO filter');
  await tester.tap(erc20FilterItem);
  print('🔍 FILTERS: Applied ERC20 filter');
  await tester.pumpAndSettle();

  expect(bep20Items, findsNothing);
  expect(utxoItems, findsNothing);
  expect(erc20Items, findsWidgets);
  print('🔍 FILTERS: Verified ERC20 filter results');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run filters tests:', (WidgetTester tester) async {
    print('🔍 MAIN: Starting filters test suite');
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();

    print('🔍 MAIN: Accepting alpha warning');
    await acceptAlphaWarning(tester);

    await restoreWalletToTest(tester);
    print('🔍 MAIN: Wallet restored');

    await testFilters(tester);
    await tester.pumpAndSettle();

    print('🔍 MAIN: Filters tests completed successfully');
  }, semanticsEnabled: false);
}
