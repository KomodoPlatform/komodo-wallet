import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/coin_group_name.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/coin_group_protocol.dart';

class CoinNameAndProtocol extends StatelessWidget {
  const CoinNameAndProtocol(this.coin, this.opened);

  final Coin? coin;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        CoinGroupName(coin: coin, opened: opened),
        const SizedBox(height: 2),
        CoinGroupProtocol(coin),
      ],
    );
  }
}
