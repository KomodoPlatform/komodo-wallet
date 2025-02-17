import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_event.dart';
import 'package:web_dex/bloc/trezor_connection_bloc/trezor_connection_state.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/model/hw_wallet/trezor_connection_status.dart';
import 'package:web_dex/model/wallet.dart';

class TrezorConnectionBloc
    extends Bloc<TrezorConnectionEvent, TrezorConnectionState> {
  TrezorConnectionBloc({
    required TrezorRepo trezorRepo,
    required KomodoDefiSdk kdfSdk,
    required CurrentWalletBloc walletRepo,
  })  : _kdfSdk = kdfSdk,
        _walletRepo = walletRepo,
        _trezorRepo = trezorRepo,
        super(TrezorConnectionState.initial()) {
    _trezorConnectionStatusListener = trezorRepo.connectionStatusStream
        .listen(_onTrezorConnectionStatusChanged);
    _authModeListener = kdfSdk.auth.authStateChanges.listen(_onAuthModeChanged);

    on<TrezorConnectionStatusChange>(_onConnectionStatusChange);
  }

  void _onTrezorConnectionStatusChanged(TrezorConnectionStatus status) {
    add(TrezorConnectionStatusChange(status: status));
  }

  void _onAuthModeChanged(KdfUser? user) {
    if (user != null) {
      final Wallet? currentWallet = _walletRepo.wallet;
      if (currentWallet == null) return;
      if (currentWallet.config.type != WalletType.trezor) return;

      final String? pubKey = user.walletId.pubkeyHash;
      if (pubKey == null) return;

      _trezorRepo.subscribeOnConnectionStatus(pubKey);
    } else {
      _trezorRepo.unsubscribeFromConnectionStatus();
    }
  }

  final KomodoDefiSdk _kdfSdk;
  final TrezorRepo _trezorRepo;
  final CurrentWalletBloc _walletRepo;
  late StreamSubscription<TrezorConnectionStatus>
      _trezorConnectionStatusListener;
  late StreamSubscription<KdfUser?> _authModeListener;

  Future<void> _onConnectionStatusChange(TrezorConnectionStatusChange event,
      Emitter<TrezorConnectionState> emit) async {
    final status = event.status;
    emit(TrezorConnectionState(status: status));

    switch (status) {
      case TrezorConnectionStatus.unreachable:
        await _kdfSdk.auth.signOut();
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
