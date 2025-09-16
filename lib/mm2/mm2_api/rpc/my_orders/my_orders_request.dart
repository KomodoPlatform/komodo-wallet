import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class MyOrdersRequest implements BaseRequest {
  @override
  final String method = 'my_orders';
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'userpass': userpass,
      };
}
