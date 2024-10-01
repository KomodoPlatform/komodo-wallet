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

Future<void> testImportWallet(WidgetTester tester) async {
  const String walletName = 'my-wallet-restored';
  const String password = 'pppaaasssDDD555444@@@';
  const String customSeed = 'my-custom-seed';
  final Finder importWalletButton =
      find.byKey(const Key('import-wallet-button'));
  final Finder nameField = find.byKey(const Key('name-wallet-field'));
  final Finder passwordField = find.byKey(const Key('create-password-field'));
  final Finder passwordConfirmField =
      find.byKey(const Key('create-password-field-confirm'));
  final Finder importSeedField = find.byKey(const Key('import-seed-field'));
  final Finder importConfirmButton =
      find.byKey(const Key('confirm-seed-button'));
  final Finder allowCustomSeedCheckbox =
      find.byKey(const Key('checkbox-custom-seed'));
  final Finder customSeedDialogInput =
      find.byKey(const Key('custom-seed-dialog-input'));
  final Finder customSeedDialogOkButton =
      find.byKey(const Key('custom-seed-dialog-ok-button'));
  const String confirmCustomSeedText = 'I Understand';
  final Finder eulaCheckbox = find.byKey(const Key('checkbox-eula'));
  final Finder tocCheckbox = find.byKey(const Key('checkbox-toc'));
  final Finder authorizedWalletButton =
      find.widgetWithText(AccountSwitcher, walletName);
  final Finder walletsManagerWrapper =
      find.byKey(const Key('wallets-manager-wrapper'));

  await tester.pumpAndSettle();
  await tapOnMobileConnectWallet(tester, WalletType.iguana);

  // New wallet test
  expect(importWalletButton, findsOneWidget);
  await tester.tap(importWalletButton);
  await tester.pumpAndSettle();

  // Wallet creation step
  await tester.tap(nameField);
  await tester.enterText(nameField, walletName);
  await tester.enterText(importSeedField, customSeed);
  await tester.pumpNFrames(10);
  await tester.tap(eulaCheckbox);
  await tester.pumpNFrames(10);
  await tester.tap(tocCheckbox);
  await tester.pumpNFrames(10);
  await tester.tap(allowCustomSeedCheckbox);
  await tester.pumpNFrames(10);
  await tester.enterText(customSeedDialogInput, confirmCustomSeedText);
  await tester.pumpNFrames(10);
  await tester.tap(customSeedDialogOkButton);
  await tester.pumpNFrames(20);
  await tester.tap(importConfirmButton);
  await tester.pumpAndSettle();

  // Enter password step
  await tester.enterText(passwordField, password);
  await tester.enterText(passwordConfirmField, password);
  await tester.tap(importConfirmButton);
  await pumpUntilDisappear(tester, walletsManagerWrapper);
  if (!isMobile) {
    expect(authorizedWalletButton, findsOneWidget);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run Wallet Import tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      print('ACCEPT ALPHA WARNING');
      await acceptAlphaWarning(tester);
      await testImportWallet(tester);
      await tester.pumpAndSettle();

      print('END WALLET IMPORT TESTS');
    },
    semanticsEnabled: false,
  );
}
