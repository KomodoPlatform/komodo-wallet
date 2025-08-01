import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show PrivateKeyPolicy;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/wallet.dart';

part 'auth_bloc_event.dart';
part 'auth_bloc_state.dart';
part 'trezor_auth_mixin.dart';

/// AuthBloc is responsible for managing the authentication state of the
/// application. It handles events such as login and logout changes.
class AuthBloc extends Bloc<AuthBlocEvent, AuthBlocState> with TrezorAuthMixin {
  /// Handles [AuthBlocEvent]s and emits [AuthBlocState]s.
  /// [_kdfSdk] is an instance of [KomodoDefiSdk] used for authentication.
  AuthBloc(this._kdfSdk, this._walletsRepository, this._settingsRepository)
      : super(AuthBlocState.initial()) {
    on<AuthModeChanged>(_onAuthChanged);
    on<AuthStateClearRequested>(_onClearState);
    on<AuthSignOutRequested>(_onLogout);
    on<AuthSignInRequested>(_onLogIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthRestoreRequested>(_onRestore);
    on<AuthSeedBackupConfirmed>(_onSeedBackupConfirmed);
    on<AuthWalletDownloadRequested>(_onWalletDownloadRequested);
    on<AuthStateRestoreRequested>(_onStateRestoreRequested);
    on<AuthLifecycleCheckRequested>(_onLifecycleCheckRequested);
    setupTrezorEventHandlers();
  }

  final KomodoDefiSdk _kdfSdk;
  final WalletsRepository _walletsRepository;
  final SettingsRepository _settingsRepository;
  StreamSubscription<KdfUser?>? _authChangesSubscription;
  final _log = Logger('AuthBloc');

  @override
  KomodoDefiSdk get _sdk => _kdfSdk;

  @override
  Future<void> close() async {
    await _authChangesSubscription?.cancel();
    await super.close();
  }

  Future<bool> _areWeakPasswordsAllowed() async {
    final settings = await _settingsRepository.loadSettings();
    return settings.weakPasswordsAllowed;
  }

  Future<void> _onLogout(
    AuthSignOutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _log.info('Logging out from a wallet');
    emit(AuthBlocState.loading());
    await _kdfSdk.auth.signOut();
    await _authChangesSubscription?.cancel();
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

      _log.info('login from a wallet');
      emit(AuthBlocState.loading());

      final weakPasswordsAllowed = await _areWeakPasswordsAllowed();

      await _kdfSdk.auth.signIn(
        walletName: event.wallet.name,
        password: event.password,
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
          allowWeakPassword: weakPasswordsAllowed,
        ),
      );
      final KdfUser? currentUser = await _kdfSdk.auth.currentUser;
      if (currentUser == null) {
        return emit(AuthBlocState.error(AuthException.notSignedIn()));
      }

      _log.info('logged in from a wallet');
      emit(AuthBlocState.loggedIn(currentUser));
      _listenToAuthStateChanges();
    } catch (e, s) {
      if (e is AuthException) {
        // Preserve the original error type for specific errors like incorrect password
        _log.shout(
          'Auth error during login for wallet ${event.wallet.name}',
          e,
          s,
        );
        emit(AuthBlocState.error(e));
      } else {
        // For non-auth exceptions, use a generic error type
        final errorMsg = 'Failed to login wallet ${event.wallet.name}';
        _log.shout(errorMsg, e, s);
        emit(
          AuthBlocState.error(
            AuthException(errorMsg, type: AuthExceptionType.generalAuthError),
          ),
        );
      }
      await _authChangesSubscription?.cancel();
    }
  }

  Future<void> _onAuthChanged(
    AuthModeChanged event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(mode: event.mode, currentUser: event.currentUser));
  }

  Future<void> _onClearState(
    AuthStateClearRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    await _authChangesSubscription?.cancel();
    emit(AuthBlocState.initial());
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

      _log.info('register from a wallet');

      final weakPasswordsAllowed = await _areWeakPasswordsAllowed();

      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
          allowWeakPassword: weakPasswordsAllowed,
        ),
      );

      _log.info('registered from a wallet');
      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: false);
      await _kdfSdk.addActivatedCoins(enabledByDefaultCoins);

      final currentUser = await _kdfSdk.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Registration failed: user is not signed in');
      }
      emit(AuthBlocState.loggedIn(currentUser));
      _listenToAuthStateChanges();
    } catch (e, s) {
      final errorMsg = 'Failed to register wallet ${event.wallet.name}';
      _log.shout(errorMsg, e, s);
      emit(
        AuthBlocState.error(
          AuthException(errorMsg, type: AuthExceptionType.generalAuthError),
        ),
      );
      await _authChangesSubscription?.cancel();
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

      _log.info('restore from a wallet');

      final weakPasswordsAllowed = await _areWeakPasswordsAllowed();

      await _kdfSdk.auth.register(
        password: event.password,
        walletName: event.wallet.name,
        mnemonic: Mnemonic.plaintext(event.seed),
        options: AuthOptions(
          derivationMethod: event.wallet.config.type == WalletType.hdwallet
              ? DerivationMethod.hdWallet
              : DerivationMethod.iguana,
          allowWeakPassword: weakPasswordsAllowed,
        ),
      );

      _log.info('restored from a wallet');
      await _kdfSdk.setWalletType(event.wallet.config.type);
      await _kdfSdk.confirmSeedBackup(hasBackup: event.wallet.config.hasBackup);
      await _kdfSdk.addActivatedCoins(enabledByDefaultCoins);

      final currentUser = await _kdfSdk.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Registration failed: user is not signed in');
      }
      emit(AuthBlocState.loggedIn(currentUser));

      // Delete legacy wallet on successful restoration & login to avoid
      // duplicates in the wallet list
      if (event.wallet.isLegacyWallet) {
        await _kdfSdk.addActivatedCoins(event.wallet.config.activatedCoins);
        await _walletsRepository.deleteWallet(
          event.wallet,
          password: event.password,
        );
      }

      _listenToAuthStateChanges();
    } catch (e, s) {
      final errorMsg = 'Failed to restore existing wallet ${event.wallet.name}';
      _log.shout(errorMsg, e, s);
      emit(
        AuthBlocState.error(
          AuthException(errorMsg, type: AuthExceptionType.generalAuthError),
        ),
      );
      await _authChangesSubscription?.cancel();
    }
  }

  Future<bool> _didSignInExistingWallet(Wallet wallet, String password) async {
    final existingWallets = await _kdfSdk.auth.getUsers();
    final walletExists = existingWallets.any(
      (KdfUser user) => user.walletId.name == wallet.name,
    );
    if (walletExists) {
      add(AuthSignInRequested(wallet: wallet, password: password));
      _log.warning('Wallet ${wallet.name} already exist, attempting sign-in');
      return true;
    }

    return false;
  }

  Future<void> _onSeedBackupConfirmed(
    AuthSeedBackupConfirmed event,
    Emitter<AuthBlocState> emit,
  ) async {
    // emit the current user again to pull in the updated seed backup status
    // and make the backup notification banner disappear
    await _kdfSdk.confirmSeedBackup();
    emit(
      AuthBlocState(
        mode: AuthorizeMode.logIn,
        currentUser: await _kdfSdk.auth.currentUser,
      ),
    );
  }

  Future<void> _onWalletDownloadRequested(
    AuthWalletDownloadRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final Wallet? wallet = (await _kdfSdk.auth.currentUser)?.wallet;
      if (wallet == null) return;

      await _walletsRepository.downloadEncryptedWallet(wallet, event.password);

      await _kdfSdk.confirmSeedBackup();
      emit(
        AuthBlocState(
          mode: AuthorizeMode.logIn,
          currentUser: await _kdfSdk.auth.currentUser,
        ),
      );
    } catch (e, s) {
      _log.shout('Failed to download wallet data', e, s);
    }
  }

  Future<void> _onStateRestoreRequested(
    AuthStateRestoreRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    final bool signedIn = await _kdfSdk.auth.isSignedIn();
    final KdfUser? user = signedIn ? await _kdfSdk.auth.currentUser : null;
    emit(
      AuthBlocState(
        mode: signedIn ? AuthorizeMode.logIn : AuthorizeMode.noLogin,
        currentUser: user,
      ),
    );

    if (signedIn) {
      _listenToAuthStateChanges();
    }
  }

  Future<void> _onLifecycleCheckRequested(
    AuthLifecycleCheckRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    final currentUser = await _kdfSdk.auth.currentUser;

    // Do not emit any state if the user is currently attempting to log in.
    // TODO(takenagain)!: This is a temporary workaround to avoid emitting
    // AuthBlocState.loggedIn while the user is still logging in.
    // This should be replaced with a more robust solution.
    if (currentUser != null && !state.isLoading) {
      emit(AuthBlocState.loggedIn(currentUser));
      _listenToAuthStateChanges();
    }
  }

  @override
  void _listenToAuthStateChanges() {
    _authChangesSubscription?.cancel();
    _authChangesSubscription = _kdfSdk.auth.watchCurrentUser().listen((user) {
      final AuthorizeMode event =
          user != null ? AuthorizeMode.logIn : AuthorizeMode.noLogin;
      add(AuthModeChanged(mode: event, currentUser: user));
    });
  }
}
