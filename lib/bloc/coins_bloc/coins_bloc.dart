import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'coins_event.dart';
part 'coins_state.dart';

/// Responsible for coin activation, deactivation, syncing, and fiat price
class CoinsBloc extends Bloc<CoinsEvent, CoinsState> {
  CoinsBloc(
    this._kdfSdk,
    this._coinsRepo,
  ) : super(CoinsState.initial()) {
    on<CoinsStarted>(_onCoinsStarted, transformer: droppable());
    // TODO: move auth listener to ui layer: bloclistener should fire auth events
    on<CoinsBalanceMonitoringStarted>(_onCoinsBalanceMonitoringStarted);
    on<CoinsBalanceMonitoringStopped>(_onCoinsBalanceMonitoringStopped);
    on<CoinsBalancesRefreshed>(_onCoinsRefreshed, transformer: droppable());
    on<CoinsActivated>(_onCoinsActivated, transformer: concurrent());
    on<CoinsDeactivated>(_onCoinsDeactivated, transformer: concurrent());
    on<CoinsPricesUpdated>(_onPricesUpdated, transformer: droppable());
    on<CoinsSessionStarted>(_onLogin, transformer: restartable());
    on<CoinsSessionEnded>(_onLogout, transformer: restartable());
    on<CoinsWalletCoinUpdated>(_onWalletCoinUpdated, transformer: sequential());
    on<CoinsPubkeysRequested>(
      _onCoinsPubkeysRequested,
      transformer: concurrent(),
    );
  }

  final KomodoDefiSdk _kdfSdk;
  final CoinsRepo _coinsRepo;

  final _log = Logger('CoinsBloc');

  StreamSubscription<Coin>? _enabledCoinsSubscription;
  Timer? _updateBalancesTimer;
  Timer? _updatePricesTimer;

  @override
  Future<void> close() async {
    await _enabledCoinsSubscription?.cancel();
    _updateBalancesTimer?.cancel();
    _updatePricesTimer?.cancel();

    await super.close();
  }

  Future<void> _onCoinsPubkeysRequested(
    CoinsPubkeysRequested event,
    Emitter<CoinsState> emit,
  ) async {
    try {
      // Return early if the coin is not yet in wallet coins, meaning that
      // it's not yet activated.
      // TODO: update this once coin activation is fully handled by the SDK
      final coin = state.walletCoins[event.coinId];
      if (coin == null) return;

      // Get pubkeys from the SDK through the repo
      final asset = _kdfSdk.assets.available[coin.id]!;
      final pubkeys = await _kdfSdk.pubkeys.getPubkeys(asset);

      // Update state with new pubkeys
      emit(
        state.copyWith(
          pubkeys: {
            ...state.pubkeys,
            event.coinId: pubkeys,
          },
        ),
      );
    } catch (e, s) {
      _log.shout('Failed to get pubkeys for ${event.coinId}', e, s);
    }
  }

  Future<void> _onCoinsStarted(
    CoinsStarted event,
    Emitter<CoinsState> emit,
  ) async {
    emit(state.copyWith(coins: _coinsRepo.getKnownCoinsMap()));

    final existingUser = await _kdfSdk.auth.currentUser;
    if (existingUser != null) {
      add(CoinsSessionStarted(existingUser));
    }

    add(CoinsPricesUpdated());
    _updatePricesTimer?.cancel();
    _updatePricesTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(CoinsPricesUpdated()),
    );

    // This is used to connect [CoinsBloc] to [CoinsManagerBloc] via [CoinsRepo],
    // since coins manager bloc activates and deactivates coins using the repository.
    // Other auto-activation sources, like the DEX, will also use the repository
    // to activate coins, so this subscription is needed to keep the coins bloc
    // in sync with the coins manager and other auto-activation sources.
    await _enabledCoinsSubscription?.cancel();
    _enabledCoinsSubscription = _coinsRepo.enabledAssetsChanges.stream.listen(
      (Coin coin) => add(CoinsWalletCoinUpdated(coin)),
    );
  }

  Future<void> _onCoinsRefreshed(
    CoinsBalancesRefreshed event,
    Emitter<CoinsState> emit,
  ) async {
    final coinUpdateStream = _coinsRepo.updateIguanaBalances(state.walletCoins);
    await emit.forEach(
      coinUpdateStream,
      onData: (Coin coin) {
        if (!state.walletCoins.containsKey(coin.abbr)) {
          _log.warning(
            'Coin ${coin.abbr} not found in wallet coins, skipping update',
          );
          return state;
        }
        return state.copyWith(
          walletCoins: {...state.walletCoins, coin.id.id: coin},
          coins: {...state.coins, coin.id.id: coin},
        );
      },
    );

    final coinUpdates = _syncIguanaCoinsStates();
    await emit.forEach(
      coinUpdates,
      onData: (coin) =>
          state.copyWith(walletCoins: {...state.walletCoins, coin.id.id: coin}),
      onError: (error, stackTrace) {
        _log.severe('Error syncing iguana coins states', error, stackTrace);
        return state;
      },
    );
  }

  Future<void> _onWalletCoinUpdated(
    CoinsWalletCoinUpdated event,
    Emitter<CoinsState> emit,
  ) async {
    final coin = event.coin;
    final walletCoins = Map<String, Coin>.of(state.walletCoins);

    if (coin.isInactive) {
      walletCoins.remove(coin.id.id);
      emit(state.copyWith(walletCoins: walletCoins));
      return;
    }

    final walletCoin = state.walletCoins[coin.id.id];
    final hasCoinStateChanged =
        walletCoin == null || walletCoin.state != coin.state;

    // Only update the wallet coins list if state has changed, since it does not
    // concern the coins list.
    if (hasCoinStateChanged) {
      emit(state.copyWith(walletCoins: {...walletCoins, coin.id.id: coin}));
    }
  }

  Future<void> _onCoinsBalanceMonitoringStopped(
    CoinsBalanceMonitoringStopped event,
    Emitter<CoinsState> emit,
  ) async {
    _updateBalancesTimer?.cancel();
  }

  Future<void> _onCoinsBalanceMonitoringStarted(
    CoinsBalanceMonitoringStarted event,
    Emitter<CoinsState> emit,
  ) async {
    _updateBalancesTimer?.cancel();
    _updateBalancesTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => add(CoinsBalancesRefreshed()),
    );
  }

  Future<void> _onCoinsActivated(
    CoinsActivated event,
    Emitter<CoinsState> emit,
  ) async {
    // Start off by emitting the newly activated coins so that they all appear
    // in the list at once, rather than one at a time as they are activated
    emit(_prePopulateListWithActivatingCoins(event.coinIds));
    await _activateCoins(event.coinIds, emit);

    final currentWallet = await _kdfSdk.currentWallet();
    if (currentWallet?.config.type == WalletType.iguana ||
        currentWallet?.config.type == WalletType.hdwallet) {
      final coinUpdates = _syncIguanaCoinsStates();
      await emit.forEach(
        coinUpdates,
        onData: (coin) => state
            .copyWith(walletCoins: {...state.walletCoins, coin.id.id: coin}),
      );
    }

    add(CoinsBalancesRefreshed());
  }

  Future<void> _onCoinsDeactivated(
    CoinsDeactivated event,
    Emitter<CoinsState> emit,
  ) async {
    final currentWalletCoins = state.walletCoins;
    final currentCoins = state.coins;
    final Set<String> coinIdsToDisable = {...event.coinIds};

    if (currentWalletCoins.isEmpty) {
      _log.warning('No wallet coins to disable');
      return;
    }

    // Disable all child coins of the parent coins being deactivated.
    for (final assetId in event.coinIds) {
      final coin = currentWalletCoins[assetId];
      if (coin != null) {
        coinIdsToDisable.addAll(
          currentWalletCoins.values
              .where((c) => c.parentCoin?.abbr == coin.abbr)
              .map((c) => c.abbr),
        );
      }
    }

    // Remove coins from the state early to avoid reactivation
    // via pubkey requests
    emit(
      _flushCoinsFromState(currentWalletCoins, coinIdsToDisable, currentCoins),
    );

    // Remove coins from the SDK metadata field before deactivating to
    // prevent reactivation on login or via state syncing tasks.
    final coinsToDisable = event.coinIds
        .map((id) => currentWalletCoins[id])
        .whereType<Coin>()
        .toList();
    await _coinsRepo.deactivateCoinsSync(coinsToDisable, notify: false);
  }

  CoinsState _flushCoinsFromState(
    Map<String, Coin> currentWalletCoins,
    Set<String> coinsToDisable,
    Map<String, Coin> currentCoins,
  ) {
    final updatedWalletCoins = Map.fromEntries(
      currentWalletCoins.entries
          .where((entry) => !coinsToDisable.contains(entry.key)),
    );
    final updatedCoins = Map<String, Coin>.of(currentCoins);
    for (final assetId in coinsToDisable) {
      final coin = currentWalletCoins[assetId]!;
      updatedCoins[coin.id.id] = coin.copyWith(state: CoinState.inactive);
    }
    return state.copyWith(walletCoins: updatedWalletCoins, coins: updatedCoins);
  }

  Future<void> _onPricesUpdated(
    CoinsPricesUpdated event,
    Emitter<CoinsState> emit,
  ) async {
    final prices = await _coinsRepo.fetchCurrentPrices();
    if (prices == null) {
      _log.severe('Coin prices list empty/null');
      return;
    }
    final didPricesChange = !mapEquals(state.prices, prices);
    if (!didPricesChange) {
      _log.info('Coin prices list unchanged');
      return;
    }

    Map<String, Coin> updateCoinsWithPrices(Map<String, Coin> coins) {
      final map = coins.map((key, coin) {
        // Use configSymbol to lookup for backwards compatibility with the old,
        // string-based price list (and fallback)
        final price = prices[coin.id.symbol.configSymbol];
        if (price != null) {
          return MapEntry(key, coin.copyWith(usdPrice: price));
        }
        return MapEntry(key, coin);
      });

      return Map.of(map).unmodifiable();
    }

    emit(
      state.copyWith(
        prices: prices.unmodifiable(),
        coins: updateCoinsWithPrices(state.coins),
        walletCoins: updateCoinsWithPrices(state.walletCoins),
      ),
    );
  }

  Future<void> _onLogin(
    CoinsSessionStarted event,
    Emitter<CoinsState> emit,
  ) async {
    try {
      _coinsRepo.flushCache();
      final Wallet currentWallet = event.signedInUser.wallet;

      // Start off by emitting the newly activated coins so that they all appear
      // in the list at once, rather than one at a time as they are activated
      final coinsToActivate = currentWallet.config.activatedCoins;
      emit(_prePopulateListWithActivatingCoins(coinsToActivate));
      await _activateCoins(coinsToActivate, emit);

      add(CoinsBalancesRefreshed());
      add(CoinsBalanceMonitoringStarted());
    } catch (e, s) {
      _log.shout('Error on login', e, s);
    }
  }

  Future<void> _onLogout(
    CoinsSessionEnded event,
    Emitter<CoinsState> emit,
  ) async {
    add(CoinsBalanceMonitoringStopped());

    emit(
      state.copyWith(
        walletCoins: {},
      ),
    );
    _coinsRepo.flushCache();
  }

  Future<void> _activateCoins(
    Iterable<String> coins,
    Emitter<CoinsState> emit,
  ) async {
    if (coins.isEmpty) {
      _log.warning('No coins to activate');
      return;
    }

    // Filter out assets that are not available in the SDK. This is to avoid activation
    // activation loops for assets not supported by the SDK.this may happen if the wallet
    // has assets that were removed from the SDK or the config has unsupported default
    // assets.
    final coinsToActivate = coins
        .map((coin) => _kdfSdk.assets.findAssetsByConfigId(coin))
        .where((assetsSet) => assetsSet.isNotEmpty)
        .map((assetsSet) => assetsSet.single);

    final enableFutures = coinsToActivate
        .map((asset) => _coinsRepo.activateAssetsSync([asset]))
        .toList();

    // Ignore the return type here and let the broadcast handle the state updates as
    // coins are activated.
    await Future.wait(enableFutures);
  }

  CoinsState _prePopulateListWithActivatingCoins(Iterable<String> coins) {
    final knownCoins = _coinsRepo.getKnownCoinsMap();
    final activatingCoins = Map<String, Coin>.fromIterable(
      coins
          .map(
            (coin) {
              final sdkCoin = knownCoins[coin];
              return sdkCoin?.copyWith(state: CoinState.activating);
            },
          )
          .where((coin) => coin != null)
          .cast<Coin>(),
      key: (element) => (element as Coin).id.id,
    );
    return state.copyWith(
      walletCoins: {...state.walletCoins, ...activatingCoins},
      coins: {...knownCoins, ...state.coins, ...activatingCoins},
    );
  }

  /// Yields one coin at a time to provide visual feedback to the user as
  /// coins are activated.
  ///
  /// When multiple coins are found for the provided IDs,
  Stream<Coin> _syncIguanaCoinsStates() async* {
    final coinsBlocWalletCoinsState = state.walletCoins;
    final previouslyActivatedCoinIds =
        (await _kdfSdk.currentWallet())?.config.activatedCoins ?? [];

    final walletAssets = <Asset>[];
    for (final coinId in previouslyActivatedCoinIds) {
      final assets = _kdfSdk.assets.findAssetsByConfigId(coinId);
      if (assets.isEmpty) {
        _log.warning(
          'No assets found for activated coin ID: $coinId. '
          'This coin will be skipped during synchronization.',
        );
        continue;
      }
      if (assets.length > 1) {
        final assetIds = assets.map((a) => a.id.id).join(', ');
        _log.shout('Multiple assets found for activated coin ID: $coinId. '
            'Expected single asset, found ${assets.length}: $assetIds. ');
      }

      // This is expected to throw if there are multiple assets, to stick
      // to the strategy of using `.single` elsewhere in the codebase.
      walletAssets.add(assets.single);
    }

    final coinsToSync =
        _getWalletCoinsNotInState(walletAssets, coinsBlocWalletCoinsState);
    if (coinsToSync.isNotEmpty) {
      _log.info(
        'Found ${coinsToSync.length} wallet coins not in state, '
        'syncing them to state as suspended',
      );
      yield* Stream.fromIterable(coinsToSync);
    }
  }

  List<Coin> _getWalletCoinsNotInState(
      List<Asset> walletAssets, Map<String, Coin> coinsBlocWalletCoinsState) {
    final List<Coin> coinsToSyncToState = [];

    final enabledAssetsNotInState = walletAssets
        .where((asset) => !coinsBlocWalletCoinsState.containsKey(asset.id.id))
        .toList();

    // Show assets that are in the wallet metadata but not in the state. This might
    // happen if activation occurs outside of the coins bloc, like the dex or
    // coins manager auto-activation or deactivation.
    for (final asset in enabledAssetsNotInState) {
      final coin = _coinsRepo.getCoinFromId(asset.id);
      if (coin == null) {
        _log.shout(
          'Coin ${asset.id.id} not found in coins repository, '
          'skipping sync from wallet metadata to coins bloc state.',
        );
        continue;
      }

      coinsToSyncToState.add(coin.copyWith(state: CoinState.suspended));
    }

    return coinsToSyncToState;
  }
}
