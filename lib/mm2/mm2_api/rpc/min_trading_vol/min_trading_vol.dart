import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class MinTradingVolRequest implements BaseRequest {
  MinTradingVolRequest({required this.coin});

  @override
  late String userpass;
  @override
  final String method = 'min_trading_vol';
  final String coin;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'userpass': userpass,
    'coin': coin,
  };
}
