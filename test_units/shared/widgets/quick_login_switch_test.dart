import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/shared/widgets/quick_login_switch.dart';
import 'package:web_dex/shared/widgets/remember_wallet_service.dart';

void main() {
  group('QuickLoginSwitch and RememberWalletService Integration Tests', () {
    testWidgets(
      'QuickLoginSwitch should provide static access to service methods',
      (WidgetTester tester) async {
        // Test that static methods are accessible
        expect(QuickLoginSwitch.hasShownRememberMeDialogThisSession, false);
        expect(QuickLoginSwitch.hasBeenLoggedInThisSession, false);

        // Test tracking user login
        QuickLoginSwitch.trackUserLoggedIn();
        expect(QuickLoginSwitch.hasBeenLoggedInThisSession, true);

        // Test reset functionality
        QuickLoginSwitch.resetOnLogout();
        expect(QuickLoginSwitch.hasShownRememberMeDialogThisSession, false);
        expect(QuickLoginSwitch.hasBeenLoggedInThisSession, false);
      },
    );

    test('RememberWalletService should maintain state correctly', () {
      // Initial state
      expect(RememberWalletService.hasShownRememberMeDialogThisSession, false);
      expect(RememberWalletService.hasBeenLoggedInThisSession, false);

      // Track login
      RememberWalletService.trackUserLoggedIn();
      expect(RememberWalletService.hasBeenLoggedInThisSession, true);

      // Reset state
      RememberWalletService.resetOnLogout();
      expect(RememberWalletService.hasShownRememberMeDialogThisSession, false);
      expect(RememberWalletService.hasBeenLoggedInThisSession, false);
    });

    testWidgets('QuickLoginSwitch widget should render correctly', (
      WidgetTester tester,
    ) async {
      bool switchValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickLoginSwitch(
              value: switchValue,
              onChanged: (value) {
                switchValue = value;
              },
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}
