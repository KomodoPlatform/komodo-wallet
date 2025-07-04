// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_wallet/main.dart' as app;

import '../../common/pause.dart';
import '../../helpers/accept_alpha_warning.dart';
import 'no_login_taker_form_test.dart';
import 'no_login_wallet_access_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  noLoginWidgetTests();
}

void noLoginWidgetTests({
  bool skip = false,
  int retryLimit = 0,
  Duration timeout = const Duration(minutes: 10),
}) {
  return testWidgets(
    'Run no login mode tests:',
    (WidgetTester tester) async {
      tester.testTextInput.register();
      await app.main();
      await tester.pumpAndSettle();

      await acceptAlphaWarning(tester);
      await pause(msg: 'START NO LOGIN MODE TESTS');
      await testNoLoginWalletAccess(tester);
      // No Login taker form test should be always ran last here
      await testNoLoginTakerForm(tester);

      await pause(sec: 5, msg: 'END NO LOGIN MODE TESTS');
    },
    semanticsEnabled: false,
    retry: retryLimit,
    timeout: Timeout(timeout),
    skip: skip,
  );
}
