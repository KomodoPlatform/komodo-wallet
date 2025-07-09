part of 'auth_bloc.dart';

/// Mixin that exposes Trezor authentication helpers for [AuthBloc].
mixin TrezorAuthMixin on Bloc<AuthBlocEvent, AuthBlocState> {
  KomodoDefiSdk get _sdk;
  final _log = Logger('TrezorAuthMixin');

  /// Registers handlers for Trezor specific events.
  void setupTrezorEventHandlers() {
    on<AuthTrezorInitAndAuthStarted>(_onTrezorInitAndAuth);
    on<AuthTrezorPinProvided>(_onTrezorProvidePin);
    on<AuthTrezorPassphraseProvided>(_onTrezorProvidePassphrase);
    on<AuthTrezorCancelled>(_onTrezorCancel);
  }

  /// Abstract method overriden in [AuthBloc] to start listening
  /// to authentication state changes.
  void _listenToAuthStateChanges();

  Future<void> _onTrezorInitAndAuth(
    AuthTrezorInitAndAuthStarted event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      const authOptions = AuthOptions(
        derivationMethod: DerivationMethod.hdWallet,
        privKeyPolicy: PrivateKeyPolicy.trezor(),
      );

      final Stream<AuthenticationState> authStream = _sdk.auth.signInStream(
        walletName: '', // handled internally by sdk
        password: '', // handled internally by sdk
        options: authOptions,
      );

      await for (final authState in authStream) {
        final mappedState = await _handleAuthenticationState(authState);
        emit(mappedState);
        if (authState.status == AuthenticationStatus.completed ||
            authState.status == AuthenticationStatus.error ||
            authState.status == AuthenticationStatus.cancelled) {
          _listenToAuthStateChanges();
          break;
        }
      }
    } catch (e) {
      _log.shout('Trezor authentication failed', e);
      emit(
        AuthBlocState.error(
          AuthException(
            e.toString(),
            type: AuthExceptionType.generalAuthError,
          ),
        ),
      );
    }
  }

  Future<AuthBlocState> _handleAuthenticationState(
    AuthenticationState authState,
  ) async {
    switch (authState.status) {
      case AuthenticationStatus.initializing:
        return AuthBlocState.trezorInitializing(
          message: authState.message ?? 'Initializing Trezor device...',
          taskId: authState.taskId,
        );
      case AuthenticationStatus.waitingForDevice:
        return AuthBlocState.trezorInitializing(
          message:
              authState.message ?? 'Waiting for Trezor device connection...',
          taskId: authState.taskId,
        );
      case AuthenticationStatus.waitingForDeviceConfirmation:
        return AuthBlocState.trezorAwaitingConfirmation(
          message: authState.message ??
              'Please follow instructions on your Trezor device',
          taskId: authState.taskId,
        );
      case AuthenticationStatus.pinRequired:
        return AuthBlocState.trezorPinRequired(
          message: authState.message ?? 'Please enter your Trezor PIN',
          taskId: authState.taskId!,
        );
      case AuthenticationStatus.passphraseRequired:
        return AuthBlocState.trezorPassphraseRequired(
          message: authState.message ?? 'Please enter your Trezor passphrase',
          taskId: authState.taskId!,
        );
      case AuthenticationStatus.authenticating:
        return AuthBlocState.loading();
      case AuthenticationStatus.completed:
        return _setupTrezorWallet(authState);
      case AuthenticationStatus.error:
        return AuthBlocState.error(
          AuthException(
            authState.error ?? 'Trezor authentication failed',
            type: AuthExceptionType.generalAuthError,
          ),
        );
      case AuthenticationStatus.cancelled:
        return AuthBlocState.error(
          AuthException(
            'Trezor authentication was cancelled',
            type: AuthExceptionType.generalAuthError,
          ),
        );
    }
  }

  /// Sets up the Trezor wallet after successful authentication.
  /// This includes setting the wallet type, confirming seed backup,
  /// and adding the default activated coins.
  Future<AuthBlocState> _setupTrezorWallet(
    AuthenticationState authState,
  ) async {
    // This should not happen, but if it does then trezor initialization failed
    // and we should not proceed.
    if (authState.user == null) {
      return AuthBlocState.error(
        AuthException(
          'Trezor initialization failed',
          type: AuthExceptionType.generalAuthError,
        ),
      );
    }

    await _sdk.setWalletType(WalletType.trezor);
    await _sdk.confirmSeedBackup(hasBackup: true);
    if (authState.user!.wallet.config.activatedCoins.isEmpty) {
      // If no coins are activated, we assume this is the first time
      // the user is setting up their Trezor wallet.
      await _sdk.addActivatedCoins(enabledByDefaultCoins);
    }

    // Refresh the current user to pull in the updated wallet metadata
    // configured above.
    final updatedUser = await _sdk.auth.currentUser;
    return AuthBlocState.loggedIn(updatedUser!);
  }

  Future<void> _onTrezorProvidePin(
    AuthTrezorPinProvided event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final taskId = state.authenticationState?.taskId;
      if (taskId == null) {
        emit(
          AuthBlocState.error(
            AuthException(
              'No task ID found',
              type: AuthExceptionType.generalAuthError,
            ),
          ),
        );
        return;
      }

      await _sdk.auth.setHardwareDevicePin(taskId, event.pin);
    } catch (e) {
      _log.shout('Failed to provide PIN', e);
      emit(
        AuthBlocState.error(
          AuthException(
            'Failed to provide PIN',
            type: AuthExceptionType.generalAuthError,
          ),
        ),
      );
    }
  }

  Future<void> _onTrezorProvidePassphrase(
    AuthTrezorPassphraseProvided event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final taskId = state.authenticationState?.taskId;
      if (taskId == null) {
        emit(
          AuthBlocState.error(
            AuthException(
              'No task ID found',
              type: AuthExceptionType.generalAuthError,
            ),
          ),
        );
        return;
      }

      await _sdk.auth.setHardwareDevicePassphrase(
        taskId,
        event.passphrase,
      );
    } catch (e) {
      _log.shout('Failed to provide passphrase', e);
      emit(
        AuthBlocState.error(
          AuthException(
            'Failed to provide passphrase',
            type: AuthExceptionType.generalAuthError,
          ),
        ),
      );
    }
  }

  Future<void> _onTrezorCancel(
    AuthTrezorCancelled event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState.initial());
  }
}
