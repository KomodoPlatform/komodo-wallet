import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_bloc.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_repo.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/feedback_form/feedback_form.dart';
import 'package:web_dex/shared/widgets/feedback_form/feedback_form_thanks.dart';

class FeedbackFormWrapper extends StatelessWidget {
  const FeedbackFormWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            FeedbackFormBloc(feedbackFormRepo: FeedbackFormRepo()),
        child: BlocBuilder<FeedbackFormBloc, FeedbackFormState>(
          builder: (context, state) {
            if (state is FeedbackFormSuccessState) {
              return const FeedbackFormThanks();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.feedbackFormTitle.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    LocaleKeys.feedbackFormDescription.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: FeedbackForm(formState: state),
                ),
              ],
            );
          },
        ));
  }
}
