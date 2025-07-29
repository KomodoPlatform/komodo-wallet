import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/views/settings/widgets/security_settings/security_action_plate.dart';
import 'package:web_dex/views/settings/widgets/security_settings/unban_pubkeys_dialog.dart';

/// Widget for unbanning public keys from the main security settings.
///
/// This widget provides a consistent layout similar to other security actions
/// and allows users to unban all banned public keys without requiring
/// password authentication.
class UnbanPubkeysPlate extends StatefulWidget {
  const UnbanPubkeysPlate({super.key, this.onUnbanComplete});

  /// Optional callback that is called when the unban operation completes.
  final VoidCallback? onUnbanComplete;

  @override
  State<UnbanPubkeysPlate> createState() => _UnbanPubkeysPlateState();
}

class _UnbanPubkeysPlateState extends State<UnbanPubkeysPlate> {
  @override
  Widget build(BuildContext context) {
    return SecurityActionPlate(
      icon: Icon(Icons.block),
      title: 'Unban Pubkeys',
      description:
          'Unban public keys that were previously banned due to failed transactions or security concerns.',
      actionText: 'Unban Pubkeys',
      onActionPressed: () => _handleUnbanPressed(context),
    );
  }

  /// Handles the unban operation without password confirmation.
  ///
  /// This method:
  /// 1. Calls the SDK to unban all pubkeys directly
  /// 2. Shows the results in a dialog
  /// 3. Optionally calls the completion callback
  /// 4. Shows appropriate snackbars for feedback
  Future<void> _handleUnbanPressed(BuildContext context) async {
    if (!mounted) return;

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
              Text('Unbanning pubkeys...'),
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
            content: Text('${result.unbanned.length} unbanned pubkeys'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Show info snackbar if no pubkeys were banned
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No banned pubkeys found'),
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
            content: Text('Failed to unban pubkeys'),
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
