import 'package:equatable/equatable.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

abstract class FeedbackFormState extends Equatable {
  const FeedbackFormState();
  @override
  List<Object?> get props => [];
}

class FeedbackFormInitialState extends FeedbackFormState {
  const FeedbackFormInitialState();
}

class FeedbackFormSuccessState extends FeedbackFormState {
  const FeedbackFormSuccessState();
}

class FeedbackFormFailureState extends FeedbackFormState {
  const FeedbackFormFailureState(
      {this.emailError, this.messageError, this.sendingError});
  final BaseError? emailError;
  final BaseError? messageError;
  final BaseError? sendingError;

  @override
  List<Object?> get props => [emailError, messageError, sendingError];
}

class FeedbackFormSendingState extends FeedbackFormState {
  const FeedbackFormSendingState();
}
