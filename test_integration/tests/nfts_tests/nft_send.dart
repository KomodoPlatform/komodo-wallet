// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testNftSend(WidgetTester tester) async {
  print('TEST NFT SEND');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run NFT send tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    print('ACCEPT ALPHA WARNING');
    await acceptAlphaWarning(tester);
    await restoreWalletToTest(tester);
    await testNftSend(tester);
    await tester.pumpAndSettle();

    print('END NFT SEND TESTS');
  }, semanticsEnabled: false);
}
