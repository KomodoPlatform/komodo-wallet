import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/model/text_error.dart';

class SendRawTransactionResponse {
  SendRawTransactionResponse({
    required this.txHash,
    this.error,
  });

  factory SendRawTransactionResponse.fromJson(Map<String, dynamic> json) {
    final dynamic error = json['error'];
    return SendRawTransactionResponse(
      txHash: json['tx_hash'],
      error: error is String ? TextError(error: error) : null,
    );
  }
  final String? txHash;
  final BaseError? error;
}
