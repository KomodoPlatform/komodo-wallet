import 'package:flutter/material.dart';
import 'package:web_dex/views/settings/widgets/security_settings/security_action_plate.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget for initiating private key backup from the main security settings.
///
/// **Security Architecture**: This widget is the entry point for the hybrid
/// security approach to private key handling:
/// - Displays the private key backup option in the main security settings
/// - Initiates the secure authentication and export flow when pressed
/// - Does NOT store or handle any sensitive data itself
/// - Triggers the secure private key export process through callbacks
///
/// **Design Pattern**: Uses the generic SecurityActionPlate for consistent layout.
class PlatePrivateKeyBackup extends StatelessWidget {
  /// Creates a new PlatePrivateKeyBackup widget.
  ///
  /// [onViewPrivateKeysPressed] Callback triggered when user wants to export
  /// private keys. This callback should handle authentication and initiate
  /// the secure private key retrieval process.
  const PlatePrivateKeyBackup({
    super.key,
    required this.onViewPrivateKeysPressed,
  });

  /// Callback function to handle private key export initiation.
  ///
  /// **Security Note**: This callback should trigger the hybrid security flow:
  /// 1. Show password authentication dialog
  /// 2. Validate authentication through BLoC
  /// 3. Fetch private keys securely in UI layer
  /// 4. Navigate to private key display screen
  final Function(BuildContext context) onViewPrivateKeysPressed;

  @override
  Widget build(BuildContext context) {
    return SecurityActionPlate(
      icon: Icon(Icons.key),
      title: LocaleKeys.exportPrivateKeys.tr(),
      description: LocaleKeys.exportPrivateKeysDescription.tr(),
      actionText: LocaleKeys.exportPrivateKeys.tr(),
      onActionPressed: () => onViewPrivateKeysPressed(context),
      showWarningIndicator: false,
    );
  }
}
