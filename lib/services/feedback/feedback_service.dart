import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:web_dex/services/feedback/feedback_provider.dart';
import 'package:web_dex/services/feedback/providers/cloudflare_feedback_provider.dart';
import 'package:web_dex/services/feedback/providers/debug_console_feedback_provider.dart';
import 'package:web_dex/services/feedback/providers/trello_feedback_provider.dart';

export 'feedback_ui_extension.dart';

/// Service that handles user feedback submission
class FeedbackService {
  final FeedbackProvider provider;

  const FeedbackService({required this.provider});

  /// Creates a FeedbackService instance with the first available provider.
  static FeedbackService? create() {
    final provider = [
      // Try Cloudflare provider first (our default)
      CloudflareFeedbackProvider.fromEnvironment(),
      TrelloFeedbackProvider.fromEnvironment(),
      // Use debug console provider as fallback in debug mode
      if (kDebugMode) DebugConsoleFeedbackProvider(),
    ].firstWhereOrNull((provider) => provider != null && provider.isAvailable);

    return provider != null ? FeedbackService(provider: provider) : null;
  }

  /// Returns true if feedback functionality is available
  bool get isAvailable => provider.isAvailable;

  /// Submits user feedback to the configured provider
  ///
  /// Returns true if feedback was submitted successfully, false otherwise
  Future<bool> handleFeedback(UserFeedback feedback) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final buildMode = kReleaseMode
        ? 'release'
        : kDebugMode
        ? 'debug'
        : (kProfileMode ? 'profile' : 'unknown');

    // Extract contact information from the extras if provided
    String? contactMethod;
    String? contactDetails;
    String? feedbackType;

    if (feedback.extra != null && feedback.extra is JsonMap) {
      final extras = feedback.extra!;
      contactMethod = extras.valueOrNull<String>('contact_method');
      contactDetails = extras.valueOrNull<String>('contact_details');
      feedbackType = extras.valueOrNull<String>('feedback_type');
    }

    final Map<String, dynamic> metadata = {
      if (contactMethod != null) 'contactMethod': contactMethod,
      if (contactDetails != null) 'contactDetails': contactDetails,
      'platform': kIsWeb ? 'web' : 'native',
      'commitHash': const String.fromEnvironment(
        'COMMIT_HASH',
        defaultValue: 'unknown',
      ),
      // We don't want to expose the base URI for native builds as this could
      // contain personal information.
      'baseUrl': kIsWeb ? Uri.base.toString() : null,
      'targetPlatform': defaultTargetPlatform.name,
      ...packageInfo.data,
      'mode': buildMode,
      'timestamp': DateTime.now().toIso8601String(),
      'wallet':
          (await GetIt.I<KomodoDefiSdk>().auth.currentUser)?.toJson() ?? 'None',
    };

    try {
      await provider.submitFeedback(
        description: feedback.text,
        screenshot: feedback.screenshot,
        type: feedbackType ?? 'User Feedback',
        metadata: metadata,
      );
      return true;
    } catch (e) {
      final altAvailable = provider is TrelloFeedbackProvider
          ? CloudflareFeedbackProvider.fromEnvironment().isAvailable
          : provider is CloudflareFeedbackProvider
          ? TrelloFeedbackProvider.hasEnvironmentVariables()
          : true;
      if (kDebugMode && !altAvailable) {
        debugPrint('Failed to submit feedback: $e');
      }
      return false;
    }
  }
}
