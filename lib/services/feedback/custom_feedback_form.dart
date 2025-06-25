import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/constants.dart';

/// A data type holding user feedback consisting of a feedback type and free-form text
class CustomFeedback {
  CustomFeedback({
    this.feedbackType,
    this.feedbackText,
    this.contactMethod,
    this.contactDetails,
  });

  FeedbackType? feedbackType;
  String? feedbackText;
  ContactMethod? contactMethod;
  String? contactDetails;

  @override
  String toString() {
    return {
      'feedback_type': feedbackType.toString(),
      'feedback_text': feedbackText,
      'contact_method': contactMethod?.name,
      'contact_details': contactDetails,
    }.toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'feedback_type': feedbackType.toString(),
      'feedback_text': feedbackText,
      'contact_method': contactMethod?.name,
      'contact_details': contactDetails,
    };
  }
}

/// What type of feedback the user wants to provide.
enum FeedbackType {
  bugReport,
  featureRequest,
  support,
  other;

  // TODO: Localisation
  String get description {
    switch (this) {
      case bugReport:
        return 'Bug Report';
      case featureRequest:
        return 'Feature Request';
      case support:
        return 'Support Request';
      case other:
        return 'Other';
    }
  }
}

/// A form that prompts the user for the type of feedback they want to give and free form text feedback.
/// The submit button is disabled until the user provides the feedback type. All other fields are optional.
class CustomFeedbackForm extends StatefulWidget {
  const CustomFeedbackForm({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  static FeedbackBuilder get feedbackBuilder =>
      (context, onSubmit, scrollController) => CustomFeedbackForm(
        onSubmit: onSubmit,
        scrollController: scrollController,
      );

  @override
  State<CustomFeedbackForm> createState() => _CustomFeedbackFormState();
}

// TODO: Refactor into a bloc and show validation errors.
class _CustomFeedbackFormState extends State<CustomFeedbackForm> {
  final CustomFeedback _customFeedback = CustomFeedback();
  String? _contactError;
  String? _feedbackError;
  bool _isLoading = false;

  /// Determines if the feedback form is valid and can be submitted
  bool isFormValid() {
    // Basic check: feedback type must be provided and form must not be loading
    bool isValid = _customFeedback.feedbackType != null && !_isLoading;

    // Contact details validation: if either contact method or details is provided,
    // then both must be provided
    bool hasContactMethod = _customFeedback.contactMethod != null;
    bool hasContactDetails =
        _customFeedback.contactDetails != null &&
        _customFeedback.contactDetails!.trim().isNotEmpty;

    _contactError = null;
    _feedbackError = null;
    if (_customFeedback.feedbackType == FeedbackType.support) {
      if (!hasContactMethod || !hasContactDetails) {
        isValid = false;
        _contactError = LocaleKeys.contactRequiredError.tr();
      }
    } else {
      if ((hasContactMethod && !hasContactDetails) ||
          (!hasContactMethod && hasContactDetails)) {
        isValid = false;
        _contactError = LocaleKeys.contactRequiredError.tr();
      }
    }
    if (isValid &&
        _customFeedback.contactMethod == ContactMethod.email &&
        hasContactDetails &&
        !_isValidEmail(_customFeedback.contactDetails!.trim())) {
      isValid = false;
      _contactError = LocaleKeys.emailValidatorError.tr();
    }

    final feedbackText = _customFeedback.feedbackText?.trim() ?? '';
    if (isValid && feedbackText.isEmpty) {
      isValid = false;
      _feedbackError = LocaleKeys.feedbackValidatorEmptyError.tr();
    } else if (isValid && feedbackText.length > feedbackMaxLength) {
      isValid = false;
      _feedbackError = LocaleKeys.feedbackValidatorMaxLengthError.tr(
        args: [feedbackMaxLength.toString()],
      );
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formValid = isFormValid();

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (widget.scrollController != null)
                const FeedbackSheetDragHandle(),
              ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  widget.scrollController != null ? 20 : 16,
                  16,
                  0,
                ),
                children: [
                  Text(
                    'What kind of feedback do you want to give?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<FeedbackType>(
                    isExpanded: true,
                    value: _customFeedback.feedbackType,
                    items: FeedbackType.values
                        .map(
                          (type) => DropdownMenuItem<FeedbackType>(
                            value: type,

                            // TODO: l10n
                            child: Text(type.description),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (feedbackType) => setState(
                            () => _customFeedback.feedbackType = feedbackType,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please describe your feedback:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    maxLength: feedbackMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(feedbackMaxLength),
                    ],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Enter your feedback here...',
                      errorText: _feedbackError,
                    ),
                    onChanged: (newFeedback) => setState(
                      () => _customFeedback.feedbackText = newFeedback,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _customFeedback.feedbackType == FeedbackType.support
                        ? "How can we contact you?"
                        : "How can we contact you? (Optional)",
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
                          value: _customFeedback.contactMethod,
                          hint: const Text('Select'),
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
                          onChanged: _isLoading
                              ? null
                              : (contactMethod) => setState(
                                  () => _customFeedback.contactMethod =
                                      contactMethod,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: _getContactHint(
                              _customFeedback.contactMethod,
                            ),
                          ),
                          onChanged: (newContactDetails) {
                            setState(() {
                              _customFeedback.contactDetails =
                                  newContactDetails;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_contactError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _contactError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
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
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              TextButton(
                onPressed: formValid ? () => _submitFeedback() : null,
                child: const Text('SUBMIT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitFeedback() {
    if (!isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _feedbackError ??
                _contactError ??
                LocaleKeys.contactRequiredError.tr(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Call the onSubmit callback provided by BetterFeedback
    widget
        .onSubmit(
          _customFeedback.feedbackText ?? '',
          extras: _customFeedback.toMap(),
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
  }

  bool _isValidEmail(String email) {
    return emailRegex.hasMatch(email);
  }

  String _getContactHint(ContactMethod? method) {
    switch (method) {
      case ContactMethod.discord:
        return 'Your Discord username';
      case ContactMethod.matrix:
        return 'Your Matrix ID';
      case ContactMethod.telegram:
        return 'Your Telegram username';
      case ContactMethod.email:
        return 'Your email address';
      default:
        return 'Enter your contact details';
    }
  }
}

/// Contact methods available for feedback follow-up
enum ContactMethod {
  discord,
  matrix,
  telegram,
  email;

  String get label {
    switch (this) {
      case discord:
        return 'Discord';
      case matrix:
        return 'Matrix';
      case telegram:
        return 'Telegram';
      case email:
        return 'Email';
    }
  }
}
