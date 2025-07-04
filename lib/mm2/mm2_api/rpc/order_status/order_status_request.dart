import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class OrderStatusRequest implements BaseRequest {
  OrderStatusRequest({required this.uuid});
  final String uuid;
  @override
  late String userpass;
  @override
  final String method = 'order_status';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass,
        'method': method,
        'uuid': uuid,
      };
}
