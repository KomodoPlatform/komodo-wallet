import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web_dex/services/feedback/feedback_formatter.dart';
import 'package:web_dex/services/feedback/feedback_provider.dart';
import 'package:web_dex/services/logger/get_logger.dart' as app_logger;

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

    final missing = requiredVars.entries.where((e) => e.value.isEmpty).toList();
    return missing.isEmpty;
  }

  static TrelloFeedbackProvider? fromEnvironment() {
    if (!hasEnvironmentVariables()) return null;
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
    // 1) Create card with formatted description
    final formattedDesc = FeedbackFormatter.createAgentFriendlyDescription(
      description,
      type,
      metadata,
    );

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

    // 2) Attach screenshot
    final imgReq = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.trello.com/1/cards/$cardId/attachments'),
    );
    imgReq.fields.addAll({'key': apiKey, 'token': token});
    imgReq.files.add(
      http.MultipartFile.fromBytes(
        'file',
        screenshot,
        filename: 'screenshot.png',
        contentType: MediaType('image', 'png'),
      ),
    );
    final imgResp = await http.Response.fromStream(await imgReq.send());
    if (imgResp.statusCode != 200) {
      throw Exception(
        'Failed to attach screenshot (${imgResp.statusCode}): ${imgResp.body}',
      );
    }

    // 3) Attach logs (<= 9MB) - optional
    try {
      final bytes = await app_logger.logger.exportRecentLogsBytes(
        maxBytes: 9 * 1024 * 1024,
      );
      if (bytes.isEmpty) return;

      final logsReq = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.trello.com/1/cards/$cardId/attachments'),
      );
      logsReq.fields.addAll({'key': apiKey, 'token': token});
      logsReq.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'logs.txt',
          contentType: MediaType('text', 'plain'),
        ),
      );
      final logsResp = await http.Response.fromStream(await logsReq.send());
      if (logsResp.statusCode != 200) {
        throw Exception(
          'Failed to attach logs (${logsResp.statusCode}): ${logsResp.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Skipping logs attachment (Trello): $e');
      }
    }
  }
}
