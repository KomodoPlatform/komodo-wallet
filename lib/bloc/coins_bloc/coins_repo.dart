import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    as kdf_rpc;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/blocs/trezor_coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/bloc_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/disable_coin/disable_coin_req.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_request.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/withdraw_details/withdraw_details.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinsRepo {
  CoinsRepo({
    required KomodoDefiSdk kdfSdk,
    required MM2 mm2,
    required TrezorCoinsBloc trezorBloc,
  })  : _kdfSdk = kdfSdk,
        _mm2 = mm2,
        trezor = trezorBloc {
    enabledAssetsChanges = StreamController<Coin>.broadcast(
      onListen: () => _enabledAssetListenerCount += 1,
      onCancel: () => _enabledAssetListenerCount -= 1,
    );
  }

  final KomodoDefiSdk _kdfSdk;
  final MM2 _mm2;
  // TODO: refactor to use repository - pin/password input events need to be
  // handled, which are currently done through the trezor "bloc"
  final TrezorCoinsBloc trezor;

  /// { acc: { abbr: address }}, used in Fiat Page
  final Map<String, Map<String, String>> _addressCache = {};
  Map<String, CexPrice> _pricesCache = {};
  final Map<String, ({double balance, double sendableBalance})> _balancesCache =
      {};

  // why could they not implement this in streamcontroller or a wrapper :(
  late final StreamController<Coin> enabledAssetsChanges;
  int _enabledAssetListenerCount = 0;
  bool get _enabledAssetsHasListeners => _enabledAssetListenerCount > 0;
  Future<void> _broadcastAsset(Coin coin) async {
    final currentUser = await _kdfSdk.auth.currentUser;
    if (currentUser != null) {
      coin.enabledType = currentUser.wallet.config.type;
    }

    if (_enabledAssetsHasListeners) {
      enabledAssetsChanges.add(coin);
    }
  }

  void flushCache() {
    // Intentionally avoid flushing the prices cache - prices are independent
    // of the user's session and should be updated on a regular basis.
    _addressCache.clear();
    _balancesCache.clear();
  }

  List<Coin> getKnownCoins() {
    final Map<AssetId, Asset> assets = _kdfSdk.assets.available;
    return assets.values.map(_assetToCoinWithoutAddress).toList();
  }

  Map<String, Coin> getKnownCoinsMap() {
    final Map<AssetId, Asset> assets = _kdfSdk.assets.available;
    return Map.fromEntries(
      assets.values.map(
        (asset) => MapEntry(asset.id.id, _assetToCoinWithoutAddress(asset)),
      ),
    );
  }

  Coin? getCoinFromId(AssetId id) {
    final asset = _kdfSdk.assets.available[id];
    if (asset == null) return null;
    return _assetToCoinWithoutAddress(asset);
  }

  @Deprecated('Use KomodoDefiSdk assets or getCoinFromId instead.')
  Coin? getCoin(String coinId) {
    if (coinId.isEmpty) return null;

    try {
      final assets = _kdfSdk.assets.assetsFromTicker(coinId);
      if (assets.isEmpty || assets.length > 1) {
        log(
          'Coin "$coinId" not found. ${assets.length} results returned',
          isError: true,
        ).ignore();
        return null;
      }
      return _assetToCoinWithoutAddress(assets.single);
    } catch (_) {
      return null;
    }
  }

  Future<List<Coin>> getWalletCoins() async {
    final currentUser = await _kdfSdk.auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    final activatedCoins = await _kdfSdk.assets.getActivatedAssets();
    return activatedCoins
        .map((Asset asset) => _assetToCoinWithoutAddress(asset))
        .toList();
  }

  Future<Coin?> getEnabledCoin(String coinId) async {
    final currentUser = await _kdfSdk.auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    final enabledAssets = await _kdfSdk.assets.getEnabledCoins();
    final enabledAsset = enabledAssets.firstWhereOrNull(
      (asset) => asset == coinId,
    );
    if (enabledAsset == null) {
      return null;
    }

    final coin = getCoin(enabledAsset);
    if (coin == null) {
      return null;
    }
    final coinAddress = await getFirstPubkey(coin.abbr);
    return coin.copyWith(
      address: coinAddress,
      state: CoinState.active,
      enabledType: currentUser.wallet.config.type,
    );
  }

  Future<List<Coin>> getEnabledCoins() async {
    final enabledCoinsMap = await getEnabledCoinsMap();
    return enabledCoinsMap.values.toList();
  }

  Future<Map<String, Coin>> getEnabledCoinsMap() async {
    final currentUser = await _kdfSdk.auth.currentUser;
    if (currentUser == null) {
      return {};
    }

    final enabledCoins = await _kdfSdk.assets.getActivatedAssets();
    final entries = await Future.wait(
      enabledCoins.map(
        (asset) async =>
            MapEntry(asset.id.id, _assetToCoinWithoutAddress(asset)),
      ),
    );
    final coinsMap = Map.fromEntries(entries);
    for (final coinId in coinsMap.keys) {
      final coin = coinsMap[coinId]!;
      final coinAddress = await getFirstPubkey(coin.abbr);
      coinsMap[coinId] = coin.copyWith(
        address: coinAddress,
        state: CoinState.active,
        enabledType: currentUser.wallet.config.type,
      );
    }
    return coinsMap;
  }

  Coin _assetToCoinWithoutAddress(Asset asset) {
    final coin = asset.toCoin();
    final balance = _balancesCache[coin.abbr]?.balance;
    final sendableBalance = _balancesCache[coin.abbr]?.sendableBalance;
    final price = _pricesCache[coin.abbr];

    Coin? parentCoin;
    if (asset.id.isChildAsset) {
      final parentCoinId = asset.id.parentId!;
      final parentAsset = _kdfSdk.assets.available[parentCoinId];
      if (parentAsset == null) {
        log('Parent coin $parentCoinId not found.', isError: true).ignore();
        parentCoin = null;
      } else {
        parentCoin = _assetToCoinWithoutAddress(parentAsset);
      }
    }

    return coin.copyWith(
      balance: balance,
      sendableBalance: sendableBalance,
      usdPrice: price,
      parentCoin: parentCoin,
    );
  }

  /// Attempts to get the balance of a coin. If the coin is not found, it will
  /// return a zero balance.
  Future<kdf_rpc.BalanceInfo> tryGetBalanceInfo(AssetId coinId) async {
    try {
      final asset = _kdfSdk.assets.available[coinId];
      if (asset == null) {
        throw ArgumentError.value(coinId, 'coinId', 'Coin $coinId not found');
      }

      final pubkeys = await _kdfSdk.pubkeys.getPubkeys(asset);
      return pubkeys.balance;
    } catch (e, s) {
      log(
        'Failed to get coin $coinId balance: $e',
        isError: true,
        path: 'coins_repo => tryGetBalanceInfo',
        trace: s,
      ).ignore();
      return kdf_rpc.BalanceInfo.zero();
    }
  }

  Future<void> activateAssetsSync(List<Asset> assets) async {
    final isSignedIn = await _kdfSdk.auth.isSignedIn();
    if (!isSignedIn) {
      final coinIdList = assets.map((e) => e.id.id).join(', ');
      log('No wallet signed in. Skipping activation of [$coinIdList}]')
          .ignore();
      return;
    }

    for (final asset in assets) {
      final coin = asset.toCoin();
      try {
        await _broadcastAsset(coin.copyWith(state: CoinState.activating));

        // ignore: deprecated_member_use
        final progress = await _kdfSdk.assets.activateAsset(assets.single).last;
        if (!progress.isSuccess) {
          throw StateError('Failed to activate coin ${asset.id.id}');
        }

        await _broadcastAsset(coin.copyWith(state: CoinState.active));
      } catch (e, s) {
        log(
          'Error activating asset: ${asset.id.id} \n$e',
          isError: true,
          path: 'coins_repo => activateAssetsSync',
          trace: s,
        ).ignore();
        await _broadcastAsset(
          asset.toCoin().copyWith(state: CoinState.suspended),
        );
      } finally {
        // Register outside of the try-catch to ensure icon is available even
        // in a suspended or failing activation status.
        if (coin.logoImageUrl?.isNotEmpty == true) {
          CoinIcon.registerCustomIcon(
            coin.id.id,
            NetworkImage(coin.logoImageUrl!),
          );
        }
      }
    }
  }

  Future<void> activateCoinsSync(List<Coin> coins) async {
    final isSignedIn = await _kdfSdk.auth.isSignedIn();
    if (!isSignedIn) {
      final coinIdList = coins.map((e) => e.abbr).join(', ');
      log('No wallet signed in. Skipping activation of [$coinIdList}]')
          .ignore();
      return;
    }

    for (final coin in coins) {
      try {
        final asset = _kdfSdk.assets.available[coin.id];
        if (asset == null) {
          log(
            'Coin ${coin.id} not found. Skipping activation.',
            isError: true,
          ).ignore();
          continue;
        }

        await _broadcastAsset(coin.copyWith(state: CoinState.activating));

        // ignore: deprecated_member_use
        final progress = await _kdfSdk.assets.activateAsset(asset).last;
        if (!progress.isSuccess) {
          throw StateError('Failed to activate coin ${coin.abbr}');
        }

        await _broadcastAsset(coin.copyWith(state: CoinState.active));
      } catch (e, s) {
        log(
          'Error activating coin: ${coin.abbr} \n$e',
          isError: true,
          trace: s,
          path: 'coins_repo->activateCoinsSync',
        ).ignore();
        await _broadcastAsset(coin.copyWith(state: CoinState.suspended));
      } finally {
        // Register outside of the try-catch to ensure icon is available even
        // in a suspended or failing activation status.
        if (coin.logoImageUrl?.isNotEmpty == true) {
          CoinIcon.registerCustomIcon(
            coin.id.id,
            NetworkImage(coin.logoImageUrl!),
          );
        }
      }
    }
  }

  Future<void> deactivateCoinsSync(List<Coin> coins) async {
    if (!await _kdfSdk.auth.isSignedIn()) return;

    for (final coin in coins) {
      await _disableCoin(coin.abbr);
      await _broadcastAsset(coin.copyWith(state: CoinState.inactive));
    }
  }

  Future<void> _disableCoin(String coinId) async {
    try {
      await _mm2.call(DisableCoinReq(coin: coinId));
    } catch (e, s) {
      log(
        'Error disabling $coinId: $e',
        path: 'api=> disableCoin => _call',
        trace: s,
        isError: true,
      ).ignore();
      return;
    }
  }

  @Deprecated('Use SDK pubkeys.getPubkeys instead and let the user '
      'select from the available options.')
  Future<String?> getFirstPubkey(String coinId) async {
    final asset = _kdfSdk.assets.findAssetsByTicker(coinId).single;
    final pubkeys = await _kdfSdk.pubkeys.getPubkeys(asset);
    if (pubkeys.keys.isEmpty) {
      return null;
    }
    return pubkeys.keys.first.address;
  }

  double? getUsdPriceByAmount(String amount, String coinAbbr) {
    final Coin? coin = getCoin(coinAbbr);
    final double? parsedAmount = double.tryParse(amount);
    final double? usdPrice = coin?.usdPrice?.price;

    if (coin == null || usdPrice == null || parsedAmount == null) {
      return null;
    }
    return parsedAmount * usdPrice;
  }

  Future<Map<String, CexPrice>?> fetchCurrentPrices() async {
    final Map<String, CexPrice>? prices =
        await _updateFromMain() ?? await _updateFromFallback();

    if (prices != null) {
      _pricesCache = prices;
    }

    return _pricesCache;
  }

  Future<CexPrice?> fetchPrice(String ticker) async {
    final Map<String, CexPrice>? prices = await fetchCurrentPrices();
    if (prices == null || !prices.containsKey(ticker)) return null;

    return prices[ticker]!;
  }

  Future<Map<String, CexPrice>?> _updateFromMain() async {
    http.Response res;
    String body;
    try {
      res = await http.get(pricesUrlV3);
      body = res.body;
    } catch (e, s) {
      log(
        'Error updating price from main: $e',
        path: 'cex_services => _updateFromMain => http.get',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e, s) {
      log(
        'Error parsing of update price from main response: $e',
        path: 'cex_services => _updateFromMain => jsonDecode',
        trace: s,
        isError: true,
      ).ignore();
    }

    if (json == null) return null;
    final Map<String, CexPrice> prices = {};
    json.forEach((String priceTicker, dynamic pricesData) {
      final pricesJson = pricesData as Map<String, dynamic>? ?? {};
      prices[priceTicker] = CexPrice(
        ticker: priceTicker,
        price: double.tryParse(pricesJson['last_price'] as String? ?? '') ?? 0,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          (pricesJson['last_updated_timestamp'] as int? ?? 0) * 1000,
        ),
        priceProvider:
            cexDataProvider(pricesJson['price_provider'] as String? ?? ''),
        change24h: double.tryParse(pricesJson['change_24h'] as String? ?? ''),
        changeProvider:
            cexDataProvider(pricesJson['change_24h_provider'] as String? ?? ''),
        volume24h: double.tryParse(pricesJson['volume24h'] as String? ?? ''),
        volumeProvider:
            cexDataProvider(pricesJson['volume_provider'] as String? ?? ''),
      );
    });
    return prices;
  }

  Future<Map<String, CexPrice>?> _updateFromFallback() async {
    final List<String> ids = (await getEnabledCoins())
        .map((c) => c.coingeckoId ?? '')
        .toList()
      ..removeWhere((id) => id.isEmpty);
    final Uri fallbackUri = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids='
      '${ids.join(',')}&vs_currencies=usd',
    );

    http.Response res;
    String body;
    try {
      res = await http.get(fallbackUri);
      body = res.body;
    } catch (e, s) {
      log(
        'Error updating price from fallback: $e',
        path: 'cex_services => _updateFromFallback => http.get',
        trace: s,
        isError: true,
      ).ignore();
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error parsing of update price from fallback response: $e',
        path: 'cex_services => _updateFromFallback => jsonDecode',
        trace: s,
        isError: true,
      ).ignore();
    }

    if (json == null) return null;
    final Map<String, CexPrice> prices = {};

    for (final MapEntry<String, dynamic> entry in json.entries) {
      final coingeckoId = entry.key;
      final pricesData = entry.value as Map<String, dynamic>? ?? {};
      if (coingeckoId == 'test-coin') continue;

      // Coins with the same coingeckoId supposedly have same usd price
      // (e.g. KMD == KMD-BEP20)
      final Iterable<Coin> samePriceCoins =
          getKnownCoins().where((coin) => coin.coingeckoId == coingeckoId);

      for (final Coin coin in samePriceCoins) {
        prices[coin.abbr] = CexPrice(
          ticker: coin.abbr,
          price: double.parse(pricesData['usd'].toString()),
        );
      }
    }

    return prices;
  }

  Future<Map<String, Coin>> updateTrezorBalances(
    Map<String, Coin> walletCoins,
  ) async {
    final walletCoinsCopy = Map<String, Coin>.from(walletCoins);
    final coins =
        walletCoinsCopy.entries.where((entry) => entry.value.isActive).toList();
    for (final MapEntry<String, Coin> entry in coins) {
      walletCoinsCopy[entry.key]!.accounts =
          await trezor.trezorRepo.getAccounts(entry.value);
    }

    return walletCoinsCopy;
  }

  Stream<Coin> updateIguanaBalances(Map<String, Coin> walletCoins) async* {
    final walletCoinsCopy = Map<String, Coin>.from(walletCoins);
    final coins =
        walletCoinsCopy.values.where((coin) => coin.isActive).toList();

    final newBalances =
        await Future.wait(coins.map((coin) => tryGetBalanceInfo(coin.id)));

    for (int i = 0; i < coins.length; i++) {
      final newBalance = newBalances[i].total.toDouble();
      final newSendableBalance = newBalances[i].spendable.toDouble();

      final balanceChanged = newBalance != coins[i].balance;
      final sendableBalanceChanged =
          newSendableBalance != coins[i].sendableBalance;
      if (balanceChanged || sendableBalanceChanged) {
        yield coins[i].copyWith(
          balance: newBalance,
          sendableBalance: newSendableBalance,
        );
        _balancesCache[coins[i].abbr] =
            (balance: newBalance, sendableBalance: newSendableBalance);
      }
    }
  }

  Future<BlocResponse<WithdrawDetails, BaseError>> withdraw(
    WithdrawRequest request,
  ) async {
    Map<String, dynamic>? response;
    try {
      response = await _mm2.call(request) as Map<String, dynamic>?;
    } catch (e, s) {
      log(
        'Error withdrawing ${request.params.coin}: $e',
        path: 'api => withdraw',
        trace: s,
        isError: true,
      ).ignore();
    }

    if (response == null) {
      log('Withdraw error: response is null', isError: true).ignore();
      return BlocResponse(
        error: TextError(error: LocaleKeys.somethingWrong.tr()),
      );
    }

    if (response['error'] != null) {
      log('Withdraw error: ${response['error']}', isError: true).ignore();
      return BlocResponse(
        error: withdrawErrorFactory.getError(response, request.params.coin),
      );
    }

    final WithdrawDetails withdrawDetails = WithdrawDetails.fromJson(
      response['result'] as Map<String, dynamic>? ?? {},
    );

    return BlocResponse(
      result: withdrawDetails,
    );
  }
}
