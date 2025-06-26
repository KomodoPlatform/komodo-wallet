import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/model/hw_wallet/trezor_task.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/constants.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_pin_pad.dart';

Future<void> showTrezorPinDialog(TrezorTask task) async {
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
    popupContent: TrezorDialogPinPad(
      onComplete: (String pin) async {
        final authBloc = context.read<AuthBloc>();
        authBloc.add(AuthTrezorPinProvided(pin));
        close();
      },
      onClose: close,
    ),
  );

  isOpen = true;
  popupManager.show();

  while (isOpen) {
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }
}
