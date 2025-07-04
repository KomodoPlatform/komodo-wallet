import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/shared/constants.dart';

class RefreshNftMetadataRequest implements BaseRequest {
  RefreshNftMetadataRequest({
    required this.chain,
    required this.tokenAddress,
    required this.tokenId,
  });

  final String chain;
  final String tokenAddress;
  final String tokenId;
  @override
  late String userpass;

  @override
  final String method = 'refresh_nft_metadata';

  @override
  Map<String, dynamic> toJson() {
    return {
      "userpass": userpass,
      "method": method,
      "mmrpc": "2.0",
      "params": {
        "token_address": tokenAddress,
        "token_id": tokenId,
        "chain": chain,
        "url": moralisProxyUrl,
        "url_antispam": nftAntiSpamUrl,
        "komodo_proxy": false,
      }
    };
  }
}
