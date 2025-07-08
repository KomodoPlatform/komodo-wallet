import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/hw_wallet/hw_wallet.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/hw_dialog_wallet_select.dart';

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
                !context.read<AuthBloc>().state.isLoading) {
              context.read<AuthBloc>().add(const AuthTrezorInitAndAuthStarted());
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
