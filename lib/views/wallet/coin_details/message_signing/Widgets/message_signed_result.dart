import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';

class MessageSignedResult extends StatelessWidget {
  final ThemeData theme;
  final PubkeyInfo selected;
  final String message;
  final String signedMessage;

  const MessageSignedResult({
    super.key,
    required this.theme,
    required this.selected,
    required this.message,
    required this.signedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      color: theme.colorScheme.surface.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              LocaleKeys.messageSigned.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: theme.colorScheme.primary, width: 4),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 66,
                color: theme.colorScheme.primary,
              ),
            ),
            Center(
              child: Text(
                LocaleKeys.addressLabel.tr(args: [selected.address]),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildStyledSection(context,
                content: message,
                icon: Icons.chat_bubble_outline,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                showTopBorder: true),
            _buildStyledSection(
              context,
              content: signedMessage,
              icon: Icons.vpn_key_outlined,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              showTopBorder: false,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: UiSecondaryButton(
                    text: 'Share',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: signedMessage));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UiPrimaryButton(
                    text: 'Copy',
                    onPressed: () {
                      // TODO: Add share logic
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledSection(
    BuildContext context, {
    required String content,
    required IconData icon,
    required BorderRadius borderRadius,
    bool showTopBorder = true,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border(
          top: showTopBorder
              ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))
              : BorderSide.none,
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          left: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
