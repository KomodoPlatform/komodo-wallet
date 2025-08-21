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
  const CustomFeedbackForm({super.key, required this.scrollController});

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
        // final theme = Theme.of(context); // Unused here; section widgets read theme directly
        final isLoading = state.status == FeedbackFormStatus.submitting;
        final formValid = state.isValid && !isLoading;
        final submitLabel = LocaleKeys.send.tr();

        final requiresContact =
            state.feedbackType == FeedbackType.support ||
                state.feedbackType == FeedbackType.missingCoins;

        return Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (scrollController != null)
                      const FeedbackSheetDragHandle(),
                    _ScrollableFormContent(
                      scrollController: scrollController,
                      topPadding: scrollController != null ? 20.0 : 0.0,
                      children: [
                        _SectionTitle(
                          title: LocaleKeys.feedbackFormKindQuestion.tr(),
                        ),
                        const SizedBox(height: 4),
                        _FeedbackTypeDropdown(
                          isLoading: isLoading,
                          selected: state.feedbackType,
                        ),

                        const SizedBox(height: 8),
                        _MessageField(
                          isLoading: isLoading,
                          errorText: state.feedbackTextError,
                        ),

                        const SizedBox(height: 8),
                        _SectionTitle(
                          title: requiresContact
                              ? LocaleKeys.feedbackFormContactRequired.tr()
                              : LocaleKeys.feedbackFormContactOptional.tr(),
                        ),
                        const SizedBox(height: 4),
                        if (!requiresContact)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: UiCheckbox(
                              value: state.contactOptOut,
                              text: LocaleKeys.feedbackFormNoContactOptOut.tr(),
                              onChanged: isLoading
                                  ? null
                                  : (value) => context
                                      .read<FeedbackFormBloc>()
                                      .add(FeedbackFormContactOptOutToggled(
                                          value)),
                            ),
                          ),
                        _ContactRow(
                          isLoading: isLoading,
                          selectedMethod: state.contactMethod,
                          contactError: state.contactDetailsError,
                          disabled: state.contactOptOut && !requiresContact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _ActionsRow(
                  isLoading: isLoading,
                  isFormValid: formValid,
                  submitLabel: submitLabel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrollableFormContent extends StatelessWidget {
  const _ScrollableFormContent({
    required this.scrollController,
    required this.topPadding,
    required this.children,
  });

  final ScrollController? scrollController;
  final double topPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          children: children,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(title, style: theme.textTheme.titleMedium);
  }
}

class _FeedbackTypeDropdown extends StatelessWidget {
  const _FeedbackTypeDropdown({
    required this.isLoading,
    required this.selected,
  });

  final bool isLoading;
  final FeedbackType? selected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FeedbackType>(
      autofocus: true,
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) =>
          value == null ? 'Please select a feedback type' : null,
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
              if (feedbackType == FeedbackType.missingCoins) {
                showMissingCoinsDialog(context);
              }
              context.read<FeedbackFormBloc>().add(
                FeedbackFormTypeChanged(feedbackType),
              );
            },
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({required this.isLoading, required this.errorText});

  final bool isLoading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return UiTextFormField(
      maxLines: null,
      maxLength: feedbackMaxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      enabled: !isLoading,
      labelText: LocaleKeys.feedbackFormDescribeTitle.tr(),
      hintText: LocaleKeys.feedbackFormMessageHint.tr(),
      errorText: errorText,
      validationMode: InputValidationMode.eager,
      onChanged: (value) => context.read<FeedbackFormBloc>().add(
        FeedbackFormMessageChanged(value ?? ''),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.isLoading,
    required this.selectedMethod,
    required this.contactError,
    this.disabled = false,
  });

  final bool isLoading;
  final ContactMethod? selectedMethod;
  final String? contactError;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final inputsEnabled = !isLoading && !disabled;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: DropdownButtonFormField<ContactMethod>(
            isExpanded: true,
            initialValue: selectedMethod,
            hint: Text(LocaleKeys.feedbackFormSelectContactMethod.tr()),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ContactMethod.values
                .map(
                  (method) => DropdownMenuItem<ContactMethod>(
                    value: method,
                    child: Text(method.label),
                  ),
                )
                .toList(),
            onChanged: inputsEnabled
                ? (method) => context.read<FeedbackFormBloc>().add(
                      FeedbackFormContactMethodChanged(method),
                    )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: UiTextFormField(
            enabled: inputsEnabled,
            maxLength: contactDetailsMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            hintText: _getContactHint(selectedMethod).tr(),
            errorText: contactError,
            validationMode: InputValidationMode.eager,
            onChanged: (value) => context.read<FeedbackFormBloc>().add(
              FeedbackFormContactDetailsChanged(value ?? ''),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isLoading,
    required this.isFormValid,
    required this.submitLabel,
  });

  final bool isLoading;
  final bool isFormValid;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onPressed: isLoading ? null : () => BetterFeedback.of(context).hide(),
          child: Text(LocaleKeys.cancel.tr()),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: isFormValid
              ? () => context.read<FeedbackFormBloc>().add(
                  const FeedbackFormSubmitted(),
                )
              : null,
          label: Text(submitLabel),
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

String _getContactHint(ContactMethod? method) {
  switch (method) {
    case ContactMethod.discord:
      return LocaleKeys.feedbackFormDiscordHint;
    case ContactMethod.matrix:
      return LocaleKeys.feedbackFormMatrixHint;
    case ContactMethod.telegram:
      return LocaleKeys.feedbackFormTelegramHint;
    case ContactMethod.email:
      return LocaleKeys.feedbackFormEmailHint;
    default:
      return LocaleKeys.feedbackFormContactHint;
  }
}
