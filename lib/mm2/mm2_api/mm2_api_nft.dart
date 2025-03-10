import 'dart:convert';

import 'package:http/http.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/mm2/mm2_api/rpc/errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/get_nft_list/get_nft_list_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/refresh_nft_metadata/refresh_nft_metadata_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/update_nft/update_nft_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/withdraw/withdraw_nft_request.dart';
import 'package:web_dex/mm2/rpc/nft_transaction/nft_transactions_request.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';

class Mm2ApiNft {
  Mm2ApiNft(this.call, this._sdk);

  final KomodoDefiSdk _sdk;
  final Future<JsonMap> Function(dynamic) call;

  Future<Map<String, dynamic>> updateNftList(
    List<NftBlockchains> chains,
  ) async {
    try {
      final List<String> nftChains = await getActiveNftChains(chains);
      if (nftChains.isEmpty) {
        return {
          'error':
              'Please ensure an NFT chain is activated and patiently await '
                  'while your NFTs are loaded.',
        };
      }
      final UpdateNftRequest request = UpdateNftRequest(chains: nftChains);

      final JsonMap json = await call(request);
      log(
        request.toJson().toString(),
        path: 'UpdateNftRequest',
      ).ignore();
      log(
        json.toJsonString(),
        path: 'UpdateNftResponse',
      ).ignore();
      return json;
    } catch (e, s) {
      log(
        'Error updating nfts: $e',
        path: 'UpdateNftResponse',
        trace: s,
        isError: true,
      ).ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> refreshNftMetadata({
    required String chain,
    required String tokenAddress,
    required String tokenId,
  }) async {
    try {
      final RefreshNftMetadataRequest request = RefreshNftMetadataRequest(
        chain: chain,
        tokenAddress: tokenAddress,
        tokenId: tokenId,
      );
      return await call(request);
    } catch (e) {
      log(
        e.toString(),
        path: 'Mm2ApiNft => RefreshNftMetadataRequest',
        isError: true,
      ).ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getNftList(List<NftBlockchains> chains) async {
    try {
      final List<String> nftChains = await getActiveNftChains(chains);
      if (nftChains.isEmpty) {
        return {
          'error':
              'Please ensure the NFT chain is activated and patiently await '
                  'while your NFTs are loaded.',
        };
      }
      final GetNftListRequest request = GetNftListRequest(chains: nftChains);

      final JsonMap json = await call(request);

      log(
        request.toJson().toString(),
        path: 'getActiveNftChains',
      ).ignore();
      log(
        json.toJsonString(),
        path: 'UpdateNftResponse',
      ).ignore();

      return json;
    } catch (e) {
      log(e.toString(), path: 'Mm2ApiNft => getNftList', isError: true)
          .ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> withdraw(WithdrawNftRequest request) async {
    try {
      return await call(request);
    } catch (e) {
      log(e.toString(), path: 'Mm2ApiNft => withdraw', isError: true).ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getNftTxs(
    NftTransactionsRequest request,
    bool withAdditionalInfo,
  ) async {
    try {
      final JsonMap json = await call(request);
      if (withAdditionalInfo) {
        final jsonUpdated = await const ProxyApiNft().addDetailsToTx(json);
        return jsonUpdated;
      }
      return json;
    } catch (e) {
      log(e.toString(), path: 'Mm2ApiNft => getNftTransactions', isError: true)
          .ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getNftTxDetails(
    NftTxDetailsRequest request,
  ) async {
    try {
      final additionalTxInfo = await const ProxyApiNft()
          .getTxDetailsByHash(request.chain, request.txHash);
      return additionalTxInfo;
    } catch (e) {
      log(e.toString(), path: 'Mm2ApiNft => getNftTxDetails', isError: true)
          .ignore();
      throw TransportError(message: e.toString());
    }
  }

  Future<List<String>> getActiveNftChains(List<NftBlockchains> chains) async {
    final List<Asset> apiCoins = await _sdk.assets.getActivatedAssets();
    final List<String> enabledCoinIds = apiCoins.map((c) => c.id.id).toList();
    log(
      enabledCoinIds.toString(),
      path: 'Mm2ApiNft => enabledCoins',
      isError: true,
    ).ignore();
    final List<String> nftCoins = chains.map((c) => c.coinAbbr()).toList();
    log(nftCoins.toString(), path: 'Mm2ApiNft => nftCoins', isError: true)
        .ignore();
    final List<NftBlockchains> activeChains = chains
        .map((c) => c)
        .toList()
        .where((c) => enabledCoinIds.contains(c.coinAbbr()))
        .toList();
    log(
      activeChains.toString(),
      path: 'Mm2ApiNft => activeChains',
      isError: true,
    ).ignore();
    final List<String> nftChains =
        activeChains.map((c) => c.toApiRequest()).toList();
    log(nftChains.toString(), path: 'Mm2ApiNft => nftChains', isError: true)
        .ignore();
    return nftChains;
  }
}

class ProxyApiNft {
  const ProxyApiNft();
  static const _errorBaseMessage = 'ProxyApiNft API: ';
  Future<Map<String, dynamic>> addDetailsToTx(Map<String, dynamic> json) async {
    final transactions =
        List<dynamic>.from(json['result']['transfer_history'] as List? ?? []);
    final listOfAdditionalData = transactions
        .map(
          (tx) => {
            'blockchain': convertChainForProxy(tx['chain'] as String),
            'tx_hash': tx['transaction_hash'],
          },
        )
        .toList();

    final response = await Client().post(
      Uri.parse(txByHashUrl),
      body: jsonEncode(listOfAdditionalData),
    );
    final jsonBody = jsonDecode(response.body) as JsonMap;
    json['result']['transfer_history'] = transactions.map((element) {
      final txHash = element['transaction_hash'] as String?;
      final tx = jsonBody[txHash] as JsonMap?;
      if (tx != null) {
        element['confirmations'] = tx['confirmations'];
        element['fee_details'] = tx['fee_details'];
      }
      return element;
    }).toList();

    return json;
  }

  Future<Map<String, dynamic>> getTxDetailsByHash(
    String blockchain,
    String txHash,
  ) async {
    final listOfAdditionalData = [
      {
        'blockchain': convertChainForProxy(blockchain),
        'tx_hash': txHash,
      }
    ];
    final body = jsonEncode(listOfAdditionalData);
    try {
      final response = await Client().post(
        Uri.parse(txByHashUrl),
        body: body,
      );
      final jsonBody = jsonDecode(response.body) as JsonMap;
      return jsonBody[txHash] as JsonMap;
    } catch (e) {
      throw Exception(_errorBaseMessage + e.toString());
    }
  }

  String convertChainForProxy(String chain) {
    switch (chain) {
      case 'AVALANCHE':
        return 'avx';
      case 'BSC':
        return 'bnb';
      case 'ETH':
        return 'eth';
      case 'FANTOM':
        return 'ftm';
      case 'POLYGON':
        return 'plg';
    }

    throw UnimplementedError();
  }
}
