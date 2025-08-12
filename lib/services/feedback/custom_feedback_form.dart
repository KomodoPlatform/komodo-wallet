import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/feedback/feedback_models.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/views/support/missing_coins_dialog.dart';

/// A form that prompts the user for feedback using BLoC for state management.
class CustomFeedbackForm extends StatelessWidget {
  const CustomFeedbackForm({
    super.key,
    required this.scrollController,
  });

  final ScrollController? scrollController;

  static FeedbackBuilder get feedbackBuilder =>
      (context, onSubmit, scrollController) => BlocProvider(
            create: (_) => FeedbackFormBloc(onSubmit),
            child: CustomFeedbackForm(scrollController: scrollController),
          );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedbackFormBloc, FeedbackFormState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final isLoading = state.status == FeedbackFormStatus.submitting;
        final formValid = state.isValid && !isLoading;
        return Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (scrollController != null)
                      const FeedbackSheetDragHandle(),
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        scrollController != null ? 20 : 16,
                        16,
                        0,
                      ),
                      children: [
                        Text(
                          'What kind of feedback do you want to give?',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<FeedbackType>(
                          isExpanded: true,
                          value: state.feedbackType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a feedback type';
                            }
                            return null;
                          },
                          items: FeedbackType.values
                              .map(
                                (type) => DropdownMenuItem<FeedbackType>(
                                  value: type,
                                  child: Text(type.description),
                                ),
                              )
                              .toList(),
                          onChanged: isLoading
                              ? null
                              : (feedbackType) {
                                  if (feedbackType ==
                                      FeedbackType.missingCoins) {
                                    showMissingCoinsDialog(context);
                                  }
                                  context.read<FeedbackFormBloc>().add(
                                      FeedbackFormTypeChanged(feedbackType));
                                },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please describe your feedback:',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        UiTextFormField(
                          maxLength: feedbackMaxLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          enabled: !isLoading,
                          autofocus: true,
                          hintText: 'Enter your feedback here...',
                          errorText: state.feedbackTextError,
                          validationMode: InputValidationMode.eager,
                          onChanged: (value) => context
                              .read<FeedbackFormBloc>()
                              .add(FeedbackFormMessageChanged(value ?? '')),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.feedbackType == FeedbackType.support ||
                                  state.feedbackType ==
                                      FeedbackType.missingCoins
                              ? 'How can we contact you?'
                              : 'How can we contact you? (Optional)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130,
                              child: DropdownButtonFormField<ContactMethod>(
                                isExpanded: true,
                                value: state.contactMethod,
                                hint: const Text('Select'),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: ContactMethod.values
                                    .map(
                                      (method) =>
                                          DropdownMenuItem<ContactMethod>(
                                        value: method,
                                        child: Text(method.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isLoading
                                    ? null
                                    : (method) => context
                                        .read<FeedbackFormBloc>()
                                        .add(FeedbackFormContactMethodChanged(
                                            method)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: UiTextFormField(
                                enabled: !isLoading,
                                maxLength: contactDetailsMaxLength,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                hintText: _getContactHint(state.contactMethod),
                                errorText: state.contactDetailsError,
                                validationMode: InputValidationMode.eager,
                                onChanged: (value) => context
                                    .read<FeedbackFormBloc>()
                                    .add(FeedbackFormContactDetailsChanged(
                                        value ?? '')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      ),
                    TextButton(
                      onPressed: formValid
                          ? () => context
                              .read<FeedbackFormBloc>()
                              .add(const FeedbackFormSubmitted())
                          : null,
                      child: const Text('SUBMIT'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _getContactHint(ContactMethod? method) {
  switch (method) {
    case ContactMethod.discord:
      return 'Discord username (e.g., username123)';
    case ContactMethod.matrix:
      return 'Matrix ID (e.g., @user:matrix.org)';
    case ContactMethod.telegram:
      return 'Telegram username (e.g., @username)';
    case ContactMethod.email:
      return 'Your email address';
    default:
      return 'Enter your contact details';
  }
}
