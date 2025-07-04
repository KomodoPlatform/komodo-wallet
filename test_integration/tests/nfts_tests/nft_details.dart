// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testNftDetails(WidgetTester tester) async {
  print('TEST NFT DEAILS');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run NFT details tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    print('ACCEPT ALPHA WARNING');
    await acceptAlphaWarning(tester);
    await restoreWalletToTest(tester);
    await testNftDetails(tester);
    await tester.pumpAndSettle();

    print('END NFT DETAILS TESTS');
  }, semanticsEnabled: false);
}
