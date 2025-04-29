import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_dex/model/feedback_data.dart';
import 'package:web_dex/model/feedback_request.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FeedbackFormRepo {
  Future<bool> send(FeedbackData feedback) async {
    try {
      final Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

      final String body = json.encode(
        FeedbackRequest(email: feedback.email, message: feedback.message),
      );

      await http.post(
        feedbackUrl,
        headers: headers,
        body: body,
      );
      return true;
    } catch (e, s) {
      log('Sending feedback error: ${e.toString()}',
          path: 'feedback_service => send', trace: s, isError: true);
      return false;
    }
  }
}
