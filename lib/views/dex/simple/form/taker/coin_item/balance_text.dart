import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class BalanceText extends StatelessWidget {
  const BalanceText(this.coin);
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final double? balance = coin.isActive ? coin.balance : null;
    return Text(
      formatDexAmt(balance),
      style: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }
}
