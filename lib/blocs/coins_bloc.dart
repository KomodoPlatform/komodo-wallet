import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/blocs/trezor_coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/bloc_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_request.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/cex_price.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/withdraw_details/withdraw_details.dart';
import 'package:web_dex/services/cex_service/cex_service.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinsBloc implements BlocBase {
  CoinsBloc({
    required Mm2Api api,
    required CurrentWalletBloc currentWalletBloc,
    required AuthRepository authRepo,
    required CoinsRepo coinsRepo,
  })  : _coinsRepo = coinsRepo,
        _currentWalletBloc = currentWalletBloc {
    trezor = TrezorCoinsBloc(
      trezorRepo: trezorRepo,
      walletRepo: currentWalletBloc,
    );
  }

  Future<void> init() async {
    _authorizationSubscription = authRepo.authMode.listen((event) async {
      switch (event) {
        case AuthorizeMode.noLogin:
          _isLoggedIn = false;
          await _onLogout();
          break;
        case AuthorizeMode.logIn:
          _isLoggedIn = true;
          await _onLogIn();
          break;
        case AuthorizeMode.hiddenLogin:
          break;
      }
    });
    _updateBalancesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (loginActivationFinished) {
        updateBalances();
      }
    });

    _loadKnownCoins();
  }

  Map<String, Map<String, String>> addressCache =
      {}; // { acc: { abbr: address }}, used in Fiat Page

  late StreamSubscription<AuthorizeMode> _authorizationSubscription;
  late TrezorCoinsBloc trezor;
  final CoinsRepo _coinsRepo;

  final CurrentWalletBloc _currentWalletBloc;
  late StreamSubscription<Map<String, CexPrice>> _pricesSubscription;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  late Timer _updateBalancesTimer;

  final StreamController<List<Coin>> _knownCoinsController =
      StreamController<List<Coin>>.broadcast();
  Sink<List<Coin>> get _inKnownCoins => _knownCoinsController.sink;
  Stream<List<Coin>> get outKnownCoins => _knownCoinsController.stream;

  List<Coin> _knownCoins = [];

  List<Coin> get knownCoins => _knownCoins;

  Map<String, Coin> _knownCoinsMap = {};
  Map<String, Coin> get knownCoinsMap => _knownCoinsMap;

  final StreamController<List<Coin>> _walletCoinsController =
      StreamController<List<Coin>>.broadcast();
  Sink<List<Coin>> get _inWalletCoins => _walletCoinsController.sink;
  Stream<List<Coin>> get outWalletCoins => _walletCoinsController.stream;

  List<Coin> _walletCoins = [];
  List<Coin> get walletCoins => _walletCoins;
  set walletCoins(List<Coin> coins) {
    _walletCoins = coins;
    _walletCoinsMap = Map.fromEntries(
      coins.map((coin) => MapEntry(coin.abbr.toUpperCase(), coin)),
    );
    _inWalletCoins.add(_walletCoins);
  }

  Map<String, Coin> _walletCoinsMap = {};
  Map<String, Coin> get walletCoinsMap => _walletCoinsMap;

  final StreamController<bool> _loginActivationFinishedController =
      StreamController<bool>.broadcast();
  Sink<bool> get _inLoginActivationFinished =>
      _loginActivationFinishedController.sink;
  Stream<bool> get outLoginActivationFinished =>
      _loginActivationFinishedController.stream;

  bool _loginActivationFinished = false;
  bool get loginActivationFinished => _loginActivationFinished;
  set loginActivationFinished(bool value) {
    _loginActivationFinished = value;
    _inLoginActivationFinished.add(_loginActivationFinished);
  }

  Future<void> _activateLoginWalletCoins() async {
    final Wallet? currentWallet = _currentWalletBloc.wallet;
    if (currentWallet == null || !_isLoggedIn) {
      return;
    }

    final List<Coin> coins = currentWallet.config.activatedCoins
        .map((abbr) => getCoin(abbr))
        .whereType<Coin>()
        .where((coin) => !coin.isActive)
        .toList();

    await activateCoins(coins, skipUpdateBalance: true);
    await updateBalances();
    await reActivateSuspended(attempts: 2);

    loginActivationFinished = true;
  }

  Future<void> _onLogIn() async {
    await _activateLoginWalletCoins();
    await updateBalances();
  }

  Coin? getCoin(String abbr) {
    return getWalletCoin(abbr) ?? getKnownCoin(abbr);
  }

  Future<void> _loadKnownCoins() async {
    _knownCoins = await _coinsRepo.getKnownCoins();
    _knownCoinsMap = Map.fromEntries(
      _knownCoins.map((coin) => MapEntry(coin.abbr.toUpperCase(), coin)),
    );
    _inKnownCoins.add(_knownCoins);
  }

  Coin? getWalletCoin(String abbr) {
    return _walletCoinsMap[abbr.toUpperCase()];
  }

  Coin? getKnownCoin(String abbr) {
    return _knownCoinsMap[abbr.toUpperCase()];
  }

  Future<void> updateBalances() async {
    switch (_currentWalletBloc.wallet?.config.type) {
      case WalletType.trezor:
        await _updateTrezorBalances();
        break;
      case WalletType.iguana:
        await _updateIguanaBalances();
        break;
      case WalletType.metamask:
      case WalletType.keplr:
      case null:
        await _updateIguanaBalances();
        break;
    }
  }

  Future<void> _updateTrezorBalances() async {
    final coins = _walletCoins.where((coin) => coin.isActive).toList();
    for (Coin coin in coins) {
      coin.accounts = await trezor.getAccounts(coin);
    }
    _updateCoins();
  }

  Future<void> _updateIguanaBalances() async {
    bool changed = false;
    final coins = _walletCoins.where((coin) => coin.isActive).toList();

    final newBalances = await Future.wait(
        coins.map((coin) => _coinsRepo.getBalanceInfo(coin.abbr)));

    for (int i = 0; i < coins.length; i++) {
      if (newBalances[i] != null) {
        final newBalance = double.parse(newBalances[i]!.balance.decimal);
        final newSendableBalance = double.parse(newBalances[i]!.volume.decimal);

        if (newBalance != coins[i].balance ||
            newSendableBalance != coins[i].sendableBalance) {
          changed = true;
          coins[i].balance = newBalance;
          coins[i].sendableBalance = newSendableBalance;
        }
      }
    }

    if (changed) {
      _updateCoins();
    }
  }

  void _updateCoinsCexPrices(Map<String, CexPrice> prices) {
    bool changed = false;
    for (Coin coin in _knownCoins) {
      final CexPrice? usdPrice = prices[abbr2Ticker(coin.abbr)];

      changed = changed || usdPrice != coin.usdPrice;
      coin.usdPrice = usdPrice;

      final Coin? enabledCoin = getWalletCoin(coin.abbr);
      enabledCoin?.usdPrice = usdPrice;

      _inKnownCoins.add(_knownCoins);
    }
    if (changed) {
      _updateCoins();
    }

    log('CEX prices updated', path: 'coins_bloc => updateCoinsCexPrices');
  }

  Future<void> _activateCoin(Coin coin,
      {bool skipUpdateBalance = false}) async {
    if (!_isLoggedIn || coin.isActivating || coin.isActive) return;

    coin.state = CoinState.activating;
    await _addCoinToWallet(coin);
    _updateCoins();

    switch (currentWalletBloc.wallet?.config.type) {
      case WalletType.iguana:
        await _activateIguanaCoin(coin, skipUpdateBalance: skipUpdateBalance);
        break;
      case WalletType.trezor:
        await _activateTrezorCoin(coin);
        break;
      case WalletType.metamask:
      case WalletType.keplr:
      case null:
        break;
    }
    _updateCoins();
  }

  Future<void> _activateIguanaCoin(Coin coin,
      {bool skipUpdateBalance = false}) async {
    log('Enabling a ${coin.name}', path: 'coins_bloc => enable');
    await _activateParentOf(coin, skipUpdateBalance: skipUpdateBalance);
    await _coinsRepo.activateCoins([coin]);
    await _syncIguanaCoinState(coin);

    if (!skipUpdateBalance) await updateBalances();
    log('${coin.name} has enabled', path: 'coins_bloc => enable');
  }

  Future<void> _activateTrezorCoin(Coin coin) async {
    await trezor.activateCoin(coin);
  }

  Future<void> _activateParentOf(Coin coin,
      {bool skipUpdateBalance = false}) async {
    final Coin? parentCoin = coin.parentCoin;
    if (parentCoin == null) return;

    if (parentCoin.isInactive) {
      await activateCoins([parentCoin], skipUpdateBalance: skipUpdateBalance);
    }

    await pauseWhile(
      () => parentCoin.isActivating,
      timeout: const Duration(seconds: 100),
    );
  }

  Future<void> _onLogout() async {
    final List<Coin> coins = [...walletCoins];
    for (Coin coin in coins) {
      switch (coin.enabledType) {
        case WalletType.iguana:
          await _deactivateApiCoin(coin);
          break;
        case WalletType.trezor:
        case WalletType.metamask:
        case WalletType.keplr:
        case null:
          break;
      }
      coin.reset();
    }
    walletCoins = [];
    loginActivationFinished = false;
  }

  Future<void> deactivateWalletCoins() async {
    await deactivateCoins(walletCoins);
  }

  Future<void> deactivateCoins(List<Coin> coins) async {
    await Future.wait(coins.map(deactivateCoin));
  }

  Future<void> deactivateCoin(Coin coin) async {
    log('Disabling a ${coin.name}', path: 'coins_bloc => disable');
    await _removeCoinFromWallet(coin);
    _updateCoins();
    await _deactivateApiCoin(coin);
    _updateCoins();

    log(
      '${coin.name} has been disabled',
      path: 'coins_bloc => disable',
    );
  }

  Future<void> _deactivateApiCoin(Coin coin) async {
    if (coin.isSuspended || coin.isActivating) return;
    await _coinsRepo.deactivateCoin(coin);
  }

  Future<void> _removeCoinFromWallet(Coin coin) async {
    coin.reset();
    _walletCoins.removeWhere((enabledCoin) => enabledCoin.abbr == coin.abbr);
    _walletCoinsMap.remove(coin.abbr.toUpperCase());
    await _currentWalletBloc.removeCoin(coin.abbr);
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

  Future<BlocResponse<WithdrawDetails, BaseError>> withdraw(
      WithdrawRequest request) async {
    final Map<String, dynamic>? response = await _coinsRepo.withdraw(request);

    if (response == null) {
      log('Withdraw error: response is null', isError: true);
      return BlocResponse(
        result: null,
        error: TextError(error: LocaleKeys.somethingWrong.tr()),
      );
    }

    if (response['error'] != null) {
      log('Withdraw error: ${response['error']}', isError: true);
      return BlocResponse(
        result: null,
        error: withdrawErrorFactory.getError(response, request.params.coin),
      );
    }

    final WithdrawDetails withdrawDetails = WithdrawDetails.fromJson(
      response['result'] as Map<String, dynamic>? ?? {},
    );

    return BlocResponse(
      result: withdrawDetails,
      error: null,
    );
  }

  Future<SendRawTransactionResponse> sendRawTransaction(
      SendRawTransactionRequest request) async {
    final SendRawTransactionResponse response =
        await _coinsRepo.sendRawTransaction(request);

    return response;
  }

  Future<void> activateCoins(List<Coin> coins,
      {bool skipUpdateBalance = false}) async {
    final List<Future<void>> enableFutures = coins
        .map(
            (coin) => _activateCoin(coin, skipUpdateBalance: skipUpdateBalance))
        .toList();
    await Future.wait(enableFutures);
  }

  Future<void> _addCoinToWallet(Coin coin) async {
    if (getWalletCoin(coin.abbr) != null) return;

    coin.enabledType = _currentWalletBloc.wallet?.config.type;
    _walletCoins.add(coin);
    _walletCoinsMap[coin.abbr.toUpperCase()] = coin;
    await _currentWalletBloc.addCoin(coin);
  }

  Future<void> _syncIguanaCoinState(Coin coin) async {
    final List<Coin> apiCoins = await _coinsRepo.getEnabledCoins([coin]);
    final Coin? apiCoin =
        apiCoins.firstWhereOrNull((coin) => coin.abbr == coin.abbr);

    if (apiCoin != null) {
      // enabled on gui side, but not on api side - suspend
      coin.state = CoinState.active;
    } else {
      // enabled on both sides - unsuspend
      coin.state = CoinState.suspended;
    }

    for (Coin apiCoin in apiCoins) {
      if (getWalletCoin(apiCoin.abbr) == null) {
        // enabled on api side, but not on gui side - enable on gui side
        _walletCoins.add(apiCoin);
        _walletCoinsMap[apiCoin.abbr.toUpperCase()] = apiCoin;
      }
    }
    _updateCoins();
  }

  Future<void> reactivateAll() async {
    for (Coin coin in _walletCoins) {
      coin.state = CoinState.inactive;
    }

    await activateCoins(_walletCoins);
  }

  Future<void> reActivateSuspended({int attempts = 1}) async {
    for (int i = 0; i < attempts; i++) {
      final List<Coin> suspended =
          _walletCoins.where((coin) => coin.isSuspended).toList();
      if (suspended.isEmpty) return;

      await activateCoins(suspended);
    }
  }

  void subscribeOnPrice(CexService cexService) {
    _pricesSubscription = cexService.pricesStream
        .listen((prices) => _updateCoinsCexPrices(prices));
  }

  void _updateCoins() {
    walletCoins = _walletCoins;
  }

  Future<String?> getCoinAddress(String abbr) async {
    final loggedIn = isLoggedIn && currentWalletBloc.wallet != null;
    if (!loggedIn) {
      return null;
    }

    final accountKey = currentWalletBloc.wallet!.id;
    final abbrKey = abbr;

    if (addressCache.containsKey(accountKey) &&
        addressCache[accountKey]!.containsKey(abbrKey)) {
      return addressCache[accountKey]![abbrKey];
    } else {
      await activateCoins([getCoin(abbr)!]);
      final coin = walletCoins.firstWhereOrNull((c) => c.abbr == abbr);

      if (coin != null && coin.address != null) {
        if (!addressCache.containsKey(accountKey)) {
          addressCache[accountKey] = {};
        }

        // Cache this wallet's addresses
        for (final walletCoin in walletCoins) {
          if (walletCoin.address != null &&
              !addressCache[accountKey]!.containsKey(walletCoin.abbr)) {
            // Exit if the address already exists in a different account
            // Address belongs to another account, this is a bug, 
            // gives outdated data
            for (final entry in addressCache.entries) {
              if (entry.key != accountKey &&
                  entry.value.containsValue(walletCoin.address)) {
                return null;
              }
            }

            addressCache[accountKey]![walletCoin.abbr] = walletCoin.address!;
          }
        }

        return addressCache[accountKey]![abbrKey];
      }
    }
    return null;
  }

  @override
  void dispose() {
    _walletCoinsController.close();
    _knownCoinsController.close();
    _updateBalancesTimer.cancel();
    _authorizationSubscription.cancel();
    _pricesSubscription.cancel();
  }
}
