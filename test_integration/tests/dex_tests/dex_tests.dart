// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';
import './maker_orders_test.dart';
import './taker_orders_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Run DEX tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await tester.pumpAndSettle();
      await testMakerOrder(tester);
      await tester.pumpAndSettle();
      await testTakerOrder(tester);

      print('END DEX TESTS');
    },
    semanticsEnabled: false,
  );
}
