import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinTicker extends StatelessWidget {
  const CoinTicker({
    required this.coinId,
    this.showSuffix = false,
    super.key,
    this.style,
  });

  final String? coinId;
  final TextStyle? style;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    final String? coin = coinId;
    if (coin == null) return const SizedBox.shrink();

    return AutoScrollText(
      text: showSuffix ? abbr2TickerWithSuffix(coin) : abbr2Ticker(coin),
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          )
          .merge(style),
    );
  }
}
