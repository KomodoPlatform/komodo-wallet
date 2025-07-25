import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/shared/utils/utils.dart';

abstract class ICustomTokenImportRepository {
  Future<Asset> fetchCustomToken(CoinSubClass network, String address);
  Future<void> importCustomToken(Asset asset);
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  KdfCustomTokenImportRepository(this._kdfSdk, this._coinsRepo);

  final CoinsRepo _coinsRepo;
  final KomodoDefiSdk _kdfSdk;

  @override
  Future<Asset> fetchCustomToken(CoinSubClass network, String address) async {
    final convertAddressResponse =
        await _kdfSdk.client.rpc.address.convertAddress(
      from: address,
      coin: network.ticker,
      toFormat: AddressFormat.fromCoinSubClass(CoinSubClass.erc20),
    );
    final contractAddress = convertAddressResponse.address;
    final knownCoin = _kdfSdk.assets.available.values.firstWhereOrNull(
      (asset) => asset.contractAddress == contractAddress,
    );
    if (knownCoin == null) {
      return await _createNewCoin(
        contractAddress,
        network,
        address,
      );
    }

    return knownCoin;
  }

  Future<Asset> _createNewCoin(
    String contractAddress,
    CoinSubClass network,
    String address,
  ) async {
    final response = await _kdfSdk.client.rpc.utility.getTokenInfo(
      contractAddress: contractAddress,
      platform: network.ticker,
      protocolType: CoinSubClass.erc20.formatted,
    );

    final platformAssets = _kdfSdk.assets.findAssetsByConfigId(network.ticker);
    if (platformAssets.length != 1) {
      throw Exception('Platform asset not found. ${platformAssets.length} '
          'results returned.');
    }
    final platformAsset = platformAssets.single;
    final platformConfig = platformAsset.protocol.config;
    final String ticker = response.info.symbol;
    final tokenApi = await fetchTokenInfoFromApi(network, contractAddress);

    final coinId = '$ticker-${network.ticker}';
    final logoImageUrl = tokenApi?['image']?['large'] ??
        tokenApi?['image']?['small'] ??
        tokenApi?['image']?['thumb'];
    final newCoin = Asset(
      signMessagePrefix: null,
      id: AssetId(
        id: coinId,
        name: tokenApi?['name'] ?? ticker,
        symbol: AssetSymbol(
          assetConfigId: '$ticker-${network.ticker}',
          coinGeckoId: tokenApi?['id'],
          coinPaprikaId: tokenApi?['id'],
        ),
        chainId: AssetChainId(chainId: 0),
        subClass: network,
        derivationPath: '',
      ),
      isWalletOnly: false,
      protocol: Erc20Protocol.fromJson({
        'type': network.formatted,
        'chain_id': 0,
        'nodes': [],
        'swap_contract_address':
            platformConfig.valueOrNull<String>('swap_contract_address'),
        'fallback_swap_contract':
            platformConfig.valueOrNull<String>('fallback_swap_contract'),
        'protocol': {
          'protocol_data': {
            'platform': network.ticker,
            'contract_address': address,
          },
        },
        'logo_image_url': logoImageUrl,
        'explorer_url': platformConfig.valueOrNull<String>('explorer_url'),
        'explorer_url_tx':
            platformConfig.valueOrNull<String>('explorer_url_tx'),
        'explorer_url_address':
            platformConfig.valueOrNull<String>('explorer_url_address'),
      }).copyWith(isCustomToken: true),
    );

    AssetIcon.registerCustomIcon(
      newCoin.id,
      NetworkImage(
        tokenApi?['image']?['large'] ??
            'assets/coin_icons/png/${ticker.toLowerCase()}.png',
      ),
    );

    return newCoin;
  }

  @override
  Future<void> importCustomToken(Asset asset) async {
    await _coinsRepo.activateAssetsSync([asset]);
  }

  Future<Map<String, dynamic>?> fetchTokenInfoFromApi(
    CoinSubClass coinType,
    String contractAddress,
  ) async {
    final platform = getNetworkApiName(coinType);
    if (platform == null) {
      log('Unsupported Image URL Network: $coinType');
      return null;
    }

    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/coins/$platform/'
      'contract/$contractAddress',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      log('Error fetching token data from $url: $e');
      return null;
    }
  }

  // this does not appear to match the coingecko id field in the coins config.
  // notable differences are bep20, matic, and hrc20
  // these could possibly be mapped with another field, or it should be changed
  // to the subclass formatted/ticker fields
  String? getNetworkApiName(CoinSubClass coinType) {
    switch (coinType) {
      case CoinSubClass.erc20:
        return 'ethereum';        // https://api.coingecko.com/api/v3/coins/ethereum/contract/0x56072C95FAA701256059aa122697B133aDEd9279
      case CoinSubClass.bep20:
        return 'bsc';             // https://api.coingecko.com/api/v3/coins/bsc/contract/0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
      case CoinSubClass.arbitrum:
        return 'arbitrum-one';    // https://api.coingecko.com/api/v3/coins/arbitrum-one/contract/0xCBeb19549054CC0a6257A77736FC78C367216cE7
      case CoinSubClass.avx20:
        return 'avalanche';       // https://api.coingecko.com/api/v3/coins/avalanche/contract/0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
      case CoinSubClass.moonriver:
        return 'moonriver';       // https://api.coingecko.com/api/v3/coins/moonriver/contract/0x0caE51e1032e8461f4806e26332c030E34De3aDb
      case CoinSubClass.matic:
        return 'polygon-pos';     // https://api.coingecko.com/api/v3/coins/polygon-pos/contract/0xdF7837DE1F2Fa4631D716CF2502f8b230F1dcc32
      case CoinSubClass.krc20:
        return 'kcc';             // https://api.coingecko.com/api/v3/coins/kcc/contract/0x0039f574ee5cc39bdd162e9a88e3eb1f111baf48
      case CoinSubClass.qrc20:
        return null;              // Unable to find working url
      case CoinSubClass.ftm20:
        return null;              // Unable to find working url
      case CoinSubClass.hecoChain:
        return null;              // Unable to find working url
      case CoinSubClass.hrc20:
        return null;              // Unable to find working url
      default:
        return null;
    }
  }
}
