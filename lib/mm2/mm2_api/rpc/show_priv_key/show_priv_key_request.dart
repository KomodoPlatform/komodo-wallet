import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class ShowPrivKeyRequest implements BaseRequest {
  ShowPrivKeyRequest({
    required this.coin,
  });
  @override
  late String userpass;
  @override
  final String method = 'show_priv_key';
  final String coin;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'userpass': userpass,
        'coin': coin,
      };
}
