import 'package:flutter/material.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:web_dex/shared/widgets/auto_scroll_text.dart';

class WalletListItem extends StatelessWidget {
  const WalletListItem({Key? key, required this.wallet, required this.onClick})
      : super(key: key);
  final Wallet wallet;
  final void Function(Wallet, WalletsManagerExistWalletAction) onClick;

  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      height: 40,
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      onPressed: () => onClick(wallet, WalletsManagerExistWalletAction.logIn),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.person,
              size: 21,
              color: Theme.of(context).textTheme.labelLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoScrollText(
              text: wallet.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // TODO: enable delete for sdk wallets as well when supported
          if (wallet.isLegacyWallet)
            IconButton(
                onPressed: () =>
                    onClick(wallet, WalletsManagerExistWalletAction.delete),
                icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
