import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_bloc.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_event.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({Key? key, required this.formState}) : super(key: key);
  final FeedbackFormState formState;

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final FeedbackFormState state = widget.formState;
    final bool isSending = state is FeedbackFormSendingState;
    BaseError? emailError;
    BaseError? messageError;
    BaseError? sendingError;
    if (state is FeedbackFormFailureState) {
      emailError = state.emailError;
      messageError = state.messageError;
      sendingError = state.sendingError;
    }
    return Form(
      key: const Key('feedback-form'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiTextFormField(
            key: const Key('feedback-email-field'),
            controller: _emailController,
            textInputAction: TextInputAction.next,
            hintText: LocaleKeys.email.tr(),
            keyboardType: TextInputType.emailAddress,
            validationMode: InputValidationMode.eager,
            validator: (_) => emailError?.message,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: UiTextFormField(
              key: const Key('feedback-message-field'),
              controller: _messageController,
              hintText: LocaleKeys.yourFeedback.tr(),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              maxLength: 500,
              counterText: '',
              textInputAction: TextInputAction.send,
              validationMode: InputValidationMode.eager,
              validator: (_) => messageError?.message,
            ),
          ),
          if (sendingError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                sendingError.message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: UiPrimaryButton(
              key: const Key('feedback-submit-button'),
              text: LocaleKeys.sendFeedback.tr(),
              prefix: isSending
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: UiSpinner(),
                    )
                  : null,
              onPressed: isSending
                  ? null
                  : () {
                      context
                          .read<FeedbackFormBloc>()
                          .add(FeedbackFormSubmitted(
                            email: _emailController.text,
                            message: _messageController.text,
                          ));
                    },
            ),
          )
        ],
      ),
    );
  }
}
