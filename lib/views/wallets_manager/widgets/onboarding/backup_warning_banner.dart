import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

/// Backup warning banner that reminds users to backup their seed phrase.
///
/// This banner is based on Figma designs (node 9398:37389).
/// It appears on the main wallet view when the seed phrase has not been
/// backed up and provides a direct action to start the backup flow.
class BackupWarningBanner extends StatelessWidget {
  const BackupWarningBanner({
    required this.onBackupTap,
    this.onDismiss,
    super.key,
  });

  final VoidCallback onBackupTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B00).withOpacity(0.1),
            const Color(0xFFFF6B00).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B00), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF6B00),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.backupBannerTitle.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          UiPrimaryButton(
            onPressed: onBackupTap,
            text: LocaleKeys.backupBannerAction.tr(),
            height: 38,
            textStyle: const TextStyle(fontSize: 12),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: const Color(0xFF797B89),
            ),
          ],
        ],
      ),
    );
  }
}
