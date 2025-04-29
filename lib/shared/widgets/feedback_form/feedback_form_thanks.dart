import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_bloc.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';

class FeedbackFormThanks extends StatelessWidget {
  const FeedbackFormThanks({Key? key}) : super(key: key);

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
            child: Text(
              LocaleKeys.feedbackFormThanksTitle.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              LocaleKeys.feedbackFormThanksDescription.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 21.0),
            child: UiLightButton(
                key: const Key('feedback-add-more-button'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                text: LocaleKeys.addMoreFeedback.tr(),
                onPressed: () {
                  context
                      .read<FeedbackFormBloc>()
                      .add(const FeedbackFormReset());
                }),
          ),
        ],
      ),
    );
  }
}
