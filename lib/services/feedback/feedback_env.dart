import 'package:envied/envied.dart';

// NOTE: The generated file contains the actual environment variables
// and should not be committed to the repository (even when obfuscated).
// To generate this file, run either of the following commands:
//  dart run build_runner build
//  flutter pub run build_runner build
part 'feedback_env.g.dart';

@Envied(path: '.env', allowOptionalFields: true, obfuscate: true)
abstract class FeedbackEnv {
  @EnviedField(varName: 'TRELLO_API_KEY')
  static String? apiKey = _FeedbackEnv.apiKey;

  @EnviedField(varName: 'TRELLO_TOKEN')
  static String? token = _FeedbackEnv.token;

  @EnviedField(varName: 'TRELLO_BOARD_ID')
  static String? boardId = _FeedbackEnv.boardId;

  @EnviedField(varName: 'TRELLO_LIST_ID')
  static String? listId = _FeedbackEnv.listId;

  /// Returns true if all required environment variables are available
  static bool hasAllVariables() {
    return hasApiKey() && hasToken() && hasBoardId() && hasListId();
  }

  /// Returns true if specific variable is defined and not empty
  static bool hasApiKey() => apiKey != null && apiKey!.isNotEmpty;
  static bool hasToken() => token != null && token!.isNotEmpty;
  static bool hasBoardId() => boardId != null && boardId!.isNotEmpty;
  static bool hasListId() => listId != null && listId!.isNotEmpty;
}
