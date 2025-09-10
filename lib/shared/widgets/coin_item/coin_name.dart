import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class CoinName extends StatelessWidget {
  const CoinName({required this.text, super.key, this.style});

  final String? text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final String? coinName = text;
    if (coinName == null) return const SizedBox.shrink();

    return Text(
      coinName,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.custom.dexCoinProtocolColor,
      ).merge(style),
      overflow: TextOverflow.ellipsis,
    );
  }
}
