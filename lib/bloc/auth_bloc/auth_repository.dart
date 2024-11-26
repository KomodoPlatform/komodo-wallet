import 'dart:async';

import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/shared/utils/utils.dart';

class AuthRepository {
  AuthRepository();
  final StreamController<AuthorizeMode> _authController =
      StreamController<AuthorizeMode>.broadcast();
  Stream<AuthorizeMode> get authMode => _authController.stream;

  Future<void> logIn(
    AuthorizeMode mode, {
    String? seed,
    String? password,
    String? walletName,
  }) async {
    try {
      await mm2.start(
        passphrase: seed,
        walletName: walletName,
        walletPassword: password,
      );
    } catch (e) {
      log('mm2 start error: ${e.toString()}');
      rethrow;
    }

    setAuthMode(mode);
  }

  void setAuthMode(AuthorizeMode mode) {
    _authController.sink.add(mode);
  }

  Future<void> logOut() async {
    await mm2.stop();
    setAuthMode(AuthorizeMode.noLogin);
  }
}

final AuthRepository authRepo = AuthRepository();
