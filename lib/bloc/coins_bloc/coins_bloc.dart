import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/cex_market_data/sdk_auth_activation_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/trading_status/trading_status_service.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'coins_event.dart';
part 'coins_state.dart';

/// Responsible for coin activation, deactivation, syncing, and fiat price
class CoinsBloc extends Bloc<CoinsEvent, CoinsState> {
  CoinsBloc(this._kdfSdk, this._coinsRepo, this._tradingStatusService)
    : super(CoinsState.initial()) {
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
  final TradingStatusService _tradingStatusService;

  final _log = Logger('CoinsBloc');

  StreamSubscription<Coin>? _enabledCoinsSubscription;
  Timer? _updateBalancesTimer;
  Timer? _updatePricesTimer;
  bool _isInitialActivationInProgress = false;

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
      if (_isInitialActivationInProgress) {
        _log.info(
          'Skipping pubkeys request for ${event.coinId} while initial activation is in progress.',
        );
        return;
      }

      // Coins are added to walletCoins before activation even starts
      // to show them in the UI regardless of activation state.
      // If the coin is not found here, it means the auth state handler
      // has not pre-populated the list with activating coins yet.
      final coin = state.walletCoins[event.coinId];
      if (coin == null) {
        _log.warning(
          'Coin ${event.coinId} not found in wallet coins, cannot fetch pubkeys',
        );
        return;
      }

      // Get pubkeys from the SDK through the repo
      final asset = _kdfSdk.assets.available[coin.id]!;
      final pubkeys = await _kdfSdk.pubkeys.getPubkeys(asset);

      // Update state with new pubkeys
      emit(state.copyWith(pubkeys: {...state.pubkeys, event.coinId: pubkeys}));
    } catch (e, s) {
      _log.shout('Failed to get pubkeys for ${event.coinId}', e, s);
    }
  }

  Future<void> _onCoinsStarted(
    CoinsStarted event,
    Emitter<CoinsState> emit,
  ) async {
    // Wait for trading status service to receive initial status before
    // populating coins list. This ensures geo-blocked assets are properly
    // filtered from the start, preventing them from appearing in the UI
    // before filtering is applied.
    //
    // TODO: UX Improvement - For faster startup, populate coins immediately
    // and reactively filter when trading status updates arrive. This would
    // eliminate startup delay (~100-500ms) but requires UI to handle dynamic
    // removal of blocked assets. See TradingStatusService._currentStatus for
    // related trade-offs.
    await _tradingStatusService.initialStatusReady;

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
      currentWalletCoins.entries.where(
        (entry) => !coinsToDisable.contains(entry.key),
      ),
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
    try {
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

        // .map already returns a new map, so we don't need to create a new map
        return map.unmodifiable();
      }

      emit(
        state.copyWith(
          prices: prices.unmodifiable(),
          coins: updateCoinsWithPrices(state.coins),
          walletCoins: updateCoinsWithPrices(state.walletCoins),
        ),
      );
    } catch (e, s) {
      _log.shout('Error on prices updated', e, s);
    }
  }

  Future<void> _onLogin(
    CoinsSessionStarted event,
    Emitter<CoinsState> emit,
  ) async {
    _isInitialActivationInProgress = true;
    try {
      // Ensure any cached addresses/pubkeys from a previous wallet are cleared
      // so that UI fetches fresh pubkeys for the newly logged-in wallet.
      emit(state.copyWith(pubkeys: {}));
      _coinsRepo.flushCache();
      final Wallet currentWallet = event.signedInUser.wallet;

      // Start off by emitting the newly activated coins so that they all appear
      // in the list at once, rather than one at a time as they are activated
      final coinsToActivate = currentWallet.config.activatedCoins;

      // Filter out blocked coins before activation
      final allowedCoins = coinsToActivate.where((coinId) {
        final assets = _kdfSdk.assets.findAssetsByConfigId(coinId);
        if (assets.isEmpty) return false;
        return !_tradingStatusService.isAssetBlocked(assets.single.id);
      });

      emit(_prePopulateListWithActivatingCoins(allowedCoins));
      _scheduleInitialBalanceRefresh(allowedCoins);
      final activationFuture = _activateCoins(allowedCoins, emit);
      unawaited(() async {
        try {
          await activationFuture;
        } catch (e, s) {
          _log.shout('Error during initial coin activation', e, s);
        } finally {
          _isInitialActivationInProgress = false;
        }
      }());
    } catch (e, s) {
      _isInitialActivationInProgress = false;
      _log.shout('Error on login', e, s);
    }
  }

  Future<void> _onLogout(
    CoinsSessionEnded event,
    Emitter<CoinsState> emit,
  ) async {
    _resetInitialActivationState();
    add(CoinsBalanceMonitoringStopped());

    emit(
      state.copyWith(
        walletCoins: {},
        // Clear pubkeys to avoid showing addresses from the previous wallet
        // after logout or wallet switch.
        pubkeys: {},
      ),
    );
    _coinsRepo.flushCache();
  }

  void _scheduleInitialBalanceRefresh(Iterable<String> coinsToActivate) {
    if (isClosed) return;

    final knownCoins = _coinsRepo.getKnownCoinsMap();
    final walletCoinsForThreshold = coinsToActivate
        .map((coinId) => knownCoins[coinId])
        .whereType<Coin>()
        .toList();

    if (walletCoinsForThreshold.isEmpty) {
      add(CoinsBalancesRefreshed());
      add(CoinsBalanceMonitoringStarted());
      return;
    }

    unawaited(() async {
      var triggeredByThreshold = false;
      try {
        triggeredByThreshold = await _kdfSdk.waitForEnabledCoinsToPassThreshold(
          walletCoinsForThreshold,
          threshold: 0.8,
          timeout: const Duration(minutes: 1),
        );
      } catch (e, s) {
        _log.shout(
          'Failed while waiting for enabled coins threshold during login',
          e,
          s,
        );
      }

      if (isClosed) {
        return;
      }

      if (triggeredByThreshold) {
        _log.fine(
          'Initial balance refresh triggered after 80% of coins activated.',
        );
      } else {
        _log.fine(
          'Initial balance refresh triggered after timeout while waiting for coin activation.',
        );
      }

      add(CoinsBalancesRefreshed());
      add(CoinsBalanceMonitoringStarted());
    }());
  }

  void _resetInitialActivationState() {
    _isInitialActivationInProgress = false;
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
    final availableAssets = coins
        .map((coin) => _kdfSdk.assets.findAssetsByConfigId(coin))
        .where((assetsSet) => assetsSet.isNotEmpty)
        .map((assetsSet) => assetsSet.single);

    // Filter out blocked assets
    final coinsToActivate = _tradingStatusService.filterAllowedAssets(
      availableAssets.toList(),
    );

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
          .map((coin) {
            final sdkCoin = knownCoins[coin];
            return sdkCoin?.copyWith(state: CoinState.activating);
          })
          .where((coin) => coin != null)
          .cast<Coin>()
          // Do not pre-populate zhtlc coins, as they require configuration
          // and longer activation times, and are handled separately.
          .where((coin) => coin.id.subClass != CoinSubClass.zhtlc),
      key: (element) => (element as Coin).id.id,
    );
    return state.copyWith(
      walletCoins: {...state.walletCoins, ...activatingCoins},
      coins: {...knownCoins, ...state.coins, ...activatingCoins},
    );
  }
}
