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

class AuthTrezorInitAndAuthStarted extends AuthBlocEvent {
  const AuthTrezorInitAndAuthStarted({
    required this.isRegister,
    required this.derivationMethod,
  });

  final bool isRegister;
  final DerivationMethod derivationMethod;
}

class AuthTrezorPinProvided extends AuthBlocEvent {
  const AuthTrezorPinProvided({required this.taskId, required this.pin});

  final int taskId;
  final String pin;
}

class AuthTrezorPassphraseProvided extends AuthBlocEvent {
  const AuthTrezorPassphraseProvided({
    required this.taskId,
    required this.passphrase,
  });

  final int taskId;
  final String passphrase;
}

class AuthTrezorCancelled extends AuthBlocEvent {
  const AuthTrezorCancelled();
}
