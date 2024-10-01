// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/goto.dart' as goto;
import '../../common/pause.dart';
import '../../common/tester_utils.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';
import 'wallet_tools.dart';

Future<void> testCexPrices(WidgetTester tester) async {
  print('TEST CEX PRICES');

  const String docByTicker = 'DOC';
  const String kmdBep20ByTicker = 'KMD';

  final Finder totalAmount = find.byKey(
    const Key('overview-total-balance'),
  );
  final Finder coinDetailsReturnButton = find.byKey(
    const Key('back-button'),
  );
  final Finder kmdBep20CoinActive = find.byKey(
    const Key('active-coin-item-kmd-bep20'),
  );
  final Finder kmdBep20Price = find.byKey(
    const Key('fiat-price-kmd-bep20'),
  );
  final Finder list = find.byKey(
    const Key('wallet-page-coins-list'),
  );
  final Finder page = find.byKey(
    const Key('wallet-page'),
  );
  final Finder kmdBep20Item = find.byKey(
    const Key('coins-manager-list-item-kmd-bep20'),
  );
  final Finder docItem = find.byKey(
    const Key('coins-manager-list-item-doc'),
  );
  final Finder searchCoinsField = find.byKey(
    const Key('wallet-page-search-field'),
  );

  await goto.bridgePage(tester);
  // Enter Wallet View
  await goto.walletPage(tester);
  expect(page, findsOneWidget);
  expect(totalAmount, findsOneWidget);

  await addAsset(tester, asset: docItem, search: docByTicker);
  await addAsset(tester, asset: kmdBep20Item, search: kmdBep20ByTicker);

  try {
    expect(list, findsOneWidget);
  } on TestFailure {
    print('**Error** testCexPrices() list: $list');
  }

  // Check KMD-BEP20 cex price
  final hasKmdBep20 = await filterAsset(
    tester,
    asset: kmdBep20CoinActive,
    text: kmdBep20ByTicker,
    searchField: searchCoinsField,
  );

  if (hasKmdBep20) {
    await testerTap(tester, kmdBep20CoinActive);
    final Text text = kmdBep20Price.evaluate().single.widget as Text;
    final String? priceStr = text.data;
    final double? priceDouble = double.tryParse(priceStr ?? '');
    expect(priceDouble != null && priceDouble > 0, true);
    await testerTap(tester, coinDetailsReturnButton);
  }

  // Check DOC cex price (does not exist)
  // TODO: re-enable this after the doc/marty changes have been decided on
  // await testerTap(tester, docCoinActive);
  // expect(docPrice, findsNothing);

  await goto.walletPage(tester);

  await removeAsset(tester, asset: docItem, search: docByTicker);
  await removeAsset(tester, asset: kmdBep20Item, search: kmdBep20ByTicker);
  await pause(msg: 'END TEST CEX PRICES');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run cex prices tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      print('ACCEPT ALPHA WARNING');
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testCexPrices(tester);
      await tester.pumpAndSettle();

      print('END CEX PRICES TESTS');
    },
    semanticsEnabled: false,
  );
}
