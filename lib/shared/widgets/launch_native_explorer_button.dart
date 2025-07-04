import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/ui/ui_primary_button.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class LaunchNativeExplorerButton extends StatelessWidget {
  const LaunchNativeExplorerButton({
    Key? key,
    required this.coin,
    this.address,
  }) : super(key: key);
  final Coin coin;
  final String? address;

  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      width: 160,
      height: 30,
      onPressed: () {
        launchURLString(getNativeExplorerUrlByCoin(coin, address));
      },
      text: LocaleKeys.viewOnExplorer.tr(),
    );
  }
}
