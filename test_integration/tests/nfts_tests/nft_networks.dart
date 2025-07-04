// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testNftNetworks(WidgetTester tester) async {
  print('TEST NFT NETWORKS');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run NFT networs tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    print('ACCEPT ALPHA WARNING');
    await acceptAlphaWarning(tester);
    await restoreWalletToTest(tester);
    await testNftNetworks(tester);
    await tester.pumpAndSettle();

    print('END NFT NETWORKS TESTS');
  }, semanticsEnabled: false);
}
