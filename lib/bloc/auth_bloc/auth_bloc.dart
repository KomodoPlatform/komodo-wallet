import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/auth_checker/auth_checker.dart';
import 'package:web_dex/services/auth_checker/get_auth_checker.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

import 'auth_bloc_event.dart';
import 'auth_bloc_state.dart';
import 'auth_repository.dart';

class AuthBloc extends Bloc<AuthBlocEvent, AuthBlocState> {
  AuthBloc({required AuthRepository authRepo})
      : _authRepo = authRepo,
        super(AuthBlocState.initial()) {
    on<AuthChangedEvent>(_onAuthChanged);
    on<AuthLogOutEvent>(_onLogout);
    on<AuthReLogInEvent>(_onReLogIn);
    _authorizationSubscription = _authRepo.authMode.listen((event) {
      add(AuthChangedEvent(mode: event));
    });
  }
  late StreamSubscription<AuthorizeMode> _authorizationSubscription;
  final AuthRepository _authRepo;
  final AuthChecker _authChecker = getAuthChecker();

  Stream<AuthorizeMode> get outAuthorizeMode => _authRepo.authMode;

  @override
  Future<void> close() async {
    _authorizationSubscription.cancel();
    super.close();
  }

  Future<bool> isLoginAllowed(Wallet newWallet) async {
    final String walletEncryptedSeed = newWallet.config.seedPhrase;
    final bool isLoginAllowed =
        await _authChecker.askConfirmLoginIfNeeded(walletEncryptedSeed);
    return isLoginAllowed;
  }

  Future<void> _onLogout(
    AuthLogOutEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    log(
      'Logging out from a wallet',
      path: 'auth_bloc => _logOut',
    );

    await _logOut();
    if (!isRunningAsChromeExtension()) {
      await _authRepo.logIn(AuthorizeMode.noLogin);
    }

    log(
      'Logged out from a wallet',
      path: 'auth_bloc => _logOut',
    );
  }

  Future<void> _onReLogIn(
    AuthReLogInEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    log(
      're-login  from a wallet',
      path: 'auth_bloc => _reLogin',
    );

    if (isRunningAsChromeExtension()) {
      // No logout when auto-login without the seed or password
      if (event.seed != '') {
        await _logOut();
      }
    } else {
      await _logOut();
    }

    await _logIn(event.seed, event.wallet);

    log(
      're-logged in  from a wallet',
      path: 'auth_bloc => _reLogin',
    );
  }

  Future<void> _onAuthChanged(
      AuthChangedEvent event, Emitter<AuthBlocState> emit) async {
    emit(AuthBlocState(mode: event.mode));
  }

  Future<void> _logOut() async {
    await _authRepo.logOut();
    final currentWallet = currentWalletBloc.wallet;
    if (currentWallet != null &&
        currentWallet.config.type == WalletType.iguana) {
      _authChecker.removeSession(currentWallet.config.seedPhrase);
    }
    currentWalletBloc.wallet = null;
  }

  Future<void> _logIn(
    String seed,
    Wallet wallet,
  ) async {
    await _authRepo.logIn(AuthorizeMode.logIn, seed);
    currentWalletBloc.wallet = wallet;

    if (isRunningAsChromeExtension()) {
      await getStorage().write('lastLoginWalletId', wallet.id);
    }

    if (wallet.config.type == WalletType.iguana) {
      _authChecker.addSession(wallet.config.seedPhrase);
    }
  }
}
