part of 'auth_bloc.dart';

/// Mixin that exposes Trezor authentication helpers for [AuthBloc].
mixin TrezorAuthMixin on Bloc<AuthBlocEvent, AuthBlocState> {
  KomodoDefiSdk get _sdk;

  /// Registers handlers for Trezor specific events.
  void setupTrezorEventHandlers() {
    on<AuthTrezorInitAndAuthStarted>(_onTrezorInitAndAuth);
    on<AuthTrezorPinProvided>(_onTrezorProvidePin);
    on<AuthTrezorPassphraseProvided>(_onTrezorProvidePassphrase);
    on<AuthTrezorCancelled>(_onTrezorCancel);
  }

  Future<void> _onTrezorInitAndAuth(
    AuthTrezorInitAndAuthStarted event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final authOptions = AuthOptions(
        derivationMethod: DerivationMethod.hdWallet,
        privKeyPolicy: const PrivateKeyPolicy.trezor(),
      );

      final existingWallets = await _sdk.wallets;
      final trezorWalletExists =
          existingWallets.any((w) => w.name == 'My Trezor');

      final Stream<AuthenticationState> authStream = trezorWalletExists
          ? _sdk.auth.signInStream(
              walletName: 'My Trezor',
              password: '',
              options: authOptions,
            )
          : _sdk.auth.signInStream(
              walletName: 'My Trezor',
              password: '',
              options: authOptions,
            );

      await for (final authState in authStream) {
        final mappedState = _handleAuthenticationState(authState);
        emit(mappedState);
        if (authState.status == AuthenticationStatus.completed ||
            authState.status == AuthenticationStatus.error ||
            authState.status == AuthenticationStatus.cancelled) {
          break;
        }
      }
    } catch (e) {
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

  AuthBlocState _handleAuthenticationState(AuthenticationState authState) {
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
        if (authState.user != null) {
          return AuthBlocState.loggedIn(authState.user!);
        } else {
          return AuthBlocState.trezorReady();
        }
      case AuthenticationStatus.error:
        return AuthBlocState.error(
          AuthException('Trezor authentication failed: ${authState.message}',
              type: AuthExceptionType.generalAuthError),
        );
      case AuthenticationStatus.cancelled:
        return AuthBlocState.error(
          AuthException('Trezor authentication was cancelled',
              type: AuthExceptionType.generalAuthError),
        );
    }
  }

  Future<void> _onTrezorProvidePin(
    AuthTrezorPinProvided event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final taskId = state.authenticationState?.taskId;
      if (taskId == null) {
        emit(AuthBlocState.error(AuthException('No task ID found',
            type: AuthExceptionType.generalAuthError)));
        return;
      }

      await _sdk.auth.setHardwareDevicePin(taskId, event.pin);
    } catch (_) {
      emit(AuthBlocState.error(AuthException('Failed to provide PIN',
          type: AuthExceptionType.generalAuthError)));
    }
  }

  Future<void> _onTrezorProvidePassphrase(
    AuthTrezorPassphraseProvided event,
    Emitter<AuthBlocState> emit,
  ) async {
    try {
      final taskId = state.authenticationState?.taskId;
      if (taskId == null) {
        emit(AuthBlocState.error(AuthException('No task ID found',
            type: AuthExceptionType.generalAuthError)));
        return;
      }

      await _sdk.auth.setHardwareDevicePassphrase(
        taskId,
        event.passphrase,
      );
    } catch (_) {
      emit(AuthBlocState.error(AuthException('Failed to provide passphrase',
          type: AuthExceptionType.generalAuthError)));
    }
  }

  Future<void> _onTrezorCancel(
    AuthTrezorCancelled event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState.initial());
  }
}
