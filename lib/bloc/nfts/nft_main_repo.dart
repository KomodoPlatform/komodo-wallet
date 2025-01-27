import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api_nft.dart';
import 'package:web_dex/mm2/mm2_api/rpc/errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/get_nft_list/get_nft_list_res.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';

class NftsRepo {
  NftsRepo({
    required Mm2ApiNft api,
    required CoinsRepo coinsRepo,
  })  : _coinsRepo = coinsRepo,
        _api = api;

  final CoinsRepo _coinsRepo;
  final Mm2ApiNft _api;

  Future<void> updateNft(List<NftBlockchains> chains) async {
    // Only runs on active nft chains
    final json = await _api.updateNftList(chains);
    if (json['error'] != null) {
      log(json['error'], path: 'nft_main_repo => updateNft', isError: true);
      throw ApiError(message: json['error']);
    }
  }

  Future<List<NftToken>> getNfts(List<NftBlockchains> chains) async {
    // Only runs on active nft chains
    final json = await _api.getNftList(chains);
    final jsonError = json['error'];
    if (jsonError != null) {
      log(
        jsonError,
        path: 'nft_main_repo => getNfts',
        isError: true,
      );
      if (jsonError is String &&
          jsonError.toLowerCase().startsWith('transport')) {
        throw TransportError(message: jsonError);
      } else {
        throw ApiError(message: jsonError);
      }
    }

    if (json['result'] == null) {
      throw ApiError(message: LocaleKeys.somethingWrong.tr());
    }
    try {
      final response = GetNftListResponse.fromJson(json);
      final nfts = response.result.nfts;
      final coins = await _coinsRepo.getKnownCoins();
      for (NftToken nft in nfts) {
        final coin = coins.firstWhere((c) => c.type == nft.coinType);
        final parentCoin = coin.parentCoin ?? coin;
        nft.parentCoin = parentCoin;
      }
      return response.result.nfts;
    } on StateError catch (e) {
      throw TextError(error: e.toString());
    } catch (e) {
      throw ParsingApiJsonError(
          message: 'nft_main_repo -> getNfts: ${e.toString()}');
    }
  }
}
