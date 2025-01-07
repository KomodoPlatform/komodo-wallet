import 'package:flutter/material.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

class DexFiatAmountText extends StatelessWidget {
  final Coin coin;
  final Rational amount;
  final TextStyle? style;
  const DexFiatAmountText(
      {super.key, required this.coin, required this.amount, this.style});

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle =
        Theme.of(context).textTheme.bodySmall?.merge(style);

    return Text(
      getFormattedFiatAmount(context, coin.abbr, amount),
      style: textStyle,
    );
  }
}
