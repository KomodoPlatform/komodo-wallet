import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';

abstract class AuthBlocEvent {
  const AuthBlocEvent();
}

class AuthChangedEvent extends AuthBlocEvent {
  const AuthChangedEvent({required this.mode});
  final AuthorizeMode mode;
}

class AuthLogOutEvent extends AuthBlocEvent {
  const AuthLogOutEvent();
}

class AuthReLogInEvent extends AuthBlocEvent {
  const AuthReLogInEvent({
    required this.seed,
    required this.password,
    required this.wallet,
  });

  final String seed;
  final String password;
  final Wallet wallet;
}
