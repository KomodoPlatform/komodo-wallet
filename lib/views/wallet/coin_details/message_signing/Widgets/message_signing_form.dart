import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/message_signing/message_signing_bloc.dart';
import 'package:web_dex/bloc/message_signing/message_signing_event.dart';
import 'package:web_dex/bloc/message_signing/message_signing_state.dart';
import 'package:web_dex/model/coin.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class MessageSigningForm extends StatelessWidget {
  final MessageSigningState state;
  final ThemeData theme;
  final Coin coin;
  final Asset asset;
  final TextEditingController messageController;
  final VoidCallback onSignPressed;

  const MessageSigningForm({
    super.key,
    required this.state,
    required this.theme,
    required this.coin,
    required this.asset,
    required this.messageController,
    required this.onSignPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectEnabled = state.addresses.length > 1;
    final isSubmitting = state.status == MessageSigningStatus.submitting;
    final hasError = state.status == MessageSigningStatus.failure &&
        state.errorMessage != null;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.signingAddress.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (hasError)
              ErrorMessageWidget(errorMessage: state.errorMessage!)
            else if (state.addresses.isEmpty)
              const SizedBox()
            else
              Builder(
                builder: (context) {
                  final selected = state.selected ?? state.addresses.first;
                  return AddressSelectInput(
                    addresses: state.addresses,
                    selectedAddress: selected,
                    onAddressSelected: isSelectEnabled
                        ? (address) {
                            if (address != null) {
                              context.read<MessageSigningBloc>().add(
                                    MessageSigningAddressSelected(address),
                                  );
                            }
                          }
                        : null,
                    assetName: asset.id.name,
                  );
                },
              ),
            const SizedBox(height: 20),
            Text(
              LocaleKeys.messageToSign.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: EnhancedMessageInput(
                    controller: messageController,
                    hintText: LocaleKeys.enterMessage.tr(),
                    showCopyButton: true,
                    onCopyPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        messageController.text = data!.text!;
                      }
                    },
                    trailingIcon: UiPrimaryButton.flexible(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final result =
                                  await QrCodeReaderOverlay.show(context);
                              if (result != null) {
                                messageController.text = result;
                              }
                            },
                      child: const Icon(Icons.qr_code_scanner, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: UiPrimaryButton.flexible(
                text: LocaleKeys.signMessageButton.tr(),
                onPressed: isSubmitting ? null : onSignPressed,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorMessageWidget extends StatelessWidget {
  final String errorMessage;

  const ErrorMessageWidget({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        errorMessage,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}

class EnhancedMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool showCopyButton;
  final VoidCallback? onCopyPressed;
  final Widget? trailingIcon;

  const EnhancedMessageInput({
    required this.controller,
    required this.hintText,
    this.showCopyButton = false,
    this.onCopyPressed,
    this.trailingIcon,
    super.key,
  });

  @override
  State<EnhancedMessageInput> createState() => _EnhancedMessageInputState();
}

class _EnhancedMessageInputState extends State<EnhancedMessageInput> {
  late int charCount = widget.controller.text.length;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCharCount);
  }

  void _updateCharCount() =>
      setState(() => charCount = widget.controller.text.length);

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      filled: true,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      letterSpacing: 0.5,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    cursorColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.trailingIcon != null) widget.trailingIcon!,
                      if (widget.showCopyButton)
                        UiPrimaryButton.flexible(
                          padding: const EdgeInsets.all(8),
                          onPressed: widget.onCopyPressed,
                          child: const Icon(Icons.content_paste, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$charCount characters',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}