import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/constants.dart';

/// Default dialog view, covers all unhandled events
class TrezorDialogMessage extends StatelessWidget {
  const TrezorDialogMessage(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: trezorDialogSubtitle);
  }
}
