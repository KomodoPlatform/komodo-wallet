import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/trezor_init_bloc/trezor_init_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/hw_wallet/hw_wallet.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/hw_dialog_wallet_select.dart';

class HwDialogInit extends StatelessWidget {
  const HwDialogInit({Key? key, required this.close}) : super(key: key);
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HwDialogWalletSelect(
          onSelect: (WalletBrand brand) async {
            if (brand == WalletBrand.trezor &&
                !context.read<TrezorInitBloc>().state.inProgress) {
              context.read<TrezorInitBloc>().add(const TrezorInit());
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: UiUnderlineTextButton(
            text: LocaleKeys.cancel.tr(),
            onPressed: close,
          ),
        )
      ],
    );
  }
}
