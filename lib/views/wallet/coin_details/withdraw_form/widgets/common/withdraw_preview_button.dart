import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class PreviewWithdrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSending;
  final String? text;
  final double height;

  const PreviewWithdrawButton({
    required this.onPressed,
    required this.isSending,
    this.text,
    this.height = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: UiPrimaryButton(
        onPressed: onPressed,
        child: isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text ?? LocaleKeys.previewWithdrawal.tr()),
      ),
    );
  }
}