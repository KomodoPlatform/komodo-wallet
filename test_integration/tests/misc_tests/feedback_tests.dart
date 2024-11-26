// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/main.dart' as app;

import '../../common/goto.dart' as goto;
import '../../common/pause.dart';
import '../../common/widget_tester_action_extensions.dart';
import '../../helpers/accept_alpha_warning.dart';

Future<void> testFeedbackForm(WidgetTester tester) async {
  await goto.settingsPage(tester);
  await tester.pumpAndSettle();
  await tester.tapAndPump(find.byKey(const Key('settings-menu-item-feedback')));
  await tester.pumpAndSettle();
  tester.ensureVisible(find.byKey(const Key('feedback-email-field')));
  tester.ensureVisible(find.byKey(const Key('feedback-message-field')));
  tester.ensureVisible(find.byKey(const Key('feedback-submit-button')));
  await pause(msg: 'END TEST FEEDBACK');
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Run feedback tests:', (WidgetTester tester) async {
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    await acceptAlphaWarning(tester);
    print('ACCEPT ALPHA WARNING');
    await tester.pumpAndSettle();
    await testFeedbackForm(tester);

    print('END FEEDBACK FORM TESTS');
  }, semanticsEnabled: false);
}
