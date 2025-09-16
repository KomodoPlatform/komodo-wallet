import 'package:web_dex/model/nft.dart';

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
