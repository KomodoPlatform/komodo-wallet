abstract class FeedbackFormEvent {
  const FeedbackFormEvent();
}

class FeedbackFormSubmitted extends FeedbackFormEvent {
  const FeedbackFormSubmitted({
    required this.email,
    required this.message,
  });
  final String email;
  final String message;
}

class FeedbackFormReset extends FeedbackFormEvent {
  const FeedbackFormReset();
}
