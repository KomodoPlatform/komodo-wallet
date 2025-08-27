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
import 'test_seed_import_georestriction.dart';
import 'test_withdraw.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  walletsWidgetTests();
}

void walletsWidgetTests({
  bool skip = false,
}) {
  return testWidgets(
    'Run wallet tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();

      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testCoinIcons(tester);
      await testActivateCoins(tester);
      await testCexPrices(tester);
      await testWithdraw(tester);
      await testFilters(tester);
      await testSeedImportGeorestriction(tester);

      // Disabled until the bitrefill feature is re-enabled
      // await tester.pumpAndSettle();
      // await testBitrefillIntegration(tester);
    },
    semanticsEnabled: false,
    skip: skip,
  );
}
