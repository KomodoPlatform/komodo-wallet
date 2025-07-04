import 'package:komodo_wallet/model/nft.dart';

class WithdrawNftResponse {
  WithdrawNftResponse({
    required this.result,
  });
  final NftTransactionDetails result;

  factory WithdrawNftResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawNftResponse(
        result: NftTransactionDetails.fromJson(json['result']));
  }
}
