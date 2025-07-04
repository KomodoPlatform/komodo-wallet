import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class OrderBookDepthReq implements BaseRequest {
  OrderBookDepthReq({this.pairs = const <dynamic>[]});

  @override
  late String userpass;
  @override
  final String method = 'orderbook_depth';

  final List<dynamic> pairs;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'userpass': userpass,
      'pairs': pairs,
    };
  }

  @override
  String toString() {
    return 'OrderBookDepthReq(${pairs.length})';
  }
}
