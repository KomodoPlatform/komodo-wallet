import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/wallet.dart';

import '../common/pump_and_settle.dart';
import '../helpers/get_funded_wif.dart';
import 'connect_wallet.dart';

Future<void> restoreWalletToTest(WidgetTester tester) async {
  // Restores wallet to be used in following tests
  final String testSeed = getFundedWif();
  const String walletName = 'my-wallet';
  const String password = 'pppaaasssDDD555444@@@';
  final Finder importWalletButton =
      find.byKey(const Key('import-wallet-button'));
  final Finder nameField = find.byKey(const Key('name-wallet-field'));
  final Finder passwordField = find.byKey(const Key('create-password-field'));
  final Finder passwordConfirmField =
      find.byKey(const Key('create-password-field-confirm'));
  final Finder importSeedField = find.byKey(const Key('import-seed-field'));
  final Finder importConfirmButton =
      find.byKey(const Key('confirm-seed-button'));
  final Finder eulaCheckBox = find.byKey(const Key('checkbox-eula'));
  final Finder tocCheckBox = find.byKey(const Key('checkbox-toc'));
  final Finder walletsManagerWrapper =
      find.byKey(const Key('wallets-manager-wrapper'));
  final Finder allowCustomSeedCheckbox =
      find.byKey(const Key('checkbox-custom-seed'));
  final Finder customSeedDialogInput =
      find.byKey(const Key('custom-seed-dialog-input'));
  final Finder customSeedDialogOkButton =
      find.byKey(const Key('custom-seed-dialog-ok-button'));
  const String confirmCustomSeedText = 'I Understand';

  await tester.pumpAndSettle();
  isMobile
      ? await tapOnMobileConnectWallet(tester, WalletType.iguana)
      : await tapOnAppBarConnectWallet(tester, WalletType.iguana);
  await tester.ensureVisible(importWalletButton);
  await tester.tap(importWalletButton);
  await tester.pumpAndSettle();

  await tester.tap(nameField);
  await tester.enterText(nameField, walletName);
  await tester.enterText(importSeedField, testSeed);
  await tester.pump();

  // Change focus from the text field to allow the text error to appear
  // TODO: look into more aggressive input validation
  await tester.tap(eulaCheckBox);
  await tester.pump();
  await tester.tap(tocCheckBox);
  await tester.pumpNFrames(5);

  if (!bip39.validateMnemonic(testSeed)) {
    await tester.tap(allowCustomSeedCheckbox);
    await tester.pumpNFrames(5);
    await tester.enterText(customSeedDialogInput, confirmCustomSeedText);
    await tester.pumpNFrames(5);
    await tester.tap(customSeedDialogOkButton);
    // Works on safari with 5 frames, but requires more on chrome?
    await tester.pumpNFrames(10);
  }

  await tester.dragUntilVisible(
    importConfirmButton,
    walletsManagerWrapper,
    const Offset(0, -15),
  );
  await tester.pumpNFrames(5);
  await tester.tap(importConfirmButton);
  await tester.pumpNFrames(5);
  await tester.enterText(passwordField, password);
  await tester.enterText(passwordConfirmField, password);
  await tester.dragUntilVisible(
    importConfirmButton,
    walletsManagerWrapper,
    const Offset(0, -15),
  );
  await tester.pumpNFrames(5);
  await tester.tap(importConfirmButton);
  await pumpUntilDisappear(tester, walletsManagerWrapper);
}
