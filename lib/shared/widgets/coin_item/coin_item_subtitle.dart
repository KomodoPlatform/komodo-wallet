import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_amount.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_protocol_name.dart';
import 'package:komodo_wallet/shared/widgets/segwit_icon.dart';

class CoinItemSubtitle extends StatelessWidget {
  const CoinItemSubtitle({
    required this.coin,
    required this.size,
    super.key,
    this.amount,
    this.text,
  });

  final Coin? coin;
  final CoinItemSize size;
  final double? amount;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return amount != null
        ? CoinAmount(
            amount: amount!,
            style: TextStyle(fontSize: size.titleFontSize, height: 1),
          )
        : coin?.mode == CoinMode.segwit && text == null
            ? SegwitIcon(height: size.segwitIconSize)
            : CoinProtocolName(
                text: text ?? coin?.typeNameWithTestnet,
                upperCase: text == null,
                size: size,
              );
  }
}
