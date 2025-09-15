import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class NftTxnFailurePage extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const NftTxnFailurePage({
    super.key,
    required this.message,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.secondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 15.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ext!.error, width: 6),
            ),
            child: Icon(Icons.close_rounded, size: 66, color: ext.error),
          ),
        ),
        Center(
          child: Text(
            LocaleKeys.loadingError.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: ext.error),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 324,
            decoration: BoxDecoration(
              color: theme.custom.subCardBackgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText.rich(
              TextSpan(text: message),
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: UiPrimaryButton(
            text: LocaleKeys.tryAgainButton.tr(),
            width: 324,
            onPressed: onReload,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
