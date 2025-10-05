import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Seed backup warning screen that educates users about seed phrase security
/// before showing them the actual seed phrase.
///
/// This screen is based on Figma designs (node 8994:12153, 9207:1546).
/// It displays three critical warnings about seed phrase security and
/// requires users to acknowledge before proceeding.
class SeedBackupWarningScreen extends StatelessWidget {
  const SeedBackupWarningScreen({
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return ResponsiveOnboardingScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelConfirmation(context),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: ResponsiveLayout.onboardingBackgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        _buildIllustration(),
                        const SizedBox(height: 24),
                        _buildEyesOnlyBadge(),
                        const SizedBox(height: 12),
                        Text(
                          LocaleKeys.onboardingSeedBackupWarningTitle.tr(),
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildWarningBox(
                          icon: Icons.key,
                          text: LocaleKeys.onboardingSeedBackupWarning1.tr(),
                        ),
                        const SizedBox(height: 16),
                        _buildWarningBox(
                          icon: Icons.edit_note,
                          text: LocaleKeys.onboardingSeedBackupWarning2.tr(),
                        ),
                        const SizedBox(height: 16),
                        _buildWarningBox(
                          icon: Icons.warning_amber,
                          text: LocaleKeys.onboardingSeedBackupWarning3.tr(),
                          isWarning: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                verticalPadding,
              ),
              child: UiPrimaryButton(
                onPressed: onContinue,
                text: LocaleKeys.continueText.tr(),
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.security, size: 80, color: Color(0xFF3D77E9)),
      ),
    );
  }

  Widget _buildEyesOnlyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, size: 16, color: Color(0xFFADAFC4)),
          const SizedBox(width: 8),
          Text(
            LocaleKeys.onboardingSeedBackupForYourEyesOnly.tr(),
            style: const TextStyle(color: Color(0xFFADAFC4)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox({
    required IconData icon,
    required String text,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(13),
        border: isWarning
            ? Border.all(color: const Color(0xFFFF6B00), width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isWarning
                ? const Color(0xFFFF6B00)
                : const Color(0xFF3D77E9),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFADAFC4),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.cancelWalletCreationTitle.tr()),
        content: Text(LocaleKeys.cancelWalletCreationMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          UiPrimaryButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel();
            },
            text: LocaleKeys.confirm.tr(),
          ),
        ],
      ),
    );
  }
}
