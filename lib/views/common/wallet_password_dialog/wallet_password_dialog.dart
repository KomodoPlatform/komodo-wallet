import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/auth_bloc/auth_bloc.dart';
import 'package:komodo_wallet/dispatchers/popup_dispatcher.dart';
import 'package:komodo_wallet/model/wallet.dart';
import 'package:komodo_wallet/views/common/wallet_password_dialog/password_dialog_content.dart';

// Shows wallet password dialog and
// returns password value or null (if wrong or cancelled)
Future<String?> walletPasswordDialog(
  BuildContext context, {
  Wallet? wallet,
}) async {
  final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
  wallet ??= currentWallet;
  late PopupDispatcher popupManager;
  bool isOpen = false;
  String? password;

  void close() {
    popupManager.close();
    isOpen = false;
  }

  popupManager = PopupDispatcher(
    context: context,
    popupContent: PasswordDialogContent(
      wallet: wallet,
      onSuccess: (String pass) {
        password = pass;
        close();
      },
      onCancel: close,
    ),
  );

  isOpen = true;
  popupManager.show();

  while (isOpen) {
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }

  return password;
}
