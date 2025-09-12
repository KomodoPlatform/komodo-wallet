import 'dart:async' show TimeoutException;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';

/// Abstraction for fetching and importing custom tokens.
///
/// Implementations should resolve token metadata and activate tokens so they
/// become available to the user within the wallet.
abstract class ICustomTokenImportRepository {
  /// Fetch an [Asset] for a custom token on [network] using [address].
  ///
  /// May return an existing known asset or construct a new one when absent.
  Future<Asset> fetchCustomToken(AssetId networkId, String address);

  /// Import the provided custom token [asset] into the wallet (e.g. activate it).
  Future<void> importCustomToken(Asset asset);

  /// Get the API name for the given coin subclass.
  String? getNetworkApiName(CoinSubClass coinType);
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  KdfCustomTokenImportRepository(
    this._kdfSdk,
    this._coinsRepo, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final CoinsRepo _coinsRepo;
  final KomodoDefiSdk _kdfSdk;
  final http.Client _httpClient;
  final _log = Logger('KdfCustomTokenImportRepository');

  @override
  Future<Asset> fetchCustomToken(AssetId networkId, String address) async {
    final networkSubclass = networkId.subClass;
    final convertAddressResponse = await _kdfSdk.client.rpc.address
        .convertAddress(
          from: address,
          coin: networkSubclass.ticker,
          toFormat: AddressFormat.fromCoinSubClass(CoinSubClass.erc20),
        );
    final contractAddress = convertAddressResponse.address;
    final knownCoin = _kdfSdk.assets.available.values.firstWhereOrNull(
      (asset) =>
          asset.contractAddress == contractAddress &&
          asset.id.subClass == networkSubclass,
    );
    if (knownCoin == null) {
      return _createNewCoin(contractAddress, networkId);
    }

    return knownCoin;
  }

  Future<Asset> _createNewCoin(
    String contractAddress,
    AssetId networkId,
  ) async {
    final network = networkId.subClass;

    _log.info('Creating new coin for $contractAddress on $network');
    final response = await _kdfSdk.client.rpc.utility.getTokenInfo(
      contractAddress: contractAddress,
      platform: network.ticker,
      protocolType:
          CoinSubClass.erc20.tokenStandardSuffix ??
          CoinSubClass.erc20.name.toUpperCase(),
    );

    final platformAssets = _kdfSdk.assets.findAssetsByConfigId(network.ticker);
    if (platformAssets.length != 1) {
      throw Exception(
        'Platform asset not found. ${platformAssets.length} '
        'results returned.',
      );
    }

    final platformAsset = platformAssets.single;
    final platformConfig = platformAsset.protocol.config;
    final String ticker = response.info.symbol;
    final tokenApi = await fetchTokenInfoFromApi(network, contractAddress);
    final platformChainId = int.parse(
      platformAsset.id.chainId.formattedChainId,
    );
    final coinId = '$ticker-${network.tokenStandardSuffix}';
    final logoImageUrl =
        tokenApi?['image']?['large'] ??
        tokenApi?['image']?['small'] ??
        tokenApi?['image']?['thumb'];

    _log.info('Creating new coin for $coinId on $network');
    final newCoin = Asset(
      signMessagePrefix: null,
      id: AssetId(
        id: coinId,
        name: tokenApi?['name'] ?? ticker,
        symbol: AssetSymbol(
          assetConfigId: coinId,
          coinGeckoId: tokenApi?['id'],
          coinPaprikaId: tokenApi?['id'],
        ),
        chainId: platformAsset.id.chainId,
        subClass: network,
        derivationPath: '',
      ),
      isWalletOnly: false,
      protocol: Erc20Protocol.fromJson(platformConfig).copyWithProtocolData(
        coin: coinId,
        type: network.tokenStandardSuffix,
        chainId: platformChainId,
        contractAddress: contractAddress,
        platform: network.ticker,
        logoImageUrl: logoImageUrl,
        isCustomToken: true,
      ),
    );

    AssetIcon.registerCustomIcon(
      newCoin.id,
      NetworkImage(
        logoImageUrl ?? 'assets/coin_icons/png/${ticker.toLowerCase()}.png',
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
    String contractAddress, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final platform = getNetworkApiName(coinType);
    if (platform == null) {
      _log.warning('Unsupported Image URL Network: $coinType');
      return null;
    }

    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/coins/$platform/'
      'contract/$contractAddress',
    );

    try {
      final response = await _httpClient
          .get(url)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('Timeout fetching token data from $url');
            },
          );
      final data = jsonDecode(response.body);
      return data;
    } catch (e, s) {
      _log.severe('Error fetching token data from $url', e, s);
      return null;
    }
  }

  // TODO: when migrating to the API, change this to fetch the coingecko
  // asset_platforms: https://api.coingecko.com/api/v3/asset_platforms
  @override
  String? getNetworkApiName(CoinSubClass coinType) {
    switch (coinType) {
      case CoinSubClass.erc20:
        return 'ethereum'; // https://api.coingecko.com/api/v3/coins/ethereum/contract/0x56072C95FAA701256059aa122697B133aDEd9279
      case CoinSubClass.bep20:
        return 'bsc'; // https://api.coingecko.com/api/v3/coins/bsc/contract/0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
      case CoinSubClass.arbitrum:
        return 'arbitrum-one'; // https://api.coingecko.com/api/v3/coins/arbitrum-one/contract/0xCBeb19549054CC0a6257A77736FC78C367216cE7
      case CoinSubClass.avx20:
        return 'avalanche'; // https://api.coingecko.com/api/v3/coins/avalanche/contract/0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
      case CoinSubClass.moonriver:
        return 'moonriver'; // https://api.coingecko.com/api/v3/coins/moonriver/contract/0x0caE51e1032e8461f4806e26332c030E34De3aDb
      case CoinSubClass.matic:
        return 'polygon-pos'; // https://api.coingecko.com/api/v3/coins/polygon-pos/contract/0xdF7837DE1F2Fa4631D716CF2502f8b230F1dcc32
      case CoinSubClass.krc20:
        return 'kcc'; // https://api.coingecko.com/api/v3/coins/kcc/contract/0x0039f574ee5cc39bdd162e9a88e3eb1f111baf48
      case CoinSubClass.qrc20:
        return null; // Unable to find working url
      case CoinSubClass.ftm20:
        return null; // Unable to find working url
      case CoinSubClass.hecoChain:
        return null; // Unable to find working url
      case CoinSubClass.hrc20:
        return null; // Unable to find working url
      default:
        return null;
    }
  }
}

extension on Erc20Protocol {
  Erc20Protocol copyWithProtocolData({
    String? coin,
    String? type,
    String? contractAddress,
    String? platform,
    String? logoImageUrl,
    bool? isCustomToken,
    int? chainId,
  }) {
    final currentConfig = JsonMap.from(config);
    currentConfig.addAll({
      if (coin != null) 'coin': coin,
      if (type != null) 'type': type,
      if (chainId != null) 'chain_id': chainId,
      if (logoImageUrl != null) 'logo_image_url': logoImageUrl,
      if (isCustomToken != null) 'is_custom_token': isCustomToken,
      if (contractAddress != null || platform != null)
        'protocol': {
          'protocol_data': {
            'contract_address': contractAddress ?? this.contractAddress,
            'platform': platform ?? subClass.ticker,
          },
        },
    });
    return Erc20Protocol.fromJson(currentConfig);
  }
}
