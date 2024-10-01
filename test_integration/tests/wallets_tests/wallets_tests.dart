// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';
import 'test_activate_coins.dart';
import 'test_cex_prices.dart';
import 'test_coin_assets.dart';
import 'test_filters.dart';
import 'test_withdraw.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Run wallet tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();

      print('RESTORE WALLET TO TEST');
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await tester.pumpAndSettle();
      await testCoinIcons(tester);
      await tester.pumpAndSettle();
      await testActivateCoins(tester);
      await tester.pumpAndSettle();
      await testCexPrices(tester);
      await tester.pumpAndSettle();
      await testWithdraw(tester);
      await tester.pumpAndSettle();
      await testFilters(tester);

      print('END WALLET TESTS');
    },
    semanticsEnabled: false,
  );
}
