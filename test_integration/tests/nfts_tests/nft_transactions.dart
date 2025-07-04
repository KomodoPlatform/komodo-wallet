// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testNftTransactions(WidgetTester tester) async {
  print('TEST NFT TRANSACTIONS');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run NFT Transactions tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    print('ACCEPT ALPHA WARNING');
    await acceptAlphaWarning(tester);
    await restoreWalletToTest(tester);
    await testNftTransactions(tester);
    await tester.pumpAndSettle();

    print('END NFT TRANSACTIONS TESTS');
  }, semanticsEnabled: false);
}
