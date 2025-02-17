import 'package:flutter/material.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_type_list_item.dart';

class WalletsTypeList extends StatelessWidget {
  const WalletsTypeList({Key? key, required this.onWalletTypeClick})
      : super(key: key);
  final void Function(WalletType) onWalletTypeClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: WalletType.values
          .where((type) => type != WalletType.hdwallet)
          .map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: WalletTypeListItem(
                  key: Key('wallet-type-list-item-${type.name}'),
                  type: type,
                  onClick: onWalletTypeClick,
                ),
              ))
          .toList(),
    );
  }
}
