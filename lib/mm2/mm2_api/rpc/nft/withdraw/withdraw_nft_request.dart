import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/model/nft.dart';

class WithdrawNftRequest implements BaseRequest {
  WithdrawNftRequest({
    required this.type,
    required this.chain,
    required this.toAddress,
    required this.tokenAddress,
    required this.tokenId,
    this.amount,
    this.max,
  });
  final NftContractType type;
  final NftBlockchains chain;
  final String toAddress;
  final String tokenAddress;
  final String tokenId;
  final int? amount;
  final bool? max;
  @override
  late String userpass;

  @override
  String get method => 'withdraw_nft';

  @override
  Map<String, dynamic> toJson() {
    return {
      'mmrpc': '2.0',
      'userpass': userpass,
      'method': method,
      'params': {
        'type': type.toWithdrawRequest(),
        'withdraw_data': {
          'chain': chain.toApiRequest(),
          "to": toAddress,
          "token_address": tokenAddress,
          "token_id": tokenId,
          if (max != null && type == NftContractType.erc1155) 'max': max,
          if (amount != null && type == NftContractType.erc1155)
            'amount': amount.toString(),
        },
      },
    };
  }
}
