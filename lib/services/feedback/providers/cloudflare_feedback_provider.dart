import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web_dex/services/feedback/feedback_formatter.dart';
import 'package:web_dex/services/feedback/feedback_provider.dart';
import 'package:web_dex/services/logger/get_logger.dart' as app_logger;

class CloudflareFeedbackProvider implements FeedbackProvider {
  final String apiKey;
  final String prodEndpoint;
  final String listId;
  final String boardId;

  const CloudflareFeedbackProvider({
    required this.apiKey,
    required this.prodEndpoint,
    required this.listId,
    required this.boardId,
  });

  static CloudflareFeedbackProvider fromEnvironment() {
    return CloudflareFeedbackProvider(
      apiKey: const String.fromEnvironment('FEEDBACK_API_KEY'),
      prodEndpoint: const String.fromEnvironment('FEEDBACK_PRODUCTION_URL'),
      listId: const String.fromEnvironment('TRELLO_LIST_ID'),
      boardId: const String.fromEnvironment('TRELLO_BOARD_ID'),
    );
  }

  String get _endpoint => prodEndpoint;

  @override
  bool get isAvailable =>
      apiKey.isNotEmpty &&
      prodEndpoint.isNotEmpty &&
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
      final formattedDesc = FeedbackFormatter.createAgentFriendlyDescription(
        description,
        type,
        metadata,
      );

      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      request.headers.addAll({'X-KW-KEY': apiKey, 'Accept-Charset': 'utf-8'});
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

      try {
        final Uint8List logsBytes = await app_logger.logger
            .exportRecentLogsBytes(maxBytes: 9 * 1024 * 1024);
        if (logsBytes.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'logs',
              logsBytes,
              filename: 'logs.txt',
              contentType: MediaType('text', 'plain'),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Skipping logs attachment: $e');
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to submit feedback (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
