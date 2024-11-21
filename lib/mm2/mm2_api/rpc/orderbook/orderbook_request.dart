import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class OrderbookRequest implements BaseRequest {
  OrderbookRequest({
    required this.base,
    required this.rel,
  });

  final String base;
  final String rel;
  @override
  late String userpass;
  @override
  final String method = 'orderbook';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'mmrpc': '2.0',
        'userpass': userpass,
        'method': method,
        'params': {
          'base': base,
          'rel': rel,
        }
      };
}
