import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_dex/services/feedback/feedback_provider.dart';

class DebugConsoleFeedbackProvider implements FeedbackProvider {
  @override
  bool get isAvailable => true;

  @override
  Future<void> submitFeedback({
    required String description,
    required Uint8List screenshot,
    required String type,
    required Map<String, dynamic> metadata,
  }) async {
    debugPrint('---------------- DEBUG FEEDBACK ----------------');
    debugPrint('Type: $type');
    debugPrint('Description:');
    debugPrint(description);
    debugPrint('\nMetadata:');
    metadata.forEach((key, value) => debugPrint('$key: $value'));
    debugPrint('Screenshot size: ${screenshot.length} bytes');
    debugPrint('---------------------------------------------');
  }
}
