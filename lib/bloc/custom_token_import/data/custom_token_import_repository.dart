import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';

abstract class ICustomTokenImportRepository {
  Future<Coin> fetchCustomToken(CoinSubClass network, String address);

  Future<void> importCustomToken(Asset asset);

  /// Method for importing custom tokens using the legacy [Coin] model.
  @Deprecated('Use importCustomToken instead, using the new Asset model')
  Future<void> importCustomTokenLegacy(String coinId);
}

class KdfCustomTokenImportRepository implements ICustomTokenImportRepository {
  KdfCustomTokenImportRepository(this._kdfSdk, this._coinsRepo);

  final CoinsRepo _coinsRepo;
  final KomodoDefiSdk _kdfSdk;

  @override
  Future<Coin> fetchCustomToken(CoinSubClass network, String address) async {
    final platformCoin = await _activatePlatformCoin(network);
    final convertAddressResponse =
        await _kdfSdk.client.rpc.wallet.convertAddress(
      fromAddress: address,
      coinSubClass: network,
    );
    final contractAddress = convertAddressResponse.address;
    final knownCoin = _coinsRepo.getKnownCoins().firstWhereOrNull(
          (coin) => coin.protocolData?.contractAddress == contractAddress,
        );
    if (knownCoin == null) {
      return await _createNewCoin(
        contractAddress,
        network,
        address,
        platformCoin,
      );
    }

    final updatedBalance = await _getBalance(knownCoin);
    return knownCoin.copyWith(
      balance: updatedBalance.toDouble(),
    );
  }

  Future<Coin> _createNewCoin(
    String contractAddress,
    CoinSubClass network,
    String address,
    Coin platformCoin,
  ) async {
    final response = await _kdfSdk.client.rpc.utility.getTokenInfo(
      contractAddress: contractAddress,
      platform: network.ticker,
      protocolType: network.formatted,
    );

    final String ticker = response.info.symbol;
    final int decimals = response.info.decimals;
    final tokenApi = await fetchTokenInfoFromApi(network, contractAddress);
    final price = tokenApi?['market_data']?['current_price']?['usd'];
    final CoinType coinType = network.toCoinType();

    final newCoin = Coin(
      isCustomCoin: true,
      abbr: '$ticker-${network.ticker}',
      decimals: decimals,
      name: tokenApi?['name'] ?? ticker,
      parentCoin: platformCoin,
      protocolType: 'ERC20',
      type: coinType,
      protocolData: ProtocolData(
        platform: platformCoin.abbr,
        contractAddress: address,
      ),
      logoImageUrl: tokenApi?['image']?['large'] ??
          tokenApi?['image']?['small'] ??
          tokenApi?['image']?['thumb'],
      coingeckoId: tokenApi?['id'],
      usdPrice: price == null ? null : CexPrice(ticker: ticker, price: price),
      explorerUrl: platformCoin.explorerUrl,
      explorerTxUrl: platformCoin.explorerTxUrl,
      explorerAddressUrl: platformCoin.explorerAddressUrl,
      swapContractAddress: platformCoin.swapContractAddress,
      fallbackSwapContract: platformCoin.fallbackSwapContract,
      state: CoinState.inactive,
      mode: CoinMode.standard,
      isTestCoin: false,
      walletOnly: false,
      priority: 0,
    );

    CoinIcon.registerCustomIcon(
        newCoin.abbr,
        NetworkImage(
          tokenApi?['image']?['large'] ??
              'assets/coin_icons/png/${ticker.toLowerCase()}.png',
        ));

    await _kdfSdk.addCustomCoin(newCoin);
    return newCoin.copyWith(
      balance: (await _getBalance(newCoin)).toDouble(),
    );
  }

  Future<Decimal> _getBalance(Coin coin) async {
    await _coinsRepo.activateCoinsSync([coin]);
    final balanceInfo = await _coinsRepo.getBalanceInfo(coin.abbr);
    await _coinsRepo.deactivateCoinsSync([coin]);

    return balanceInfo?.spendable ?? Decimal.zero;
  }

  Future<Coin> _activatePlatformCoin(CoinSubClass network) async {
    final platformCoinAbbr = network.ticker;
    final platformCoin = _coinsRepo.getCoin(platformCoinAbbr);
    if (platformCoin == null) throw "$platformCoinAbbr platform coin not found";

    await _coinsRepo.activateCoinsSync([platformCoin]);
    return platformCoin;
  }

  @override
  Future<void> importCustomToken(Asset asset) async {
    await _coinsRepo.activateCoinsSync([asset.toCoin()]);
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
        'https://api.coingecko.com/api/v3/coins/$platform/contract/$contractAddress');

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      log('Error fetching token image URL: $e');
      return null;
    }
  }

  // TODO: replace with coin config field? This should be equivalent to the
  // coinbase id field in the config, since coinbase API is being used
  String? getNetworkApiName(CoinSubClass coinType) {
    switch (coinType) {
      case CoinSubClass.erc20:
        return 'ethereum';
      case CoinSubClass.bep20:
        return 'binance-smart-chain';
      case CoinSubClass.qrc20:
        return 'qtum';
      case CoinSubClass.ftm20:
        return 'fantom';
      case CoinSubClass.arbitrum:
        return 'arbitrum-one';
      case CoinSubClass.avx20:
        return 'avalanche';
      case CoinSubClass.moonriver:
        return 'moonriver';
      case CoinSubClass.hecoChain:
        return 'huobi-token';
      case CoinSubClass.matic:
        return 'polygon-pos';
      case CoinSubClass.hrc20:
        return 'harmony-shard-0';
      case CoinSubClass.krc20:
        return 'kcc';
      default:
        return null;
    }
  }

  @override
  Future<void> importCustomTokenLegacy(String coinId) {
    final asset = _kdfSdk.assets.assetsFromTicker(coinId).single;
    return importCustomToken(asset);
  }
}
