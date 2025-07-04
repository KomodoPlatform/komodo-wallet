// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../common/widget_tester_action_extensions.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testFiatFormInputs(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Starting fiat form test');
  final Finder fiatFinder = find.byKey(const Key('main-menu-fiat'));

  await tester.tap(fiatFinder);
  print('🔍 FIAT FORM TEST: Tapped fiat menu item');
  // wait for fiat form to load fiat currencies, coin list, and payment methods
  await tester.pumpAndSettle();

  await _testFiatAmountField(tester);
  await _testFiatSelection(tester);
  await _testCoinSelection(tester);
  await _testPaymentMethodSelection(tester);
  await _textSubmit(tester);
}

Future<void> _textSubmit(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Testing form submission');
  final Finder submitFinder =
      find.byKey(const Key('fiat-onramp-submit-button'));
  final Finder webviewFinder = find.byKey(const Key('flutter-in-app-webview'));

  expect(submitFinder, findsOneWidget, reason: 'Submit button not found');
  await tester.tap(submitFinder);
  print('🔍 FIAT FORM TEST: Tapped submit button');
  await tester.pumpAndSettle();
  expect(webviewFinder, findsOneWidget, reason: 'Webview not found');
  print('🔍 FIAT FORM TEST: Verified webview loaded');
}

Future<void> _testFiatAmountField(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Testing fiat amount field');
  final Finder fiatAmountFinder =
      find.byKey(const Key('fiat-amount-form-field'));

  await tester.tapAndPump(fiatAmountFinder);
  await tester.enterText(fiatAmountFinder, '50');
  print('🔍 FIAT FORM TEST: Entered fiat amount: 50');
  await tester.pump();
  await tester.pumpAndSettle(); // wait for payment methods to populate

  await _testPaymentMethodSelection(tester);
}

Future<void> _testFiatSelection(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Testing fiat currency selection');
  final Finder fiatDropdownFinder =
      find.byKey(const Key('fiat-onramp-fiat-dropdown'));
  final Finder usdIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-USD'));
  final Finder eurIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-EUR'));

  await tester.tapAndPump(fiatDropdownFinder);
  expect(usdIconFinder, findsOneWidget, reason: 'USD icon not found');
  expect(eurIconFinder, findsOneWidget, reason: 'EUR icon not found');
  print('🔍 FIAT FORM TEST: Verified USD and EUR options');
  await tester.tapAndPump(eurIconFinder);
  print('🔍 FIAT FORM TEST: Selected EUR');
  await tester.pumpAndSettle(); // wait for payment methods to populate
}

Future<void> _testCoinSelection(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Testing coin selection');
  final Finder coinDropdownFinder =
      find.byKey(const Key('fiat-onramp-coin-dropdown'));
  final Finder btcIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-BTC'));
  final Finder maticIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-LTC'));

  await tester.tapAndPump(coinDropdownFinder);
  expect(btcIconFinder, findsOneWidget, reason: 'BTC icon not found');
  print('🔍 FIAT FORM TEST: Verified BTC option');
  await _tapCurrencyItem(tester, maticIconFinder);
  print('🔍 FIAT FORM TEST: Selected LTC');
  await tester.pumpAndSettle(); // wait for payment methods to populate

  await _testPaymentMethodSelection(tester);
}

Future<void> _tapCurrencyItem(WidgetTester tester, Finder asset) async {
  print('🔍 FIAT FORM TEST: Tapping currency item');
  final Finder list = find.byKey(const Key('fiat-onramp-currency-list'));
  final Finder dialog = find.byKey(const Key('fiat-onramp-currency-dialog'));

  expect(
    dialog,
    findsOneWidget,
    reason: 'Fiat onramp currency dialog not found',
  );
  expect(list, findsOneWidget, reason: 'Fiat onramp currency list not found');
  print('🔍 FIAT FORM TEST: Verified currency dialog and list');
  await tester.dragUntilVisible(asset, list, const Offset(0, -50));
  await tester.pumpAndSettle();
  await tester.tapAndPump(asset);
}

Future<void> _testPaymentMethodSelection(WidgetTester tester) async {
  print('🔍 FIAT FORM TEST: Testing payment method selection');
  final Finder rampPaymentMethodFinder =
      find.byKey(const Key('fiat-payment-method-ramp-0'));
  final Finder banxaPaymentMethodFinder =
      find.byKey(const Key('fiat-payment-method-banxa-0'));

  expect(
    rampPaymentMethodFinder,
    findsOneWidget,
    reason: 'Ramp payment method not found',
  );
  expect(
    banxaPaymentMethodFinder,
    findsOneWidget,
    reason: 'Banxa payment method not found',
  );
  print('🔍 FIAT FORM TEST: Verified Ramp and Banxa payment methods');

  await tester.tapAndPump(rampPaymentMethodFinder);
  print('🔍 FIAT FORM TEST: Selected Ramp payment method');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run fiat form tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testFiatFormInputs(tester);

      print('END fiat form TESTS');
    },
    semanticsEnabled: false,
  );
}
