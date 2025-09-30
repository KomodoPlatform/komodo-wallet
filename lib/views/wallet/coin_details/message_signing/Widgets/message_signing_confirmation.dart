import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/message_signing/message_signing_bloc.dart';
import 'package:web_dex/bloc/message_signing/message_signing_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class MessageSigningConfirmationCard extends StatelessWidget {
  final ThemeData theme;
  final String message;
  final String coinAbbr;
  final bool understood;
  final VoidCallback onCancel;
  final ValueChanged<bool> onUnderstoodChanged;

  const MessageSigningConfirmationCard({
    super.key,
    required this.theme,
    required this.message,
    required this.coinAbbr,
    required this.understood,
    required this.onCancel,
    required this.onUnderstoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = context.read<MessageSigningBloc>().state.selected;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      color: theme.colorScheme.surface.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.confirmMessageSigning.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStyledSection(context,
                content: selected?.address ?? '',
                icon: Icons.account_balance_wallet,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                showTopBorder: true),
            _buildStyledSection(context,
                content: message,
                icon: Icons.chat_bubble_outline,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                showTopBorder: false),
            const SizedBox(height: 24),
            Text(
              LocaleKeys.messageSigningWarning.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            UiCheckbox(
              value: understood,
              onChanged: (val) => onUnderstoodChanged(val),
              text: LocaleKeys.messageSigningCheckboxText.tr(),
              textColor: theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: UiSecondaryButton(
                    text: LocaleKeys.cancel.tr(),
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UiPrimaryButton(
                    text: LocaleKeys.confirm.tr(),
                    onPressed: understood
                        ? () {
                            context.read<MessageSigningBloc>().add(
                                  MessageSigningFormSubmitted(
                                    message: message,
                                    coinAbbr: coinAbbr,
                                  ),
                                );
                            onCancel();
                          }
                        : null,
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
