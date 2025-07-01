import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_body.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_ui/komodo_ui.dart';

class CoinItem extends StatelessWidget {
  const CoinItem({
    required this.coin,
    super.key,
    this.amount,
    this.size = CoinItemSize.medium,
    this.subtitleText,
  });

  final Coin? coin;
  final double? amount;
  final CoinItemSize size;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetLogo.fromId(
          coin?.id,
          size: size.coinLogo,
        ),
        SizedBox(width: size.spacer),
        Flexible(
          child: CoinItemBody(
            coin: coin,
            amount: amount,
            size: size,
            subtitleText: subtitleText,
          ),
        ),
      ],
    );
  }
}
