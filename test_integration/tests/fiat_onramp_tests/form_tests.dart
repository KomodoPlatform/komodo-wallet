// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/pump_and_settle.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testFiatFormInputs(WidgetTester tester) async {
  final Finder fiatFinder = find.byKey(const Key('main-menu-fiat'));

  await tester.tap(fiatFinder);
  // wait for fiat form to load fiat currencies, coin list, and payment methods
  await tester.pumpAndSettle();

  await _testFiatAmountField(tester);
  await _testFiatSelection(tester);
  await _testCoinSelection(tester);
  await _testPaymentMethodSelection(tester);
  await _textSubmit(tester);
}

Future<void> _textSubmit(WidgetTester tester) async {
  final Finder submitFinder =
      find.byKey(const Key('fiat-onramp-submit-button'));
  final Finder webviewFinder = find.byKey(const Key('flutter-in-app-webview'));

  expect(submitFinder, findsOneWidget, reason: 'Submit button not found');
  await tester.tap(submitFinder);
  await tester.pumpAndSettle();
  expect(webviewFinder, findsOneWidget, reason: 'Webview not found');
}

Future<void> _testFiatAmountField(WidgetTester tester) async {
  final Finder fiatAmountFinder =
      find.byKey(const Key('fiat-amount-form-field'));

  await tester.tap(fiatAmountFinder);
  await tester.pump();
  await tester.enterText(fiatAmountFinder, '50');
  await tester.pump();
  await tester.pumpAndSettle(); // wait for payment methods to populate

  await _testPaymentMethodSelection(tester);
}

Future<void> _testFiatSelection(WidgetTester tester) async {
  final Finder fiatDropdownFinder =
      find.byKey(const Key('fiat-onramp-fiat-dropdown'));
  final Finder usdIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-USD'));
  final Finder eurIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-EUR'));

  await tester.tap(fiatDropdownFinder);
  await tester.pumpNFrames(10);
  expect(usdIconFinder, findsOneWidget, reason: 'USD icon not found');
  expect(eurIconFinder, findsOneWidget, reason: 'EUR icon not found');
  await tester.tap(eurIconFinder);
  await tester.pump();
  await tester.pumpAndSettle(); // wait for payment methods to populate
}

Future<void> _testCoinSelection(WidgetTester tester) async {
  final Finder coinDropdownFinder =
      find.byKey(const Key('fiat-onramp-coin-dropdown'));
  final Finder btcIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-BTC'));
  final Finder maticIconFinder =
      find.byKey(const Key('fiat-onramp-currency-item-LTC'));

  await tester.tap(coinDropdownFinder);
  await tester.pumpAndSettle();
  expect(btcIconFinder, findsOneWidget, reason: 'BTC icon not found');
  await _tapCurrencyItem(tester, maticIconFinder);
  await tester.pump();
  await tester.pumpAndSettle(); // wait for payment methods to populate

  await _testPaymentMethodSelection(tester);
}

Future<void> _tapCurrencyItem(WidgetTester tester, Finder asset) async {
  final Finder list = find.byKey(const Key('fiat-onramp-currency-list'));
  final Finder dialog = find.byKey(const Key('fiat-onramp-currency-dialog'));

  expect(
    dialog,
    findsOneWidget,
    reason: 'Fiat onramp currency dialog not found',
  );
  expect(list, findsOneWidget, reason: 'Fiat onramp currency list not found');
  await tester.dragUntilVisible(asset, list, const Offset(0, -50));
  await tester.pumpAndSettle();
  await tester.tap(asset);
}

Future<void> _testPaymentMethodSelection(WidgetTester tester) async {
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

  await tester.tap(rampPaymentMethodFinder);
  await tester.pump();
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
