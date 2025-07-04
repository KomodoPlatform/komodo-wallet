import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/common/coin_list_item_desktop.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/common/coin_list_item_mobile.dart';

class CoinListItem extends StatelessWidget {
  const CoinListItem({
    Key? key,
    required this.coin,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  final Coin coin;
  final Color backgroundColor;
  final void Function(Coin) onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: coin.isActivating ? 0.3 : 1, child: _buildItem());
  }

  Widget _buildItem() {
    return isMobile
        ? CoinListItemMobile(
            coin: coin,
            backgroundColor: backgroundColor,
            onTap: onTap,
          )
        : CoinListItemDesktop(
            coin: coin,
            backgroundColor: backgroundColor,
            onTap: onTap,
          );
  }
}
