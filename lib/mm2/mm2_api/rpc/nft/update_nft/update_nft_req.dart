import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/shared/constants.dart';

class UpdateNftRequest implements BaseRequest {
  UpdateNftRequest({
    required this.chains,
  });

  final List<String> chains;
  @override
  late String userpass;

  @override
  final String method = 'update_nft';

  @override
  Map<String, dynamic> toJson() {
    return {
      "userpass": userpass,
      "method": method,
      "mmrpc": "2.0",
      "params": {
        "chains": chains,
        "url": moralisProxyUrl,
        "url_antispam": nftAntiSpamUrl,
        "komodo_proxy": false,
      }
    };
  }
}
