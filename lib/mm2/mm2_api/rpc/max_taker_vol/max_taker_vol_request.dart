import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class MaxTakerVolRequest implements BaseRequest {
  MaxTakerVolRequest({
    required this.coin,
  });
  @override
  late String userpass;
  @override
  final String method = 'max_taker_vol';
  final String coin;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'userpass': userpass,
        'coin': coin,
      };
}
