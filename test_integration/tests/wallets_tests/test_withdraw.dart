// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;
import 'package:web_dex/shared/widgets/auto_scroll_text.dart';

import '../../common/pause.dart';
import '../../common/pump_and_settle.dart';
import '../../common/tester_utils.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/get_funded_wif.dart';
import '../../helpers/restore_wallet.dart';
import 'wallet_tools.dart';

Future<void> testWithdraw(WidgetTester tester) async {
  print('TEST WITHDRAW');

  final Finder martyCoinItem = find.byKey(
    const Key('coins-manager-list-item-marty'),
  );
  final Finder martyCoinActive = find.byKey(
    const Key('active-coin-item-marty'),
  );
  final Finder coinBalance = find.byKey(
    const Key('coin-details-balance'),
  );
  final Finder sendButton = find.byKey(
    const Key('coin-details-send-button'),
  );
  final Finder addressInput = find.byKey(
    const Key('withdraw-recipient-address-input'),
  );
  final Finder amountInput = find.byKey(
    const Key('enter-form-amount-input'),
  );
  final Finder sendEnterButton = find.byKey(
    const Key('send-enter-button'),
  );
  final Finder confirmBackButton = find.byKey(
    const Key('confirm-back-button'),
  );
  final Finder confirmAgreeButton = find.byKey(
    const Key('confirm-agree-button'),
  );
  final Finder completeButtons = find.byKey(
    const Key('complete-buttons'),
  );
  final Finder viewOnExplorerButton = find.byKey(
    const Key('send-complete-view-on-explorer'),
  );
  final Finder doneButton = find.byKey(
    const Key('send-complete-done'),
  );
  final Finder exitButton = find.byKey(
    const Key('back-button'),
  );
  final Finder receiveButton = find.byKey(
    const Key('coin-details-receive-button'),
  );
  final Finder copyAddressButton = find.byKey(
    const Key('coin-details-address-field'),
  );

  await addAsset(tester, asset: martyCoinItem, search: 'marty');
  await pause(sec: 5);
  await tester.pumpNFrames(20);

  expect(martyCoinActive, findsOneWidget);
  await testerTap(tester, martyCoinActive);

  expect(coinBalance, findsOneWidget);

  final AutoScrollText text =
      coinBalance.evaluate().single.widget as AutoScrollText;

  final String priceStr = text.text;
  final double? priceDouble = double.tryParse(priceStr);
  expect(priceDouble != null && priceDouble > 0, true);
  expect(receiveButton, findsOneWidget);

  await testerTap(tester, receiveButton);
  expect(copyAddressButton, findsOneWidget);
  expect(copyAddressButton, findsOneWidget);

  await testerTap(tester, exitButton);
  expect(sendButton, findsOneWidget);

  await testerTap(tester, sendButton);
  expect(addressInput, findsOneWidget);
  expect(amountInput, findsOneWidget);
  expect(sendEnterButton, findsOneWidget);

  await testerTap(tester, addressInput);
  await enterText(tester, finder: addressInput, text: getRandomAddress());
  await testerTap(tester, amountInput);
  await enterText(tester, finder: amountInput, text: '0.01');
  await testerTap(tester, sendEnterButton);
  await tester.pumpAndSettle(); // skip all loading & transition frames

  expect(confirmBackButton, findsOneWidget);
  expect(confirmAgreeButton, findsOneWidget);
  await testerTap(tester, confirmAgreeButton);
  await tester.pumpAndSettle(); // skip all loading & transition frames

  expect(completeButtons, findsOneWidget);
  expect(viewOnExplorerButton, findsOneWidget);
  expect(doneButton, findsOneWidget);
  await testerTap(tester, doneButton);
  await tester.pumpAndSettle(); // skip all loading & transition frames

  expect(exitButton, findsOneWidget);
  await testerTap(tester, exitButton);
  await tester.pumpAndSettle(); // skip all loading & transition frames

  await removeAsset(tester, asset: martyCoinItem, search: 'marty');

  print('END TEST WITHDRAW');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run withdraw tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      print('ACCEPT ALPHA WARNING');
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testWithdraw(tester);
      await tester.pumpAndSettle();

      print('END WITHDARW TESTS');
    },
    semanticsEnabled: false,
  );
}
