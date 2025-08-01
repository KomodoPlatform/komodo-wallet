import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';

class WalletTypeListItem extends StatelessWidget {
  const WalletTypeListItem({
    Key? key,
    required this.type,
    required this.onClick,
  }) : super(key: key);
  final WalletType type;
  final void Function(WalletType) onClick;

  @override
  Widget build(BuildContext context) {
    final bool needAttractAttention =
        type == WalletType.iguana || type == WalletType.hdwallet;
    final bool isSupported = _checkWalletSupport(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        UiPrimaryButton(
          height: 50,
          backgroundColor: needAttractAttention
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.tertiary,
          onPressed: isSupported ? () => onClick(type) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (type != WalletType.iguana && type != WalletType.hdwallet)
                SvgPicture.asset(
                  _iconPath,
                  width: 25,
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      LocaleKeys.connectSomething.tr(args: [_walletTypeName]),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  String get _iconPath {
    switch (type) {
      case WalletType.iguana:
      case WalletType.hdwallet:
        return '$assetsPath/ui_icons/atomic_dex.svg';
      case WalletType.metamask:
        return '$assetsPath/ui_icons/metamask.svg';
      case WalletType.keplr:
        return '$assetsPath/ui_icons/keplr.svg';
      case WalletType.trezor:
        if (theme.mode == ThemeMode.dark) {
          return '$assetsPath/ui_icons/hardware_wallet.svg';
        } else {
          return '$assetsPath/ui_icons/hardware_wallet_dark.svg';
        }
    }
  }

  String get _walletTypeName {
    switch (type) {
      case WalletType.iguana:
      case WalletType.hdwallet:
        return LocaleKeys.komodoWallet.tr();
      case WalletType.metamask:
        return LocaleKeys.metamask.tr();
      case WalletType.keplr:
        return 'Keplr';
      case WalletType.trezor:
        return LocaleKeys.hardwareWallet.tr();
    }
  }

  bool _checkWalletSupport(WalletType type) {
    switch (type) {
      case WalletType.iguana:
      case WalletType.trezor:
      case WalletType.hdwallet:
        return true;
      case WalletType.keplr:
      case WalletType.metamask:
        return false;
    }
  }
}
