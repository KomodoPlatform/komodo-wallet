class FeedbackRequest {
  const FeedbackRequest({
    required this.email,
    required this.message,
  });

  final String email;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'message': message,
      };
}
