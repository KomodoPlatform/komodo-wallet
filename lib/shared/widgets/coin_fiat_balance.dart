import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/shared/widgets/auto_scroll_text.dart';

class CoinFiatBalance extends StatelessWidget {
  const CoinFiatBalance(
    this.coin, {
    super.key,
    this.style,
    this.isSelectable = false,
    this.isAutoScrollEnabled = false,
  });

  final Coin coin;
  final TextStyle? style;
  final bool isSelectable;
  final bool isAutoScrollEnabled;

  @override
  Widget build(BuildContext context) {
    final balanceStream = context.sdk.balances.watchBalance(coin.id);

    final TextStyle mergedStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500).merge(style);

    return StreamBuilder<BalanceInfo>(
        stream: balanceStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final balanceStr = formatUsdValue(
            coin.lastKnownUsdBalance(context.sdk),
          );

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
        });
  }
}
