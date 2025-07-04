import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class SendRawTransactionRequest implements BaseRequest {
  SendRawTransactionRequest({
    required this.coin,
    required this.txHex,
  });

  factory SendRawTransactionRequest.fromJson(Map<String, dynamic> json) {
    return SendRawTransactionRequest(
      coin: json['coin'],
      txHex: json['tx_hex'],
    );
  }

  @override
  final String method = 'send_raw_transaction';

  String coin;
  String txHex;

  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'coin': coin,
      'tx_hex': txHex,
      'userpass': userpass,
    };
  }
}
