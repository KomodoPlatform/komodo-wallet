// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';
import 'form_tests.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  fiatOnRampWidgetTests();
}

void fiatOnRampWidgetTests({
  bool skip = false,
  int retryLimit = 0,
  Duration timeout = const Duration(minutes: 10),
}) {
  return testWidgets(
    'Run Fiat On-Ramp tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();
      await acceptAlphaWarning(tester);
      await restoreWalletToTest(tester);
      await testFiatFormInputs(tester);

      print('END Fiat On-Ramp TESTS');
    },
    semanticsEnabled: false,
    skip: skip,
    retry: retryLimit,
    timeout: Timeout(timeout),
  );
}
