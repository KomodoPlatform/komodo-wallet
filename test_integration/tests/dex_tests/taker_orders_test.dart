// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;
import 'package:komodo_wallet/shared/widgets/copied_text.dart';
import 'package:komodo_wallet/views/dex/entities_list/history/history_item.dart';

import '../../common/pause.dart';
import '../../common/widget_tester_action_extensions.dart';
import '../../common/widget_tester_pump_extension.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testTakerOrder(WidgetTester tester) async {
  print('🔍 TAKER ORDER: Starting taker order test');

  final String sellCoin = Random().nextDouble() > 0.5 ? 'DOC' : 'MARTY';
  const String sellAmount = '0.01';
  final String buyCoin = sellCoin == 'DOC' ? 'MARTY' : 'DOC';
  print('🔍 TAKER ORDER: Selected sell coin: $sellCoin, buy coin: $buyCoin');

  await _openTakerOrderForm(tester);
  await _selectSellCoin(tester, sellAmount: sellAmount, sellCoin: sellCoin);
  await _selectBuyCoin(tester, buyCoin: buyCoin);
  await _createTakerOrder(tester);
  print('🔍 TAKER ORDER: Form completed and order submitted');

  print('🔍 TAKER ORDER: Waiting for swap completion (max 15 minutes)');
  await tester.pumpAndSettle().timeout(
    const Duration(minutes: 15),
    onTimeout: () {
      print('❌ TAKER ORDER: Swap timeout - exceeded 15 minutes');
      throw Exception(
          'Test error: DOC->MARTY taker Swap took more than 15 minutes');
    },
  );

  await _expectSwapSuccess(tester);
  print('🔍 TAKER ORDER: Swap completed successfully');

  await _testSwapHistoryTable(tester);
  print('🔍 TAKER ORDER: History verification completed');
}

Finder _infiniteBidFinder() {
  print('🔍 INFINITE BID: Searching for infinite bid volume');
  const String infiniteBidVolume = '2.00';
  final bidsTable = find.byKey(const Key('orderbook-bids-list'));
  bool infiniteBidPredicate(Widget widget) {
    if (widget is Text) {
      return widget.data?.contains(infiniteBidVolume) ?? false;
    }
    return false;
  }

  final infiniteBids = find.descendant(
    of: bidsTable,
    matching: find.byWidgetPredicate(infiniteBidPredicate),
  );
  print('🔍 INFINITE BID: Bid search completed');
  return infiniteBids;
}

Future<void> _testSwapHistoryTable(
  WidgetTester tester, {
  Duration timeout = const Duration(milliseconds: 5000),
}) async {
  print('🔍 HISTORY CHECK: Starting history table verification');

  final Finder backButton = find.byKey(const Key('return-button'));
  final Finder historyTab = find.byKey(const Key('dex-history-tab'));

  await tester.tapAndPump(backButton);
  print('🔍 HISTORY CHECK: Returned to previous screen');

  await tester.tapAndPump(historyTab);
  print('🔍 HISTORY CHECK: Opened history tab');

  await tester.pump(timeout);
  expect(find.byType(HistoryItem), findsOneWidget,
      reason: 'Test error: Swap history item not found');
  print('🔍 HISTORY CHECK: Found history item successfully');
}

Future<void> _expectSwapSuccess(WidgetTester tester) async {
  print('🔍 SWAP VERIFY: Starting swap verification process');

  final Finder tradingDetailsScrollable = find.byType(Scrollable);
  final Finder takerFeeSentEventStep =
      find.byKey(const Key('swap-details-step-TakerFeeSent'));
  final Finder makerPaymentReceivedEventStep =
      find.byKey(const Key('swap-details-step-MakerPaymentReceived'));
  final Finder takerPaymentSentEventStep =
      find.byKey(const Key('swap-details-step-TakerPaymentSent'));
  final Finder takerPaymentSpentEventStep =
      find.byKey(const Key('swap-details-step-TakerPaymentSpent'));
  final Finder makerPaymentSpentEventStep =
      find.byKey(const Key('swap-details-step-MakerPaymentSpent'));
  final Finder swapSuccess = find.byKey(const Key('swap-status-success'));
  final Finder backButton = find.byKey(const Key('return-button'));

  expect(swapSuccess, findsOneWidget);
  print('🔍 SWAP VERIFY: Found success status');

  expect(
      find.descendant(
          of: takerFeeSentEventStep, matching: find.byType(CopiedText)),
      findsOneWidget);
  print('🔍 SWAP VERIFY: Taker fee sent verified');

  expect(
      find.descendant(
          of: makerPaymentReceivedEventStep, matching: find.byType(CopiedText)),
      findsOneWidget);
  print('🔍 SWAP VERIFY: Maker payment received verified');

  await tester.dragUntilVisible(takerPaymentSentEventStep,
      tradingDetailsScrollable, const Offset(0, -10));
  print('🔍 SWAP VERIFY: Scrolled to taker payment sent');
  expect(
    find.descendant(
        of: takerPaymentSentEventStep, matching: find.byType(CopiedText)),
    findsOneWidget,
  );

  await tester.dragUntilVisible(takerPaymentSpentEventStep,
      tradingDetailsScrollable, const Offset(0, -10));
  expect(
    find.descendant(
        of: takerPaymentSpentEventStep, matching: find.byType(CopiedText)),
    findsOneWidget,
  );

  await tester.dragUntilVisible(makerPaymentSpentEventStep,
      tradingDetailsScrollable, const Offset(0, -10));
  expect(
    find.descendant(
        of: makerPaymentSpentEventStep, matching: find.byType(CopiedText)),
    findsOneWidget,
  );

  await tester.dragUntilVisible(
      backButton, tradingDetailsScrollable, const Offset(0, 10));
  print('🔍 SWAP VERIFY: All swap steps verified successfully');
}

Future<void> _createTakerOrder(WidgetTester tester) async {
  print('🔍 CREATE ORDER: Starting order creation');

  final Finder takeOrderButton = find.byKey(const Key('take-order-button'));
  final Finder takeOrderConfirmButton =
      find.byKey(const Key('take-order-confirm-button'));

  await tester.dragUntilVisible(takeOrderButton,
      find.byKey(const Key('taker-form-layout-scroll')), const Offset(0, -150));
  print('🔍 CREATE ORDER: Scrolled to take order button');
  await tester.waitForButtonEnabled(
    takeOrderButton,
    // system health check runs on a 30-second timer, so allow for multiple
    // checks until the button is visible
    timeout: const Duration(seconds: 90),
  );
  await tester.tapAndPump(takeOrderButton);
  print('🔍 CREATE ORDER: Tapped take order button');
  // wait for confirm button loader and page switch
  await tester.pumpAndSettle();
  await pause(sec: 2);

  await tester.dragUntilVisible(
      takeOrderConfirmButton,
      find.byKey(const Key('taker-order-confirmation-scroll')),
      const Offset(0, -150));
  print('🔍 CREATE ORDER: Scrolled to confirm button');
  await tester.tapAndPump(takeOrderConfirmButton);
  print('🔍 CREATE ORDER: Order confirmed');
}

Future<void> _openTakerOrderForm(WidgetTester tester) async {
  print('🔍 OPEN FORM: Navigating to taker order form');

  final Finder dexSectionButton = find.byKey(const Key('main-menu-dex'));
  final Finder dexSectionSwapTab = find.byKey(const Key('dex-swap-tab'));

  await tester.tap(dexSectionButton);
  print('🔍 OPEN FORM: Opened DEX section');
  await tester.pumpAndSettle();

  await tester.tap(dexSectionSwapTab);
  print('🔍 OPEN FORM: Opened swap tab');
  await tester.pumpAndSettle();
}

Future<void> _selectSellCoin(
  WidgetTester tester, {
  required String sellCoin,
  required String sellAmount,
}) async {
  print('🔍 SELL CONFIG: Setting up sell parameters');
  final Finder sellCoinSelectButton =
      find.byKey(const Key('taker-form-sell-switcher'));
  final Finder sellCoinSearchField = find.descendant(
    of: find.byKey(const Key('taker-sell-coins-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder sellCoinItem = find.byKey(Key('Coin-table-item-$sellCoin'));
  final Finder sellAmountField = find.descendant(
    of: find.byKey(const Key('taker-sell-amount')),
    matching: find.byKey(const Key('amount-input')),
  );

  await tester.tapAndPump(sellCoinSelectButton);
  print('🔍 SELL CONFIG: Opened coin selector');

  await tester.enterText(sellCoinSearchField, sellCoin);
  print('🔍 SELL CONFIG: Entered search text: $sellCoin');
  await tester.pumpNFrames(10);

  await tester.tapAndPump(sellCoinItem);
  print('🔍 SELL CONFIG: Selected coin');

  await tester.enterText(sellAmountField, sellAmount);
  print('🔍 SELL CONFIG: Entered amount: $sellAmount');
  await tester.pumpNFrames(10);
}

Future<void> _selectBuyCoin(WidgetTester tester,
    {required String buyCoin}) async {
  print('🔍 BUY CONFIG: Setting up buy parameters');

  final Finder buyCoinSelectButton =
      find.byKey(const Key('taker-form-buy-switcher'));
  final Finder buyCoinSearchField = find.descendant(
    of: find.byKey(const Key('taker-orders-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder buyCoinItem = find.byKey(Key('BestOrder-table-item-$buyCoin'));
  final Finder infiniteBids = _infiniteBidFinder();

  await tester.tapAndPump(buyCoinSelectButton);
  print('🔍 BUY CONFIG: Opened coin selector');

  await tester.enterText(buyCoinSearchField, buyCoin);
  print('🔍 BUY CONFIG: Entered search text: $buyCoin');
  await tester.pumpNFrames(10);

  await tester.tapAndPump(buyCoinItem);
  print('🔍 BUY CONFIG: Selected coin');

  await pause();

  if (infiniteBids.evaluate().isNotEmpty) {
    print('🔍 BUY CONFIG: Found infinite bid, selecting it');
    await tester.tapAndPump(infiniteBids.first);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run taker order tests:', (WidgetTester tester) async {
    print('🔍 MAIN: Starting taker order test suite');
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();

    print('🔍 MAIN: Accepting alpha warning');
    await acceptAlphaWarning(tester);

    await restoreWalletToTest(tester);
    print('🔍 MAIN: Wallet restored');
    await tester.pumpAndSettle();

    await testTakerOrder(tester);
    print('🔍 MAIN: Taker order test completed successfully');
  }, semanticsEnabled: false);
}
