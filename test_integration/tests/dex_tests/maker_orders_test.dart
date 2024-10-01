// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;
import 'package:web_dex/shared/widgets/focusable_widget.dart';
import 'package:web_dex/views/dex/entities_list/orders/order_item.dart';

import '../../common/pause.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testMakerOrder(WidgetTester tester) async {
  const String sellCoin = 'DOC';
  const String sellAmount = '0.012345';
  const String buyCoin = 'MARTY';
  const String buyAmount = '0.023456';

  String? truncatedUuid;

  final Finder dexSectionButton = find.byKey(const Key('main-menu-dex'));
  final Finder makeOrderTab = find.byKey(const Key('make-order-tab'));
  final Finder sellCoinSelectButton =
      find.byKey(const Key('maker-form-sell-switcher'));
  final Finder sellCoinSearchField = find.descendant(
    of: find.byKey(const Key('maker-sell-coins-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder sellCoinItem =
      find.byKey(const Key('Coin-table-item-$sellCoin'));
  final Finder sellAmountField =
      find.byKey(const Key('maker-sell-amount-input'));
  final Finder buyCoinSelectButton =
      find.byKey(const Key('maker-form-buy-switcher'));
  final Finder buyCoinSearchField = find.descendant(
    of: find.byKey(const Key('maker-buy-coins-table')),
    matching: find.byKey(const Key('search-field')),
  );
  final Finder buyCoinItem = find.byKey(const Key('Coin-table-item-$buyCoin'));
  final Finder buyAmountField = find.byKey(const Key('maker-buy-amount-input'));
  final Finder makeOrderButton = find.byKey(const Key('make-order-button'));
  final Finder makeOrderConfirmButton =
      find.byKey(const Key('make-order-confirm-button'));
  final Finder orderListItem = find.byType(OrderItem);
  final Finder orderUuidWidget = find.byKey(const Key('maker-order-uuid'));

  // Open maker order form
  await tester.tap(dexSectionButton);
  await tester.pumpAndSettle();
  await tester.tap(makeOrderTab);
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

  // Select buy coin, enter buy amount
  await tester.tap(buyCoinSelectButton);
  await tester.pumpAndSettle();
  await tester.enterText(buyCoinSearchField, buyCoin);
  await tester.pumpAndSettle();
  await tester.tap(buyCoinItem);
  await tester.pumpAndSettle();
  await tester.enterText(buyAmountField, buyAmount);
  await tester.pumpAndSettle();

  // Create order
  await tester.dragUntilVisible(
    makeOrderButton,
    find.byKey(const Key('maker-form-layout-scroll')),
    const Offset(0, -100),
  );
  await tester.tap(makeOrderButton);
  await tester.pumpAndSettle();

  await tester.dragUntilVisible(
    makeOrderConfirmButton,
    find.byKey(const Key('maker-order-conformation-scroll')),
    const Offset(0, -100),
  );
  await tester.tap(makeOrderConfirmButton);
  await tester.pumpAndSettle();
  await pause(sec: 5);

  // Open order details page
  expect(orderListItem, findsOneWidget);
  await tester.tap(find.descendant(
      of: orderListItem, matching: find.byType(FocusableWidget)));
  await tester.pumpAndSettle();

  // Find order UUID on maker order details page
  expect(orderUuidWidget, findsOneWidget);
  truncatedUuid = (orderUuidWidget.evaluate().single.widget as Text).data;
  expect(truncatedUuid != null, isTrue);
  expect(truncatedUuid?.isNotEmpty, isTrue);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run maker order tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    await acceptAlphaWarning(tester);
    await restoreWalletToTest(tester);
    await tester.pumpAndSettle();
    await testMakerOrder(tester);

    print('END MAKER ORDER TESTS');
  }, semanticsEnabled: false);
}
