import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

class NftTransactionsRequest implements BaseRequest {
  NftTransactionsRequest({
    required this.chains,
    required this.max,
  });
  @override
  late String userpass;
  @override
  final String method = 'get_nft_transfers';
  final List<String> chains;
  final bool max;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'userpass': userpass,
        'mmrpc': '2.0',
        'params': {
          'chains': chains,
          'max': max,
          "protect_from_spam": true,
          "filters": {"exclude_spam": true, "exclude_phishing": true}
        },
      };
}

class NftTxDetailsRequest {
  final String chain;
  final String txHash;

  NftTxDetailsRequest({
    required this.chain,
    required this.txHash,
  });
}
