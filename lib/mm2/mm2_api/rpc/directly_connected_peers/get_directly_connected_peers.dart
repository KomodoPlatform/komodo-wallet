import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class GetDirectlyConnectedPeers implements BaseRequest {
  GetDirectlyConnectedPeers({this.method = 'get_directly_connected_peers'});

  @override
  final String method;
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'method': method, 'userpass': userpass};
  }
}
