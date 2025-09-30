import 'dart:typed_data';

/// Abstract interface for feedback providers
abstract class FeedbackProvider {
  /// Submits feedback to the provider
  Future<void> submitFeedback({
    required String description,
    required Uint8List screenshot,
    required String type,
    required Map<String, dynamic> metadata,
  });

  /// Returns true if this provider is configured and available for use
  bool get isAvailable;
}
