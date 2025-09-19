import 'package:web_dex/model/nft.dart';

class GetNftListResponse {
  const GetNftListResponse({required this.result});
  final GetNftListResponseResult result;

  static GetNftListResponse fromJson(Map<String, dynamic> json) {
    return GetNftListResponse(
        result: GetNftListResponseResult.fromJson(json['result']));
  }
}

class GetNftListResponseResult {
  const GetNftListResponseResult({required this.nfts});
  static GetNftListResponseResult fromJson(Map<String, dynamic> json) {
    final dynamic nftsJson = json['nfts'];
    final List<dynamic> nftList = nftsJson is List<dynamic> ? nftsJson : [];
    return GetNftListResponseResult(
        nfts: nftList.map(NftToken.fromJson).toList());
  }

  final List<NftToken> nfts;
}
