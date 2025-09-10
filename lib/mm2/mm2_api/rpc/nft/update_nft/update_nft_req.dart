import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/shared/constants.dart';

class UpdateNftRequest implements BaseRequest {
  UpdateNftRequest({required this.chains});

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
      },
    };
  }
}
