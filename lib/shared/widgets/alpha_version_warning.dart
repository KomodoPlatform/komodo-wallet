import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/shared/widgets/send_analytics_checkbox.dart';

class AlphaVersionWarning extends StatelessWidget {
  const AlphaVersionWarning({Key? key, required this.onAccept})
      : super(key: key);
  final Function() onAccept;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final ScrollController scrollController = ScrollController();
    return SingleChildScrollView(
      controller: scrollController,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isRunningAsChromeExtension())
              Image.asset(
                '$assetsPath/logo/alpha_warning.png',
                filterQuality: FilterQuality.high,
              ),
            Padding(
              padding:
                  EdgeInsets.only(top: isRunningAsChromeExtension() ? 0 : 25.0),
              child: Text(
                LocaleKeys.alphaVersionWarningTitle.tr(),
                style: appTheme.textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                LocaleKeys.alphaVersionWarningDescription.tr(),
                style: appTheme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.justify,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: SendAnalyticsCheckbox(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: UiPrimaryButton(
                key: const Key('accept-alpha-warning-button'),
                height: 30,
                text: LocaleKeys.accept.tr(),
                onPressed: () {
                  onAccept();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
