import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
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
    log('Logging out from a wallet', path: 'auth_bloc => _logOut').ignore();
    emit(AuthBlocState.loading());
    await _kdfSdk.auth.signOut();
    emit(AuthBlocState.initial());
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
      emit(AuthBlocState.loading());
      await _kdfSdk.auth.signIn(
        walletName: event.wallet.name,
        password: event.password,
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
        ),
      );
      final KdfUser? currentUser = await _kdfSdk.auth.currentUser;
      if (currentUser == null) {
        return emit(AuthBlocState.error('Failed to login'));
      }

      log('logged in  from a wallet', path: 'auth_bloc => _reLogin').ignore();
      emit(AuthBlocState.loggedIn(currentUser));
      _listenToAuthStateChanges();
    } catch (e, s) {
      log(
        'Failed to login wallet ${event.wallet.name}',
        isError: true,
        trace: s,
        path: 'auth_bloc -> onLogin',
      ).ignore();
      emit(AuthBlocState.error(e.toString()));
      await _authorizationSubscription?.cancel();
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
      emit(AuthBlocState.loading());
      if (await _didSignInExistingWallet(event.wallet, event.password)) {
        return;
      }

      log('register  from a wallet', path: 'auth_bloc => _register').ignore();
      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
        ),
      );

      final KdfUser? currentUser = await _kdfSdk.auth.currentUser;
      if (!await _kdfSdk.auth.isSignedIn() || currentUser == null) {
        throw Exception('Registration failed: user is not signed in');
      }

      log('registered  from a wallet', path: 'auth_bloc => _register').ignore();
      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: false);
      emit(AuthBlocState.loggedIn(currentUser));
      _listenToAuthStateChanges();
    } catch (e, s) {
      log(
        'Failed to register wallet ${event.wallet.name}',
        isError: true,
        trace: s,
        path: 'auth_bloc -> onRegister',
      ).ignore();
      emit(AuthBlocState.error(e.toString()));
      await _authorizationSubscription?.cancel();
    }
  }

  Future<void> _onRestore(
    AuthRestoreRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      emit(AuthBlocState.loading());
      if (await _didSignInExistingWallet(event.wallet, event.password)) {
        return;
      }

      log('restore  from a wallet', path: 'auth_bloc => _restore').ignore();
      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        mnemonic: Mnemonic.plaintext(event.seed),
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
        ),
      );

      final currentUser = await _kdfSdk.auth.currentUser;
      if (!await _kdfSdk.auth.isSignedIn() || currentUser == null) {
        throw Exception('Registration failed: user is not signed in');
      }

      log('restored  from a wallet', path: 'auth_bloc => _restore').ignore();
      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: event.wallet.config.hasBackup);
      emit(AuthBlocState.loggedIn(currentUser));

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
      emit(AuthBlocState.error(e.toString()));
      await _authorizationSubscription?.cancel();
    }
  }

  Future<bool> _didSignInExistingWallet(
    Wallet wallet,
    String password,
  ) async {
    final existingWallets = await _kdfSdk.auth.getUsers();
    final walletExists = existingWallets
        .any((KdfUser user) => user.walletId.name == wallet.name);
    if (walletExists) {
      add(AuthSignInRequested(wallet: wallet, password: password));
      log('Wallet ${wallet.name} already exist, attempting sign-in').ignore();
      return true;
    }

    return false;
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
