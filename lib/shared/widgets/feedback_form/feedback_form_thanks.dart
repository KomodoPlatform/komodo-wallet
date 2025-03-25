import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/feedback/feedback_service.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';

// TODO: Repurpose this widget to show a thank you message after feedback is.
// This code is no longer used since the feedback form is now handled by the
// `feedback` package.
class FeedbackFormThanks extends StatelessWidget {
  const FeedbackFormThanks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('feedback-thanks'),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(18.0)),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            '$assetsPath/logo/komodian_thanks.png',
            height: 162,
            width: 169,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Text(LocaleKeys.feedbackFormThanksTitle.tr(),
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              LocaleKeys.feedbackFormDescription.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 21.0),
            child: UiLightButton(
              key: const Key('feedback-add-more-button'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              text: LocaleKeys.addMoreFeedback.tr(),
              onPressed: () => context.showFeedback(),
            ),
          ),
        ],
      ),
    );
  }
}
