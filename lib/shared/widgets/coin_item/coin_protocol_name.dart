import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';

class CoinProtocolName extends StatelessWidget {
  const CoinProtocolName({
    super.key,
    this.text,
    this.size,
    this.upperCase = true,
  });

  final String? text;
  final CoinItemSize? size;
  final bool upperCase;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();

    return AutoScrollText(
      text: upperCase ? text!.toUpperCase() : text!,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: theme.custom.dexCoinProtocolColor,
      ).merge(
        TextStyle(
          fontSize: size?.subtitleFontSize,
          height: 1,
        ),
      ),
    );
  }
}
