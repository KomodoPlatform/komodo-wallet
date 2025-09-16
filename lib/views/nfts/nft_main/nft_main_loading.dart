import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class NftMainLoading extends StatelessWidget {
  const NftMainLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorSchemeExtension colorScheme =
        Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 50, bottom: 15),
          alignment: Alignment.center,
          child: Text(
            LocaleKeys.loadingNfts.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodyMBold.copyWith(color: colorScheme.secondary),
          ),
        ),
        const UiSpinnerList()
      ],
    );
  }
}
