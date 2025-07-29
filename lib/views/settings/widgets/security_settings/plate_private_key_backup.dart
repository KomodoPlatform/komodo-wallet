import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

/// Widget for initiating private key backup from the main security settings.
///
/// **Security Architecture**: This widget is the entry point for the hybrid
/// security approach to private key handling:
/// - Displays the private key backup option in the main security settings
/// - Initiates the secure authentication and export flow when pressed
/// - Does NOT store or handle any sensitive data itself
/// - Triggers the secure private key export process through callbacks
///
/// **Design Pattern**: Responsive single widget that adapts layout based on
/// screen size and available width, similar to [PlateSeedBackup] but specifically
/// designed for private key export functionality.
class PlatePrivateKeyBackup extends StatelessWidget {
  /// Creates a new PlatePrivateKeyBackup widget.
  ///
  /// [onViewPrivateKeysPressed] Callback triggered when user wants to export
  /// private keys. This callback should handle authentication and initiate
  /// the secure private key retrieval process.
  const PlatePrivateKeyBackup({required this.onViewPrivateKeysPressed});

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
    return _ResponsiveBody(onViewPrivateKeysPressed: onViewPrivateKeysPressed);
  }
}

/// Single responsive widget that handles all layout cases.
/// Adapts between mobile/desktop and column/row layouts based on screen size.
class _ResponsiveBody extends StatelessWidget {
  const _ResponsiveBody({required this.onViewPrivateKeysPressed});

  final Function(BuildContext context) onViewPrivateKeysPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = !isMobile;

    // Determine layout type based on screen size and platform
    final useColumnLayout = isMobile || screenWidth < 600.0;

    return Container(
      padding: _getPadding(isDesktop),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: useColumnLayout
          ? _buildColumnLayout(isDesktop)
          : _buildRowLayout(),
    );
  }

  /// Returns appropriate padding based on platform
  EdgeInsets _getPadding(bool isDesktop) {
    return isDesktop
        ? const EdgeInsets.all(24)
        : const EdgeInsets.symmetric(horizontal: 12);
  }

  /// Builds column layout for mobile or constrained desktop widths
  Widget _buildColumnLayout(bool isDesktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: isDesktop ? 16 : 24),
        const _PrivateKeyIcon(),
        SizedBox(height: isDesktop ? 16 : 28),
        const _PrivateKeyTitle(),
        const SizedBox(height: 12),
        const _PrivateKeyBody(),
        SizedBox(height: isDesktop ? 16 : 8),
        _PrivateKeyButtons(onViewPrivateKeysPressed: onViewPrivateKeysPressed),
        SizedBox(height: isDesktop ? 16 : 6),
      ],
    );
  }

  /// Builds row layout for wide desktop screens
  Widget _buildRowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            const _PrivateKeyIcon(),
            const SizedBox(width: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  const _PrivateKeyTitle(),
                  const SizedBox(height: 12),
                  const _PrivateKeyBody(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Spacer(),
            _PrivateKeyButtons(
              onViewPrivateKeysPressed: onViewPrivateKeysPressed,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}

/// Icon widget for the private key backup section.
///
/// **Note**: Currently uses the same icon as seed backup for consistency.
/// This could be updated with a private key specific icon in the future.
class _PrivateKeyIcon extends StatelessWidget {
  const _PrivateKeyIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.key,
      size: 50,
      color: theme.custom.defaultGradientButtonTextColor,
    );
  }
}

/// Title widget for the private key backup section.
///
/// Displays the private key export title with a warning indicator
/// to emphasize the security-sensitive nature of this operation.
class _PrivateKeyTitle extends StatelessWidget {
  const _PrivateKeyTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: theme.custom.decreaseColor,
            borderRadius: BorderRadius.circular(7 / 2),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            LocaleKeys.exportPrivateKeys.tr(),
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Description widget explaining the purpose of private key export.
class _PrivateKeyBody extends StatelessWidget {
  const _PrivateKeyBody();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Text(
        LocaleKeys.exportPrivateKeysDescription.tr(),
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Button widget for initiating private key export.
///
/// **Security Note**: This button triggers the hybrid security flow when pressed:
/// 1. Calls the onViewPrivateKeysPressed callback
/// 2. Parent widget handles authentication
/// 3. Secure private key retrieval is initiated
/// 4. Navigation to private key display screen
class _PrivateKeyButtons extends StatelessWidget {
  const _PrivateKeyButtons({required this.onViewPrivateKeysPressed});

  final Function(BuildContext context) onViewPrivateKeysPressed;

  @override
  Widget build(BuildContext context) {
    final text = LocaleKeys.exportPrivateKeys.tr();
    final width = isMobile ? double.infinity : 187.0;
    final height = isMobile ? 52.0 : 40.0;

    return UiPrimaryButton(
      onPressed: () => onViewPrivateKeysPressed(context),
      width: width,
      height: height,
      text: text,
      textStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: theme.custom.defaultGradientButtonTextColor,
      ),
    );
  }
}
