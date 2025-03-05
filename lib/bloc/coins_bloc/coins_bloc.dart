import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
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
    // TODO: move auth listener to ui layer: bloclistener fires auth events
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

  StreamSubscription<Coin>? _enabledCoinsSubscription;
  Timer? _updateBalancesTimer;
  Timer? _updatePricesTimer;
  Timer? _reActivateSuspendedTimer;

  // prevents RPC spamming on startup & previous inconsistencies with sdk wallet
  KdfUser? _currentUserCache;

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
      // Get current coin
      final coin = state.coins[event.coinId];
      if (coin == null) return;

      // Get pubkeys from the SDK through the repo
      final asset = _kdfSdk.assets.assetsFromTicker(event.coinId).single;
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
      log(
        'Failed to get pubkeys for ${event.coinId}: $e',
        isError: true,
        path: 'coins_bloc => _onCoinsPubkeysRequested',
        trace: s,
      ).ignore();
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
    _currentUserCache ??= await _kdfSdk.auth.currentUser;
    switch (_currentUserCache?.wallet.config.type) {
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
            walletCoins: {...state.walletCoins, coin.abbr: coin},
            coins: {...state.coins, coin.abbr: coin},
          ),
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
      await _kdfSdk.addActivatedCoins([coin.abbr]);
      emit(
        state.copyWith(
          walletCoins: {...walletCoins, coin.abbr: coin},
          coins: {...state.coins, coin.abbr: coin},
        ),
      );
    }

    if (coin.isInactive) {
      walletCoins.remove(coin.abbr);
      await _kdfSdk.removeActivatedCoins([coin.abbr]);
      emit(
        state.copyWith(
          walletCoins: walletCoins,
          coins: {...state.coins, coin.abbr: coin},
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

    if (_currentUserCache?.wallet.config.type == WalletType.iguana ||
        _currentUserCache?.wallet.config.type == WalletType.hdwallet) {
      final coinUpdates = _syncIguanaCoinsStates(event.coinIds);
      await emit.forEach(
        coinUpdates,
        onData: (coin) => state
            .copyWith(walletCoins: {...state.walletCoins, coin.abbr: coin}),
      );
    }
  }

  Future<void> _onCoinsDeactivated(
    CoinsDeactivated event,
    Emitter<CoinsState> emit,
  ) async {
    for (final coinId in event.coinIds) {
      final coin = state.walletCoins[coinId]!;
      log(
        'Disabling a ${coin.name} ($coinId)',
        path: 'coins_bloc => disable',
      ).ignore();
      coin.reset();

      await _kdfSdk.removeActivatedCoins([coin.abbr]);
      await _mm2Api.disableCoin(coin.abbr);

      final newWalletCoins = Map<String, Coin>.of(state.walletCoins)
        ..remove(coin.abbr);
      final newCoins = Map<String, Coin>.of(state.coins);
      newCoins[coin.abbr]!.state = CoinState.inactive;
      emit(state.copyWith(walletCoins: newWalletCoins, coins: newCoins));

      log('${coin.name} has been disabled', path: 'coins_bloc => disable')
          .ignore();
    }
  }

  Future<void> _onPricesUpdated(
    CoinsPricesUpdated event,
    Emitter<CoinsState> emit,
  ) async {
    bool changed = false;
    final prices = await _coinsRepo.fetchCurrentPrices();

    if (prices == null) {
      log(
        'Coin prices list empty/null',
        isError: true,
        path: 'coins_bloc => _onPricesUpdated',
      ).ignore();
      return;
    }

    final coins = Map<String, Coin>.of(state.coins);
    for (final entry in state.coins.entries) {
      final coin = entry.value;
      final CexPrice? usdPrice = prices[abbr2Ticker(coin.abbr)];

      if (usdPrice != coin.usdPrice) {
        changed = true;
        // Create new coin instance with updated price
        coins[entry.key] = coin.copyWith(usdPrice: usdPrice);
      }
    }

    if (changed) {
      final newWalletCoins = state.walletCoins.map(
        (String coinId, Coin coin) => MapEntry<String, Coin>(
          coinId,
          coin.copyWith(usdPrice: coins[coinId]!.usdPrice),
        ),
      );
      emit(
        state.copyWith(
          coins: coins,
          walletCoins: {...state.walletCoins, ...newWalletCoins},
        ),
      );
    }

    log('CEX prices updated', path: 'coins_bloc => updateCoinsCexPrices')
        .ignore();
  }

  Future<void> _onLogin(
    CoinsSessionStarted event,
    Emitter<CoinsState> emit,
  ) async {
    _coinsRepo.flushCache();
    _currentUserCache = event.signedInUser;
    await _activateLoginWalletCoins(emit);
    emit(state.copyWith(loginActivationFinished: true));

    add(CoinsBalancesRefreshed());
    add(CoinsBalanceMonitoringStarted());
  }

  Future<void> _onLogout(
    CoinsSessionEnded event,
    Emitter<CoinsState> emit,
  ) async {
    add(CoinsBalanceMonitoringStopped());
    _currentUserCache = null;

    final List<Coin> coins = [...state.walletCoins.values];
    for (final Coin coin in coins) {
      switch (coin.enabledType) {
        case WalletType.iguana:
        case WalletType.hdwallet:
          coin.reset();
          final newWalletCoins = Map<String, Coin>.of(state.walletCoins);
          newWalletCoins.remove(coin.abbr.toUpperCase());
          emit(state.copyWith(walletCoins: newWalletCoins));
          log('${coin.name} has been removed', path: 'coins_bloc => _onLogout')
              .ignore();
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
          ...coins.map((coin) => coin.copyWith(balance: 0)).toList().toMap(),
        },
      ),
    );
    _coinsRepo.flushCache();
  }

  Future<List<Coin>> _activateCoins(
    Iterable<String> coins,
    Emitter<CoinsState> emit,
  ) async {
    // Start off by emitting the newly activated coins so that they all appear
    // in the list at once, rather than one at a time as they are activated
    _prePopulateListWithActivatingCoins(coins, emit);

    try {
      await _kdfSdk.addActivatedCoins(coins);
    } catch (e, s) {
      log(
        'Failed to activate coins in SDK: $e',
        isError: true,
        path: 'coins_bloc => _activateCoins',
        trace: s,
      ).ignore();
      // Update state to reflect failure
      return [];
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
          walletCoins: {...state.walletCoins, coin.abbr: coin},
          coins: {...state.coins, coin.abbr: coin},
        ),
      );
    }

    return results;
  }

  void _prePopulateListWithActivatingCoins(
    Iterable<String> coins,
    Emitter<CoinsState> emit,
  ) {
    final activatingCoins = Map<String, Coin>.fromIterable(
      coins
          .map(
            (coin) {
              final sdkCoin = state.coins[coin] ?? _coinsRepo.getCoin(coin);
              return sdkCoin?.copyWith(
                state: CoinState.activating,
                enabledType: _currentUserCache?.wallet.config.type,
              );
            },
          )
          .where((coin) => coin != null)
          .cast<Coin>(),
      key: (element) => (element as Coin).abbr,
    );
    emit(
      state.copyWith(
        walletCoins: {...state.walletCoins, ...activatingCoins},
        coins: {...state.coins, ...activatingCoins},
      ),
    );
  }

  Future<Coin> _activateCoin(String coinId) async {
    Coin? coin = state.coins[coinId] ?? _coinsRepo.getCoin(coinId);
    if (coin == null) {
      throw ArgumentError.value(coinId, 'coinId', 'Coin not found');
    }

    try {
      final isLoggedIn = _currentUserCache != null;
      if (!isLoggedIn || coin.isActive) {
        return coin;
      }

      switch (_currentUserCache?.wallet.config.type) {
        case WalletType.iguana:
        case WalletType.hdwallet:
          coin = await _activateIguanaCoin(coin);
        case WalletType.trezor:
          coin = await _activateTrezorCoin(coin, coinId);
        case WalletType.metamask:
        case WalletType.keplr:
        case null:
          break;
      }
    } catch (e, s) {
      log(
        'Error activating coin ${coin!.id.toString()}',
        isError: true,
        trace: s,
      );
    }

    return coin;
  }

  Future<Coin> _activateTrezorCoin(Coin coin, String coinId) async {
    final asset = _kdfSdk.assets.available[coin.id];
    if (asset == null) {
      log('Failed to find asset for coin: ${coin.id}', isError: true);
      return coin.copyWith(state: CoinState.suspended);
    }
    final accounts = await _trezorBloc.activateCoin(asset);
    final state = accounts.isNotEmpty ? CoinState.active : CoinState.suspended;
    return coin.copyWith(state: state, accounts: accounts);
  }

  Future<Coin> _activateIguanaCoin(Coin coin) async {
    try {
      log('Enabling a ${coin.name}', path: 'coins_bloc => enable').ignore();
      await _coinsRepo.activateCoinsSync([coin]);
      coin.state = CoinState.active;
      log('${coin.name} has enabled', path: 'coins_bloc => enable').ignore();
    } catch (e, s) {
      coin.state = CoinState.suspended;
      log(
        'Failed to activate iguana coin: $e',
        isError: true,
        path: 'coins_bloc => _activateIguanaCoin',
        trace: s,
      ).ignore();
    }
    return coin;
  }

  Future<List<Coin>> _activateLoginWalletCoins(Emitter<CoinsState> emit) async {
    final Wallet? currentWallet = _currentUserCache?.wallet;
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
          .map((coin) => coin.abbr)
          .toList();

      coinsToBeActivated.addAll(suspended);
      coinsToBeActivated.addAll(_getUnactivatedWalletCoins());

      if (coinsToBeActivated.isEmpty) return;
      yield await _activateCoins(coinsToBeActivated, emit);
    }
  }

  List<String> _getUnactivatedWalletCoins() {
    final Wallet? currentWallet = _currentUserCache?.wallet;
    if (currentWallet == null) {
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

    for (final coinId in coins) {
      final Coin? apiCoin = await _coinsRepo.getEnabledCoin(coinId);
      final coin = walletCoins[coinId];
      if (coin == null) {
        log('Coin $coinId removed from wallet, skipping sync').ignore();
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

      for (final String apiCoinId in await _kdfSdk.assets.getEnabledCoins()) {
        if (!walletCoins.containsKey(apiCoinId)) {
          // enabled on api side, but not on gui side - enable on gui side
          final apiCoin = await _coinsRepo.getEnabledCoin(apiCoinId);
          if (apiCoin != null) {
            yield apiCoin;
          }
        }
      }
    }
  }
}
