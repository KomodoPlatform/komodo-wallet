import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class BitrefillButtonView extends StatelessWidget {
  const BitrefillButtonView({
    super.key,
    required this.onPressed,
  });

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return UiPrimaryButton.flexible(
      prefix: SvgPicture.asset(
        '$assetsPath/others/bitrefill_logo.svg',
      ),
      textStyle: themeData.textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: themeData.colorScheme.tertiary,
      onPressed: onPressed,
      text: LocaleKeys.spend.tr(),
    );
  }
}
