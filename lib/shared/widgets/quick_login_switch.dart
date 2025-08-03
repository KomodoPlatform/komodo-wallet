import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/remember_wallet_service.dart';

class QuickLoginSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const QuickLoginSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Show remembered wallet dialog if conditions are met
  static Future<void> maybeShowRememberedWallet(BuildContext context) async {
    return RememberWalletService.maybeShowRememberedWallet(context);
  }

  /// Track when user has been logged in
  static void trackUserLoggedIn() {
    RememberWalletService.trackUserLoggedIn();
  }

  /// Reset remember me dialog state when user logs out
  static void resetOnLogout() {
    RememberWalletService.resetOnLogout();
  }

  /// Check if remember me dialog has been shown this session
  static bool get hasShownRememberMeDialogThisSession =>
      RememberWalletService.hasShownRememberMeDialogThisSession;

  /// Check if user has been logged in this session
  static bool get hasBeenLoggedInThisSession =>
      RememberWalletService.hasBeenLoggedInThisSession;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Row(
        children: [
          Text(LocaleKeys.oneClickLogin.tr()),
          const SizedBox(width: 8),
          Tooltip(
            message: LocaleKeys.quickLoginTooltip.tr(),
            child: const Icon(Icons.info, size: 16),
          ),
        ],
      ),
      subtitle: Text(
        LocaleKeys.quickLoginSubtitle.tr(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
