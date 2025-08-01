part of 'feedback_form_bloc.dart';

sealed class FeedbackFormEvent extends Equatable {
  const FeedbackFormEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackFormTypeChanged extends FeedbackFormEvent {
  const FeedbackFormTypeChanged(this.type);

  final FeedbackType? type;

  @override
  List<Object?> get props => [type];
}

class FeedbackFormMessageChanged extends FeedbackFormEvent {
  const FeedbackFormMessageChanged(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FeedbackFormContactMethodChanged extends FeedbackFormEvent {
  const FeedbackFormContactMethodChanged(this.method);

  final ContactMethod? method;

  @override
  List<Object?> get props => [method];
}

class FeedbackFormContactDetailsChanged extends FeedbackFormEvent {
  const FeedbackFormContactDetailsChanged(this.details);

  final String details;

  @override
  List<Object?> get props => [details];
}

class FeedbackFormSubmitted extends FeedbackFormEvent {
  const FeedbackFormSubmitted();
}
