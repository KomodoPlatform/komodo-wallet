import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:web_dex/shared/utils/utils.dart';

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
