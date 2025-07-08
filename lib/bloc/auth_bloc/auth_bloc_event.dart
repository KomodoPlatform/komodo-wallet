part of 'auth_bloc.dart';

abstract class AuthBlocEvent {
  const AuthBlocEvent();
}

class AuthModeChanged extends AuthBlocEvent {
  const AuthModeChanged({required this.mode, required this.currentUser});

  final AuthorizeMode mode;
  final KdfUser? currentUser;
}

class AuthStateClearRequested extends AuthBlocEvent {
  const AuthStateClearRequested();
}

class AuthSignOutRequested extends AuthBlocEvent {
  const AuthSignOutRequested();
}

class AuthSignInRequested extends AuthBlocEvent {
  const AuthSignInRequested({required this.wallet, required this.password});

  final Wallet wallet;
  final String password;
}

class AuthRegisterRequested extends AuthBlocEvent {
  const AuthRegisterRequested({required this.wallet, required this.password});

  final Wallet wallet;
  final String password;
}

class AuthRestoreRequested extends AuthBlocEvent {
  const AuthRestoreRequested({
    required this.wallet,
    required this.password,
    required this.seed,
  });

  final Wallet wallet;
  final String password;
  final String seed;
}

class AuthSeedBackupConfirmed extends AuthBlocEvent {
  const AuthSeedBackupConfirmed();
}

class AuthWalletDownloadRequested extends AuthBlocEvent {
  const AuthWalletDownloadRequested({required this.password});
  final String password;
}

/// Dispatched to restore authentication state after the SDK has been
/// initialized. If a user session exists, the bloc will emit the
/// appropriate [AuthBlocState].
class AuthStateRestoreRequested extends AuthBlocEvent {
  const AuthStateRestoreRequested();
}

class AuthTrezorInitAndAuthStarted extends AuthBlocEvent {
  const AuthTrezorInitAndAuthStarted();
}

class AuthTrezorPinProvided extends AuthBlocEvent {
  const AuthTrezorPinProvided(this.pin);

  final String pin;
}

class AuthTrezorPassphraseProvided extends AuthBlocEvent {
  const AuthTrezorPassphraseProvided(this.passphrase);

  final String passphrase;
}

class AuthTrezorCancelled extends AuthBlocEvent {
  const AuthTrezorCancelled();
}

/// Event emitted on app lifecycle changes to check if a user is already signed
/// in and restore the auth state.
class AuthLifecycleCheckRequested extends AuthBlocEvent {
  const AuthLifecycleCheckRequested();
}
