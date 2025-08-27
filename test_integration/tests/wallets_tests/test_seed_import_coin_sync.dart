// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/goto.dart' as goto;
import '../../common/pause.dart';
import '../../common/widget_tester_action_extensions.dart';
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testSeedImportGeorestriction(WidgetTester tester) async {
  await pause(sec: 2, msg: 'TEST SEED IMPORT COIN SYNC');

  await pause(sec: 2, msg: '🔍 SEED IMPORT: Starting seed import coin sync test');
  
  // Test seed phrase for import
  const String testSeed = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  const String walletName = 'Test Import Wallet';
  const String password = 'testpassword123';

  // Navigate to wallets manager
  await goto.walletsManager(tester);
  print('🔍 SEED IMPORT: Navigated to wallets manager');

  // Tap import button
  final Finder importButton = find.byKey(const Key('wallet-import-button'));
  await tester.tapAndPump(importButton);
  print('🔍 SEED IMPORT: Tapped import button');

  // Enter wallet name
  final Finder nameField = find.byKey(const Key('name-wallet-field'));
  await tester.enterText(nameField, walletName);
  print('🔍 SEED IMPORT: Entered wallet name');

  // Enter seed phrase
  final Finder seedField = find.byKey(const Key('import-seed-field'));
  await tester.enterText(seedField, testSeed);
  print('🔍 SEED IMPORT: Entered seed phrase');

  // Accept EULA and TOS
  final Finder eulaCheckbox = find.byKey(const Key('import-wallet-eula-checks'));
  await tester.tapAndPump(eulaCheckbox);
  print('🔍 SEED IMPORT: Accepted EULA and TOS');

  // Tap continue button
  final Finder continueButton = find.text('Continue');
  await tester.tapAndPump(continueButton);
  print('🔍 SEED IMPORT: Tapped continue button');

  // Enter password
  final Finder passwordField = find.byKey(const Key('password-field'));
  await tester.enterText(passwordField, password);
  print('🔍 SEED IMPORT: Entered password');

  // Tap import button
  final Finder finalImportButton = find.text('Import');
  await tester.tapAndPump(finalImportButton);
  print('🔍 SEED IMPORT: Tapped final import button');

  // Wait for import to complete
  await tester.pumpAndSettle(const Duration(seconds: 10));
  print('🔍 SEED IMPORT: Import completed');

  // Navigate to wallet page
  await goto.walletPage(tester);
  print('🔍 SEED IMPORT: Navigated to wallet page');

  // Check if coins are visible in the wallet
  // Look for any coin items in the wallet list
  final Finder coinListItems = find.byKey(const Key('coin-list-item-'));
  await tester.pumpAndSettle();
  
  // Verify that coins are visible (even if suspended due to activation failures)
  expect(coinListItems, findsWidgets, reason: 'Coins should be visible in wallet after import, even if suspended');
  print('🔍 SEED IMPORT: Verified coins are visible in wallet');

  await pause(msg: '🔍 SEED IMPORT: Test completed');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run seed import coin sync test:', (WidgetTester tester) async {
    print('🔍 MAIN: Starting seed import coin sync test suite');
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    
    await acceptAlphaWarning(tester);
    await testSeedImportGeorestriction(tester);
    
    print('🔍 MAIN: Seed import coin sync tests completed successfully');
  });
}