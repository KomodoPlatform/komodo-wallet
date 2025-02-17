// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';
import 'nft_networks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  nftsWidgetTests();
}

void nftsWidgetTests({
  bool skip = false,
  int retryLimit = 0,
  Duration timeout = const Duration(minutes: 10),
}) {
  return testWidgets(
    'Run NFT tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();

      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testNftNetworks(tester);

      print('END NFT TESTS');
    },
    semanticsEnabled: false,
    skip: skip,
    retry: retryLimit,
    timeout: Timeout(timeout),
  );
}
