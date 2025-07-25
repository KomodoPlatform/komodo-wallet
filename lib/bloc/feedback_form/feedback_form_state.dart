part of 'feedback_form_bloc.dart';

enum FeedbackFormStatus { initial, submitting, success, failure }

class FeedbackFormState extends Equatable {
  const FeedbackFormState({
    this.feedbackType,
    this.feedbackText = '',
    this.feedbackTextError,
    this.contactMethod,
    this.contactDetails = '',
    this.contactDetailsError,
    this.status = FeedbackFormStatus.initial,
    this.errorMessage,
  });

  final FeedbackType? feedbackType;
  final String feedbackText;
  final String? feedbackTextError;
  final ContactMethod? contactMethod;
  final String contactDetails;
  final String? contactDetailsError;
  final FeedbackFormStatus status;
  final String? errorMessage;

  bool get isValid =>
      feedbackType != null &&
      feedbackTextError == null &&
      contactDetailsError == null &&
      feedbackText.trim().isNotEmpty;

  FeedbackFormState copyWith({
    FeedbackType? feedbackType,
    String? feedbackText,
    String? feedbackTextError,
    ContactMethod? contactMethod,
    String? contactDetails,
    String? contactDetailsError,
    FeedbackFormStatus? status,
    String? errorMessage,
  }) {
    return FeedbackFormState(
      feedbackType: feedbackType ?? this.feedbackType,
      feedbackText: feedbackText ?? this.feedbackText,
      feedbackTextError: feedbackTextError,
      contactMethod: contactMethod ?? this.contactMethod,
      contactDetails: contactDetails ?? this.contactDetails,
      contactDetailsError: contactDetailsError,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        feedbackType,
        feedbackText,
        feedbackTextError,
        contactMethod,
        contactDetails,
        contactDetailsError,
        status,
        errorMessage,
      ];
}
