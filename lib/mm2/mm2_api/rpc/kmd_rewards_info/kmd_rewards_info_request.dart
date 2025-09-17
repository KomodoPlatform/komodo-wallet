import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class KmdRewardsInfoRequest implements BaseRequest {
  @override
  final String method = 'kmd_rewards_info';
  @override
  late String userpass;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'method': method, 'userpass': userpass};
  }
}
