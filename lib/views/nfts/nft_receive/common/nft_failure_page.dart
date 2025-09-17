import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class NftReceiveFailurePage extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const NftReceiveFailurePage({
    super.key,
    required this.message,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    final textTheme = Theme.of(context).extension<TextThemeExtension>();
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
              style: textTheme?.bodyS,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: UiPrimaryButton(
            text: LocaleKeys.retryButtonText.tr(),
            width: 324,
            onPressed: onReload,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
