import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_event.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_state.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/hw_wallet/trezor_connection_status.dart';
import 'package:web_dex/model/wallet.dart';

class TrezorConnectionBloc
    extends Bloc<TrezorConnectionEvent, TrezorConnectionState> {
  TrezorConnectionBloc({
    required TrezorRepo trezorRepo,
    required AuthRepository authRepo,
    required CurrentWalletBloc walletRepo,
  })  : _authRepo = authRepo,
        _walletRepo = walletRepo,
        super(TrezorConnectionState.initial()) {
    _trezorConnectionStatusListener = trezorRepo.connectionStatusStream
        .listen(_onTrezorConnectionStatusChanged);
    _authModeListener = _authRepo.authMode.listen(_onAuthModeChanged);

    on<TrezorConnectionStatusChange>(_onConnectionStatusChange);
  }

  void _onTrezorConnectionStatusChanged(TrezorConnectionStatus status) {
    add(TrezorConnectionStatusChange(status: status));
  }

  void _onAuthModeChanged(AuthorizeMode mode) {
    if (mode == AuthorizeMode.logIn) {
      final Wallet? currentWallet = _walletRepo.wallet;
      if (currentWallet == null) return;
      if (currentWallet.config.type != WalletType.trezor) return;

      final String? pubKey = currentWallet.config.pubKey;
      if (pubKey == null) return;

      trezorRepo.subscribeOnConnectionStatus(pubKey);
    } else {
      trezorRepo.unsubscribeFromConnectionStatus();
    }
  }

  final AuthRepository _authRepo;
  final CurrentWalletBloc _walletRepo;
  late StreamSubscription<TrezorConnectionStatus>
      _trezorConnectionStatusListener;
  late StreamSubscription<AuthorizeMode> _authModeListener;

  Future<void> _onConnectionStatusChange(TrezorConnectionStatusChange event,
      Emitter<TrezorConnectionState> emit) async {
    final status = event.status;
    emit(TrezorConnectionState(status: status));

    switch (status) {
      case TrezorConnectionStatus.unreachable:
        if (await mm2.isSignedIn()) await authRepo.logOut();
        await _authRepo.logIn(AuthorizeMode.noLogin);
        return;
      case TrezorConnectionStatus.unknown:
      case TrezorConnectionStatus.connected:
        return;
    }
  }

  @override
  Future<void> close() {
    _trezorConnectionStatusListener.cancel();
    _authModeListener.cancel();
    return super.close();
  }
}
