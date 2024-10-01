// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;
import 'package:web_dex/shared/widgets/copied_text.dart';
import 'package:web_dex/views/dex/entities_list/history/history_item.dart';

import '../../common/pause.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testTakerOrder(WidgetTester tester) async {
  final String sellCoin = Random().nextDouble() > 0.5 ? 'DOC' : 'MARTY';
  const String sellAmount = '0.01';
  final String buyCoin = sellCoin == 'DOC' ? 'MARTY' : 'DOC';

  final Finder dexSectionButton = find.byKey(const Key('main-menu-dex'));
  final Finder dexSectionSwapTab = find.byKey(const Key('dex-swap-tab'));
  final Finder sellCoinSelectButton = find.byKey(
    const Key('taker-form-sell-switcher'),
  );
  final Finder sellCoinSearchField = find.descendant(
    of: find.byKey(const Key('taker-sell-coins-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder sellCoinItem = find.byKey(Key('Coin-table-item-$sellCoin'));
  final Finder sellAmountField = find.descendant(
    of: find.byKey(const Key('taker-sell-amount')),
    matching: find.byKey(const Key('amount-input')),
  );
  final Finder buyCoinSelectButton =
      find.byKey(const Key('taker-form-buy-switcher'));
  final Finder buyCoinSearchField = find.descendant(
    of: find.byKey(const Key('taker-orders-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder buyCoinItem = find.byKey(Key('BestOrder-table-item-$buyCoin'));

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

  final Finder takeOrderButton = find.byKey(const Key('take-order-button'));
  final Finder takeOrderConfirmButton =
      find.byKey(const Key('take-order-confirm-button'));
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
  final Finder historyTab = find.byKey(const Key('dex-history-tab'));

  // Open taker order form
  await tester.tap(dexSectionButton);
  await tester.pumpAndSettle();
  await tester.tap(dexSectionSwapTab);
  await tester.pumpAndSettle();

  // Select sell coin, enter sell amount
  await tester.tap(sellCoinSelectButton);
  await tester.pumpAndSettle();
  await tester.enterText(sellCoinSearchField, sellCoin);
  await tester.pumpAndSettle();
  await tester.tap(sellCoinItem);
  await tester.pumpAndSettle();
  await tester.enterText(sellAmountField, sellAmount);
  await tester.pumpAndSettle();

  // Select buy coin
  await tester.tap(buyCoinSelectButton);
  await tester.pumpAndSettle();
  await tester.enterText(buyCoinSearchField, buyCoin);
  await tester.pumpAndSettle();
  await tester.tap(buyCoinItem);
  await tester.pumpAndSettle();

  await pause();

  // Select infinite bid if it exists
  if (infiniteBids.evaluate().isNotEmpty) {
    await tester.tap(infiniteBids.first);
    await tester.pumpAndSettle();
  }

  // Create order
  await tester.dragUntilVisible(
    takeOrderButton,
    find.byKey(const Key('taker-form-layout-scroll')),
    const Offset(0, -150),
  );
  await tester.tap(takeOrderButton);
  await tester.pumpAndSettle();

  await tester.dragUntilVisible(
    takeOrderConfirmButton,
    find.byKey(const Key('taker-order-confirmation-scroll')),
    const Offset(0, -150),
  );
  await tester.tap(takeOrderConfirmButton);
  await tester.pumpAndSettle().timeout(
    const Duration(minutes: 10),
    onTimeout: () {
      throw 'Test error: DOC->MARTY taker Swap took more than 10 minutes';
    },
  );

  expect(
    swapSuccess,
    findsOneWidget,
    reason: 'Test error: Taker Swap was not successful (probably failed)',
  );

  expect(
    find.descendant(
      of: takerFeeSentEventStep,
      matching: find.byType(CopiedText),
    ),
    findsOneWidget,
    reason: "Test error: 'takerFeeSent' event tx copied text not found",
  );
  expect(
    find.descendant(
      of: makerPaymentReceivedEventStep,
      matching: find.byType(CopiedText),
    ),
    findsOneWidget,
    reason: "Test error: 'makerPaymentReceived' event tx copied text not found",
  );

  await tester.dragUntilVisible(
    takerPaymentSentEventStep,
    tradingDetailsScrollable,
    const Offset(0, -10),
  );
  expect(
    find.descendant(
      of: takerPaymentSentEventStep,
      matching: find.byType(CopiedText),
    ),
    findsOneWidget,
    reason: "Test error: 'takerPaymentSent' event tx copied text not found",
  );

  await tester.dragUntilVisible(
    takerPaymentSpentEventStep,
    tradingDetailsScrollable,
    const Offset(0, -10),
  );
  expect(
    find.descendant(
      of: takerPaymentSpentEventStep,
      matching: find.byType(CopiedText),
    ),
    findsOneWidget,
    reason: "Test error: 'takerPaymentSpent' event tx copied text not found",
  );

  await tester.dragUntilVisible(
    makerPaymentSpentEventStep,
    tradingDetailsScrollable,
    const Offset(0, -10),
  );
  expect(
    find.descendant(
      of: makerPaymentSpentEventStep,
      matching: find.byType(CopiedText),
    ),
    findsOneWidget,
    reason: "Test error: 'makerPaymentSpent' event tx copied text not found",
  );

  await tester.dragUntilVisible(
    backButton,
    tradingDetailsScrollable,
    const Offset(0, 10),
  );

  await tester.tap(backButton);
  await tester.pumpAndSettle();
  await tester.tap(historyTab);
  await tester.pump(const Duration(milliseconds: 1000));
  expect(
    find.byType(HistoryItem),
    findsOneWidget,
    reason: 'Test error: Swap history item not found',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run taker order tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await tester.pumpAndSettle();
      await testTakerOrder(tester);

      print('END TAKER ORDER TESTS');
    },
    semanticsEnabled: false,
  );
}
