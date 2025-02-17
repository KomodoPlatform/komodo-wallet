import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/model/hw_wallet/trezor_task.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/constants.dart';

import 'trezor_steps/trezor_dialog_select_wallet.dart';

Future<void> showTrezorPassphraseDialog(TrezorTask task) async {
  late PopupDispatcher popupManager;
  bool isOpen = false;
  final BuildContext? context = materialPageContext;
  if (context == null) return;

  void close() {
    popupManager.close();
    isOpen = false;
  }

  popupManager = PopupDispatcher(
    context: context,
    width: trezorDialogWidth,
    onDismiss: close,
    popupContent: TrezorDialogSelectWallet(
      onComplete: (String passphrase) async {
        final trezorRepo = RepositoryProvider.of<TrezorRepo>(context);
        await trezorRepo.sendPassphrase(passphrase, task);
        // todo(yurii): handle invalid pin
        close();
      },
    ),
  );

  isOpen = true;
  popupManager.show();

  while (isOpen) {
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }
}
