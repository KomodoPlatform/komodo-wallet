import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'auth_bloc_event.dart';
part 'auth_bloc_state.dart';

/// AuthBloc is responsible for managing the authentication state of the
/// application. It handles events such as login and logout changes.
class AuthBloc extends Bloc<AuthBlocEvent, AuthBlocState> {
  /// Handles [AuthBlocEvent]s and emits [AuthBlocState]s.
  /// [_kdfSdk] is an instance of [KomodoDefiSdk] used for authentication.
  AuthBloc(this._kdfSdk, this._walletsRepository)
      : super(AuthBlocState.initial()) {
    on<AuthModeChanged>(_onAuthChanged);
    on<AuthSignOutRequested>(_onLogout);
    on<AuthSignInRequested>(_onLogIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthRestoreRequested>(_onRestore);
  }

  final KomodoDefiSdk _kdfSdk;
  final WalletsRepository _walletsRepository;
  StreamSubscription<KdfUser?>? _authorizationSubscription;

  @override
  Future<void> close() async {
    await _authorizationSubscription?.cancel();
    await super.close();
  }

  Future<void> _onLogout(
    AuthSignOutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    log(
      'Logging out from a wallet',
      path: 'auth_bloc => _logOut',
    ).ignore();

    await _kdfSdk.auth.signOut();
    log(
      'Logged out from a wallet',
      path: 'auth_bloc => _logOut',
    ).ignore();
    emit(const AuthBlocState(mode: AuthorizeMode.noLogin, currentUser: null));
  }

  Future<void> _onLogIn(
    AuthSignInRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      if (event.wallet.isLegacyWallet) {
        return add(
          AuthRestoreRequested(
            wallet: event.wallet,
            password: event.password,
            seed: await event.wallet.getLegacySeed(event.password),
          ),
        );
      }

      log('login  from a wallet', path: 'auth_bloc => _reLogin').ignore();
      await _kdfSdk.auth.signIn(
        walletName: event.wallet.name,
        password: event.password,
        options: const AuthOptions(derivationMethod: DerivationMethod.iguana),
      );
      log('logged in  from a wallet', path: 'auth_bloc => _reLogin').ignore();
      emit(
        AuthBlocState(
          mode: AuthorizeMode.logIn,
          currentUser: await _kdfSdk.auth.currentUser,
        ),
      );
      _listenToAuthStateChanges();
    } catch (e, s) {
      log(
        'Failed to login wallet ${event.wallet.name}',
        isError: true,
        trace: s,
        path: 'auth_bloc -> onLogin',
      ).ignore();
      emit(const AuthBlocState(mode: AuthorizeMode.noLogin));
    }
  }

  Future<void> _onAuthChanged(
    AuthModeChanged event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(mode: event.mode, currentUser: event.currentUser));
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final existingWallets = await _kdfSdk.auth.getUsers();
      final walletExists = existingWallets
          .any((KdfUser user) => user.walletId.name == event.wallet.name);
      if (walletExists) {
        add(
          AuthSignInRequested(wallet: event.wallet, password: event.password),
        );
        log('Wallet ${event.wallet.name} already exist, attempting sign-in')
            .ignore();
        return;
      }

      log('register  from a wallet', path: 'auth_bloc => _register').ignore();
      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        options: const AuthOptions(derivationMethod: DerivationMethod.iguana),
      );
      if (!await _kdfSdk.auth.isSignedIn()) {
        throw Exception('Registration failed: user is not signed in');
      }
      log('registered  from a wallet', path: 'auth_bloc => _register').ignore();
      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: false);
      emit(
        AuthBlocState(
          mode: AuthorizeMode.logIn,
          currentUser: await _kdfSdk.auth.currentUser,
        ),
      );
      _listenToAuthStateChanges();
    } catch (e, s) {
      log(
        'Failed to register wallet ${event.wallet.name}',
        isError: true,
        trace: s,
        path: 'auth_bloc -> onRegister',
      ).ignore();
      emit(const AuthBlocState(mode: AuthorizeMode.noLogin));
    }
  }

  Future<void> _onRestore(
    AuthRestoreRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final existingWallets = await _kdfSdk.auth.getUsers();
      final walletExists = existingWallets
          .any((KdfUser user) => user.walletId.name == event.wallet.name);
      if (walletExists) {
        add(
          AuthSignInRequested(wallet: event.wallet, password: event.password),
        );
        log('Wallet ${event.wallet.name} already exist, attempting sign-in')
            .ignore();
        return;
      }

      log('restore  from a wallet', path: 'auth_bloc => _restore').ignore();
      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        mnemonic: Mnemonic.plaintext(event.seed),
        options: const AuthOptions(derivationMethod: DerivationMethod.iguana),
      );
      if (!await _kdfSdk.auth.isSignedIn()) {
        throw Exception('Registration failed: user is not signed in');
      }
      log('restored  from a wallet', path: 'auth_bloc => _restore').ignore();

      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: event.wallet.config.hasBackup);

      emit(
        AuthBlocState(
          mode: AuthorizeMode.logIn,
          currentUser: await _kdfSdk.auth.currentUser,
        ),
      );

      // Delete legacy wallet on successful restoration & login to avoid
      // duplicates in the wallet list
      if (event.wallet.isLegacyWallet) {
        await _kdfSdk.addActivatedCoins(event.wallet.config.activatedCoins);
        await _walletsRepository.deleteWallet(event.wallet);
      }

      _listenToAuthStateChanges();
    } catch (e, s) {
      log(
        'Failed to restore existing wallet ${event.wallet.name}',
        isError: true,
        trace: s,
        path: 'auth_bloc -> onRestore',
      ).ignore();
      emit(const AuthBlocState(mode: AuthorizeMode.noLogin));
    }
  }

  void _listenToAuthStateChanges() {
    _authorizationSubscription?.cancel();
    _authorizationSubscription = _kdfSdk.auth.authStateChanges.listen((user) {
      final AuthorizeMode event =
          user != null ? AuthorizeMode.logIn : AuthorizeMode.noLogin;
      add(AuthModeChanged(mode: event, currentUser: user));
    });
  }
}
