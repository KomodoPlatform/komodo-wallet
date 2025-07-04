import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

class DisableCoinButton extends StatelessWidget {
  const DisableCoinButton({required this.onClick});
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    return UiUnderlineTextButton(
      key: const Key('disable-coin-button'),
      width: 100,
      height: 24,
      textFontSize: 12,
      textFontWeight: FontWeight.w500,
      text: LocaleKeys.disable.tr(),
      onPressed: onClick,
    );
  }
}
