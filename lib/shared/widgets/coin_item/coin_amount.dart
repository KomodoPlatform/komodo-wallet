import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class CoinAmount extends StatelessWidget {
  const CoinAmount({
    super.key,
    required this.amount,
    this.style,
  });

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AutoScrollText(
      key: Key('coin-amount-scroll-text-$amount'),
      text: formatDexAmt(amount),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ).merge(style),
    );
  }
}
