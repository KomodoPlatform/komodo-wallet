import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_body.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_logo.dart';

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
        CoinLogo(
          coin: coin,
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
