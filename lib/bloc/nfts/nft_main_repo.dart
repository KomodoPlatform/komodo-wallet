import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/mm2/mm2_api/mm2_api_nft.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/errors.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/nft/get_nft_list/get_nft_list_res.dart';
import 'package:komodo_wallet/model/nft.dart';
import 'package:komodo_wallet/model/text_error.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

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
      log(
        json['error'] as String,
        path: 'nft_main_repo => updateNft',
        isError: true,
      ).ignore();
      throw ApiError(message: json['error'] as String);
    }
  }

  Future<List<NftToken>> getNfts(List<NftBlockchains> chains) async {
    // Only runs on active nft chains
    final json = await _api.getNftList(chains);
    final jsonError = json['error'] as String?;
    if (jsonError != null) {
      log(
        jsonError,
        path: 'nft_main_repo => getNfts',
        isError: true,
      ).ignore();
      if (jsonError.toLowerCase().startsWith('transport')) {
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
      final coins = _coinsRepo.getKnownCoins();
      for (final NftToken nft in nfts) {
        final coin = coins.firstWhere((c) => c.type == nft.coinType);
        final parentCoin = coin.parentCoin ?? coin;
        nft.parentCoin = parentCoin;
      }
      return response.result.nfts;
    } on StateError catch (e) {
      throw TextError(error: e.toString());
    } catch (e) {
      throw ParsingApiJsonError(message: 'nft_main_repo -> getNfts: $e');
    }
  }
}
