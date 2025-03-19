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
import 'package:logging/logging.dart';
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

  final _log = Logger('CoinsRepo');

  /// { acc: { abbr: address }}, used in Fiat Page
  final Map<String, Map<String, String>> _addressCache = {};

  // TODO: Remove since this is also being cached in the SDK
  Map<String, CexPrice> _pricesCache = {};

  // Cache structure for storing balance information to reduce SDK calls
  // This is a temporary solution until the full migration to SDK is complete
  // The type is being kept as ({ double balance, double spendable }) to minimize
  // the changes needed for full migration in the future
  final Map<String, ({double balance, double spendable})> _balancesCache = {};

  // Map to keep track of active balance watchers
  final Map<AssetId, StreamSubscription<BalanceInfo>> _balanceWatchers = {};

  /// Hack used to broadcast activated/deactivated coins to the CoinsBloc to
  /// update the status of the coins in the UI layer. This is needed as there
  /// are direct references to [CoinsRepo] that activate/deactivate coins
  /// without the [CoinsBloc] being aware of the changes (e.g. [CoinsManagerBloc]).
  late final StreamController<Coin> enabledAssetsChanges;
  // why could they not implement this in streamcontroller or a wrapper :(
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

  Future<BalanceInfo?> balance(AssetId id) => _kdfSdk.balances.getBalance(id);

  BalanceInfo? lastKnownBalance(AssetId id) => _kdfSdk.balances.lastKnown(id);

  /// Subscribe to balance updates for an asset using the SDK's balance manager
  void _subscribeToBalanceUpdates(Asset asset, Coin coin) {
    // Cancel any existing subscription for this asset
    _balanceWatchers[asset.id]?.cancel();

    // Start a new subscription
    _balanceWatchers[asset.id] =
        _kdfSdk.balances.watchBalance(asset.id).listen((balanceInfo) {
      // Update the balance cache with the new values
      _balancesCache[asset.id.id] = (
        balance: balanceInfo.total.toDouble(),
        spendable: balanceInfo.spendable.toDouble(),
      );
    });
  }

  void flushCache() {
    // Intentionally avoid flushing the prices cache - prices are independent
    // of the user's session and should be updated on a regular basis.
    _addressCache.clear();
    _balancesCache.clear();

    // Cancel all balance watchers
    for (final subscription in _balanceWatchers.values) {
      subscription.cancel();
    }
    _balanceWatchers.clear();
  }

  void dispose() {
    for (final subscription in _balanceWatchers.values) {
      subscription.cancel();
    }
    _balanceWatchers.clear();

    enabledAssetsChanges.close();
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
        _log.warning(
          'Coin "$coinId" not found. ${assets.length} results returned',
        );
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
    final coinAddress = await getFirstPubkey(coin.id.id);
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
      final coinAddress = await getFirstPubkey(coin.id.id);
      coinsMap[coinId] = coin.copyWith(
        address: coinAddress,
        state: CoinState.active,
        enabledType: currentUser.wallet.config.type,
      );

      // Set up balance watcher for this coin
      final asset = enabledCoins.firstWhere((asset) => asset.id.id == coinId);
      _subscribeToBalanceUpdates(asset, coinsMap[coinId]!);
    }
    return coinsMap;
  }

  Coin _assetToCoinWithoutAddress(Asset asset) {
    final coin = asset.toCoin();
    final balanceInfo = _balancesCache[coin.id.id];
    final price = _pricesCache[coin.id.id];

    Coin? parentCoin;
    if (asset.id.isChildAsset) {
      final parentCoinId = asset.id.parentId!;
      final parentAsset = _kdfSdk.assets.available[parentCoinId];
      if (parentAsset == null) {
        _log.warning('Parent coin $parentCoinId not found.');
        parentCoin = null;
      } else {
        parentCoin = _assetToCoinWithoutAddress(parentAsset);
      }
    }

    // For backward compatibility, still set the deprecated fields
    // This will be removed in a future migration step
    return coin.copyWith(
      sendableBalance: balanceInfo?.spendable,
      usdPrice: price,
      parentCoin: parentCoin,
    );
  }

  /// Attempts to get the balance of a coin. If the coin is not found, it will
  /// return a zero balance.
  Future<kdf_rpc.BalanceInfo> tryGetBalanceInfo(AssetId coinId) async {
    try {
      final balanceInfo = await _kdfSdk.balances.getBalance(coinId);
      return balanceInfo;
    } catch (e, s) {
      _log.shout('Failed to get coin $coinId balance', e, s);
      return kdf_rpc.BalanceInfo.zero();
    }
  }

  Future<void> activateAssetsSync(List<Asset> assets) async {
    final isSignedIn = await _kdfSdk.auth.isSignedIn();
    if (!isSignedIn) {
      final coinIdList = assets.map((e) => e.id.id).join(', ');
      _log.warning(
        'No wallet signed in. Skipping activation of [$coinIdList]',
      );
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

        // Set up balance watcher for the newly activated asset
        _subscribeToBalanceUpdates(asset, coin);
      } catch (e, s) {
        _log.shout('Error activating asset: ${asset.id.id}', e, s);
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
      final coinIdList = coins.map((e) => e.id.id).join(', ');
      _log.warning(
        'No wallet signed in. Skipping activation of [$coinIdList]',
      );
      return;
    }

    for (final coin in coins) {
      try {
        final asset = _kdfSdk.assets.available[coin.id];
        if (asset == null) {
          _log.warning('Coin ${coin.id} not found. Skipping activation.');
          continue;
        }

        await _broadcastAsset(coin.copyWith(state: CoinState.activating));

        // ignore: deprecated_member_use
        final progress = await _kdfSdk.assets.activateAsset(asset).last;
        if (!progress.isSuccess) {
          throw StateError('Failed to activate coin ${coin.id.id}');
        }

        await _broadcastAsset(coin.copyWith(state: CoinState.active));

        // Set up balance watcher for the newly activated coin
        _subscribeToBalanceUpdates(asset, coin);
      } catch (e, s) {
        _log.shout('Error activating coin: ${coin.id.id} \n$e', e, s);
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
      // Cancel balance watcher for this coin
      _balanceWatchers[coin.id]?.cancel();
      _balanceWatchers.remove(coin.id);

      await _disableCoin(coin.id.id);
      await _broadcastAsset(coin.copyWith(state: CoinState.inactive));
    }
  }

  Future<void> _disableCoin(String coinId) async {
    try {
      await _mm2.call(DisableCoinReq(coin: coinId));
    } catch (e, s) {
      _log.shout('Error disabling $coinId', e, s);
      return;
    }
  }

  @Deprecated('Use SDK pubkeys.getPubkeys instead and let the user '
      'select from the available options.')
  Future<String?> getFirstPubkey(String coinId) async {
    final asset = _kdfSdk.assets.findAssetsByConfigId(coinId).single;
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
    try {
      // Try to use the SDK's price manager to get prices for active coins
      final activatedAssets = await _kdfSdk.assets.getActivatedAssets();
      for (final asset in activatedAssets) {
        try {
          // Use maybeFiatPrice to avoid errors for assets not tracked by CEX
          final fiatPrice = await _kdfSdk.marketData.maybeFiatPrice(asset.id);
          if (fiatPrice != null) {
            // Update the price cache with the value from the SDK
            _pricesCache[asset.id.id] = CexPrice(
              ticker: asset.id.id,
              price: fiatPrice.toDouble(),
              lastUpdated: DateTime.now(),
            );
          }
        } catch (e) {
          _log.warning('Failed to get price for ${asset.id.id}: $e');
        }
      }

      // Still use the backup methods for other coins or if SDK fails
      final Map<String, CexPrice>? fallbackPrices =
          await _updateFromMain() ?? await _updateFromFallback();

      if (fallbackPrices != null) {
        // Merge fallback prices with SDK prices (don't overwrite SDK prices)
        fallbackPrices.forEach((key, value) {
          if (!_pricesCache.containsKey(key)) {
            _pricesCache[key] = value;
          }
        });
      }
    } catch (e, s) {
      _log.shout('Error refreshing prices from SDK', e, s);

      // Fallback to the existing methods
      final Map<String, CexPrice>? prices =
          await _updateFromMain() ?? await _updateFromFallback();

      if (prices != null) {
        _pricesCache = prices;
      }
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
      _log.shout('Error updating price from main: $e', e, s);
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e, s) {
      _log.shout('Error parsing of update price from main response', e, s);
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
      _log.shout('Error updating price from fallback', e, s);
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>?;
    } catch (e, s) {
      _log.shout('Error parsing of update price from fallback response', e, s);
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
        prices[coin.id.id] = CexPrice(
          ticker: coin.id.id,
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

  /// Updates balances for active coins by querying the SDK
  /// Yields coins that have balance changes
  Stream<Coin> updateIguanaBalances(Map<String, Coin> walletCoins) async* {
    // This method is now mostly a fallback, as we primarily use
    // the SDK's balance watchers to get live updates. We still
    // implement it for backward compatibility.
    final walletCoinsCopy = Map<String, Coin>.from(walletCoins);
    final coins =
        walletCoinsCopy.values.where((coin) => coin.isActive).toList();

    // Get balances from the SDK for all active coins
    for (final coin in coins) {
      try {
        // Use the SDK's balance manager to get the current balance
        final balanceInfo = await _kdfSdk.balances.getBalance(coin.id);

        // Convert to double for compatibility with existing code
        final newBalance = balanceInfo.total.toDouble();
        final newSpendable = balanceInfo.spendable.toDouble();

        // Get the current cached values
        final cachedBalance = _balancesCache[coin.id.id]?.balance;
        final cachedSpendable = _balancesCache[coin.id.id]?.spendable;

        // Check if balance has changed
        final balanceChanged =
            cachedBalance == null || newBalance != cachedBalance;
        final spendableChanged =
            cachedSpendable == null || newSpendable != cachedSpendable;

        // Only yield if there's a change
        if (balanceChanged || spendableChanged) {
          // Update the cache
          _balancesCache[coin.id.id] =
              (balance: newBalance, spendable: newSpendable);

          // Yield updated coin with new balance
          // We still set both the deprecated fields and rely on the SDK
          // for future access to maintain backward compatibility
          yield coin.copyWith(
            sendableBalance: newSpendable,
          );
        }
      } catch (e, s) {
        _log.warning('Failed to update balance for ${coin.id}', e, s);
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
      _log.shout('Error withdrawing ${request.params.coin}', e, s);
    }

    if (response == null) {
      _log.shout('Withdraw error: response is null');
      return BlocResponse(
        error: TextError(error: LocaleKeys.somethingWrong.tr()),
      );
    }

    if (response['error'] != null) {
      _log.shout('Withdraw error: ${response['error']}');
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
