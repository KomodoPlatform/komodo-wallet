import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_size.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_subtitle.dart';
import 'package:komodo_wallet/shared/widgets/coin_item/coin_item_title.dart';

class CoinItemBody extends StatelessWidget {
  const CoinItemBody({
    super.key,
    required this.coin,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: size.spacer),
        CoinItemTitle(coin: coin, size: size, amount: amount),
        SizedBox(height: size.spacer),
        CoinItemSubtitle(
          coin: coin,
          size: size,
          amount: amount,
          text: subtitleText,
        ),
      ],
    );
  }
}
