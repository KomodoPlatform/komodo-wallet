// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/goto.dart' as goto;
import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Run suspended asset tests:',
    (WidgetTester tester) async {
      await runZonedGuarded(() async {
        FlutterError.onError = (FlutterErrorDetails details) {/** */};

        const String suspendedAsset = 'KMD';
        tester.testTextInput.register();
        await app.main();
        await tester.pumpAndSettle();

        await acceptAlphaWarning(tester);

        print('RESTORE WALLET TO TEST');
        await restoreWalletToTest(tester);
        await tester.pumpAndSettle();

        await goto.walletPage(tester);
        final Finder searchCoinsField =
            find.byKey(const Key('wallet-page-search-field'));
        await tester.enterText(searchCoinsField, suspendedAsset);
        await tester.pumpAndSettle();
        final Finder suspendedCoinLabel = isMobile
            ? find.byKey(const Key('retry-suspended-asset-$suspendedAsset'))
            : find.byKey(const Key('suspended-asset-message-$suspendedAsset'));
        expect(
          suspendedCoinLabel,
          findsOneWidget,
          reason: 'Test error: $suspendedAsset should be suspended,'
              ' but corresponding label was not found.',
        );
      }, (_, __) {/** */});
    },
    semanticsEnabled: false,
  );
}
