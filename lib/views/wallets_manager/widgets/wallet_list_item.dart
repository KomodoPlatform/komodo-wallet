import 'package:flutter/material.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class WalletListItem extends StatelessWidget {
  const WalletListItem({Key? key, required this.wallet, required this.onClick})
      : super(key: key);
  final Wallet wallet;
  final void Function(Wallet, WalletsManagerExistWalletAction) onClick;

  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      backgroundColor: Theme.of(context).cardColor,
      text: wallet.name,
      prefix: DecoratedBox(
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          Icons.person,
          size: 21,
          color: Theme.of(context).textTheme.labelLarge?.color,
        ),
      ),
      height: 40,
      // backgroundColor: Theme.of(context).colorScheme.onSurface,
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
            child: Text(
              wallet.name,
              // style: DefaultTextStyle.of(context).style.copyWith(
              //       fontWeight: FontWeight.w500,
              //       fontSize: 14,
              //     ),
            ),
          ),
          IconButton(
            onPressed: () =>
                onClick(wallet, WalletsManagerExistWalletAction.delete),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
