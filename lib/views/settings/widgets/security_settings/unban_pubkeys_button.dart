import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/settings/widgets/security_settings/unban_pubkeys_dialog.dart';
import 'package:web_dex/views/common/wallet_password_dialog/wallet_password_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

/// A button widget that allows users to unban public keys.
///
/// This widget provides a secure way to unban public keys that were previously
/// banned due to various reasons (e.g., failed transactions, security concerns).
/// The button requires authentication and shows the results in a dialog.
class UnbanPubkeysButton extends StatefulWidget {
  const UnbanPubkeysButton({super.key, this.onUnbanComplete});

  /// Optional callback that is called when the unban operation completes.
  /// This can be used to refresh data or update the UI state.
  final VoidCallback? onUnbanComplete;

  @override
  State<UnbanPubkeysButton> createState() => _UnbanPubkeysButtonState();
}

class _UnbanPubkeysButtonState extends State<UnbanPubkeysButton> {
  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      onPressed: () => _handleUnbanPressed(context),
      text: LocaleKeys.unbanPubkeys.tr(),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }

  /// Handles the button press event for unbanning pubkeys.
  ///
  /// This method:
  /// 1. Shows a password dialog for authentication
  /// 2. Calls the SDK to unban all pubkeys
  /// 3. Shows the results in a dialog
  /// 4. Optionally calls the completion callback
  Future<void> _handleUnbanPressed(BuildContext context) async {
    // Show password dialog first
    final password = await walletPasswordDialog(context);

    if (password == null || !mounted) return;

    try {
      // Show loading indicator
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('${LocaleKeys.unbanPubkeys.tr()}...'),
            ],
          ),
        ),
      );

      // Get the SDK instance from the repository provider
      final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);

      // Unban all pubkeys using the PubkeyManager
      final result = await sdk.pubkeys.unbanPubkeys(UnbanBy.all());

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show results dialog
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => UnbanPubkeysResultDialog(result: result),
        );
      }

      // Call completion callback if provided
      widget.onUnbanComplete?.call();

      // Show success snackbar if any pubkeys were unbanned
      if (result.unbanned.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.unbanned.length} ${LocaleKeys.unbannedPubkeys.tr()}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Show info snackbar if no pubkeys were banned
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.noBannedPubkeys.tr()),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.unbanPubkeysFailed.tr()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Log error for debugging
      debugPrint('Failed to unban pubkeys: ${e.toString()}');
    }
  }
}
