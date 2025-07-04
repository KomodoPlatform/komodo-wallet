import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_name.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_protocol_name.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_ticker.dart';
import 'package:komodo_wallet/shared/widgets/segwit_icon.dart';

class CoinItemTitle extends StatelessWidget {
  const CoinItemTitle({
    required this.coin,
    required this.size,
    super.key,
    this.amount,
  });

  final Coin? coin;
  final CoinItemSize size;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinTicker(
          coinId: coin?.abbr,
          style: TextStyle(fontSize: size.titleFontSize, height: 1),
          // Show the 'OLD' and 'TESTNET' suffixes if the coin name is not shown
          // i.e. when the amount is null
          showSuffix: amount != null,
        ),
        SizedBox(width: size.spacer),
        Flexible(
          child: amount == null
              ? CoinName(
                  text: coin?.name,
                  style: TextStyle(fontSize: size.titleFontSize, height: 1),
                )
              : coin?.mode == CoinMode.segwit
                  ? SegwitIcon(height: size.segwitIconSize)
                  : CoinProtocolName(
                      text: coin?.typeNameWithTestnet,
                      size: size,
                    ),
        ),
      ],
    );
  }
}
