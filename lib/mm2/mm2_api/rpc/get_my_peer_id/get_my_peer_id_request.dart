import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class GetMyPeerIdRequest implements BaseRequest {
  GetMyPeerIdRequest();

  @override
  final String method = 'get_my_peer_id';
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'method': method, 'userpass': userpass};
  }
}
