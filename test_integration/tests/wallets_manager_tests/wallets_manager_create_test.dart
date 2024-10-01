// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/main.dart' as app;
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/common/header/actions/account_switcher.dart';

import '../../common/pump_and_settle.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/connect_wallet.dart';

Future<void> testCreateWallet(WidgetTester tester) async {
  const String walletName = 'my-wallet-name';
  const String password = 'pppaaasssDDD555444@@@';
  final Finder createWalletButton =
      find.byKey(const Key('create-wallet-button'));
  final Finder nameField = find.byKey(const Key('name-wallet-field'));
  final Finder passwordField = find.byKey(const Key('create-password-field'));
  final Finder passwordConfirmField =
      find.byKey(const Key('create-password-field-confirm'));
  final Finder confirmButton = find.byKey(const Key('confirm-password-button'));
  final Finder eulaCheckBox = find.byKey(const Key('checkbox-eula'));
  final Finder tocCheckBox = find.byKey(const Key('checkbox-toc'));
  final Finder authorizedWalletButton =
      find.widgetWithText(AccountSwitcher, walletName);
  final Finder walletsManagerWrapper =
      find.byKey(const Key('wallets-manager-wrapper'));

  await tester.pumpAndSettle();
  await tapOnMobileConnectWallet(tester, WalletType.iguana);

  // New wallet test
  expect(createWalletButton, findsOneWidget);
  await tester.tap(createWalletButton);
  await tester.pumpAndSettle();

  // Wallet creation step
  expect(find.byKey(const Key('wallet-creation')), findsOneWidget);
  await tester.tap(nameField);
  await tester.enterText(nameField, walletName);
  await tester.enterText(passwordField, password);
  await tester.enterText(passwordConfirmField, password);
  await tester.pumpNFrames(10);
  await tester.tap(eulaCheckBox);
  await tester.pumpNFrames(10);
  await tester.tap(tocCheckBox);
  await tester.pumpNFrames(10);
  await tester.tap(confirmButton);
  await pumpUntilDisappear(tester, walletsManagerWrapper);
  if (!isMobile) {
    expect(authorizedWalletButton, findsOneWidget);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run Wallet Creation tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      print('ACCEPT ALPHA WARNING');
      await acceptAlphaWarning(tester);
      await testCreateWallet(tester);
      await tester.pumpAndSettle();

      print('END WALLET CREATION TESTS');
    },
    semanticsEnabled: false,
  );
}
