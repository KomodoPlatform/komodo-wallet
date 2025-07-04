import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/constants.dart';

class TrezorDialogSuccess extends StatelessWidget {
  const TrezorDialogSuccess({Key? key, required this.onClose})
      : super(key: key);

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Text(LocaleKeys.success.tr(), style: trezorDialogTitle);
  }
}
