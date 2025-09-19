class RecoverFundsOfSwapResponse {
  RecoverFundsOfSwapResponse({
    required this.result,
  });
  factory RecoverFundsOfSwapResponse.fromJson(Map<String, dynamic> json) =>
      RecoverFundsOfSwapResponse(
          result: RecoverFundsOfSwapResponseResult.fromJson(json['result']));
  final RecoverFundsOfSwapResponseResult result;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'result': result.toJson(),
      };
}

class RecoverFundsOfSwapResponseResult {
  RecoverFundsOfSwapResponseResult({
    required this.action,
    required this.coin,
    required this.txHash,
    required this.txHex,
  });

  factory RecoverFundsOfSwapResponseResult.fromJson(
          Map<String, dynamic> json) =>
      RecoverFundsOfSwapResponseResult(
        action: json['action'],
        coin: json['coin'],
        txHash: json['tx_hash'],
        txHex: json['tx_hex'],
      );

  final String action; // SpentOtherPayment or RefundedMyPayment
  final String coin;
  final String txHash;
  final String txHex;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'action': action,
        'coin': coin,
        'tx_hash': txHash,
        'tx_hex': txHex,
      };
}
