import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/auto_scroll_text.dart';

class CoinFiatBalance extends StatelessWidget {
  const CoinFiatBalance(
    this.coin, {
    Key? key,
    this.style,
    this.isSelectable = false,
    this.isAutoScrollEnabled = false,
  }) : super(key: key);

  final Coin coin;
  final TextStyle? style;
  final bool isSelectable;
  final bool isAutoScrollEnabled;

  @override
  Widget build(BuildContext context) {
    final balanceStr = coin.getFormattedUsdBalance;

    final TextStyle mergedStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500).merge(style);

    if (isAutoScrollEnabled) {
      return AutoScrollText(
        text: balanceStr,
        style: mergedStyle,
        isSelectable: isSelectable,
      );
    }

    return isSelectable
        ? SelectableText(balanceStr, style: mergedStyle)
        : Text(balanceStr, style: mergedStyle);
  }
}
