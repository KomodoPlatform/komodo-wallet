import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_dex/app_config/app_config.dart';

import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/extensions/string_extensions.dart';

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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

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
      contactMethod = extras['contact_method'] as String?;
      contactDetails = extras['contact_details'] as String?;
      feedbackType = extras['feedback_type'] as String?;
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
          (await GetIt.I<KomodoDefiSdk>().auth.currentUser)?.toJson() ?? 'None'
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

/// Utility class for formatting feedback descriptions in an agent-friendly way
class FeedbackFormatter {
  /// Creates a properly formatted description for agent review
  static String createAgentFriendlyDescription(
    String description,
    String type,
    Map<String, dynamic> metadata,
  ) {
    final buffer = StringBuffer();

    // Add the pre-formatted description from the form
    buffer.writeln(description);
    buffer.writeln();

    // Technical information section
    buffer.writeln('🔧 TECHNICAL INFORMATION:');
    buffer.writeln('─' * 40);

    // Group related metadata for better readability
    final appInfo = <String, dynamic>{};
    final deviceInfo = <String, dynamic>{};
    final buildInfo = <String, dynamic>{};
    final walletInfo = <String, dynamic>{};

    for (final entry in metadata.entries) {
      switch (entry.key) {
        case 'contactMethod':
        case 'contactDetails':
          // These are already handled in the form-level formatting
          break;
        case 'appName':
        case 'packageName':
        case 'version':
        case 'buildNumber':
          appInfo[entry.key] = entry.value;
          break;
        case 'platform':
        case 'targetPlatform':
        case 'baseUrl':
          deviceInfo[entry.key] = entry.value;
          break;
        case 'mode':
        case 'commitHash':
        case 'timestamp':
          buildInfo[entry.key] = entry.value;
          break;
        case 'wallet':
          walletInfo[entry.key] = entry.value;
          break;
        default:
          deviceInfo[entry.key] = entry.value;
      }
    }

    if (appInfo.isNotEmpty) {
      buffer.writeln('   📱 App Information:');
      appInfo.forEach(
          (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'));
      buffer.writeln();
    }

    if (deviceInfo.isNotEmpty) {
      buffer.writeln('   💻 Device Information:');
      deviceInfo.forEach(
          (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'));
      buffer.writeln();
    }

    if (buildInfo.isNotEmpty) {
      buffer.writeln('   🔨 Build Information:');
      buildInfo.forEach(
          (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'));
      buffer.writeln();
    }

    if (walletInfo.isNotEmpty) {
      buffer.writeln('   👛 Wallet Information:');
      walletInfo.forEach(
          (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'));
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  // Convert camel case to separate words
  static String _formatKey(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ')
        .toCapitalize();
  }

  // ...existing code...
}

/// Implementation of FeedbackProvider that submits feedback to Trello
///
/// The following environment variables must be set using dart-define:
/// TRELLO_API_KEY: Your Trello API key
/// TRELLO_TOKEN: Your Trello API token
/// TRELLO_BOARD_ID: The ID of the Trello board where feedback will be sent
/// TRELLO_LIST_ID: The ID of the Trello list where feedback will be sent

/// The Trello API key can be obtained by going to the Power-Ups console:
/// https://trello.com/power-ups/admin

/// For Komodo Wallet, the Trello API token can be re-generated by going to:
/// https://trello.com/1/authorize?expiration=never&name=Komodo%20Wallet%20Feedback&scope=read,write&response_type=token&key=YOUR_API_KEY
///
/// If you have trouble generating that or if you are setting it up for a fork,
/// there is an option in the power-up console to generate the link.
///
/// The Trello board ID and list ID can be obtained by going to the Trello board
/// and adding `.json` to the end of the URL, doing a search for the board/list
/// name and then copying the `id`.
/// E.g. https://trello.com/c/AbcdXYZ/63-feedback-user-feedback ->
/// https://trello.com/c/AbcdXYZ/63-feedback-user-feedback.json
///
/// The environment variables can be set for the build using the following
/// command for example:
/// flutter build web --dart-define TRELLO_API_KEY=YOUR_KEY_HERE --dart-define TRELLO_TOKEN=YOUR_TOKEN_HERE --dart-define TRELLO_BOARD_ID=YOUR_BOARD_ID_HERE --dart-define TRELLO_LIST_ID=YOUR_LIST_ID_HERE
class TrelloFeedbackProvider implements FeedbackProvider {
  final String apiKey;
  final String token;
  final String boardId;
  final String listId;

  const TrelloFeedbackProvider({
    required this.apiKey,
    required this.token,
    required this.boardId,
    required this.listId,
  });

  static bool hasEnvironmentVariables() {
    final requiredVars = {
      'TRELLO_API_KEY': const String.fromEnvironment('TRELLO_API_KEY'),
      'TRELLO_TOKEN': const String.fromEnvironment('TRELLO_TOKEN'),
      'TRELLO_BOARD_ID': const String.fromEnvironment('TRELLO_BOARD_ID'),
      'TRELLO_LIST_ID': const String.fromEnvironment('TRELLO_LIST_ID'),
    };

    final missingVars =
        requiredVars.entries.where((e) => e.value.isEmpty).toList();

    if (missingVars.isNotEmpty) {
      final altAvailable =
          CloudflareFeedbackProvider.fromEnvironment().isAvailable;
      if (kDebugMode && !altAvailable) {
        debugPrint(
          'Missing required environment variables for Trello feedback provider: ' +
              missingVars.join(', '),
        );
      }
      return false;
    }

    return true;
  }

  /// Creates a TrelloFeedbackProvider instance if all required environment variables are set.
  /// Returns null if any environment variable is missing or empty.
  static TrelloFeedbackProvider? fromEnvironment() {
    if (!hasEnvironmentVariables()) {
      return null;
    }

    return TrelloFeedbackProvider(
      apiKey: const String.fromEnvironment('TRELLO_API_KEY'),
      token: const String.fromEnvironment('TRELLO_TOKEN'),
      boardId: const String.fromEnvironment('TRELLO_BOARD_ID'),
      listId: const String.fromEnvironment('TRELLO_LIST_ID'),
    );
  }

  @override
  bool get isAvailable => hasEnvironmentVariables();

  @override
  Future<void> submitFeedback({
    required String description,
    required Uint8List screenshot,
    required String type,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Create comprehensive formatted description for agents
      final formattedDesc = FeedbackFormatter.createAgentFriendlyDescription(
        description,
        type,
        metadata,
      );

      // 1. Create the card
      final cardResponse = await http.post(
        Uri.parse('https://api.trello.com/1/cards'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'idList': listId,
          'key': apiKey,
          'token': token,
          'name': 'Feedback: $type',
          'desc': formattedDesc,
        }),
      );

      if (cardResponse.statusCode != 200) {
        throw Exception(
          'Failed to create Trello card (${cardResponse.statusCode}): ${cardResponse.body}',
        );
      }

      final cardId = jsonDecode(cardResponse.body)['id'];

      // 2. Attach the screenshot to the card
      final attachmentRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.trello.com/1/cards/$cardId/attachments'),
      );

      attachmentRequest.fields.addAll({'key': apiKey, 'token': token});

      attachmentRequest.files.add(
        http.MultipartFile.fromBytes(
          'file',
          screenshot,
          filename: 'screenshot.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      final attachmentResponse = await attachmentRequest.send();
      final streamedResponse = await http.Response.fromStream(
        attachmentResponse,
      );

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          'Failed to attach screenshot (${streamedResponse.statusCode}): ${streamedResponse.body}',
        );
      }
    } catch (e) {
      final altAvailable =
          CloudflareFeedbackProvider.fromEnvironment().isAvailable;
      if (kDebugMode && !altAvailable) {
        debugPrint('Error in Trello submitFeedback: $e');
      }
      rethrow;
    }
  }
}

/// Implementation of FeedbackProvider that submits feedback to Komodo's
/// internal API.
///
/// The following environment variables must be set using dart-define:
/// FEEDBACK_API_KEY: The API key for the feedback service
/// FEEDBACK_PRODUCTION_URL: The production URL for the feedback API, OR:
/// FEEDBACK_TEST_URL: The test URL for the feedback API to test in debug mode
/// TRELLO_LIST_ID: The ID of the Trello list where feedback will be sent (shared with TrelloFeedbackProvider)
/// TRELLO_BOARD_ID: The ID of the Trello board (shared with TrelloFeedbackProvider)
///
/// This provider is used for submitting feedback to the Cloudflare Worker.
/// You can set up your own feedback backend by using the repository available at:
/// https://github.com/KomodoPlatform/komodo-wallet-feedback-cf-worker
///
/// Example build command:
/// ```
/// flutter build web --dart-define=FEEDBACK_PRODUCTION_URL=https://your-api-url.com --dart-define=FEEDBACK_API_KEY=your_api_key --dart-define=TRELLO_LIST_ID=your_list_id --dart-define=TRELLO_BOARD_ID=your_board_id
/// ```
///
/// Example run command (debugging):
/// ```
/// flutter run --dart-define=FEEDBACK_TEST_URL=https://your-test-api-url.com --dart-define=FEEDBACK_API_KEY=your_api_key --dart-define=TRELLO_LIST_ID=your_list_id --dart-define=TRELLO_BOARD_ID=your_board_id
/// ```
///
/// The test URL is hardcoded in the code.
///
class CloudflareFeedbackProvider implements FeedbackProvider {
  final String apiKey;
  final String testEndpoint;
  final String prodEndpoint;
  final String listId;
  final String boardId;

  const CloudflareFeedbackProvider({
    required this.apiKey,
    required this.prodEndpoint,
    this.testEndpoint = '',
    required this.listId,
    required this.boardId,
  });

  /// Creates a CloudflareFeedbackProvider instance from environment variables.
  ///
  /// Uses the following environment variables:
  /// - FEEDBACK_API_KEY: The API key for the feedback service
  /// - FEEDBACK_PRODUCTION_URL: The production URL for the feedback API (Only required in release mode)
  /// - FEEDBACK_TEST_URL: The test URL for the feedback API (Only required in debug mode)
  /// - TRELLO_LIST_ID: The ID of the Trello list where feedback will be sent (shared with TrelloFeedbackProvider)
  /// - TRELLO_BOARD_ID: The ID of the Trello board where feedback will be sent (shared with TrelloFeedbackProvider)
  static CloudflareFeedbackProvider fromEnvironment() {
    return CloudflareFeedbackProvider(
      apiKey: const String.fromEnvironment('FEEDBACK_API_KEY'),
      prodEndpoint: const String.fromEnvironment('FEEDBACK_PRODUCTION_URL'),
      testEndpoint: const String.fromEnvironment('FEEDBACK_TEST_URL'),
      listId: const String.fromEnvironment('TRELLO_LIST_ID'),
      boardId: const String.fromEnvironment('TRELLO_BOARD_ID'),
    );
  }

  bool get useTestEndpoint => kDebugMode && testEndpoint.isNotEmpty;

  String get _endpoint => useTestEndpoint ? testEndpoint : prodEndpoint;

  @override
  bool get isAvailable =>
      apiKey.isNotEmpty &&
      (prodEndpoint.isNotEmpty || (kDebugMode && testEndpoint.isNotEmpty)) &&
      listId.isNotEmpty &&
      boardId.isNotEmpty;

  @override
  Future<void> submitFeedback({
    required String description,
    required Uint8List screenshot,
    required String type,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Create comprehensive formatted description for agents
      final formattedDesc = FeedbackFormatter.createAgentFriendlyDescription(
        description,
        type,
        metadata,
      );

      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));

      // Set headers including charset
      request.headers.addAll({
        'X-KW-KEY': apiKey,
        'Accept-Charset': 'utf-8',
      });

      // Properly encode all string fields to ensure UTF-8 encoding
      request.fields.addAll({
        'idBoard': boardId,
        'idList': listId,
        'name': 'Feedback: $type',
        'desc': formattedDesc,
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'img',
          screenshot,
          filename: 'screenshot.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      // Encode metadata as JSON with proper UTF-8 handling
      final metadataJson = metadata.toJsonString();
      request.fields['metadata'] = metadataJson;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to submit feedback (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      final altAvailable = TrelloFeedbackProvider.hasEnvironmentVariables();
      if (kDebugMode && !altAvailable) {
        debugPrint('Error in Cloudflare submitFeedback: $e');
      }
      rethrow;
    }
  }
}

/// Debug implementation of FeedbackProvider that prints feedback to console
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

extension BuildContextShowFeedback on BuildContext {
  /// Shows the feedback dialog if the feedback service is available.
  /// Does nothing if the feedback service is not configured.
  void showFeedback() {
    final feedbackService = FeedbackService.create();
    if (feedbackService == null) {
      debugPrint(
        'Feedback dialog not shown: feedback service is not configured',
      );
      return;
    }

    BetterFeedback.of(this).show((feedback) async {
      // Workaround for known BetterFeedback issue:
      // https://github.com/ueman/feedback/issues/322#issuecomment-2384060812
      await Future.delayed(Duration(milliseconds: 500));
      try {
        final success = await feedbackService.handleFeedback(feedback);

        if (success) {
          // Close the feedback dialog
          BetterFeedback.of(this).hide();

          // Check if Discord was selected as contact method
          String? contactMethod;
          if (feedback.extra != null && feedback.extra is JsonMap) {
            contactMethod = feedback.extra!['contact_method'] as String?;
          }

          // Show Discord info dialog if Discord was selected
          if (contactMethod == 'discord') {
            // Use a short delay to ensure the feedback form is fully closed
            await Future.delayed(Duration(milliseconds: 300));
            await _showDiscordInfoDialog(this);
          }

          // Show success message
          ScaffoldMessenger.of(this).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you! ${LocaleKeys.feedbackFormDescription.tr()}',
              ),
              action: SnackBarAction(
                label: LocaleKeys.addMoreFeedback.tr(),
                onPressed: () => showFeedback(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // Keep the feedback dialog open but show error message
          final theme = Theme.of(this);
          ScaffoldMessenger.of(this).showSnackBar(
            SnackBar(
              content: Text(
                LocaleKeys.feedbackError.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              backgroundColor: theme.colorScheme.errorContainer,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error submitting feedback: $e');

        // Show error message but keep dialog open
        final theme = Theme.of(this);
        ScaffoldMessenger.of(this).showSnackBar(
          SnackBar(
            content: Text(
              LocaleKeys.feedbackError.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
          ),
        );
      }
    });
  }

  /// Returns true if feedback functionality is available
  bool get isFeedbackAvailable =>
      FeedbackService.create()?.isAvailable ?? false;
}

/// Shows a dialog with information about Discord contact
Future<void> _showDiscordInfoDialog(BuildContext context) {
  final theme = Theme.of(context);

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Let\'s Connect on Discord!'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To ensure we can reach you:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Make sure you\'re a member of the Komodo Discord server',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Watch for our team in the support channel',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Feel free to reach out to us anytime in the server',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
        SizedBox(
          width: 230,
          child: UiPrimaryButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openDiscordSupport();
            },
            child: Text('Join Komodo Discord'),
          ),
        ),
      ],
    ),
  );
}

Future<void> _openDiscordSupport() async {
  try {
    await launchUrl(discordInviteUrl, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error opening Discord link: $e');
  }
}
