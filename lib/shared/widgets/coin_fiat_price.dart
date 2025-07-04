import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';

class CoinFiatPrice extends StatelessWidget {
  const CoinFiatPrice(
    this.coin, {
    Key? key,
    this.style,
  }) : super(key: key);

  final Coin coin;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final double? usdPrice = coin.usdPrice?.price;
    if (usdPrice == null || usdPrice == 0) return const SizedBox();

    final TextStyle style = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ).merge(this.style);

    // Using separate widgets here to facilitate integration testing
    return Row(
      children: [
        Text('\$', style: style),
        Text(
          formatAmt(usdPrice),
          key: Key('fiat-price-${coin.abbr.toLowerCase()}'),
          style: style,
        ),
      ],
    );
  }
}
