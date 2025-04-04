import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/trezor_coins_bloc.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
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
    this._trezorBloc,
    this._mm2Api,
  ) : super(CoinsState.initial()) {
    on<CoinsStarted>(_onCoinsStarted, transformer: droppable());
    // TODO: move auth listener to ui layer: bloclistener should fire auth events
    on<CoinsBalanceMonitoringStarted>(_onCoinsBalanceMonitoringStarted);
    on<CoinsBalanceMonitoringStopped>(_onCoinsBalanceMonitoringStopped);
    on<CoinsBalancesRefreshed>(_onCoinsRefreshed, transformer: droppable());
    on<CoinsActivated>(_onCoinsActivated, transformer: concurrent());
    on<CoinsDeactivated>(_onCoinsDeactivated, transformer: concurrent());
    on<CoinsPricesUpdated>(_onPricesUpdated, transformer: droppable());
    on<CoinsSessionStarted>(_onLogin, transformer: droppable());
    on<CoinsSessionEnded>(_onLogout, transformer: droppable());
    on<CoinsSuspendedReactivated>(
      _onReactivateSuspended,
      transformer: droppable(),
    );
    on<CoinsWalletCoinUpdated>(_onWalletCoinUpdated, transformer: sequential());
    on<CoinsPubkeysRequested>(
      _onCoinsPubkeysRequested,
      transformer: concurrent(),
    );
  }

  final KomodoDefiSdk _kdfSdk;
  final CoinsRepo _coinsRepo;
  final Mm2Api _mm2Api;
  // TODO: refactor to use repository - pin/password input events need to be
  // handled, which are currently done through the trezor "bloc"
  final TrezorCoinsBloc _trezorBloc;

  final _log = Logger('CoinsBloc');

  StreamSubscription<Coin>? _enabledCoinsSubscription;
  Timer? _updateBalancesTimer;
  Timer? _updatePricesTimer;
  Timer? _reActivateSuspendedTimer;

  @override
  Future<void> close() async {
    await _enabledCoinsSubscription?.cancel();
    _updateBalancesTimer?.cancel();
    _updatePricesTimer?.cancel();
    _reActivateSuspendedTimer?.cancel();

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

    add(CoinsPricesUpdated());
    _updatePricesTimer?.cancel();
    _updatePricesTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(CoinsPricesUpdated()),
    );
  }

  Future<void> _onCoinsRefreshed(
    CoinsBalancesRefreshed event,
    Emitter<CoinsState> emit,
  ) async {
    final currentWallet = await _kdfSdk.currentWallet();
    switch (currentWallet?.config.type) {
      case WalletType.trezor:
        final walletCoins =
            await _coinsRepo.updateTrezorBalances(state.walletCoins);
        emit(
          state.copyWith(
            walletCoins: walletCoins,
            // update balances in all coins list as well
            coins: {...state.coins, ...walletCoins},
          ),
        );
      case WalletType.metamask:
      case WalletType.keplr:
      case WalletType.iguana:
      case WalletType.hdwallet:
      case null:
        final coinUpdateStream =
            _coinsRepo.updateIguanaBalances(state.walletCoins);
        await emit.forEach(
          coinUpdateStream,
          onData: (Coin coin) => state.copyWith(
            walletCoins: {...state.walletCoins, coin.id.id: coin},
            coins: {...state.coins, coin.id.id: coin},
          ),
        );

        final coinUpdates = _syncIguanaCoinsStates(state.walletCoins.keys);
        await emit.forEach(
          coinUpdates,
          onData: (coin) => state
              .copyWith(walletCoins: {...state.walletCoins, coin.id.id: coin}),
        );
    }
  }

  Future<void> _onWalletCoinUpdated(
    CoinsWalletCoinUpdated event,
    Emitter<CoinsState> emit,
  ) async {
    final coin = event.coin;
    final walletCoins = Map<String, Coin>.of(state.walletCoins);

    if (coin.isActivating || coin.isActive || coin.isSuspended) {
      await _kdfSdk.addActivatedCoins([coin.id.id]);
      emit(
        state.copyWith(
          walletCoins: {...walletCoins, coin.id.id: coin},
          coins: {...state.coins, coin.id.id: coin},
        ),
      );
    }

    if (coin.isInactive) {
      walletCoins.remove(coin.id.id);
      await _kdfSdk.removeActivatedCoins([coin.id.id]);
      emit(
        state.copyWith(
          walletCoins: walletCoins,
          coins: {...state.coins, coin.id.id: coin},
        ),
      );
    }
  }

  Future<void> _onCoinsBalanceMonitoringStopped(
    CoinsBalanceMonitoringStopped event,
    Emitter<CoinsState> emit,
  ) async {
    _updateBalancesTimer?.cancel();
    _reActivateSuspendedTimer?.cancel();
    await _enabledCoinsSubscription?.cancel();
  }

  Future<void> _onCoinsBalanceMonitoringStarted(
    CoinsBalanceMonitoringStarted event,
    Emitter<CoinsState> emit,
  ) async {
    _updateBalancesTimer?.cancel();
    _updateBalancesTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        add(CoinsBalancesRefreshed());
      },
    );

    _reActivateSuspendedTimer?.cancel();
    _reActivateSuspendedTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => add(CoinsSuspendedReactivated()),
    );

    // This is used to connect [CoinsBloc] to [CoinsManagerBloc], since coins
    // manager bloc activates and deactivates coins using the repository.
    await _enabledCoinsSubscription?.cancel();
    _enabledCoinsSubscription = _coinsRepo.enabledAssetsChanges.stream.listen(
      (Coin coin) => add(CoinsWalletCoinUpdated(coin)),
    );
  }

  Future<void> _onReactivateSuspended(
    CoinsSuspendedReactivated event,
    Emitter<CoinsState> emit,
  ) async {
    await emit.forEach(
      _reActivateSuspended(emit),
      onData: (suspendedCoins) => state.copyWith(
        walletCoins: {
          ...state.walletCoins,
          ...suspendedCoins.toMap(),
        },
      ),
    );
  }

  Future<void> _onCoinsActivated(
    CoinsActivated event,
    Emitter<CoinsState> emit,
  ) async {
    await _activateCoins(event.coinIds, emit);
    final currentWallet = await _kdfSdk.currentWallet();
    if (currentWallet?.config.type == WalletType.iguana ||
        currentWallet?.config.type == WalletType.hdwallet) {
      final coinUpdates = _syncIguanaCoinsStates(event.coinIds);
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
    if (currentWalletCoins.isEmpty) {
      _log.warning('No wallet coins to disable');
      return;
    }

    // Remove coins from the state early to prevent reactivations
    final updatedWalletCoins = Map.fromEntries(currentWalletCoins.entries
        .where((entry) => !event.coinIds.contains(entry.key)));
    final updatedCoins = Map<String, Coin>.of(currentCoins);
    for (final assetId in event.coinIds) {
      final coin = currentWalletCoins[assetId]!;
      updatedCoins[coin.id.id] = coin.copyWith(state: CoinState.inactive);
    }
    emit(state.copyWith(walletCoins: updatedWalletCoins, coins: updatedCoins));

    for (final assetId in event.coinIds) {
      final coin = currentWalletCoins[assetId]!;
      _log.info('Disabling a ${coin.name} ($assetId)');

      try {
        await _kdfSdk.removeActivatedCoins([coin.id.id]);
        await _mm2Api.disableCoin(coin.id.id);

        _log.info('${coin.name} has been disabled');
      } catch (e, s) {
        _log.severe('Failed to disable coin $assetId', e, s);
      }
    }
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
        final price = prices[coin.id.id];
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
      await _activateLoginWalletCoins(emit);
      emit(state.copyWith(loginActivationFinished: true));

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

    final List<Coin> coins = [...state.walletCoins.values];
    for (final Coin coin in coins) {
      switch (coin.enabledType) {
        case WalletType.iguana:
        case WalletType.hdwallet:
          coin.reset();
          final newWalletCoins = Map<String, Coin>.of(state.walletCoins);
          newWalletCoins.remove(coin.id.id.toUpperCase());
          emit(state.copyWith(walletCoins: newWalletCoins));
          _log.info('Logout: ${coin.name} has been removed from wallet coins');
        case WalletType.trezor:
        case WalletType.metamask:
        case WalletType.keplr:
        case null:
          break;
      }
      coin.reset();
    }

    emit(
      state.copyWith(
        walletCoins: {},
        loginActivationFinished: false,
        coins: {
          ...state.coins,
          ...coins.toMap(),
        },
      ),
    );
    _coinsRepo.flushCache();
  }

  Future<List<Coin>> _activateCoins(
    Iterable<String> coins,
    Emitter<CoinsState> emit,
  ) async {
    try {
      // Start off by emitting the newly activated coins so that they all appear
      // in the list at once, rather than one at a time as they are activated
      emit(await _prePopulateListWithActivatingCoins(coins));

      await _kdfSdk.addActivatedCoins(coins);
    } catch (e, s) {
      _log.shout('Failed to add activated coins to SDK metadata field', e, s);
      rethrow;
    }

    final enabledAssets = await _kdfSdk.assets.getEnabledCoins();
    final coinsToActivate =
        coins.where((coin) => !enabledAssets.contains(coin));

    final enableFutures =
        coinsToActivate.map((coin) => _activateCoin(coin)).toList();
    final results = <Coin>[];
    await for (final coin
        in Stream<Coin>.fromFutures(enableFutures).asBroadcastStream()) {
      results.add(coin);
      emit(
        state.copyWith(
          walletCoins: {...state.walletCoins, coin.id.id: coin},
          coins: {...state.coins, coin.id.id: coin},
        ),
      );
    }

    return results;
  }

  Future<CoinsState> _prePopulateListWithActivatingCoins(
      Iterable<String> coins) async {
    final currentWallet = await _kdfSdk.currentWallet();
    final activatingCoins = Map<String, Coin>.fromIterable(
      coins
          .map(
            (coin) {
              final sdkCoin = state.coins[coin] ?? _coinsRepo.getCoin(coin);
              return sdkCoin?.copyWith(
                state: CoinState.activating,
                enabledType: currentWallet?.config.type,
              );
            },
          )
          .where((coin) => coin != null)
          .cast<Coin>(),
      key: (element) => (element as Coin).id.id,
    );
    return state.copyWith(
      walletCoins: {...state.walletCoins, ...activatingCoins},
      coins: {...state.coins, ...activatingCoins},
    );
  }

  Future<Coin> _activateCoin(String coinId) async {
    Coin? coin = state.coins[coinId] ?? _coinsRepo.getCoin(coinId);
    if (coin == null) {
      throw ArgumentError.value(coinId, 'coinId', 'Coin not found');
    }

    try {
      final currentWallet = await _kdfSdk.currentWallet();
      final isLoggedIn = currentWallet != null;
      if (!isLoggedIn || coin.isActive) {
        return coin;
      }

      switch (currentWallet.config.type) {
        case WalletType.iguana:
        case WalletType.hdwallet:
          coin = await _activateIguanaCoin(coin);
        case WalletType.trezor:
          coin = await _activateTrezorCoin(coin, coinId);
        case WalletType.metamask:
        case WalletType.keplr:
      }
    } catch (e, s) {
      _log.shout('Error activating coin ${coin!.id}', e, s);
    }

    return coin;
  }

  Future<Coin> _activateTrezorCoin(Coin coin, String coinId) async {
    final asset = _kdfSdk.assets.available[coin.id];
    if (asset == null) {
      _log.severe('Failed to find asset for coin: ${coin.id}');
      return coin.copyWith(state: CoinState.suspended);
    }
    final accounts = await _trezorBloc.activateCoin(asset);
    final state = accounts.isNotEmpty ? CoinState.active : CoinState.suspended;
    return coin.copyWith(state: state, accounts: accounts);
  }

  Future<Coin> _activateIguanaCoin(Coin coin) async {
    try {
      _log.info('Enabling iguana coin: ${coin.id.id}');
      await _coinsRepo.activateCoinsSync([coin]);
      coin.state = CoinState.active;
      _log.info('Iguana coin ${coin.name} has been enabled');
    } catch (e, s) {
      coin.state = CoinState.suspended;
      _log.shout('Failed to activate iguana coin', e, s);
    }
    return coin;
  }

  Future<List<Coin>> _activateLoginWalletCoins(Emitter<CoinsState> emit) async {
    final Wallet? currentWallet = await _kdfSdk.currentWallet();
    if (currentWallet == null) {
      return List.empty();
    }

    return _activateCoins(currentWallet.config.activatedCoins, emit);
  }

  Stream<List<Coin>> _reActivateSuspended(
    Emitter<CoinsState> emit, {
    int attempts = 1,
  }) async* {
    final List<String> coinsToBeActivated = [];

    for (int i = 0; i < attempts; i++) {
      final List<String> suspended = state.walletCoins.values
          .where((coin) => coin.isSuspended)
          .map((coin) => coin.id.id)
          .toList();

      coinsToBeActivated
        ..addAll(suspended)
        ..addAll(await _getUnactivatedWalletCoins());

      if (coinsToBeActivated.isEmpty) return;
      yield await _activateCoins(coinsToBeActivated, emit);
    }
  }

  Future<List<String>> _getUnactivatedWalletCoins() async {
    final Wallet? currentWallet = await _kdfSdk.currentWallet();
    if (currentWallet == null) {
      _log.warning('No current wallet found. Cannot get unactivated coins.');
      return List.empty();
    }

    return currentWallet.config.activatedCoins
        .where((coinId) => !state.walletCoins.containsKey(coinId))
        .toList();
  }

  /// yields one coin at a time to provide visual feedback to the user as
  /// coins are activated
  Stream<Coin> _syncIguanaCoinsStates(Iterable<String> coins) async* {
    final walletCoins = state.walletCoins;
    final enabledApiAssets = await _kdfSdk.assets.getActivatedAssets();

    for (final coinId in coins) {
      final Coin? apiCoin = enabledApiAssets
          .firstWhereOrNull((asset) => asset.id.id == coinId)
          ?.toCoin();
      final coin = walletCoins[coinId];
      if (coin == null) {
        _log.warning('Coin $coinId removed from wallet, skipping sync');
        continue;
      }

      if (apiCoin != null) {
        // enabled on gui side, but not on api side - suspend
        if (coin.state != CoinState.active) {
          yield coin.copyWith(state: CoinState.active);
        }
      } else {
        // enabled on both sides - unsuspend
        yield coin.copyWith(state: CoinState.suspended);
      }

      for (final asset in enabledApiAssets) {
        if (!walletCoins.containsKey(asset.id.id)) {
          await _kdfSdk.addActivatedCoins([asset.id.id]);
          // enabled on api side, but not on gui side - enable on gui side
          yield asset.toCoin();
        }
      }
    }
  }
}

//
