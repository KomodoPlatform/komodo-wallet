import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';

class BitrefillTransactionCompletedDialog extends StatelessWidget {
  const BitrefillTransactionCompletedDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onViewInvoicePressed,
    this.onPositiveButtonPressed,
  });

  final String title;
  final String message;
  final VoidCallback? onPositiveButtonPressed;
  final VoidCallback onViewInvoicePressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(message),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Expanded(
            //   child: UiPrimaryButton(
            //     height: isMobile ? 52 : 40,
            //     prefix: Container(
            //       padding: const EdgeInsets.only(right: 14),
            //       child: SvgPicture.asset(
            //         '$assetsPath/others/bitrefill_logo.svg',
            //       ),
            //     ),
            //     textStyle: themeData.textTheme.labelLarge
            //         ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            //     backgroundColor: themeData.colorScheme.tertiary,
            //     onPressed: onViewInvoicePressed,
            //     text: LocaleKeys.viewInvoice.tr(),
            //   ),
            // ),
            // const SizedBox(width: 10),
            Expanded(
              child: UiPrimaryButton(
                height: isMobile ? 52 : 40,
                prefix: Container(
                  padding: const EdgeInsets.only(right: 14),
                  child: SvgPicture.asset(
                    '$assetsPath/others/tick.svg',
                    height: 16,
                  ),
                ),
                textStyle: themeData.textTheme.labelLarge
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                backgroundColor: themeData.colorScheme.tertiary,
                onPressed: onPositiveButtonPressed ??
                    () => Navigator.of(context).pop(),
                text: LocaleKeys.ok.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
