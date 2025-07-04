import 'package:komodo_wallet/model/text_error.dart';

class SellResponse {
  SellResponse({this.error, this.result});

  factory SellResponse.fromJson(Map<String, dynamic> json) {
    return SellResponse(
      error: TextError.fromString(json['error']),
      result: SellResponseResult.fromJson(json['result']),
    );
  }

  final TextError? error;
  final SellResponseResult? result;
}

class SellResponseResult {
  SellResponseResult({required this.uuid});

  static SellResponseResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return SellResponseResult(uuid: json['uuid']);
  }

  final String uuid;
}
