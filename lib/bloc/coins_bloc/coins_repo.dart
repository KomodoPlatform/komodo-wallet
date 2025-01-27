import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    as kdf_rpc;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
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
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
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
    _addressCache.clear();
    _balancesCache.clear();
  }

  Future<List<Coin>> getKnownCoins() async {
    final assets = _kdfSdk.assets.available;
    final customTokens = await _kdfSdk.getCustomTokens();
    final customTokenAssets =
        customTokens.map((coin) => coin.toAsset()).toList();
    assets.addAll(
      Map.fromEntries(
        customTokenAssets.map((asset) => MapEntry(asset.id, asset)),
      ),
    );
    return assets.values.map(_assetToCoinWithoutAddress).toList();
  }

  Future<Map<String, Coin>> getKnownCoinsMap() async {
    final assets = _kdfSdk.assets.available;
    final coinMapEntries = Map.fromEntries(
      assets.values.map(
        (asset) => MapEntry(asset.id.id, _assetToCoinWithoutAddress(asset)),
      ),
    );
    final customTokens = await _kdfSdk.getCustomTokens();
    for (final customToken in customTokens) {
      coinMapEntries[customToken.abbr] = customToken;
    }
    return coinMapEntries;
  }

  Coin? getCoin(String coinId) {
    try {
      final assets = _kdfSdk.assets.assetsFromTicker(coinId);
      if (assets.isEmpty || assets.length > 1) {
        log(
          'Coin $coinId not found. ${assets.length} results returned',
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

    final activatedCoins = currentUser.wallet.config.activatedCoins;
    final knownCoins = await getKnownCoinsMap();
    return activatedCoins
        .map((String coinId) => knownCoins[coinId])
        .where((Coin? coin) => coin != null)
        .cast<Coin>()
        .toList();
  }

  Future<Coin?> getEnabledCoin(String coinId) async {
    final enabledAssets = await getEnabledCoinsMap();
    final coin = enabledAssets[coinId];
    if (coin == null) return null;
    return coin;
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
      final parentCoinId = asset.id.parentId!.id;
      final parentAssets = _kdfSdk.assets.assetsFromTicker(parentCoinId);
      if (parentAssets.length != 1) {
        log(
          'Parent coin $parentCoinId not found. ${parentAssets.length} results returned',
          isError: true,
        ).ignore();
      }
      final parentAsset = parentAssets.single;
      parentCoin = _assetToCoinWithoutAddress(parentAsset);
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
  Future<kdf_rpc.BalanceInfo> tryGetBalanceInfo(String abbr) async {
    try {
      final assets = _kdfSdk.assets.findAssetsByTicker(abbr).nonNulls;
      if (assets.isEmpty) {
        throw Exception("Asset $abbr not found");
      }

      if (assets.length == 1) {
        final pubkeys = await _kdfSdk.pubkeys.getPubkeys(assets.single);
        return pubkeys.balance;
      }

      final balances = await Future.wait(
        assets.map((asset) => _kdfSdk.pubkeys.getPubkeys(asset)),
      );
      return balances.fold<kdf_rpc.BalanceInfo>(
        kdf_rpc.BalanceInfo.zero(),
        (a, b) => a + b.balance,
      );
    } catch (e, s) {
      log(
        'Failed to get coin $abbr balance: $e',
        isError: true,
        path: 'coins_repo => tryGetBalanceInfo',
        trace: s,
      ).ignore();
      return kdf_rpc.BalanceInfo.zero();
    }
  }

  Future<void> activateCoinsSync(List<Coin> coins) async {
    if (!await _kdfSdk.auth.isSignedIn()) return;
    final enabledAssets = await getEnabledCoinsMap();

    for (final coin in coins) {
      try {
        if (enabledAssets.containsKey(coin.abbr)) {
          continue;
        }

        final asset = _kdfSdk.assets.findAssetsByTicker(coin.abbr).single;
        await _broadcastAsset(coin.copyWith(state: CoinState.activating));

        if (coin.parentCoin != null) {
          await _activateParentAsset(coin);
        }
        // ignore: deprecated_member_use
        await _kdfSdk.assets.activateAsset(asset).last;

        await _broadcastAsset(coin.copyWith(state: CoinState.active));
      } catch (e, s) {
        log(
          'Error activating coin: ${coin.abbr} \n$e',
          isError: true,
          trace: s,
        ).ignore();
        await _broadcastAsset(coin.copyWith(state: CoinState.suspended));
      }
    }
  }

  Future<void> _activateParentAsset(Coin coin) async {
    final parentAsset =
        _kdfSdk.assets.findAssetsByTicker(coin.parentCoin!.abbr).single;
    await _broadcastAsset(
      coin.parentCoin!.copyWith(state: CoinState.activating),
    );
    // ignore: deprecated_member_use
    await _kdfSdk.assets.activateAsset(parentAsset).last;
    await _broadcastAsset(
      coin.parentCoin!.copyWith(state: CoinState.active),
    );
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
      final Iterable<Coin> samePriceCoins = (await getKnownCoins())
          .where((coin) => coin.coingeckoId == coingeckoId);

      for (final Coin coin in samePriceCoins) {
        prices[coin.abbr] = CexPrice(
          ticker: coin.abbr,
          price: double.parse(pricesData['usd'].toString()),
        );
      }
    }

    return prices;
  }

  Future<Balance?> getBalanceInfo(String abbr) async {
    final pubkeys = await getSdkAsset(_kdfSdk, abbr).getPubkeys();
    return pubkeys.balance;
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

  Stream<Coin> updateIguanaBalances(
    Map<String, Coin> walletCoins,
  ) async* {
    final walletCoinsCopy = Map<String, Coin>.from(walletCoins);
    final coins =
        walletCoinsCopy.values.where((coin) => coin.isActive).toList();

    final newBalances =
        await Future.wait(coins.map((coin) => tryGetBalanceInfo(coin.abbr)));

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
