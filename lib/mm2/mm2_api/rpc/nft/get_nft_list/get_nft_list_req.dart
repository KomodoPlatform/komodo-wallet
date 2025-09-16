import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class GetNftListRequest implements BaseRequest {
  GetNftListRequest({
    required this.chains,
  });

  final List<String> chains;
  @override
  late String userpass;

  @override
  final String method = 'get_nft_list';

  @override
  Map<String, dynamic> toJson() {
    return {
      "userpass": userpass,
      "method": method,
      "mmrpc": "2.0",
      "params": {
        "chains": chains,
        "max": true,
        "protect_from_spam": true,
        "filters": {"exclude_spam": true, "exclude_phishing": true}
      }
    };
  }
}
