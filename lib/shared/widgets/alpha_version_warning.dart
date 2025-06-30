import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

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
            Image.asset(
              '$assetsPath/logo/alpha_warning.png',
              filterQuality: FilterQuality.high,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
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
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: UiPrimaryButton(
                key: const Key('accept-alpha-warning-button'),
                height: 30,
                text: LocaleKeys.accept.tr(),
                onPressed: () {
                  onAccept();
                  context.read<AnalyticsBloc>().add(
                        const AnalyticsActivateEvent(),
                      );
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
